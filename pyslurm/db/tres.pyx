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
from pyslurm.utils.helpers import instance_to_dict
from pyslurm.utils import cstr
from pyslurm.db.connection import _open_conn_or_error
import json


TRES_TYPE_DELIM = "/"


cdef class TrackableResourceLimits:

    def __init__(self, **kwargs):
        self.fs = {}
        self.gres = {}
        self.license = {}

        for k, v in kwargs.items():
            if TRES_TYPE_DELIM in k:
                typ, name = self._unflatten_tres(k)
                cur_val = getattr(self, typ)

                if not isinstance(cur_val, dict):
                    raise ValueError(f"TRES Type {typ} cannot have a name "
                                     f"({name}). Invalid Value: {typ}/{name}")

                cur_val.update({name : int(v)})
                setattr(self, typ, cur_val)
            else:
                setattr(self, k, v)

    @staticmethod
    cdef from_ids(char *tres_id_str, TrackableResources tres_data):
        tres_list = _tres_ids_to_names(tres_id_str, tres_data)
        if not tres_list:
            return None

        cdef TrackableResourceLimits out = TrackableResourceLimits()

        for tres in tres_list:
            typ, name, cnt = tres
            cur_val = getattr(out, typ, slurm.NO_VAL64)
            if cur_val != slurm.NO_VAL64:
                if isinstance(cur_val, dict):
                    cur_val.update({name : cnt})
                    setattr(out, typ, cur_val)
                else:
                    setattr(out, typ, cnt)

        return out

    def _validate(self, TrackableResources tres_data):
        id_dict = _tres_names_to_ids(self.to_dict(flatten_limits=True),
                                    tres_data)
        return id_dict

    def _unflatten_tres(self, type_and_name):
        typ, name = type_and_name.split(TRES_TYPE_DELIM, 1)
        return typ, name

    def _flatten_tres(self, typ, vals):
        cdef dict out = {}
        for name, cnt in vals.items():
            out[f"{typ}{TRES_TYPE_DELIM}{name}"] = cnt

        return out

    def to_dict(self, flatten_limits=False):
        cdef dict inst_dict = instance_to_dict(self)

        if flatten_limits:
            vals = inst_dict.pop("fs")
            inst_dict.update(self._flatten_tres("fs", vals))

            vals = inst_dict.pop("license")
            inst_dict.update(self._flatten_tres("license", vals))

            vals = inst_dict.pop("gres")
            inst_dict.update(self._flatten_tres("gres", vals))

        return inst_dict


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
        """Load Trackable Resources from the Database.

        Args:
            name_is_key (bool, optional):
                By default, the keys in this dict are the names of each TRES.
                If this is set to `False`, then the unique ID of the TRES will
                be used as dict keys.
        """
        cdef:
            TrackableResources out = TrackableResources()
            TrackableResource tres
            Connection conn
            SlurmList tres_data 
            SlurmListItem tres_ptr 
            TrackableResourceFilter db_filter = TrackableResourceFilter()

        # Prepare SQL Filter
        db_filter._create()

        # Setup DB Conn
        conn = _open_conn_or_error(db_connection)

        # Fetch TRES data
        tres_data = SlurmList.wrap(slurmdb_tres_get(conn.ptr, db_filter.ptr))

        if tres_data.is_null:
            raise RPCError(msg="Failed to get TRES data from slurmdbd")

        # Setup TRES objects
        for tres_ptr in SlurmList.iter_and_pop(tres_data):
            tres = TrackableResource.from_ptr(
                    <slurmdb_tres_rec_t*>tres_ptr.data)
            _id = tres.type_and_name if name_is_key else tres.id
            out[_id] = tres

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

    def to_dict(self):
        return instance_to_dict(self)

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
            type_and_name = f"{type_and_name}{TRES_TYPE_DELIM}{self.name}"

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


cdef _tres_ids_to_names(char *tres_str, TrackableResources tres_data):
    if not tres_str:
        return None

    cdef:
        dict tdict = cstr.to_dict(tres_str)
        list out = []

    if not tres_data:
        return None

    for tid, cnt in tdict.items():
        if isinstance(tid, str) and tid.isdigit():
            _tid = int(tid)
            if _tid in tres_data:
                out.append(
                    (tres_data[_tid].type, tres_data[_tid].name, int(cnt))
                )

    return out


def _tres_names_to_ids(dict tres_dict, TrackableResources tres_data):
    cdef dict out = {}
    if not tres_dict:
        return out

    for tid, cnt in tres_dict.items():
        real_id = _validate_tres_single(tid, tres_data)
        out[real_id] = cnt

    return out


def _validate_tres_single(tid, TrackableResources tres_data):
    for tres in tres_data.values():
        if tid == tres.id or tid == tres.type_and_name:
            return tres.id

    raise ValueError(f"Invalid TRES specified: {tid}")


cdef _set_tres_limits(char **dest, TrackableResourceLimits src,
                          TrackableResources tres_data):
    cstr.from_dict(dest, src._validate(tres_data))
