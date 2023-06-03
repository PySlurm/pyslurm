#########################################################################
# assoc.pyx - pyslurm slurmdbd association api
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
from pyslurm.utils.uint import *


cdef class Associations(dict):

    def __init__(self):
        pass

    @staticmethod
    def load(AssociationSearchFilter search_filter=None,
             Connection db_connection=None):
        cdef:
            Associations assoc_dict = Associations()
            Association assoc
            AssociationSearchFilter cond = search_filter
            SlurmListItem assoc_ptr
            Connection conn = db_connection
            QualitiesOfService qos_data

        if not search_filter:
            cond = AssociationSearchFilter()
        cond._create()

        if not conn:
            conn = Connection.open()

        assoc_dict.info = SlurmList.wrap(
                slurmdb_associations_get(conn.ptr, cond.ptr))
        
        if assoc_dict.info.is_null:
            raise RPCError(msg="Failed to get Association data from slurmdbd")

        qos_data = QualitiesOfService.load(name_is_key=False,
                                           db_connection=conn)

        for assoc_ptr in SlurmList.iter_and_pop(assoc_dict.info):
            assoc = Association.from_ptr(<slurmdb_assoc_rec_t*>assoc_ptr.data)
            assoc.qos_data = qos_data
            assoc_dict[assoc.id] = assoc

        return assoc_dict


cdef class AssociationSearchFilter:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)

    def __dealloc__(self):
        self._dealloc()

    def _dealloc(self):
        slurmdb_destroy_assoc_cond(self.ptr)
        self.ptr = NULL

    def _alloc(self):
        self._dealloc()
        self.ptr = <slurmdb_assoc_cond_t*>try_xmalloc(sizeof(slurmdb_assoc_cond_t))
        if not self.ptr:
            raise MemoryError("xmalloc failed for slurmdb_assoc_cond_t")

    def _create(self):
        self._alloc()
        cdef slurmdb_assoc_cond_t *ptr = self.ptr


