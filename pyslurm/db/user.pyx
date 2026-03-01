#########################################################################
# user.pyx - pyslurm slurmdbd user api
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
from pyslurm.utils.enums import SlurmEnum
from pyslurm.db.error import handle_response
from pyslurm.enums import AdminLevel
from typing import Any, Union, Optional, List, Dict


cdef class UserAPI(ConnectionWrapper):

    def load(self, db_filter: Optional[UserFilter] = None):
        cdef:
            Users out = Users()
            UserFilter cond = db_filter
            SlurmListItem user_ptr
            SlurmListItem assoc_ptr

        self.db_conn.validate()

        if not db_filter:
            cond = UserFilter()

        if cond.with_assocs is not False:
            # If not explicitly disabled, always fetch the Associations of a
            # User.
            cond.with_assocs = True
        cond._create()

        user_data = SlurmList.wrap(slurmdb_users_get(self.db_conn.ptr, cond.ptr))

        if user_data.is_null:
            raise RPCError(msg="Failed to get User data from slurmdbd")

        qos_data = self.db_conn.qos.load(name_is_key=False)
        tres_data = self.db_conn.tres.load()

        for user_ptr in SlurmList.iter_and_pop(user_data):
            user = User.from_ptr(<slurmdb_user_rec_t*>user_ptr.data)
            self.db_conn.apply_reuse(user)
            out[user.name] = user

            assoc_data = SlurmList.wrap(user.ptr.assoc_list, owned=False)
            for assoc_ptr in SlurmList.iter_and_pop(assoc_data):
                assoc = Association.from_ptr(<slurmdb_assoc_rec_t*>assoc_ptr.data)
                assoc.qos_data = qos_data
                assoc.tres_data = tres_data
                _parse_assoc_ptr(assoc)
                user.associations.append(assoc)
                self.db_conn.apply_reuse(assoc)

                if assoc.user == user.name:
                    user.default_association = assoc

        self.db_conn.apply_reuse(out)
        return out

    def delete(self, db_filter: UserFilter):
        out = []

        # TODO: test again when this is empty, does it really delete everything?
        if not db_filter.names:
            return

        self.db_conn.validate()
        db_filter._create()

        response = SlurmList.wrap(slurmdb_users_remove(self.db_conn.ptr, db_filter.ptr))
        rc = slurm_errno()
        self.db_conn.check_commit(rc)
        return handle_response(response, rc)

    def modify(self, db_filter: UserFilter, changes: Optional[User] = None, **kwargs: Any):
        cdef:
            User _changes
            SlurmListItem response_ptr

        # TODO: Properly check if the filter is empty, cause it will then probably
        # target all users. Or maybe that is fine and we need to clearly document
        # to take caution
        #if not db_filter.names:
        #    return

        _changes = _get_modify_arguments_for(User, changes, **kwargs)

        self.db_conn.validate()
        db_filter._create()

        response = SlurmList.wrap(slurmdb_users_modify(
            self.db_conn.ptr, db_filter.ptr, _changes.ptr)
        )
        rc = slurm_errno()
        self.db_conn.check_commit(rc)

        return handle_response(response, rc)

    def create(self, users: List[User]):
        cdef:
            User user
            SlurmList user_list
            list assocs_to_add = []

        if not users:
            return

        self.db_conn.validate()
        user_list = SlurmList.create(slurmdb_destroy_user_rec, owned=False)

        for user in users:
            if user.default_account:
                has_default_assoc = False
                for assoc in user.associations:
                    if not assoc.is_default:
                        continue

                    if has_default_assoc:
                        raise ValueError("Multiple Associations declared as default")

                    has_default_assoc = True
                    if not assoc.account:
                        assoc.account = user.default_account
                    elif assoc.account != user.default_account:
                        raise ValueError("Ambigous account definition")

                # Do we really need to specify a default association anyway?
                if not has_default_assoc:
                    # Caller didn't specify any default association, so we
                    # create a basic one.
                    assoc = Association(user=user.name,
                                        account=user.default_account, is_default=True)
                    user.associations.append(assoc)

            assocs_to_add.extend(user.associations)
            slurm.slurm_list_append(user_list.info, user.ptr)

        rc = slurmdb_users_add(self.db_conn.ptr, user_list.info)

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


cdef class Users(dict):

    def __init__(self, users={}, **kwargs):
        super().__init__()
        self.update(users)
        self.update(kwargs)
        self._db_conn = None

    @staticmethod
    def load(db_conn: Connection, db_filter: Optional[UserFilter] = None):
        return db_conn.users.load(db_filter)

    def delete(self, db_conn: Optional[Connection] = None):
        db_conn = Connection.reuse(self._db_conn, db_conn)
        db_filter = UserFilter(names=list(self.keys()))
        db_conn.users.delete(db_filter)

    def modify(self, changes: Optional[User] = None, db_conn: Optional[Connection] = None, **kwargs: Any):
        db_conn = Connection.reuse(self._db_conn, db_conn)
        db_filter = UserFilter(names=list(self.keys()))
        return db_conn.users.modify(db_filter, changes=changes, **kwargs)

    def create(self, db_conn: Optional[Connection] = None):
        db_conn = Connection.reuse(self._db_conn, db_conn)
        db_conn.users.create(list(self.values()))


