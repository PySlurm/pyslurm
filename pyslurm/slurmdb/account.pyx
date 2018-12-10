# cython: embedsignature=True
"""
===============
:mod:`account`
===============

The account extension module is used to wrap Slurm DB account functions

Slurm DB API Functions
-------------------

This module declares and wraps the following Slurm DB API functions:

- slurmdb_accounts_get

Account Object
---------------

Functions in this module wrap the ``slurmdb_account_rec_t`` struct found in `slurmdb.h`.
The members of this struct are converted to a :class:`Account` object.
"""
from __future__ import absolute_import, unicode_literals

from .c_account cimport *
from .slurmdb_common cimport *
from ..slurm_common cimport *
from ..utils cimport *
from ..exceptions import PySlurmError

cdef class Account:
    """An object to Slurmdb accounts"""
    cdef:
        readonly unicode name
        readonly list coordinators
        readonly unicode description
        readonly unicode organization


def get_accounts():
    """
    Get Account info from storage.

    Wraps src/sacctmgr/account_functions.c

    Args:
        None

    Returns:
        List of accounts.
    """
    cdef:
        int rc = SLURM_SUCCESS
        slurmdb_account_cond_t *acct_cond
        void *db_conn
        List acct_list
        ListIterator itr = NULL
        ListIterator itr2 = NULL
    
    acct_cond = <slurmdb_account_cond_t *>xmalloc(sizeof(slurmdb_account_cond_t))
    db_conn = <void *>NULL

    acct_list = slurmdb_accounts_get(db_conn, acct_cond)
    slurmdb_destroy_account_cond(acct_cond)

    itr = slurm_list_iterator_create(acct_list)

    account_list = []
    for _ in range(slurm_list_count(acct_list)):
        acct = <slurmdb_account_rec_t *>slurm_list_next(itr)

        this_acct = Account()

        if acct is not NULL:
            this_acct.name = tounicode(acct.name)

            coordinators = []
            if acct.coordinators:
                itr2 = slurm_list_iterator_create(acct.coordinators)

                for _ in range(slurm_list_count(acct.coordinators)):
                    coord = <slurmdb_coord_rec_t *>slurm_list_next(itr2)
                    coordinators.append(tounicode(coord.name))

                slurm_list_iterator_destroy(itr2)

            this_acct.coordinators = coordinators

            this_acct.description = tounicode(acct.description)
            this_acct.organization = tounicode(acct.organization)

        account_list.append(this_acct)

    slurm_list_iterator_destroy(itr)
    FREE_NULL_LIST(acct_list)

    return account_list
