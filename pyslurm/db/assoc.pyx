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

from pyslurm.core.error import RPCError, verify_rpc, slurm_errno
from pyslurm.utils.helpers import (
    instance_to_dict,
    user_to_uid,
)
from pyslurm.utils.uint import *
from pyslurm import settings
from pyslurm import xcollections
from pyslurm.db.error import JobsRunningError, DefaultAccountError


cdef class AssociationList(SlurmList):

    def __init__(self, owned=True):
        self.info = slurm.slurm_list_create(slurm.slurmdb_destroy_assoc_rec)
        self.owned = owned

    def append(self, Association assoc):
        slurm.slurm_list_append(self.info, assoc.ptr)
        assoc.owned = False
        self.cnt = slurm.slurm_list_count(self.info)

    def __iter__(self):
        return super().__iter__()

    def __next__(self):
        if self.is_null or self.is_itr_null:
            raise StopIteration

        if self.itr_cnt < self.cnt:
            self.itr_cnt += 1
            assoc = Association.from_ptr(<slurmdb_assoc_rec_t*>slurm.slurm_list_next(self.itr))
            assoc.owned = False
            return assoc

        self._dealloc_itr()
        raise StopIteration

    def extend(self, list_in):
        for item in list_in:
            self.append(<Association>item)


cdef class Associations(MultiClusterMap):

    def __init__(self, assocs=None):
        super().__init__(data=assocs,
                         typ="Associations",
                         val_type=Association,
                         id_attr=Association.id,
                         key_type=int)

    @staticmethod
    def load(Connection db_conn, AssociationFilter db_filter=None):
        cdef:
            Associations out = Associations()
            Association assoc
            AssociationFilter cond = db_filter
            SlurmList assoc_data
            SlurmListItem assoc_ptr
            QualitiesOfService qos_data
            TrackableResources tres_data

        db_conn.validate()

        if not db_filter:
            cond = AssociationFilter()
        cond._create()

        assoc_data = SlurmList.wrap(slurmdb_associations_get(
            db_conn.ptr, cond.ptr))

        if assoc_data.is_null:
            raise RPCError(msg="Failed to get Association data from slurmdbd.")

        # Fetch other necessary dependencies needed for translating some
        # attributes (i.e QoS IDs to its name)
        qos_data = QualitiesOfService.load(db_conn=db_conn,
                                           name_is_key=False)
        tres_data = TrackableResources.load(db_conn=db_conn)

        for assoc_ptr in SlurmList.iter_and_pop(assoc_data):
            assoc = Association.from_ptr(<slurmdb_assoc_rec_t*>assoc_ptr.data)
            assoc.qos_data = qos_data
            assoc.tres_data = tres_data
            _parse_assoc_ptr(assoc)

            cluster = assoc.cluster
            if cluster not in out.data:
                out.data[cluster] = {}
            out.data[cluster][assoc.id] = assoc

        return out

    @staticmethod
    def modify(Connection db_conn, db_filter, Association changes):
        cdef:
            AssociationFilter afilter
            SlurmList response
            SlurmListItem response_ptr
            list out = []

        db_conn.validate()

        # TODO: make db_filter optional?
        # Prepare SQL Filter
        if isinstance(db_filter, Associations):
            assoc_ids = [ass.id for ass in db_filter]
            afilter = AssociationFilter(ids=assoc_ids)
        else:
            afilter = <AssociationFilter>db_filter
        afilter._create()

        # Any data that isn't parsed yet or needs validation is done in this
        # function.
        _create_assoc_ptr(changes, db_conn)

        # Returns a List of char* with the associations that were modified
        response = SlurmList.wrap(slurmdb_associations_modify(
            db_conn.ptr, afilter.ptr, changes.ptr))

        if not response.is_null and response.cnt:
            for response_ptr in response:
                response_str = cstr.to_unicode(<char*>response_ptr.data)
                if not response_str:
                    continue

                # TODO: Better format
                out.append(response_str)

        elif not response.is_null:
            # There was no real error, but simply nothing has been modified
            return None
        else:
            # Autodetects the last slurm error
            raise RPCError()

        return out

    @staticmethod
    def create(Connection db_conn, associations, auto_add=True):
        cdef:
            Association assoc
            AssociationList assoc_list = AssociationList(owned=False)

        if not associations:
            return

        conn.validate()

        for i, assoc in enumerate(associations):
            # Make sure to remove any duplicate associations, i.e. associations
            # having the same account name set. For some reason, the slurmdbd
            # doesn't like that.
            if assoc not in assoc_list:
                assoc_list.append(assoc)

        verify_rpc(slurmdb_associations_add(db_conn.ptr, assoc_list.info))

    def delete(self, Connection db_conn):
        cdef:
            AssociationFilter afilter
            SlurmList response
            SlurmListItem response_ptr

        db_conn.validate()

        ids = [assoc.id for assoc in self.values()]
        if not ids:
            return

        a_filter = AssociationFilter(ids=ids)
        a_filter._create()

        response = SlurmList.wrap(slurmdb_associations_remove(db_conn.ptr,
                                                              a_filter.ptr))
        rc = slurm_errno()

        if rc == slurm.SLURM_SUCCESS or rc == slurm.SLURM_NO_CHANGE_IN_DATA:
            return

       #if rc == slurm.ESLURM_ACCESS_DENIED or response.is_null:
       #    verify_rpc(rc)

        # Handle the error cases.
        if rc == slurm.ESLURM_JOBS_RUNNING_ON_ASSOC:
            raise JobsRunningError.from_response(response, rc)
        elif rc == slurm.ESLURM_NO_REMOVE_DEFAULT_ACCOUNT:
            raise DefaultAccountError.from_response(response, rc)
        else:
            verify_rpc(rc)


