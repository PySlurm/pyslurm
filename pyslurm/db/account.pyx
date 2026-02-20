#########################################################################
# account.pyx - pyslurm slurmdbd account api
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
from pyslurm import xcollections
from pyslurm.db.error import DefaultAccountError, JobsRunningError


cdef class Accounts(dict):

    def __init__(self, accounts=None):
        super().__init__()

    @staticmethod
    def load(Connection db_conn, AccountFilter db_filter=None):
        cdef:
            Accounts out = Accounts()
            Account account
            AccountFilter cond = db_filter
            SlurmList account_data
            SlurmListItem account_ptr
            SlurmList assoc_data
            SlurmListItem assoc_ptr
            Association assoc
            QualitiesOfService qos_data
            TrackableResources tres_data

        db_conn.validate()

        if not db_filter:
            cond = AccountFilter()

        if cond.with_assocs is not False:
            cond.with_assocs = True

        cond._create()
        account_data = SlurmList.wrap(slurmdb_accounts_get(db_conn.ptr, cond.ptr))

        if account_data.is_null:
            raise RPCError(msg="Failed to get Account data from slurmdbd.")

        qos_data = QualitiesOfService.load(db_conn=db_conn,
                                           name_is_key=False)
        tres_data = TrackableResources.load(db_conn=db_conn)

        for account_ptr in SlurmList.iter_and_pop(account_data):
            account = Account.from_ptr(<slurmdb_account_rec_t*>account_ptr.data)
            out[account.name] = account

            assoc_data = SlurmList.wrap(account.ptr.assoc_list, owned=False)
            for assoc_ptr in SlurmList.iter_and_pop(assoc_data):
                assoc = Association.from_ptr(<slurmdb_assoc_rec_t*>assoc_ptr.data)
                assoc.qos_data = qos_data
                assoc.tres_data = tres_data
                _parse_assoc_ptr(assoc)

                if not assoc.user:
                    # This is the Association of the account itself.
                    account.association = assoc
                else:
                    # These must be User Associations.
                    account.associations.append(assoc)

        return out

    @staticmethod
    def create(Connection db_conn, accounts):
        cdef:
            Account account
            SlurmList account_list
            list assocs_to_add = []

        db_conn.validate()
        account_list = SlurmList.create(slurmdb_destroy_account_rec, owned=False)

        for account in accounts:
#           if not account.associations and add_assoc:
#               # For convenience, we create the associations by default
#               # automatically, just like sacctmgr. Can be disabled for more
#               # control.
#               assoc = Association(account=account.name)
#               account.associations.append(assoc)

            assocs_to_add.extend(account.associations)
            slurm.slurm_list_append(account_list.info, account.ptr)

        verify_rpc(slurmdb_accounts_add(db_conn.ptr, account_list.info))
        Associations.create(db_conn, assocs_to_add)

    def delete(self, Connection db_conn):
        cdef:
            AccountFilter a_filter
            SlurmList response
            list out = []

        db_conn.validate()

        a_filter = AccountFilter(names=list(self.keys()))
        a_filter._create()

        response = SlurmList.wrap(slurmdb_accounts_remove(db_conn.ptr, a_filter.ptr))
        rc = slurm_errno()

        if rc == slurm.SLURM_SUCCESS or rc == slurm.SLURM_NO_CHANGE_IN_DATA:
            return

#       if rc == slurm.ESLURM_ACCESS_DENIED or response.is_null:
#           verify_rpc(rc)

        # Handle the error cases.
        if rc == slurm.ESLURM_JOBS_RUNNING_ON_ASSOC:
            raise JobsRunningError.from_response(response, rc)
        elif rc == slurm.ESLURM_NO_REMOVE_DEFAULT_ACCOUNT:
            raise DefaultAccountError.from_response(response, rc)
        else:
            verify_rpc(rc)


cdef class AccountFilter:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)

    def __dealloc__(self):
        self._dealloc()

    def _dealloc(self):
        slurmdb_destroy_account_cond(self.ptr)
        self.ptr = NULL

    def _alloc(self):
        self._dealloc()
        self.ptr = <slurmdb_account_cond_t*>try_xmalloc(sizeof(slurmdb_account_cond_t))
        if not self.ptr:
            raise MemoryError("xmalloc failed for slurmdb_account_cond_t")

        memset(self.ptr, 0, sizeof(slurmdb_account_cond_t))

        self.ptr.assoc_cond = <slurmdb_assoc_cond_t*>try_xmalloc(sizeof(slurmdb_assoc_cond_t))
        if not self.ptr.assoc_cond:
            raise MemoryError("xmalloc failed for slurmdb_assoc_cond_t")

    def _parse_flag(self, val, flag_val):
        if val:
            self.ptr.flags |= flag_val

    def _create(self):
        self._alloc()
        cdef slurmdb_account_cond_t *ptr = self.ptr

        make_char_list(&ptr.assoc_cond.acct_list, self.names)
        self._parse_flag(self.with_assocs, slurm.SLURMDB_ACCT_FLAG_WASSOC)
        self._parse_flag(self.with_deleted, slurm.SLURMDB_ACCT_FLAG_DELETED)
        self._parse_flag(self.with_coordinators, slurm.SLURMDB_ACCT_FLAG_WCOORD)


cdef class Account:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, name=None, **kwargs):
        self._alloc_impl()
        self.name = name
        self._init_defaults()
        for k, v in kwargs.items():
            setattr(self, k, v)

    def _init_defaults(self):
        self.associations = []
        self.association = None
        self.coordinators = []

    def __dealloc__(self):
        self._dealloc_impl()

    def _dealloc_impl(self):
        slurmdb_destroy_account_rec(self.ptr)
        self.ptr = NULL

    def _alloc_impl(self):
        if not self.ptr:
            self.ptr = <slurmdb_account_rec_t*>try_xmalloc(
                    sizeof(slurmdb_account_rec_t))
            if not self.ptr:
                raise MemoryError("xmalloc failed for slurmdb_account_rec_t")

            memset(self.ptr, 0, sizeof(slurmdb_account_rec_t))

    def __repr__(self):
        return f'pyslurm.db.{self.__class__.__name__}({self.name})'

    @staticmethod
    cdef Account from_ptr(slurmdb_account_rec_t *in_ptr):
        cdef Account wrap = Account.__new__(Account)
        wrap.ptr = in_ptr
        wrap._init_defaults()
        return wrap

    def to_dict(self):
        """Database Account information formatted as a dictionary.

        Returns:
            (dict): Database Account information as dict.
        """
        return instance_to_dict(self)

    def __eq__(self, other):
        if isinstance(other, Account):
            return self.name == other.name
        return NotImplemented

    def create(self, Connection db_conn):
        Accounts.create(db_conn, [self])

    @property
    def name(self):
        return cstr.to_unicode(self.ptr.name)

    @name.setter
    def name(self, val):
        cstr.fmalloc(&self.ptr.name, val)

    @property
    def description(self):
        return cstr.to_unicode(self.ptr.description)

    @description.setter
    def description(self, val):
        cstr.fmalloc(&self.ptr.description, val)

    @property
    def organization(self):
        return cstr.to_unicode(self.ptr.organization)

    @organization.setter
    def organization(self, val):
        cstr.fmalloc(&self.ptr.organization, val)

    @property
    def is_deleted(self):
        if self.ptr.flags & slurm.SLURMDB_ACCT_FLAG_DELETED:
            return True
        return False