cdef class Association:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self):
        self._alloc_impl()

    def __dealloc__(self):
        self._dealloc_impl()

    def _dealloc_impl(self):
        slurmdb_destroy_assoc_rec(self.ptr)
        self.ptr = NULL

    def _alloc_impl(self):
        if not self.ptr:
            self.ptr = <slurmdb_assoc_rec_t*>try_xmalloc(
                    sizeof(slurmdb_assoc_rec_t))
            if not self.ptr:
                raise MemoryError("xmalloc failed for slurmdb_assoc_rec_t")

    @staticmethod
    cdef Association from_ptr(slurmdb_assoc_rec_t *in_ptr):
        cdef Association wrap = Association.__new__(Association)
        wrap.ptr = in_ptr
        return wrap

    def as_dict(self):
        """Database Association information formatted as a dictionary.

        Returns:
            (dict): Database Association information as dict
        """
        return instance_to_dict(self)

    @staticmethod
    def load(name):
        pass

    @property
    def account(self):
        return cstr.to_unicode(self.ptr.acct)

    @account.setter
    def account(self, val):
        cstr.fmalloc(&self.ptr.acct, val)

    @property
    def cluster(self):
        return cstr.to_unicode(self.ptr.cluster)

    @cluster.setter
    def cluster(self, val):
        cstr.fmalloc(&self.ptr.cluster, val)

    @property
    def comment(self):
        return cstr.to_unicode(self.ptr.comment)

    @comment.setter
    def comment(self, val):
        cstr.fmalloc(&self.ptr.comment, val)

    # uint32_t def_qos_id

    # uint16_t flags (ASSOC_FLAG_*)

    @property
    def group_jobs(self):
        return u32_parse(self.ptr.grp_jobs, zero_is_noval=False)

    @group_jobs.setter
    def group_jobs(self, val):
        self.ptr.grp_jobs = u32(val, zero_is_noval=False)

    @property
    def group_jobs_accrue(self):
        return u32_parse(self.ptr.grp_jobs_accrue, zero_is_noval=False)

    @group_jobs_accrue.setter
    def group_jobs_accrue(self, val):
        self.ptr.grp_jobs_accrue = u32(val, zero_is_noval=False)

    @property
    def group_submit_jobs(self):
        return u32_parse(self.ptr.grp_submit_jobs, zero_is_noval=False)

    @group_submit_jobs.setter
    def group_submit_jobs(self, val):
        self.ptr.grp_submit_jobs = u32(val, zero_is_noval=False)

    @property
    def group_tres(self):
        return cstr.to_dict(self.ptr.grp_tres)

    @group_tres.setter
    def group_tres(self, val):
        cstr.from_dict(&self.ptr.grp_tres, val)

    @property
    def group_tres_mins(self):
        return cstr.to_dict(self.ptr.grp_tres_mins)

    @group_tres_mins.setter
    def group_tres_mins(self, val):
        cstr.from_dict(&self.ptr.grp_tres_mins, val)

    @property
    def group_tres_run_mins(self):
        return cstr.to_dict(self.ptr.grp_tres_run_mins)

    @group_tres_run_mins.setter
    def group_tres_run_mins(self, val):
        cstr.from_dict(&self.ptr.grp_tres_run_mins, val)

    @property
    def group_wall_time(self):
        return u32_parse(self.ptr.grp_wall, zero_is_noval=False)

    @group_wall_time.setter
    def group_wall_time(self, val):
        self.ptr.grp_wall = u32(val, zero_is_noval=False)

    @property
    def id(self):
        return self.ptr.id

    @id.setter
    def id(self, val):
        self.ptr.id = val

    @property
    def is_default(self):
        return u16_parse_bool(self.ptr.is_def)

    @property
    def lft(self):
        return self.ptr.lft

    @property
    def max_jobs(self):
        return u32_parse(self.ptr.max_jobs, zero_is_noval=False)

    @max_jobs.setter
    def max_jobs(self, val):
        self.ptr.max_jobs = u32(val, zero_is_noval=False)

    @property
    def max_jobs_accrue(self):
        return u32_parse(self.ptr.max_jobs_accrue, zero_is_noval=False)

    @max_jobs_accrue.setter
    def max_jobs_accrue(self, val):
        self.ptr.max_jobs_accrue = u32(val, zero_is_noval=False)

    @property
    def max_submit_jobs(self):
        return u32_parse(self.ptr.max_submit_jobs, zero_is_noval=False)

    @max_submit_jobs.setter
    def max_submit_jobs(self, val):
        self.ptr.max_submit_jobs = u32(val, zero_is_noval=False)

    @property
    def max_tres_mins_per_job(self):
        return cstr.to_dict(self.ptr.max_tres_mins_pj)

    @max_tres_mins_per_job.setter
    def max_tres_mins_per_job(self, val):
        cstr.from_dict(&self.ptr.max_tres_mins_pj, val)

    @property
    def max_tres_run_mins_per_user(self):
        return cstr.to_dict(self.ptr.max_tres_run_mins)

    @max_tres_run_mins_per_user.setter
    def max_tres_run_mins_per_user(self, val):
        cstr.from_dict(&self.ptr.max_tres_run_mins, val)

    @property
    def max_tres_per_job(self):
        return cstr.to_dict(self.ptr.max_tres_pj)

    @max_tres_per_job.setter
    def max_tres_per_job(self, val):
        cstr.from_dict(&self.ptr.max_tres_pj, val)

    @property
    def max_tres_per_node(self):
        return cstr.to_dict(self.ptr.max_tres_pn)

    @max_tres_per_node.setter
    def max_tres_per_node(self, val):
        cstr.from_dict(&self.ptr.max_tres_pn, val)

    @property
    def max_wall_time_per_job(self):
        return u32_parse(self.ptr.max_wall_pj, zero_is_noval=False)

    @max_wall_time_per_job.setter
    def max_wall_time_per_job(self, val):
        self.ptr.max_wall_pj = u32(val, zero_is_noval=False)

    @property
    def min_priority_threshold(self):
        return u32_parse(self.ptr.min_prio_thresh, zero_is_noval=False)

    @min_priority_threshold.setter
    def min_priority_threshold(self, val):
        self.ptr.min_prio_thresh = u32(val, zero_is_noval=False)

    @property
    def parent_account(self):
        return cstr.to_unicode(self.ptr.parent_acct)

    @property
    def parent_account_id(self):
        return u32_parse(self.ptr.parent_id, zero_is_noval=False)

    @property
    def partition(self):
        return cstr.to_unicode(self.ptr.partition)

    @partition.setter
    def partition(self, val):
        cstr.fmalloc(&self.ptr.partition, val)

    @property
    def priority(self):
        return u32_parse(self.ptr.priority, zero_is_noval=False)

    @priority.setter
    def priority(self, val):
        self.ptr.priority = u32(val)

    @property
    def qos(self):
        return qos_list_to_pylist(self.ptr.qos_list, self.qos_data)

    @qos.setter
    def qos(self, val):
        make_char_list(&self.ptr.qos_list, val)

    @property
    def rgt(self):
        return self.ptr.rgt

    @property
    def shares(self):
        return u32_parse(self.ptr.shares_raw, zero_is_noval=False)

    @shares.setter
    def shares(self, val):
        self.ptr.shares_raw = u32(val)

    @property
    def user(self):
        return cstr.to_unicode(self.ptr.user)

    @user.setter
    def user(self, val):
        cstr.fmalloc(&self.ptr.user, val)

