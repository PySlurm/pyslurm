#########################################################################
# account.pxd - pyslurm slurmdbd account api
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

from libc.string cimport memcpy, memset
from pyslurm cimport slurm
from pyslurm.slurm cimport (
    slurmdb_account_rec_t,
    slurmdb_assoc_rec_t,
    slurmdb_assoc_cond_t,
    slurmdb_account_cond_t,
    slurmdb_accounts_get,
    slurmdb_accounts_add,
    slurmdb_accounts_remove,
    slurmdb_accounts_modify,
    slurmdb_destroy_account_rec,
    slurmdb_destroy_account_cond,
    try_xmalloc,
)
from pyslurm.db.util cimport (
    SlurmList,
    SlurmListItem,
    make_char_list,
    slurm_list_to_pylist,
    qos_list_to_pylist,
)
from pyslurm.db.tres cimport (
    _set_tres_limits,
    TrackableResources,
)
from pyslurm.db.connection cimport Connection, ConnectionWrapper
from pyslurm.utils cimport cstr
from pyslurm.db.qos cimport QualitiesOfService, _set_qos_list
from pyslurm.db.assoc cimport Associations, Association, _parse_assoc_ptr
from pyslurm.xcollections cimport MultiClusterMap
from pyslurm.utils.uint cimport u16_set_bool_flag


cdef class AccountAPI(ConnectionWrapper):
    pass


cdef class Accounts(dict):
    cdef public:
        Connection _db_conn


cdef class AccountFilter:
    cdef slurmdb_account_cond_t *ptr

    cdef public:
        with_assocs
        with_deleted
        with_coordinators
        names
        organizations
        descriptions


cdef class Account:
    """Slurm Database Account.

    Attributes:
        name (str):
            Name of the Account.
        description (str):
            Description of the Account.
        organization (str):
            Organization of the Account.
        is_deleted (bool):
            Whether this Account has been deleted or not.
        association (pyslurm.db.Association):
            This accounts association.
    """
    cdef:
        slurmdb_account_rec_t *ptr

    cdef readonly:
        cluster

    cdef public:
        associations
        coordinators
        association
        Connection _db_conn

    @staticmethod
    cdef Account from_ptr(slurmdb_account_rec_t *in_ptr)