cdef class AssociationFilter:

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

    def _parse_users(self):
        if not self.users:
            return None
        return list({user_to_uid(user) for user in self.users})

    def _create(self):
        self._alloc()
        cdef slurmdb_assoc_cond_t *ptr = self.ptr

        make_char_list(&ptr.user_list, self.users)
        make_char_list(&ptr.id_list, self.ids)
        make_char_list(&ptr.acct_list, self.accounts)
        make_char_list(&ptr.parent_acct_list, self.parent_accounts)
        make_char_list(&ptr.cluster_list, self.clusters)
        make_char_list(&ptr.partition_list, self.partitions)
        # TODO: These should be QOS ids, not names
        make_char_list(&ptr.qos_list, self.qos)
        # TODO: ASSOC_COND_FLAGS


cdef class AssociationLimits:
    pass


cdef class Association:

    def __cinit__(self):
        self.ptr = NULL
        self.owned = True

    def __init__(self, **kwargs):
        self._alloc_impl()
        self.id = 0
        self.cluster = settings.LOCAL_CLUSTER
        for k, v in kwargs.items():
            setattr(self, k, v)

    def __dealloc__(self):
        if self.owned:
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

            slurmdb_init_assoc_rec(self.ptr, 0)

    def __repr__(self):
        return f'pyslurm.db.{self.__class__.__name__}({self.id})'

    @staticmethod
    cdef Association from_ptr(slurmdb_assoc_rec_t *in_ptr):
        cdef Association wrap = Association.__new__(Association)
        wrap.ptr = in_ptr
        return wrap

    def to_dict(self, recursive = False):
        """Database Association information formatted as a dictionary.

        Returns:
            (dict): Database Association information as dict
        """
        return instance_to_dict(self, recursive)

    def __eq__(self, other):
        if isinstance(other, Association):
