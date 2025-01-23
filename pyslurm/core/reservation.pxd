#########################################################################
# reservation.pxd - interface to work with reservations in slurm
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

from libc.string cimport memcpy, memset
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libc.stdlib cimport free
from pyslurm cimport slurm
from pyslurm.slurm cimport (
    reserve_info_t,
    reserve_info_msg_t,
    resv_desc_msg_t,
    reservation_name_msg_t,
    reserve_response_msg_t,
    slurm_free_reservation_info_msg,
    slurm_load_reservations,
    slurm_delete_reservation,
    slurm_update_reservation,
    slurm_create_reservation,
    slurm_init_resv_desc_msg,
    xfree,
    try_xmalloc,
)

from pyslurm.utils cimport cstr
from pyslurm.utils cimport ctime
from pyslurm.utils.ctime cimport time_t
from pyslurm.utils.uint cimport *
from pyslurm.xcollections cimport MultiClusterMap

cdef extern void slurm_free_resv_desc_msg(resv_desc_msg_t *msg)
cdef extern void slurm_free_reserve_info_members(reserve_info_t *resv)


cdef class Reservations(MultiClusterMap):

    cdef:
        reserve_info_msg_t *info
        reserve_info_t tmp_info


cdef class Reservation:

    cdef:
        reserve_info_t *info
        resv_desc_msg_t *umsg
        dict passwd
        dict groups

    cdef readonly cluster

    @staticmethod
    cdef Reservation from_ptr(reserve_info_t *in_ptr)
