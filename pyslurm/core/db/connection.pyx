#########################################################################
# connection.pyx - pyslurm slurmdbd database connection
#########################################################################
# Copyright (C) 2022 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# Pyslurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Pyslurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3
# cython: embedsignature=True

from pyslurm.core.error import RPCError


cdef class Connection:
    def __cinit__(self):
        self.conn = NULL
        self.conn_flags = 0

    def __init__(self):
        self.open() 

    def open(self):
        if not self.conn:
            self.conn = <void*>slurmdb_connection_get(&self.conn_flags)
            if not self.conn:
                raise RPCError(msg="Failed to open Connection to slurmdbd")

    def close(self):
        slurmdb_connection_close(&self.conn)
        self.conn = NULL

    def is_open(self):
        if self.conn:
            return True
        else:
            return False
