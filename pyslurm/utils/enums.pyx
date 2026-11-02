#########################################################################
# utils/enums.pyx - pyslurm enum helpers
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
#
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3

from enum import Enum, Flag
import inspect

try:
    from enum import EnumMeta as EnumType
except ImportError:
    from enum import EnumType


class DocstringSupport(EnumType):
    def __new__(metacls, clsname, bases, classdict):
        cls = super().__new__(metacls, clsname, bases, classdict)

        # In the future, if we want to properly document enum members,
        # implement this:
        # source = inspect.getdoc(cls)
        # docstrings = source.replace(" ", "").split("\n")

        for member in cls:
            member.__doc__ = ""

        return cls


class SlurmEnum(str, Enum, metaclass=DocstringSupport):

    def __new__(cls, name, *args):
        # https://docs.python.org/3/library/enum.html
        #
        # 1.
        #    Second argument to str is encoding, third is error. We don't really
        #    care for that, so no need to check.
        # 2.
        #    Python Documentation recommends to not call super().__new__, but
        #    the corresponding types __new__ directly, so str here.
        # 3.
        #    Docs recommend to set _value_
        v = str(name)
        new_string = str.__new__(cls, v)
        new_string._value_ = v

        new_string._flag = int(args[0]) if len(args) >= 1 else 0
        new_string._clear_flag = int(args[1]) if len(args) >= 2 else 0
        return new_string

    def __str__(self):
        return str(self.value)

    @staticmethod
    def _generate_next_value_(name, _start, _count, _last_values):
        # We just care about the name of the member to be defined.
        return name.upper()

    @classmethod
    def from_flag(cls, flags, default):
        out = cls(default)
        for item in cls:
            if flags & item._flag or flags == item._flag:
                return item
        return out

    @classmethod
    def from_value(cls, value, default):
        # Unlike from_flag, this matches on the exact value. Use it for Slurm
        # members that hold one of a set of consecutive constants rather than
        # a bitmask.
        for item in cls:
            if item._flag == value:
                return item
        return cls(default)


class SlurmFlag(Flag, metaclass=DocstringSupport):

    def __new__(cls, flag, *args):
        parent = super()
        if hasattr(parent, "_new_member_"):
            # For Python >= 3.10, use _new_member_.
            # We could very likely just also use object.__new__, but it works
            # here, so no need to change it now.
            obj = parent._new_member_(cls)
        else:
            obj = object.__new__(cls)

        obj._value_ = int(flag)
        obj._clear_flag = int(args[0]) if len(args) >= 1 else 0
        return obj

    @classmethod
    def from_int(cls, value):
        # Any bit that has no member here is silently dropped, so that Flags
        # a newer Slurm version may set do not break decoding.
        known = 0
        for flag in cls:
            known |= flag.value

        return cls(int(value) & known)

    @classmethod
    def from_list(cls, inp):
        out = cls(0)
        for item in inp:
            if isinstance(item, cls):
                out |= item
                continue

            try:
                out |= cls[str(item).upper()]
            except KeyError:
                raise ValueError(
                    f"Invalid {cls.__name__}: {item}. Possible values are: "
                    f"{[flag.name for flag in cls]}"
                ) from None

        return out

    def to_list(self):
        """Names of all the Flags that are set, as a list of strings."""
        return [flag.name for flag in self.__class__ if flag in self]

    def _get_flags_cleared(self):
        val = self.value
        for flag in self.__class__:
            if flag not in self:
                val |= flag._clear_flag
        return val
