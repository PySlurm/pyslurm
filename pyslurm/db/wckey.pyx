#########################################################################
# wckey.pyx - pyslurm slurmdbd wckey api
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

from pyslurm.core.error import RPCError
from pyslurm.utils.helpers import (
    instance_to_dict,
    user_to_uid,
)
from pyslurm.utils.uint import *
from pyslurm import settings
from pyslurm import xcollections


cdef class WCKeys(MultiClusterMap):

    def __init__(self, wckeys=None):
        super().__init__(data=wckeys,
                         typ="WCKeys",
                         val_type=WCKey,
                         id_attr=WCKey.name,
                         key_type=str)

    @staticmethod
    def load(Connection db_conn, WCKeyFilter db_filter=None):
        cdef:
            WCKeys out = WCKeys()
            WCKey wckey
            WCKeyFilter cond = db_filter
            SlurmList wckey_data
            SlurmListItem wckey_ptr

        db_conn.validate()

        if not db_filter:
            cond = WCKeyFilter()
        cond._create()

        wckey_data = SlurmList.wrap(slurmdb_wckeys_get(db_conn.ptr, cond.ptr))

        if wckey_data.is_null:
            raise RPCError(msg="Failed to get WCKey data from slurmdbd.")

        for wckey_ptr in SlurmList.iter_and_pop(wckey_data):
            wckey = WCKey.from_ptr(<slurmdb_wckey_rec_t*>wckey_ptr.data)

            cluster = wckey.cluster
            if cluster not in out.data:
                out.data[cluster] = {}
            out.data[cluster][wckey.name] = wckey

        return out


cdef class WCKeyFilter:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)

    def __dealloc__(self):
        self._dealloc()

    def _dealloc(self):
        slurmdb_destroy_wckey_cond(self.ptr)
        self.ptr = NULL

    def _alloc(self):
        self._dealloc()
        self.ptr = <slurmdb_wckey_cond_t*>try_xmalloc(sizeof(slurmdb_wckey_cond_t))
        if not self.ptr:
            raise MemoryError("xmalloc failed for slurmdb_wckey_cond_t")

    def _create(self):
        self._alloc()
        cdef slurmdb_wckey_cond_t *ptr = self.ptr

        make_char_list(&ptr.name_list, self.names)


cdef class WCKey:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, name=None, **kwargs):
        self._alloc_impl()
        self.name = name
        self._init_defaults()
        for k, v in kwargs.items():
            setattr(self, k, v)

    def _init_defaults(self):
        self._cluster = settings.LOCAL_CLUSTER

    def __dealloc__(self):
        self._dealloc_impl()

    def _dealloc_impl(self):
        slurmdb_destroy_wckey_rec(self.ptr)
        self.ptr = NULL

    def _alloc_impl(self):
        if not self.ptr:
            self.ptr = <slurmdb_wckey_rec_t*>try_xmalloc(
                    sizeof(slurmdb_wckey_rec_t))
            if not self.ptr:
                raise MemoryError("xmalloc failed for slurmdb_wckey_rec_t")

            memset(self.ptr, 0, sizeof(slurmdb_wckey_rec_t))

    def __repr__(self):
        return f'pyslurm.db.{self.__class__.__name__}({self.name})'

    @staticmethod
    cdef WCKey from_ptr(slurmdb_wckey_rec_t *in_ptr):
        cdef WCKey wrap = WCKey.__new__(WCKey)
        wrap.ptr = in_ptr
        wrap._init_defaults()
        return wrap

    def to_dict(self):
        """Database WCKey information formatted as a dictionary.

        Returns:
            (dict): Database WCKey information as dict.
        """
        return instance_to_dict(self)

    def __eq__(self, other):
        if isinstance(other, WCKey):
            return self.id == other.id and self.cluster == other.cluster
        return NotImplemented

    @property
    def name(self):
        return cstr.to_unicode(self.ptr.name)

    @property
    def cluster(self):
        cluster = cstr.to_unicode(self.ptr.cluster)
        if not cluster:
            return self._cluster
        return cluster

    @property
    def user_name(self):
        return cstr.to_unicode(self.ptr.user)

    @property
    def user_id(self):
        return self.ptr.uid

    @property
    def is_default(self):
        return bool(self.ptr.is_def)

    @property
    def id(self):
        return self.ptr.id

    @property
    def is_deleted(self):
        if self.ptr.flags & slurm.SLURMDB_WCKEY_FLAG_DELETED:
            return True
        return False

    # TODO: list_t *accounting_list