cdef class UserFilter:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, **kwargs: Any):
        for k, v in kwargs.items():
            setattr(self, k, v)

    def __dealloc__(self):
        self._dealloc()

    def _dealloc(self):
        slurmdb_destroy_user_cond(self.ptr)
        self.ptr = NULL

    def _alloc(self):
        self._dealloc()
        self.ptr = <slurmdb_user_cond_t*>try_xmalloc(sizeof(slurmdb_user_cond_t))
        if not self.ptr:
            raise MemoryError("xmalloc failed for slurmdb_user_cond_t")

        memset(self.ptr, 0, sizeof(slurmdb_user_cond_t))

        self.ptr.assoc_cond = <slurmdb_assoc_cond_t*>try_xmalloc(sizeof(slurmdb_assoc_cond_t))
        if not self.ptr.assoc_cond:
            raise MemoryError("xmalloc failed for slurmdb_assoc_cond_t")


    def _create(self):
        self._alloc()
        cdef slurmdb_user_cond_t *ptr = self.ptr

        make_char_list(&ptr.assoc_cond.user_list, self.names)
        ptr.with_assocs = 1 if self.with_assocs else 0
        ptr.with_coords = 1 if self.with_coordinators else 0
        ptr.with_wckeys = 1 if self.with_wckeys else 0
        ptr.with_deleted = 1 if self.with_deleted else 0


cdef class User:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, name: str = None, **kwargs: Any):
        self._alloc_impl()
        self.name = name
        self._init_defaults()
        for k, v in kwargs.items():
            setattr(self, k, v)

    def _init_defaults(self):
        self.associations = []
        self.coordinators = []
        self.default_association = None
        self.wckeys = []

    def __dealloc__(self):
        self._dealloc_impl()

    def _dealloc_impl(self):
        slurmdb_destroy_user_rec(self.ptr)
        self.ptr = NULL

    def _alloc_impl(self):
        if not self.ptr:
            self.ptr = <slurmdb_user_rec_t*>try_xmalloc(
                    sizeof(slurmdb_user_rec_t))
            if not self.ptr:
                raise MemoryError("xmalloc failed for slurmdb_user_rec_t")

            memset(self.ptr, 0, sizeof(slurmdb_user_rec_t))
            self.ptr.uid = slurm.NO_VAL

    def __repr__(self):
        return f'pyslurm.db.{self.__class__.__name__}({self.name})'

    @staticmethod
    cdef User from_ptr(slurmdb_user_rec_t *in_ptr):
        cdef User wrap = User.__new__(User)
        wrap.ptr = in_ptr
        wrap._init_defaults()
        return wrap

    def to_dict(self, recursive: bool = False):
        """Database User information formatted as a dictionary.

        Returns:
            (dict): Database User information as dict.
        """
        return instance_to_dict(self, recursive)

    def __eq__(self, other: Any) -> bool:
        if isinstance(other, User):
            return self.name == other.name
        return NotImplemented

    @staticmethod
    def load(db_conn: Connection, name: str):
        user = db_conn.users.load().get(name)
        if not user:
            raise NotFoundError(msg=f"User {name} does not exist.")
        return user

    def create(self, db_conn: Optional[Connection] = None):
        Users({self.name: self}).create(self._db_conn or db_conn)

    def delete(self, db_conn: Optional[Connection] = None):
        Users({self.name: self}).delete(self._db_conn or db_conn)

    def modify(
        self,
        changes: Optional[User] = None,
        db_conn: Optional[Connection] = None,
        **kwargs: Any
    ):
        Users({self.name: self}).modify(changes=changes, db_conn=(self._db_conn or db_conn), **kwargs)

    @property
    def name(self):
        return cstr.to_unicode(self.ptr.name)

    @name.setter
    def name(self, val):
        cstr.fmalloc(&self.ptr.name, val)

    @property
    def previous_name(self):
        return cstr.to_unicode(self.ptr.old_name)

    @property
    def user_id(self):
        return u32_parse(self.ptr.uid, zero_is_noval=False)

    @property
    def default_account(self):
        return cstr.to_unicode(self.ptr.default_acct)

    @default_account.setter
    def default_account(self, val):
        cstr.fmalloc(&self.ptr.default_acct, val)

    @property
    def default_wckey(self):
        return cstr.to_unicode(self.ptr.default_wckey)

    @property
    def is_deleted(self):
        if self.ptr.flags & slurm.SLURMDB_USER_FLAG_DELETED:
            return True
        return False

    @property
    def admin_level(self):
        return AdminLevel.from_flag(self.ptr.admin_level,
                                    default=AdminLevel.UNDEFINED)

    @admin_level.setter
    def admin_level(self, val):
        self.ptr.admin_level = AdminLevel(val)._flag
