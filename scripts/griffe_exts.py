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
import griffe
import pyslurm
import re

logger = griffe.get_logger(__name__)
SLURM_VERSION = ".".join(pyslurm.__version__.split(".")[:-1])
SLURM_DOCS_URL_BASE = "https://slurm.schedmd.com/archive"
SLURM_DOCS_URL_VERSIONED = f"{SLURM_DOCS_URL_BASE}/slurm-{SLURM_VERSION}-latest"

config_files = ["acct_gather.conf", "slurm.conf", "cgroup.conf", "mpi.conf"]


def replace_with_slurm_docs_url(match):
    first_part = match.group(1)
    second_part = match.group(2)
    ref = f"[{first_part}{second_part}]"
    return f'{ref}({SLURM_DOCS_URL_VERSIONED}/{first_part}.html{second_part})'


pattern = re.compile(
    r'\{('
    + '|'.join([re.escape(config) for config in config_files])
    + r')' # Match the first word before "#"
    + r'([#][^}]+)\}' # Match "#" and everything after it until }
)

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
    def __init__(self, include_paths: list[str] | None = None,
                 ignore_paths: list[str] | None = None) -> None:

        self.include_paths = include_paths
        self.ignore_paths = ignore_paths

    def on_instance(
        self,
        node: ast.AST | griffe.ObjectNode,
        obj: griffe.Object,
        agent: griffe.Visitor | griffe.Inspector,
        **kwargs,
    ) -> None:

        if ((self.include_paths and obj.path not in self.include_paths)
                or (self.ignore_paths and obj.path in self.ignore_paths)):
            return

        try:
            runtime_obj = griffe.dynamic_import(obj.path)
            docstring = runtime_obj.__doc__
        except ImportError:
            logger.debug(f"Could not get dynamic docstring for {obj.path}")
            return
        except AttributeError:
            logger.debug(f"Object {obj.path} does not have a __doc__ attribute")
            return

        if not docstring or not obj.docstring:
            return

        fmt_docstring = pattern.sub(replace_with_slurm_docs_url, docstring)
        if fmt_docstring == docstring:
            # No need to update the docstring if nothing has changed
            return

        docstring = inspect.cleandoc(fmt_docstring)
        obj.docstring.value = docstring
