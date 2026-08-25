#########################################################################
# scripts/griffe_exts.py - griffe extensions for documentation
#########################################################################
# Copyright (C) 2025 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# This file is part of PySlurm
#
# PySlurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# PySlurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PySlurm; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

import ast
import inspect
import pathlib
import re
import griffe
import pyslurm

logger = griffe.get_logger(__name__)
SLURM_VERSION = ".".join(pyslurm.__version__.split(".")[:-1])
SLURM_DOCS_URL_BASE = "https://slurm.schedmd.com/archive"
SLURM_DOCS_URL_VERSIONED = f"{SLURM_DOCS_URL_BASE}/slurm-{SLURM_VERSION}-latest"

config_files = [
    "acct_gather.conf",
    "slurm.conf",
    "cgroup.conf",
    "mpi.conf",
    "scontrol",
]

slurm_url_pattern = re.compile(
    r"\{("
    + "|".join([re.escape(c) for c in config_files])
    + r")"
    + r"([#][^}]+)\}"
)

# Matches: def <name>(self) -> <type>:
_property_annotation_re = re.compile(
    r"\bdef\s+{name}\s*\(\s*self\s*\)\s*->\s*([\w\[\], |.]+?)\s*:"
)


def replace_with_slurm_docs_url(match):
    first_part = match.group(1)
    second_part = match.group(2)
    ref = f"[{first_part}{second_part}]"
    return f"{ref}({SLURM_DOCS_URL_VERSIONED}/{first_part}.html{second_part})"


def _find_pyx_file(obj: griffe.Object) -> pathlib.Path | None:
    """Derive the .pyx source path from an object's dotted path."""
    parts = obj.path.split(".")
    for i in range(len(parts), 0, -1):
        candidate = pathlib.Path(*parts[:i]).with_suffix(".pyx")
        if candidate.exists():
            return candidate
    return None


def _read_pyx_annotation(obj: griffe.Object) -> str | None:
    """Return the -> annotation for a property from the .pyx source, or None."""
    pyx = _find_pyx_file(obj)
    if pyx is None:
        return None
    try:
        source = pyx.read_text()
        pat = _property_annotation_re.pattern.format(name=re.escape(obj.name))
        m = re.search(pat, source)
        return m.group(1) if m else None
    except Exception:
        return None


# This class is inspired from here, with a few adaptions:
# https://github.com/mkdocstrings/griffe/blob/97f3613c5f0ae5653e8b91479c716b9ec44baacc/docs/guide/users/extending.md#full-example
#
#   ISC License
#
#   Copyright (c) 2021, Timothée Mazzucotelli
#
#   Permission to use, copy, modify, and/or distribute this software for any
#   purpose with or without fee is hereby granted, provided that the above
#   copyright notice and this permission notice appear in all copies.
#
#   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
class DynamicDocstrings(griffe.Extension):
    def __init__(
        self,
        include_paths: list[str] | None = None,
        ignore_paths: list[str] | None = None,
    ) -> None:
        self.include_paths = include_paths
        self.ignore_paths = ignore_paths

    def _is_filtered(self, obj: griffe.Object) -> bool:
        if self.include_paths and obj.path not in self.include_paths:
            return True
        if self.ignore_paths and obj.path in self.ignore_paths:
            return True
        return False

    def _apply_slurm_url_substitution(self, obj: griffe.Object) -> None:
        if not obj.docstring:
            return
        original = obj.docstring.value
        if not slurm_url_pattern.search(original):
            return
        updated = slurm_url_pattern.sub(replace_with_slurm_docs_url, original)
        obj.docstring.value = inspect.cleandoc(updated)

    def on_instance(
        self,
        node: ast.AST | griffe.ObjectNode,
        obj: griffe.Object,
        agent: griffe.Visitor | griffe.Inspector,
        **kwargs,
    ) -> None:
        if self._is_filtered(obj):
            return

        # Fix up Enum member display: strip class prefix from value and
        # remove labels so they render cleanly in the docs.
        if hasattr(obj.parent, "bases"):
            for base in obj.parent.bases:
                b = base.lower()
                if "enum" in b and not obj.name.startswith("_"):
                    v = obj.value[:-1].split(" ")[-1]
                    obj.value = v
                    obj.labels = {}
                    if "slurmflag" in b:
                        obj.value = None

        self._apply_slurm_url_substitution(obj)

    def on_attribute_instance(
        self,
        node: ast.AST | griffe.ObjectNode,
        attr: griffe.Attribute,
        agent: griffe.Visitor | griffe.Inspector,
        **kwargs,
    ) -> None:
        if self._is_filtered(attr):
            return

        # Cython cdef class properties appear as Attribute objects with a
        # "property" label but no annotation, because the C-level descriptor
        # has no fget and griffe cannot extract the -> type at runtime.
        # Read the annotation directly from the .pyx source instead.
        if attr.annotation is not None:
            return
        if "property" not in attr.labels:
            return

        ann = _read_pyx_annotation(attr)
        if ann:
            attr.annotation = griffe.ExprName(ann)
