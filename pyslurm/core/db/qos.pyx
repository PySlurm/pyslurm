#########################################################################
# qos.pyx - pyslurm slurmdbd qos api
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

from pyslurm.core.error import RPCError


cdef class QualitiesOfService(dict):

    def __init__(self):
        pass

    @staticmethod
    def load(*args, name_is_key=True, db_connection=None, **kwargs):
        cdef:
            QualitiesOfService qos_dict = QualitiesOfService()
            QualityOfService qos
            QualityOfServiceConditions cond
            SlurmListItem qos_ptr
            Connection conn = <Connection>db_connection

        if args and isinstance(args[0], QualityOfServiceConditions):
            cond = <QualityOfServiceConditions>args[0]
        else:
            cond = QualityOfServiceConditions(**kwargs)

        cond._create()
        qos_dict.db_conn = Connection() if not conn else conn
        qos_dict.info = SlurmList.wrap(slurmdb_qos_get(qos_dict.db_conn.ptr,
                                                       cond.ptr))
        if qos_dict.info.is_null():
            raise RPCError(msg="Failed to get QoS from slurmdbd")

        for qos_ptr in SlurmList.iter_and_pop(qos_dict.info):
            qos = QualityOfService.from_ptr(<slurmdb_qos_rec_t*>qos_ptr.data)
            if name_is_key:
                qos_dict[qos.name] = qos
            else:
                qos_dict[qos.id] = qos

        return qos_dict


cdef class QualityOfServiceConditions:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)

    def __dealloc__(self):
        self._dealloc()

    def _dealloc(self):
        slurmdb_destroy_qos_cond(self.ptr)
        self.ptr = NULL

    def _alloc(self):
        self._dealloc()
        self.ptr = <slurmdb_qos_cond_t*>try_xmalloc(sizeof(slurmdb_qos_cond_t))
        if not self.ptr:
            raise MemoryError("xmalloc failed for slurmdb_qos_cond_t")

    def _create(self):
        self._alloc()
        cdef slurmdb_qos_cond_t *ptr = self.ptr


cdef class QualityOfService:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, qos_id):
        pass

    def __dealloc__(self):
        slurmdb_destroy_qos_rec(self.ptr)
        self.ptr = NULL

    @staticmethod
    cdef QualityOfService from_ptr(slurmdb_qos_rec_t *in_ptr):
        cdef QualityOfService wrap = QualityOfService.__new__(QualityOfService)
        wrap.ptr = in_ptr
        return wrap

    @property
    def name(self):
        return cstr.to_unicode(self.ptr.name)

    @property
    def description(self):
        return cstr.to_unicode(self.ptr.description)

    @property
    def id(self):
        return self.ptr.id
