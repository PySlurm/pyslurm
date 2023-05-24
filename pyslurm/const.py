#########################################################################
# const.py - pyslurm constants use throughout the project
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


from pyslurm.utils.enum_types import StrEnum
from enum import auto


UNLIMITED = "UNLIMITED"


class PartitionState(StrEnum):
    UP = auto()
    DOWN = auto()
    INACTIVE = auto()
    DRAIN = auto()
    UNKNOWN = auto()


class ConsumableResource(StrEnum):
    CPU = auto()
    CORE = auto()
    SOCKET = auto()
    MEMORY = auto()
    CPU_MEMORY = auto()
    CORE_MEMORY = auto()
    SOCKET_MEMORY = auto()


class SelectTypeParameter(StrEnum):
    OTHER_CONS_RES = auto()
    ONE_TASK_PER_CORE = auto()
    PACK_NODES = auto()
    OTHER_CONS_TRES = auto()
    CORE_DEFAULT_DIST_BLOCK = auto()
    LLN = auto()


class PreemptMode(StrEnum):
    OFF = auto()
    SUSPEND = auto()
    REQUEUE = auto()
    CANCEL = auto()
    WITHIN = auto()
    GANG = auto()
