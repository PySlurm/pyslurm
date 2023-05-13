#########################################################################
# qos.pyx - pyslurm slurmdbd qos api
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

from pyslurm.core.error import RPCError
from pyslurm.utils.helpers import instance_to_dict


cdef class QualitiesOfService(dict):

    def __init__(self):
        pass

    @staticmethod
    def load(search_filter=None, name_is_key=True, db_connection=None):
        cdef:
            QualitiesOfService qos_dict = QualitiesOfService()
            QualityOfService qos
            QualityOfServiceSearchFilter cond
            SlurmListItem qos_ptr
            Connection conn = <Connection>db_connection

        if search_filter:
            cond = <QualityOfServiceSearchFilter>search_filter
        else:
            cond = QualityOfServiceSearchFilter()

        cond._create()
        qos_dict.db_conn = Connection.open() if not conn else conn
        qos_dict.info = SlurmList.wrap(slurmdb_qos_get(qos_dict.db_conn.ptr,
                                                       cond.ptr))
        if qos_dict.info.is_null:
            raise RPCError(msg="Failed to get QoS data from slurmdbd")

        for qos_ptr in SlurmList.iter_and_pop(qos_dict.info):
            qos = QualityOfService.from_ptr(<slurmdb_qos_rec_t*>qos_ptr.data)
            if name_is_key:
                qos_dict[qos.name] = qos
            else:
                qos_dict[qos.id] = qos

        return qos_dict


cdef class QualityOfServiceSearchFilter:

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

    def _parse_preempt_modes(self):
        if not self.preempt_modes:
            return 0

        if isinstance(self.preempt_modes, int):
            return self.preempt_modes
        
        out = 0
        for mode in self.preempt_modes:
            _mode = slurm_preempt_mode_num(mode)
            if _mode == slurm.NO_VAL16:
                raise ValueError(f"Unknown preempt mode: {mode}")

            out |= _mode

        return out

    def _create(self):
        self._alloc()
        cdef slurmdb_qos_cond_t *ptr = self.ptr

        make_char_list(&ptr.name_list, self.names)
        make_char_list(&ptr.id_list, self.ids)
        make_char_list(&ptr.description_list, self.descriptions)
        ptr.preempt_mode = self._parse_preempt_modes()
        ptr.with_deleted = 1 if bool(self.with_deleted) else 0
        

cdef class QualityOfService:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, name=None):
        self._alloc_impl()
        self.name = name

    def __dealloc__(self):
        self._dealloc_impl()

    def _dealloc_impl(self):
        slurmdb_destroy_qos_rec(self.ptr)
        self.ptr = NULL

    def _alloc_impl(self):
        if not self.ptr:
            self.ptr = <slurmdb_qos_rec_t*>try_xmalloc(
                    sizeof(slurmdb_qos_rec_t))
            if not self.ptr:
                raise MemoryError("xmalloc failed for slurmdb_qos_rec_t")

    @staticmethod
    cdef QualityOfService from_ptr(slurmdb_qos_rec_t *in_ptr):
        cdef QualityOfService wrap = QualityOfService.__new__(QualityOfService)
        wrap.ptr = in_ptr
        return wrap

    def as_dict(self):
        """Database QualityOfService information formatted as a dictionary.

        Returns:
            (dict): Database QualityOfService information as dict
        """
        return instance_to_dict(self)

    @staticmethod
    def load(name):
        """Load the information for a specific Quality of Service.

        Args:
            name (str):
                Name of the Quality of Service to be loaded.

        Returns:
            (QualityOfService): Returns a new QualityOfService
                instance.

        Raises:
            RPCError: If requesting the information from the database was not
                sucessful.
        """
        qfilter = QualityOfServiceSearchFilter(names=[name])
        qos_data = QualitiesOfService.load(qfilter)
        if not qos_data or name not in qos_data:
            raise RPCError(msg=f"QualityOfService {name} does not exist")

        return qos_data[name]

    @property
    def name(self):
        return cstr.to_unicode(self.ptr.name)

    @name.setter
    def name(self, val):
        cstr.fmalloc(&self.ptr.name, val)

    @property
    def description(self):
        return cstr.to_unicode(self.ptr.description)

    @property
    def id(self):
        return self.ptr.id
