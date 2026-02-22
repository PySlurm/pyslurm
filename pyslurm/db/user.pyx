#########################################################################
# user.pyx - pyslurm slurmdbd user api
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

from pyslurm.core.error import RPCError, slurm_errno, verify_rpc
from pyslurm.utils.helpers import (
    instance_to_dict,
    user_to_uid,
)
from pyslurm.utils.uint import *
from pyslurm import xcollections
from pyslurm.utils.enums import SlurmEnum
from pyslurm.db.error import JobsRunningError
from pyslurm.enums import AdminLevel


cdef class Users(dict):

    def __init__(self, users={}, **kwargs):
        super().__init__()
        self.update(users)
        self.update(kwargs)

    @staticmethod
    def load(Connection db_conn, UserFilter db_filter=None):
        cdef:
            Users out = Users()
            User user
            UserFilter cond = db_filter
            SlurmList user_data
            SlurmListItem user_ptr
            SlurmList assoc_data
            SlurmListItem assoc_ptr
            Association assoc
            QualitiesOfService qos_data
            TrackableResources tres_data

        db_conn.validate()

        if not db_filter:
            cond = UserFilter()

        if cond.with_assocs is not False:
            # If not explicitly disabled, always fetch the Associations of a
            # User.
            cond.with_assocs = True
        cond._create()

        user_data = SlurmList.wrap(slurmdb_users_get(db_conn.ptr, cond.ptr))

        if user_data.is_null:
            raise RPCError(msg="Failed to get User data from slurmdbd")

        qos_data = QualitiesOfService.load(db_conn=db_conn,
                                           name_is_key=False)
        tres_data = TrackableResources.load(db_conn=db_conn)

        for user_ptr in SlurmList.iter_and_pop(user_data):
            user = User.from_ptr(<slurmdb_user_rec_t*>user_ptr.data)
            out[user.name] = user

            assoc_data = SlurmList.wrap(user.ptr.assoc_list, owned=False)
            for assoc_ptr in SlurmList.iter_and_pop(assoc_data):
                assoc = Association.from_ptr(<slurmdb_assoc_rec_t*>assoc_ptr.data)
                assoc.qos_data = qos_data
                assoc.tres_data = tres_data
                _parse_assoc_ptr(assoc)
                user.associations.append(assoc)

                if assoc.user == user.name:
                    user.default_association = assoc

        return out

    def delete(self, Connection db_conn):
        cdef:
            UserFilter u_filter
            SlurmList response
            SlurmListItem response_ptr

        # TODO: test again when this is empty, does it really delete everything?
        names = list(self.keys())
        if not names:
            return

        db_conn.validate()

        u_filter = UserFilter(names=names)
        u_filter._create()

        response = SlurmList.wrap(slurmdb_users_remove(db_conn.ptr, u_filter.ptr))
        rc = slurm_errno()

        if rc == slurm.SLURM_SUCCESS or rc == slurm.SLURM_NO_CHANGE_IN_DATA:
            return

       #if rc == slurm.ESLURM_ACCESS_DENIED or response.is_null:
       #    verify_rpc(rc)

        # Handle the error case. Running Jobs should be the only possible error
        # where slurmdbd sends a response list.
        if rc == slurm.ESLURM_JOBS_RUNNING_ON_ASSOC:
            raise JobsRunningError.from_response(response, rc)
        else:
            verify_rpc(rc)

    def modify(self, Connection db_conn, User changes):
        cdef:
            UserFilter u_filter
            AssociationFilter a_filter
            SlurmList response
            SlurmListItem response_ptr
            list out = []

        db_conn.validate()

        u_filter = UserFilter(names=list(self.keys()))
#        a_filter = AssociationFilter()

 #       u_filter.ptr.assoc_cond = a_filter.ptr
        u_filter._create()
        response = SlurmList.wrap(slurmdb_users_modify(
            db_conn.ptr, u_filter.ptr, changes.ptr))

        if not response.is_null and response.cnt:
            for response_ptr in response:
                response_str = cstr.to_unicode(<char*>response_ptr.data)
                if not response_str:
                    continue

                out.append(response_str)

        elif not response.is_null:
            # There was no real error, but simply nothing has been modified
            return out
        else:
            # Autodetects the last slurm error
            raise RPCError(msg="Failed to modify users.")

        return out

    @staticmethod
    def create(Connection db_conn, users):
        cdef:
            User user
            SlurmList user_list
            list assocs_to_add = []

        db_conn.validate()
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

        verify_rpc(slurmdb_users_add(db_conn.ptr, user_list.info))
        # TODO: Maybe don't create the associations automatically? And don't do
        # any hidden stuff?
        Associations.create(db_conn, assocs_to_add)


cdef class UserFilter:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, **kwargs):
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

    def __init__(self, name=None, **kwargs):
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

    def to_dict(self, recursive=False):
        """Database User information formatted as a dictionary.

        Returns:
            (dict): Database User information as dict.
        """
        return instance_to_dict(self, recursive)

    def __eq__(self, other):
        if isinstance(other, User):
            return self.name == other.name
        return NotImplemented

    @staticmethod
    def load(Connection db_conn, name):
        user = Users.load(db_conn=db_conn).get(name)
        if not user:
            raise RPCError(msg=f"User {name} does not exist.")
        return user

    def create(self, Connection db_conn):
        Users.create(db_conn, [self])

    def delete(self, Connection db_conn):
        Users({self.name: self}).delete(db_conn)

    def modify(self, Connection db_conn, User changes):
        Users({self.name: self}).modify(db_conn, changes)

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
