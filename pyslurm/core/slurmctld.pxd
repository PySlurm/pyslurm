#########################################################################
# slurmctld.pxd - pyslurm slurmctld api
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
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3

from pyslurm cimport slurm
from pyslurm.slurm cimport (
    slurm_conf_t,
    slurm_load_ctl_conf,
    slurm_free_ctl_conf,
    try_xmalloc,
)
from pyslurm.core.common cimport cstr
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t, int64_t
from pyslurm.core.common.uint cimport *


cdef class Config:
    cdef slurm_conf_t *ptr
