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

from pyslurm.utils.uint import *
from pyslurm.constants import UNLIMITED
from pyslurm.core.error import RPCError


cdef class TrackableResourceFilter:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)

    def __dealloc__(self):
        self._dealloc()

    def _dealloc(self):
        slurmdb_destroy_tres_cond(self.ptr)
        self.ptr = NULL

    def _alloc(self):
        self._dealloc()
        self.ptr = <slurmdb_tres_cond_t*>try_xmalloc(sizeof(slurmdb_tres_cond_t))
        if not self.ptr:
            raise MemoryError("xmalloc failed for slurmdb_tres_cond_t")
        slurmdb_init_tres_cond(self.ptr, 0)

    def _create(self):
        self._alloc()


cdef class TrackableResources(dict):

    def __init__(self):
        pass

    @staticmethod
    def load(Connection db_connection=None, name_is_key=True):
        cdef:
            TrackableResources out = TrackableResources()
            TrackableResource tres
            Connection conn = db_connection
            SlurmList tres_list 
            SlurmListItem tres_ptr 
            TrackableResourceFilter db_filter = TrackableResourceFilter()

        if not conn:
            conn = Connection.open()

        if not conn.is_open:
            raise ValueError("Database connection is not open")

        db_filter._create()
        tres_list = SlurmList.wrap(slurmdb_tres_get(conn.ptr, db_filter.ptr))

        if tres_list.is_null:
            raise RPCError(msg="Failed to get TRES data from slurmdbd")

        for tres_ptr in SlurmList.iter_and_pop(tres_list):
            tres = TrackableResource.from_ptr(
                    <slurmdb_tres_rec_t*>tres_ptr.data)

            if name_is_key and tres.type:
                out[tres.type_and_name] = tres
            else:
                out[tres.id] = tres

        return out

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
    cdef find_count_in_str(char *tres_str, typ, on_noval=0, on_inf=0):
        return find_tres_count(tres_str, typ, on_noval, on_inf)


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
    def type_and_name(self):
        type_and_name = self.type
        if self.name:
            type_and_name = f"{type_and_name}/{self.name}"

        return type_and_name

    @property
    def count(self):
        return u64_parse(self.ptr.count)

    # rec_count
    # alloc_secs


cdef find_tres_count(char *tres_str, typ, on_noval=0, on_inf=0):
    if not tres_str:
        return on_noval

    cdef uint64_t tmp
    tmp = slurmdb_find_tres_count_in_string(tres_str, typ)
    if tmp == slurm.INFINITE64:
        return on_inf
    elif tmp == slurm.NO_VAL64:
        return on_noval
    else:
        return tmp


cdef find_tres_limit(char *tres_str, typ):
    return find_tres_count(tres_str, typ, on_noval=None, on_inf=UNLIMITED)


cdef merge_tres_str(char **tres_str, typ, val):
    cdef uint64_t _val = u64(dehumanize(val))

    current = cstr.to_dict(tres_str[0])
    if _val == slurm.NO_VAL64:
        current.pop(typ, None)
    else:
        current.update({typ : _val})

    cstr.from_dict(tres_str, current)


cdef tres_ids_to_names(char *tres_str, TrackableResources tres_data):
    if not tres_str:
        return {}

    cdef:
        dict tdict = cstr.to_dict(tres_str)
        dict out = {}

    if not tres_data:
        return tdict

    for tid, cnt in tdict.items():
        if isinstance(tid, str) and tid.isdigit():
            _tid = int(tid)
            if _tid in tres_data:
                out[tres_data[_tid].type_and_name] = cnt
                continue

        # If we can't find the TRES ID in our data, return it raw.
        out[tid] = cnt

    return out


def tres_names_to_ids(dict tres_dict, TrackableResources tres_data):
    cdef dict out = {}
    if not tres_dict:
        return out

    for tid, cnt in tres_dict.items():
        real_id = validate_tres_single(tid, tres_data)
        out[real_id] = cnt

    return out


def validate_tres_single(tid, TrackableResources tres_data):
    for tres in tres_data.values():
        if tid == tres.id or tid == tres.type_and_name:
            return tres.id

    raise ValueError(f"Invalid TRES specified: {tid}")
