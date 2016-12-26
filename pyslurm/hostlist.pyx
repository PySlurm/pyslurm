# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
"""
===============
:mod:`hostlist`
===============

The hostlist extension module is used to create and manipulate Slurm hostlists.

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

- slurm_hostlist_count
- slurm_hostlist_create
- slurm_hostlist_destroy
- slurm_hostlist_find
- slurm_hostlist_push
- slurm_hostlist_push_host
- slurm_hostlist_ranged_string_malloc
- slurm_hostlist_shift
- slurm_hostlist_uniq

Hostlist Object
---------------

Functions in this module wrap the ``hostlist_t`` opaque data type found in
`slurm.h`.
"""
from __future__ import absolute_import, unicode_literals

from libc.stdlib cimport free

from .c_hostlist cimport *
from .slurm_common cimport *
from .exceptions import PySlurmError

cdef class Hostlist:
    """An object to store hostlists."""

    cdef hostlist_t hl

    def __cinit__(self):
        self.hl = NULL

    def __dealloc__(self):
        self.destroy()

    def create(self, hostnames=None):
        """
        Create a new hostlist from a string representation.

        Args:
            hostnames (str):
        Returns:
            True if successful.
        """
        if not hostnames:
            self.hl = slurm_hostlist_create(NULL)
        else:
            self.hl = slurm_hostlist_create(hostnames)

        if not self.hl:
            raise PySlurmError("No memory")
        else:
            return True

    def destroy(self):
        """
        Destroy a hostlist object. Frees all memory allocated to the hostlist.

        Args:
            None
        Returns:
            None
        """
        if self.hl is not NULL:
            slurm_hostlist_destroy(self.hl)
            self.hl = NULL

    def count(self):
        """
        Return the number of hosts in the hostlist.

        Args:
            None
        Returns:
            Number of hosts in the hostlist
        """
        return slurm_hostlist_count(self.hl)

    def ranged_string(self):
        """
        Return the string representation of the hostlist.

        Args:
            None
        Returns:
            String representation of the hostlist
        """
        if self.hl is not NULL:
            return slurm_hostlist_ranged_string_malloc(self.hl)
        else:
            return None

    def push(self, hosts):
        """
        Push a string representation of hostnames onto a hostlist.

        The hosts argument may take the same form as in
        slurm_hostlist_create().

        Args:
            hosts (str): string representation of one or more hosts
        Returns:
            Number of hostnames inserted into the hostlist or 0 on failure
        """
        if self.hl is not NULL:
            return slurm_hostlist_push(self.hl, hosts)

    def push_host(self, host):
        """
        Push a single host onto the hostlist.

        This function is more efficient than self.push() for a single
        hostname, since the argument does not need to be checked for ranges.

        Args:
            host (str): string representation of a single host.
        Returns:
            1 for success, 0 for failure
        """
        if self.hl is not NULL:
            return slurm_hostlist_push_host(self.hl, host)

    def find(self, hostname):
        """
        Return position in hostlist after searching for the first host matching
        hostname.

        Args:
            hostname (str): string representation of a single host
        Returns:
            Position in the list if found or -1 if host not found
        """
        if self.hl is not NULL:
            return slurm_hostlist_find(self.hl, hostname)

    def shift(self):
        """
        Returns the string representation of the first host in the hostlist or
        NULL if the hostlist is empty.

        The host is removed from the hostlist.

        Args:
            None
        Returns:
            String representatio of the first host in the hostlist or NULL if
            the hostlist is empty.
        """
        if self.hl is not NULL:
            return slurm_hostlist_shift(self.hl)

    def uniq(self):
        """
        Sort the hostlist and remove duplicate entries.

        Args:
            None
        Returns:
            None
        """
        if self.hl is not NULL:
            return slurm_hostlist_uniq(self.hl)
