# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
"""
===========
:mod:`topology`
===========

The topology extension module is used to get Slurm switch topology information.

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

- slurm_load_topo
- slurm_free_topo_info_msg
- slurm_print_topo_info_msg
- slurm_print_topo_record

Topology Object
---------------

Functions in this module wrap the ``topo_info_t`` struct found in `slurm.h`.
The members of this struct are converted to a :class:`Topology` object, which
implements Python properties to retrieve the value of each attribute.

Each topology record in a ``topo_info_response_msg_t`` struct is converted to a
:class:`Topology` object when calling some of the functions in this module.

"""
from __future__ import absolute_import, unicode_literals

from libc.stdio cimport stdout

from .c_topology cimport *
from .slurm_common cimport *
from .exceptions import PySlurmError

cdef class Topology:
    """An object to wrap `topo_info_t` structs."""
    cdef:
        readonly uint16_t level
        readonly uint32_t link_speed
        readonly unicode switch_name
        readonly unicode nodes
        readonly unicode switches


def get_topologies(ids=False):
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
    return get_topo_info_msg(None, ids)


def get_topology(topology):
    """
    Return a single :class:`Topology` object for the given topology.  This
    function calls ``slurm_load_topo`` to retrieve information for all
    topologies, but the response only includes the specified topology.

    Args:
        topology (str): topology name to query

    Returns:
        Topology: A single :class:`Topology` object

    Raises:
        PySlurmError: if ``slurm_load_topo`` is unsuccessful.
    """
    return get_topo_info_msg(topology)


cdef get_topo_info_msg(topology, ids=False):
    cdef:
        topo_info_response_msg_t *topo_info_msg_ptr = NULL
        int rc

    rc = slurm_load_topo(&topo_info_msg_ptr)

    topo_list = []
    if rc == SLURM_SUCCESS:
        for record in topo_info_msg_ptr.topo_array[:topo_info_msg_ptr.record_count]:
            if topology:
                b_topology = topology.encode("UTF-8")
                if b_topology and (b_topology != record.name):
                    continue

            if ids and topology is None:
                if record.name:
                    topo_list.append(record.name)
                continue

            this_topo = Topology()

            if record.name:
                this_topo.switch_name = record.name

            this_topo.level = record.level
            this_topo.link_speed = record.link_speed

            # TODO: nodes, switches
            # Looks like it requires SLURM_TOPO_LEN env var and a little logic

            topo_list.append(this_topo)

        slurm_free_topo_info_msg(topo_info_msg_ptr)
        topo_info_msg_ptr = NULL

        if topology and topo_list:
            return topo_list[0]
        else:
            return topo_list
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
