# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
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

Functions in this module wrap the ``topo_info_t`` struct found in `slurm.h`.
The members of this struct are converted to a :class:`Topology` object, which
implements Python properties to retrieve the value of each attribute.

Each topology record in a ``topo_info_response_msg_t`` struct is converted to a
:class:`Topology` object when calling some of the functions in this module.

"""
from __future__ import absolute_import, unicode_literals

from .c_account cimport *
from .slurm_common cimport *
from .exceptions import PySlurmError

cdef class Account:
    """An object to wrap ..."""
    pass


cpdef int get_accounts():
    """
    Return a list of all topologies as :class:`Topology` objects.  This
    function calls ``slurm_load_topo`` to retrieve information for all
    topologies.

    Args:
        ids (Optional[bool]): Return list of only topology ids if True
            (default: False).

    Returns:
        list: A list of :class:`Topology` objects, one for each topology.

    Raises:
        PySlurmError: if ``slurm_load_topo`` is unsuccessful.

    """
    cdef:
        void *db_conn = NULL
#        slurmdb_account_cond_t *acct_cond = NULL
#        List account_list
        int rc

    db_conn = slurmdb_connection_get()
#    account_list = slurmdb_accounts_get(db_conn, acct_cond)

    rc = slurmdb_connection_close(&db_conn)
    return rc
