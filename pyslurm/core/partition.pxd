#########################################################################
# partition.pxd - interface to work with partitions in slurm
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

from libc.string cimport memcpy, memset
from pyslurm cimport slurm
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from pyslurm.slurm cimport (
    partition_info_msg_t,
    partition_info_t,
    update_part_msg_t,
    slurm_free_partition_info_members,
    slurm_free_partition_info_msg,
    slurm_free_update_part_msg,
    slurm_init_part_desc_msg,
    slurm_load_partitions,
    slurm_sprint_cpu_bind_type,
    cpu_bind_type_t,
    slurm_preempt_mode_string,
    slurm_preempt_mode_num,
    xfree,
    try_xmalloc,
)
from pyslurm.utils cimport cstr
from pyslurm.utils cimport ctime
from pyslurm.utils.ctime cimport time_t
from pyslurm.utils.uint cimport *
from pyslurm.core cimport slurmctld


cdef class Partitions(dict):
    """A collection of [pyslurm.Partition][] objects.

    Args:
        partitions (Union[list, dict, str], optional=None):
            Partitions to initialize this collection with.

    Attributes:
        free_memory (int):
            Amount of free memory in this node collection. (in Mebibytes)

    Raises:
        MemoryError: If malloc fails to allocate memory.
    """
    cdef:
        partition_info_msg_t *info
        partition_info_t tmp_info


cdef class Partition:
    """A Slurm partition.

    Args:
        name (str, optional=None):
            Name of a Partition

    Other Parameters:
        state (str):
            State of the Partition

    Attributes:
        name (str):
            Name of the node.

    Raises:
        MemoryError: If malloc fails to allocate memory.
    """
    cdef:
        partition_info_t *ptr
        dict passwd
        dict groups
        int power_save_enabled
        slurmctld.Config slurm_conf

    @staticmethod
    cdef Partition from_ptr(partition_info_t *in_ptr)
