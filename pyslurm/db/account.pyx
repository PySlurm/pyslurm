#########################################################################
# account.pyx - pyslurm slurmdbd account api
#########################################################################
# Copyright (C) 2026 Toni Harzendorf <toni.harzendorf@gmail.com>
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

from pyslurm.core.error import (
    RPCError,
    slurm_errno,
    verify_rpc,
    NotFoundError,
    _get_modify_arguments_for,
)
from pyslurm.utils.helpers import (
    instance_to_dict,
    user_to_uid,
)
from pyslurm.utils.uint import *
from pyslurm import xcollections
from pyslurm.db.error import handle_response
from typing import Any, Union, Optional, List, Dict


cdef class AccountAPI(ConnectionWrapper):

    def load(self, db_filter: Optional[AccountFilter] = None):
        cdef:
            Accounts out = Accounts()
            Account account
            SlurmList account_data
            SlurmListItem account_ptr
            SlurmList assoc_data
            SlurmListItem assoc_ptr
            Association assoc
            QualitiesOfService qos_data
            TrackableResources tres_data

        self.db_conn.validate()

        if not db_filter:
            db_filter = AccountFilter()

        if db_filter.with_assocs is not False:
            db_filter.with_assocs = True

        db_filter._create()
        account_data = SlurmList.wrap(slurmdb_accounts_get(self.db_conn.ptr, db_filter.ptr))

        if account_data.is_null:
            raise RPCError(msg="Failed to get Account data from slurmdbd.")

        qos_data = self.db_conn.qos.load(name_is_key=False)
        tres_data = self.db_conn.tres.load()

        for account_ptr in SlurmList.iter_and_pop(account_data):
            account = Account.from_ptr(<slurmdb_account_rec_t*>account_ptr.data)
            out[account.name] = account
            self.db_conn.apply_reuse(account)

            assoc_data = SlurmList.wrap(account.ptr.assoc_list, owned=False)
            for assoc_ptr in SlurmList.iter_and_pop(assoc_data):
                assoc = Association.from_ptr(<slurmdb_assoc_rec_t*>assoc_ptr.data)
                assoc.qos_data = qos_data
                assoc.tres_data = tres_data
                self.db_conn.apply_reuse(assoc)
                _parse_assoc_ptr(assoc)

                if not assoc.user:
                    # This is the Association of the account itself.
                    account.association = assoc
                else:
                    # These must be User Associations.
                    # TODO: maybe rename to user_associations
                    account.associations.append(assoc)

        self.db_conn.apply_reuse(out)
        return out

    def delete(self, db_filter: AccountFilter):
        out = []
        # Check is required because for some reason if the acct_cond doesn't
        # contain any valid conditions, slurmdbd will delete all accounts.
        # TODO: Maybe make it configurable
        if not db_filter.names:
            return

        self.db_conn.validate()
        db_filter._create()

        response = SlurmList.wrap(slurmdb_accounts_remove(self.db_conn.ptr, db_filter.ptr))
        rc = slurm_errno()
        self.db_conn.check_commit(rc)
        return handle_response(response, rc)

    def modify(
        self,
        db_filter: AccountFilter,
        changes: Optional[Account] = None,
        **kwargs: Any
    ):
        cdef Account _changes

        _changes = _get_modify_arguments_for(Account, changes, **kwargs)

        self.db_conn.validate()
        db_filter._create()

        response = SlurmList.wrap(slurmdb_accounts_modify(
            self.db_conn.ptr, db_filter.ptr, _changes.ptr)
        )
        rc = slurm_errno()
        self.db_conn.check_commit(rc)
        return handle_response(response, rc)

    def create(self, accounts: List[Account]):
        cdef:
            Account account
            SlurmList account_list
            list assocs_to_add = []

        self.db_conn.validate()
        account_list = SlurmList.create(slurmdb_destroy_account_rec, owned=False)

        for account in accounts:
            if not account.association:
                account.association = Association(account=account.name)

            assocs_to_add.append(account.association)
            slurm.slurm_list_append(account_list.info, account.ptr)

        rc = slurmdb_accounts_add(self.db_conn.ptr, account_list.info)

        # Could also solve this construct via a simple try..finally, but I just
        # don't want to execute commit/rollback potentially twice, even if it
        # is completely fine.
        try:
            if rc == slurm.SLURM_SUCCESS:
                self.db_conn.associations.create(assocs_to_add)
        except RPCError:
            # Just re-raise - required rollback was already taken care of
            raise
        except Exception:
            # Doing this catch-all thing might be too cautious, but just in
            # case anything goes wrong before Associations were attempted to be
            # added, we make sure that adding the users is also rollbacked.
            #
            # Because we don't want to leave Users with no associations behind
            # in the system, if associations were requested to be added.
            self.db_conn.check_commit(slurm.SLURM_ERROR)
            raise

        # TODO: SLURM_NO_CHANGE_IN_DATA
        # Should this be an error?

        # Rollback or commit in case no associations were attempted to be added
        self.db_conn.check_commit(rc)
        verify_rpc(rc)


cdef class Accounts(dict):

    def __init__(self, accounts={}, **kwargs: Any):
        super().__init__()
        self.update(accounts)
        self.update(kwargs)
        self._db_conn = None

    @staticmethod
    def load(db_conn: Connection, db_filter: Optional[AccountFilter] = None):
        return db_conn.accounts.load(db_filter)

    def delete(self, db_conn: Optional[Connection] = None):
        db_conn = Connection.reuse(self._db_conn, db_conn)
        db_filter = AccountFilter(names=list(self.keys()))
        db_conn.accounts.delete(db_filter)

    def modify(self, changes: Optional[Account] = None, db_conn: Optional[Connection] = None, **kwargs: Any):
        db_conn = Connection.reuse(self._db_conn, db_conn)
        db_filter = AccountFilter(names=list(self.keys()))
        return db_conn.accounts.modify(db_filter, changes, **kwargs)

    def create(self, db_conn: Optional[Connection] = None):
        db_conn = Connection.reuse(self._db_conn, db_conn)
        db_conn.accounts.create(list(self.values()))


cdef class AccountFilter:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, **kwargs: Any):
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

    def __init__(self, name: str = None, description: str = None, organization: str = None, **kwargs: Any):
        self._alloc_impl()
        self._init_defaults()
        self.name = name
        self.description = description or name
        self.organization = organization or name

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

    def to_dict(self, recursive: bool = False):
        """Database Account information formatted as a dictionary.

        Returns:
            (dict): Database Account information as dict.
        """
        return instance_to_dict(self, recursive)

    def __eq__(self, other: Any) -> bool:
        if isinstance(other, Account):
            return self.name == other.name
        return NotImplemented

    @staticmethod
    def load(db_conn: Connection, name: str):
        account = db_conn.accounts.load().get(name)
        if not account:
            # TODO: Maybe don't raise here and just return None and let the
            # Caller handle it?
            raise NotFoundError(msg=f"Account {name} does not exist.")
        return account

    def create(self, db_conn: Optional[Connection] = None):
        Accounts({self.name: self}).create(self._db_conn or db_conn)

    def delete(self, db_conn: Optional[Connection] = None):
        Accounts({self.name: self}).delete(self._db_conn or db_conn)

    def modify(self, changes: Optional[Account] = None, db_conn: Optional[Connection] = None, **kwargs: Any):
        Accounts({self.name: self}).modify(changes=changes, db_conn=(self._db_conn or db_conn), **kwargs)

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
