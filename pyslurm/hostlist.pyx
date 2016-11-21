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
    """An object to wrap `hostlist_t` structs."""

    cdef hostlist_t hl

    def __cinit__(self):
        self.hl = NULL

    def __dealloc__(self):
        self.destroy()

    def create(self, hostnames):
        """
        """
        self.hl = slurm_hostlist_create(hostnames)

        if not self.hl:
            raise PySlurmError("No memory")
        else:
            return True

    def destroy(self):
        """
        """
        if self.hl is not NULL:
            slurm_hostlist_destroy(self.hl)
            self.hl = NULL

    def count(self):
        """
        """
        return slurm_hostlist_count(self.hl)

    def ranged_string(self):
        """
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
        """
        if self.hl is not NULL:
            return slurm_hostlist_push(self.hl, hosts)

    def push_host(self, host):
        """
        Push a single host onto the hostlist.
        """
        if self.hl is not NULL:
            return slurm_hostlist_push_host(self.hl, host)

    def find(self, hostname):
        """
        Return position in hostlist after searching for the first host matching
        hostname.
        """
        if self.hl is not NULL:
            return slurm_hostlist_find(self.hl, hostname)

    def shift(self):
        """
        Returns the string representation of the first host in the hostlist or
        NULL if the hostlist is empty.
        """
        if self.hl is not NULL:
            return slurm_hostlist_shift(self.hl)

    def uniq(self):
        """
        Sort the hostlist and remove duplicate entries.
        """
        if self.hl is not NULL:
            return slurm_hostlist_uniq(self.hl)
