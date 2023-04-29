#########################################################################
# tres.pyx - pyslurm slurmdbd tres api
#########################################################################
# Copyright (C) 2023 Toni Harzendorf <toni.harzendorf@gmail.com>
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

from pyslurm.core.common.uint import *


cdef class TrackableResources(dict):

    def __init__(self):
        pass

    @staticmethod
    cdef TrackableResources from_str(char *tres_str):
        cdef:
            TrackableResources tres_collection
            TrackableResource tres
            str raw_str = cstr.to_unicode(tres_str)
            dict tres_dict

        tres_collection = TrackableResources.__new__(TrackableResources)
        if not raw_str:
            return tres_collection

        tres_collection.raw_str = raw_str
        tres_dict = cstr.to_dict(tres_str)
        for tres_id, val in tres_dict.items():
            tres = TrackableResource(tres_id)
            tres.ptr.count = val

        return tres

    @staticmethod
    def find_count_in_str(tres_str, typ):
        if not tres_str:
            return 0

        cdef uint64_t tmp
        tmp = slurmdb_find_tres_count_in_string(tres_str, typ)
        if tmp == slurm.INFINITE64 or tmp == slurm.NO_VAL64:
            return 0
        else:
            return tmp


cdef class TrackableResource:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, tres_id):
        self._alloc_impl()
        self.ptr.id = tres_id

    def __dealloc__(self):
        self._dealloc_impl()

    def _alloc_impl(self):
        if not self.ptr:
            self.ptr = <slurmdb_tres_rec_t*>try_xmalloc(
                    sizeof(slurmdb_tres_rec_t))
            if not self.ptr:
                raise MemoryError("xmalloc failed for slurmdb_tres_rec_t")

    def _dealloc_impl(self):
        slurmdb_destroy_tres_rec(self.ptr)
        self.ptr = NULL

    @staticmethod
    cdef TrackableResource from_ptr(slurmdb_tres_rec_t *in_ptr):
        cdef TrackableResource wrap = TrackableResource.__new__(TrackableResource)
        wrap.ptr = in_ptr
        return wrap

    @property
    def id(self):
        return self.ptr.id

    @property
    def name(self):
        return cstr.to_unicode(self.ptr.name)

    @property
    def type(self):
        return cstr.to_unicode(self.ptr.type)

    @property
    def count(self):
        return u64_parse(self.ptr.count)

    # rec_count
    # alloc_secs
