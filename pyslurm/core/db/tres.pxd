#########################################################################
# tres.pxd - pyslurm slurmdbd tres api
#########################################################################
# Copyright (C) 2023 Toni Harzendorf <toni.harzendorf@gmail.com>
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
# cython: embedsignature=True

from pyslurm cimport slurm
from pyslurm.core.common cimport cstr
from libc.stdint cimport uint64_t
from pyslurm.slurm cimport (
    slurmdb_tres_rec_t,
    slurmdb_find_tres_count_in_string,
)


cdef class TrackableResources(dict):
    cdef public raw_str

    @staticmethod
    cdef TrackableResources from_str(char *tres_str)


cdef class TrackableResource:
    cdef slurmdb_tres_rec_t *ptr  
