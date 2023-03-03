#########################################################################
# tres.pyx - pyslurm slurmdbd tres api
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
# cython: embedsignature=True

from pyslurm.core.common.uint import *


cdef class TrackableResources(dict):

    def __init__(self):
        pass

    @staticmethod
    cdef TrackableResources from_str(char *tres_str):
        cdef:
            TrackableResources tres
            str raw_str = cstr.to_unicode(tres_str)
            dict tres_dict

        tres = TrackableResources.__new__(TrackableResources)
        if not raw_str:
            return tres

        tres.raw_str = raw_str
        tres_dict = cstr.to_dict(tres_str)
        for tres_id, val in tres_dict.items():
            # TODO: resolve ids to type name
            pass

        return tres

    @staticmethod
    def find_count_in_str(tres_str, typ):
        cdef uint64_t tmp
        tmp = slurmdb_find_tres_count_in_string(tres_str, typ)
        return u64_parse(tmp)


cdef class TrackableResource:

    def __cinit__(self):
        self.ptr = NULL
