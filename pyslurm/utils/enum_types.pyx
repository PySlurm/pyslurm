#########################################################################
# enum_types.pyx - custom enums
#########################################################################
# Copyright (C) 2023 Toni Harzendorf <toni.harzendorf@gmail.com>
# Copyright (C) 2023 PySlurm Developers
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


import enum


# StrEnum is only available in relatively new python versions, but its easy to
# implement since its just a mixin of "str" and "enum.Enum"
# https://docs.python.org/3/library/enum.html#notes
class StrEnum(str, enum.Enum):

    def __str__(self):
        return str(self.value)

    def _generate_next_value_(name, *_unused):
        return name


def try_cast_enum(value, enum_type, default=None):
    try:
        return enum_type(value) 
    except ValueError:
        return default
