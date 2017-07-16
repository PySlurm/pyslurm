# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
"""
================
:mod:`front end`
================

The front end extension module is used to get Slurm front end node information.

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

- slurm_free_front_end_info_msg
- slurm_load_front_end
- slurm_print_front_end_info_msg
- slurm_print_front_end_table
- slurm_sprint_front_end_table
- slurm_init_update_front_end_msg
- slurm_update_front_end

FrontEnd Object
---------------

Functions in this module wrap the ``front_end_info_t`` struct found in `slurm.h`.
The members of this struct are converted to a :class:`FrontEnd` object, which
implements Python properties to retrieve the value of each attribute.

Each front end record in a ``front_end_info_msg_t`` struct is converted to a
:class:`FrontEnd` object when calling some of the functions in this module.

"""
from __future__ import absolute_import, unicode_literals

from libc.stdio cimport stdout

from .c_frontend cimport *
from .c_node cimport slurm_node_state_string
from .slurm_common cimport *
from .exceptions import PySlurmError

include "node.pxi"

cdef class FrontEnd:
    """An object to wrap `front_end_info_t` structs."""
    cdef:
        readonly time_t boot_time
        readonly unicode boot_time_str
        readonly unicode frontend_name
        readonly unicode reason
        readonly time_t slurmd_start_time
        readonly unicode slurmd_start_time_str
        readonly unicode state
        readonly unicode version


def get_frontends(ids=False):
    """
    Return a list of all frontends as :class:`FrontEnd` objects.  This function
    calls ``slurm_load_front_end`` to retrieve information for all front ends.

    Args:
        ids (Optional[bool]): Return list of only front end ids if True
            (default: False).

    Returns:
        list: A list of :class:`FrontEnd` objects, one for each frontend.

    Raises:
        PySlurmError: if ``slurm_load_front_end`` is unsuccessful.

    """
    return get_front_end_info_msg(None, ids)


def get_frontend(front_end):
    """
    Return a single :class:`FrontEnd` object for the given front end.  This
    function calls ``slurm_load_front_end`` to retrieve information for all
    front ends, but the response only includes the specified front end.

    Args:
        front_end (str): front end name to query

    Returns:
        Block: A single :class:`FrontEnd` object

    Raises:
        PySlurmError: if ``slurm_load_front_end`` is unsuccessful.
    """
    return get_front_end_info_msg(front_end)


cdef get_front_end_info_msg(front_end, ids=False):
    cdef:
        front_end_info_msg_t *front_end_info_msg_ptr = NULL
        uint32_t my_state
        int rc
        char *drain_str = ""
        char time_str[32]

    rc = slurm_load_front_end(<time_t> NULL, &front_end_info_msg_ptr)

    front_end_list = []
    if rc == SLURM_SUCCESS:
        for record in front_end_info_msg_ptr.front_end_array[:front_end_info_msg_ptr.record_count]:
            if front_end:
                if front_end and (front_end != <unicode>record.name):
                    continue

            if ids and front_end is None:
                if record.name:
                    front_end.append(record.name)
                continue

            this_front_end = FrontEnd()

            my_state = record.node_state
            if (my_state & NODE_STATE_DRAIN):
                my_state &= (~NODE_STATE_DRAIN)
                drain_str = "+DRAIN"

            # Line 1
            this_front_end.frontend_name = record.name
            this_front_end.state = slurm_node_state_string(my_state) + drain_str
            this_front_end.version = record.version

            if record.reason_time:
                #TODO
                pass
            else:
                this_front_end.reason = record.reason

            # Line 2
            this_front_end.boot_time = record.boot_time
            slurm_make_time_str(<time_t *>&record.boot_time,
                                time_str, sizeof(time_str))
            this_front_end.boot_time_str = time_str

            this_front_end.slurmd_start_time = record.slurmd_start_time
            slurm_make_time_str(<time_t *>&record.slurmd_start_time,
                                time_str, sizeof(time_str))
            this_front_end.slurmd_start_time_str = time_str

            # Line 3
            if record.allow_groups:
                this_front_end.allow_groups = record.allow_groups

            if record.allow_users:
                this_front_end.allow_users = record.allow_users

            if record.deny_groups:
                this_front_end.deny_groups = record.deny_groups

            if record.deny_users:
                this_front_end.deny_users = record.deny_users

            front_end_list.append(this_front_end)

        slurm_free_front_end_info_msg(front_end_info_msg_ptr)
        front_end_info_msg_ptr = NULL

        if front_end and front_end_list:
            return front_end_list[0]
        else:
            return front_end_list
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


cpdef print_front_end_info_msg(int one_liner=False):
    """
    Print information about all front ends to stdout.

    This function outputs information about all Slurm front ends based upon the
    message loaded by ``slurm_load_front_end``. It uses the
    ``slurm_print_front_end_info_msg`` function to print to stdout.  The output is
    equivalent to *scontrol show frontend*.

    Args:
        one_liner (Optional[bool]): print front ends on one line if True
            (default False)
    Raises:
        PySlurmError: If ``slurm_load_front_end`` is not successful.
    """
    cdef:
        front_end_info_msg_t *front_end_info_msg_ptr = NULL
        int rc

    rc = slurm_load_front_end(<time_t> NULL, &front_end_info_msg_ptr)

    if rc == SLURM_SUCCESS:
        slurm_print_front_end_info_msg(stdout, front_end_info_msg_ptr, one_liner)
        slurm_free_front_end_info_msg(front_end_info_msg_ptr)
        front_end_info_msg_ptr = NULL
    else:
        raise PySlurmError(slurm_strerror(rc), rc)
