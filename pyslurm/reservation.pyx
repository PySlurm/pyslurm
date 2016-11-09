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
from libc.time cimport time, difftime
from libcpp cimport bool
from posix.types cimport time_t

from .c_reservation cimport *
from .slurm_common cimport *
from .exceptions import PySlurmError

cdef class Reservation:
    """An object to wrap `reserve_info_t` structs."""
    cdef:
        readonly list accounts
        readonly unicode burst_buffer
        readonly uint32_t core_cnt
        readonly time_t duration
        readonly unicode duration_str
        readonly time_t end_time
        readonly unicode end_time_str
        readonly list features
        readonly list flags
        readonly list licenses
        readonly list midplanes
        readonly uint32_t midplane_cnt
        readonly list nodes
        readonly uint32_t node_cnt
        readonly unicode node_list
        readonly unicode partition_name
        readonly unicode reservation_name
        readonly time_t start_time
        readonly unicode start_time_str
        readonly unicode state
        readonly unicode tres
        readonly unicode users
        uint32_t watts

    @property
    def watts(self):
        """Amount of power to reserve."""
        if self.watts != <time_t>NO_VAL:
            return self.watts
        else:
            return "n/a"


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
        reserve_info_msg_t *resv_info_msg_ptr = NULL
        char tmp1[32]
        char tmp2[32]
        char tmp3[32]
        char *flag_str = NULL
        int rc
        uint32_t cluster_flags = slurmdb_setup_cluster_flags()
        bool is_bluegene = cluster_flags & CLUSTER_FLAG_BG
        time_t duration
        time_t now = time(NULL)


    rc = slurm_load_reservations(<time_t>NULL, &resv_info_msg_ptr)

    resv_list = []
    if rc == SLURM_SUCCESS:
        for record in resv_info_msg_ptr.reservation_array[:resv_info_msg_ptr.record_count]:
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

            flag_str = slurm_reservation_flags_string(record.flags)
            if is_bluegene:
                this_resv.midplanes = record.node_list.split(",")
                if record.node_cnt == NO_VAL:
                    this_resv.midplane_cnt = 0
                else:
                    this_resv.midplane_cnt = record.node_cnt
                this_resv.cnode_cnt = record.core_cnt
            else:
                this_resv.nodes = record.node_list.split(",")
                if record.node_cnt == NO_VAL:
                    this_resv.nodes = 0
                else:
                    this_resv.node_cnt = record.node_cnt
                this_resv.core_cnt = record.core_cnt

            if record.features:
                this_resv.features = record.features.split(",")

            if record.partition:
                this_resv.partition_name = record.partition

            if flag_str:
                this_resv.flags = flag_str.split(",")

            this_resv.tres = record.tres_str
            this_resv.watts = record.resv_watts

            if (record.start_time <= now) and (record.end_time >= now):
                this_resv.state = "ACTIVE"
            else:
                this_resv.state = "INACTIVE"

            if record.users:
                this_resv.users = record.users

            if record.accounts:
                this_resv.accounts = record.accounts.split(",")

            if record.licenses:
                this_resv.licenses = record.licenses.split(",")

            if record.burst_buffer:
                this_resv.burst_buffer = record.burst_buffer



            resv_list.append(this_resv)

        slurm_free_reservation_info_msg(resv_info_msg_ptr)
        resv_info_msg_ptr = NULL

        if reservation and resv_list:
            return resv_list[0]
        else:
            return resv_list
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


def print_reservation_info_msg(int one_liner=False):
    """
    Print information about all reservation records.

    This function outputs information about all Slurm reservations based upon
    the data structure loaded by ``slurm_load_reservations``. It uses the
    ``slurm_print_reservation_info_msg`` function to print to stdout.  The
    output is equivalent to *scontrol show reservations*.

    Args:
        one_liner (Optional[bool]): print reservations on one line if True
            (default False)
    Raises:
        PySlurmError: If ``slurm_load_reservations`` is not successful.
    """
    cdef:
        reserve_info_msg_t *resv_info_msg_ptr = NULL
        int rc

    rc = slurm_load_reservations(<time_t>NULL, &resv_info_msg_ptr)

    if rc == SLURM_SUCCESS:
        slurm_print_reservation_info_msg(stdout, resv_info_msg_ptr, one_liner)
        slurm_free_reservation_info_msg(resv_info_msg_ptr)
        resv_info_msg_ptr = NULL
    else:
        raise PySlurmError(slurm_strerror(rc), rc)