#            return self.id == other.id and self.cluster == other.cluster
            return self.cluster == other.cluster and self.partition == other.partition and self.account == other.account and self.user == other.user
        return NotImplemented

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

    @group_jobs_accrue.setter
    def group_jobs_accrue(self, val):

    @property
    def group_submit_jobs(self):
        return u32_parse(self.ptr.grp_submit_jobs, zero_is_noval=False)

    @group_submit_jobs.setter
    def group_submit_jobs(self, val):
        self.ptr.grp_submit_jobs = u32(val, zero_is_noval=False)

    @property
    def group_wall_time(self):
        return u32_parse(self.ptr.grp_wall, zero_is_noval=False)

    @group_wall_time.setter
    def group_wall_time(self, val):
        self.ptr.grp_wall = u32(val, zero_is_noval=False)

    @property
    def id(self):
        return u32_parse(self.ptr.id)

    @id.setter
    def id(self, val):
        self.ptr.id = val

    @property
    def is_default(self):
        return u16_parse_bool(self.ptr.is_def)

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
    def lineage(self):
        return cstr.to_unicode(self.ptr.lineage)

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

    @property
    def user_id(self):
        return u32_parse(self.ptr.uid, zero_is_noval=False)


cdef _parse_assoc_ptr(Association ass):
    cdef:
        TrackableResources tres = ass.tres_data
        QualitiesOfService qos = ass.qos_data

    policy = ass.policy

    ass.group_tres = TrackableResources.from_cstr(
            ass.ptr.grp_tres, tres)
    ass.group_tres_mins = TrackableResources.from_cstr(
            ass.ptr.grp_tres_mins, tres)
    ass.group_tres_run_mins = TrackableResources.from_cstr(
            ass.ptr.grp_tres_mins, tres)
    ass.max_tres_mins_per_job = TrackableResources.from_cstr(
            ass.ptr.max_tres_mins_pj, tres)
    ass.max_tres_run_mins_per_user = TrackableResources.from_cstr(
            ass.ptr.max_tres_run_mins, tres)
    ass.max_tres_per_job = TrackableResources.from_cstr(
            ass.ptr.max_tres_pj, tres)
    ass.max_tres_per_node = TrackableResources.from_cstr(
            ass.ptr.max_tres_pn, tres)
    ass.qos = qos_list_to_pylist(ass.ptr.qos_list, qos)

    policy.group_jobs = u32_parse(ass.ptr.grp_jobs, zero_is_noval=False)
    policy.group_jobs_accrue = u32_parse(ass.ptr.grp_jobs_accrue, zero_is_noval=False)
    # TODO: default_qos


cdef _create_assoc_ptr(Association ass, conn=None):
    # _set_tres_limits will also check if specified TRES are valid and
    # translate them to its ID which is why we need to load the current TRES
    # available in the system.
    ass.tres_data = TrackableResources.load(db_conn=conn)
    _set_tres_limits(&ass.ptr.grp_tres, ass.group_tres, ass.tres_data)
    _set_tres_limits(&ass.ptr.grp_tres_mins, ass.group_tres_mins,
                    ass.tres_data)
    _set_tres_limits(&ass.ptr.grp_tres_run_mins, ass.group_tres_run_mins,
                    ass.tres_data)
    _set_tres_limits(&ass.ptr.max_tres_mins_pj, ass.max_tres_mins_per_job,
                    ass.tres_data)
    _set_tres_limits(&ass.ptr.max_tres_run_mins, ass.max_tres_run_mins_per_user,
                    ass.tres_data)
    _set_tres_limits(&ass.ptr.max_tres_pj, ass.max_tres_per_job,
                    ass.tres_data)
    _set_tres_limits(&ass.ptr.max_tres_pn, ass.max_tres_per_node,
                    ass.tres_data)

    # _set_qos_list will also check if specified QoS are valid and translate
    # them to its ID, which is why we need to load the current QOS available
    # in the system.
    ass.qos_data = QualitiesOfService.load(db_conn=conn)
    _set_qos_list(&ass.ptr.qos_list, self.qos, ass.qos_data)

    ass.ptr.group_jobs = u32(ass.policy.group_jobs, zero_is_noval=False)
    ass.ptr.group_jobs_accrue = u32(ass.policy.group_jobs_accrue, zero_is_noval=False)

