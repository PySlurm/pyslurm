#########################################################################
# node.pxd - interface to work with nodes in slurm
#########################################################################
# Copyright (C) 2022 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# Pyslurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Pyslurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
# cython: language_level=3

from libc.string cimport memcpy, memset
from pyslurm cimport slurm
from pyslurm.slurm cimport (
    node_info_t,
    node_info_msg_t,
    update_node_msg_t,
    partition_info_msg_t,
    slurm_load_node,
    slurm_load_node_single,
    slurm_update_node,
    slurm_delete_node,
    slurm_create_node,
    slurm_load_partitions,
    slurm_free_update_node_msg,
    slurm_init_update_node_msg,
    slurm_populate_node_partitions,
    slurm_free_node_info_msg,
    slurm_free_node_info_members,
    slurm_free_update_node_msg,
    slurm_free_partition_info_msg,
    slurm_get_select_nodeinfo,
    slurm_sprint_cpu_bind_type,
    slurm_node_state_string_complete,
    slurm_node_state_string,
    cpu_bind_type_t,
)


cdef class Nodes(dict):

    cdef:
        node_info_msg_t *info
        partition_info_msg_t *part_info
        node_info_t tmp_info


cdef class Node:
    cdef:
        node_info_t *info
        update_node_msg_t *umsg
        dict passwd
        dict groups

    @staticmethod
    cdef Node from_ptr(node_info_t *in_ptr)
    
