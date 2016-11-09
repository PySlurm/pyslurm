# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
"""
==================
:mod:`reservation`
==================

The reservation extension module is used to get Slurm reservation information.

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

- slurm_load_reservations
- slurm_free_reservation_info_msg
- slurm_print_reservation_info
- slurm_print_reservation_info_msg

Reservation Object
------------------

Functions in this module wrap the ``reserve_info_t`` struct found in `slurm.h`.
The members of this struct are converted to a :class:`Reservation` object, which
implements Python properties to retrieve the value of each attribute.

Each reservation record in a ``reserve_info_msg_t`` struct is converted to a
:class:`Reservation` object when calling some of the functions in this module.

"""
from __future__ import absolute_import, unicode_literals

from libc.stdio cimport stdout
from libc.time cimport difftime
from posix.types cimport time_t

from .c_reservation cimport *
from .slurm_common cimport *
from .exceptions import PySlurmError

cdef class Reservation:
    """An object to wrap `reserve_info_t` structs."""
    cdef:
        readonly unicode accounts
        readonly unicode burst_buffer
        readonly uint32_t core_cnt
        readonly uint32_t duration
        readonly unicode duration_str
        readonly time_t end_time
        readonly unicode end_time_str
        readonly unicode features
        readonly uint32_t flags
        readonly unicode licenses
        readonly unicode reservation_name
        readonly uint32_t node_cnt
        readonly int32_t node_inx
        readonly unicode node_list
        readonly unicode partition
        readonly time_t start_time
        readonly unicode start_time_str
        readonly uint32_t resv_watts
        readonly unicode tres_str
        readonly unicode users


def get_reservations(ids=False):
    """
    Return a list of all reservations as :class:`Reservation` objects.  This
    function calls ``slurm_load_reservations`` to retrieve information for all
    reservations.

    Args:
        ids (Optional[bool]): Return list of only reservation ids if True
            (default: False).

    Returns:
        list: A list of :class:`Reservation` objects, one for each reservation.

    Raises:
        PySlurmError: if ``slurm_load_reservations`` is unsuccessful.

    """
    return get_reservation_info_msg(None, ids)


def get_reservation(reservation):
    """
    Return a single :class:`Reservation` object for the given reservation.
    This function calls ``slurm_load_topo`` to retrieve information for all
    topologies, but the response only includes the specified topology.

    Args:
        reservation (str): reservation name to query

    Returns:
        Reservation: A single :class:`Reservation` object

    Raises:
        PySlurmError: if ``slurm_load_reservations`` is unsuccessful.
    """
    return get_reservation_info_msg(reservation)


cdef get_reservation_info_msg(reservation, ids=False):
    cdef:
        reserve_info_msg_t *res_info_ptr = NULL
        char tmp1[32]
        char tmp2[32]
        char tmp3[32]
        int rc
        uint32_t duration

    rc = slurm_load_reservations(<time_t>NULL, &res_info_ptr)

    resv_list = []
    if rc == SLURM_SUCCESS:
        for record in res_info_ptr.reservation_array[:res_info_ptr.record_count]:
            if reservation:
                b_reservation = reservation.encode("UTF-8")
                if b_reservation and (b_reservation != record.name):
                    continue

            if ids and reservation is None:
                if record.name:
                    resv_list.append(record.name)
                continue

            this_resv = Reservation()

            if record.name:
                this_resv.reservation_name = record.name

            slurm_make_time_str(&record.start_time, tmp1, sizeof(tmp1))
            slurm_make_time_str(&record.end_time, tmp2, sizeof(tmp2))

            if record.end_time >= record.start_time:
                duration = <time_t>(difftime(record.end_time, record.start_time))
                slurm_secs2time_str(duration, tmp3, sizeof(tmp3))
                this_resv.duration = duration
                this_resv.duration_str = tmp3
            else:
                this_resv.duration_str = "N/A"

            this_resv.start_time = record.start_time
            this_resv.start_time_str = tmp1

            this_resv.end_time = record.end_time
            this_resv.end_time_str = tmp2

            resv_list.append(this_resv)

        slurm_free_reservation_info_msg(res_info_ptr)
        res_info_ptr = NULL

        if reservation and resv_list:
            return resv_list[0]
        else:
            return resv_list
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


#def print_topology_info_msg(int one_liner=False):
#    """
#    Print information about powercapping to stdout.
#
#    This function outputs information about all Slurm partitions based upon
#    the message loaded by ``slurm_load_powercap``. It uses the
#    ``slurm_print_powercap_info_msg`` function to print to stdout.  The
#    output is equivalent to *scontrol show powercap*.
#
#    Args:
#        one_liner (Optional[bool]): print powercap info on one line if True
#            (default False)
#    Raises:
#        PySlurmError: If ``slurm_load_powercap`` is not successful.
#    """
#    cdef:
#        powercap_info_msg_t *powercap_info_msg_ptr = NULL
#        int rc
#
#    rc = slurm_load_powercap(&powercap_info_msg_ptr)
#
#    if rc == SLURM_SUCCESS:
#        slurm_print_powercap_info_msg(stdout, powercap_info_msg_ptr, one_liner)
#        slurm_free_powercap_info_msg(powercap_info_msg_ptr)
#        powercap_info_msg_ptr = NULL
#    else:
#        raise PySlurmError(slurm_strerror(rc), rc)
