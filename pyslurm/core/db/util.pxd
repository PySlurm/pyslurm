#########################################################################
# util.pxd - pyslurm slurmdbd util functions
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

from pyslurm cimport slurm
from pyslurm.core.common cimport cstr
from pyslurm.slurm cimport (
    ListIterator,
    List,
    slurm_list_iterator_create,
    slurm_list_iterator_destroy,
    slurm_list_iterator_reset,
    slurm_list_count,
    slurm_list_next,
    slurm_list_destroy,
    slurm_list_create,
    slurm_list_pop,
    slurm_list_append,
    slurm_xfree_ptr,
)

cdef slurm_list_to_pylist(List in_list)
cdef make_char_list(List *in_list, vals)


cdef class SlurmListItem:
    cdef void *data

    @staticmethod
    cdef SlurmListItem from_ptr(void *item)


cdef class SlurmList:
    cdef:
        List info
        ListIterator itr

    cdef readonly:
        owned
        int itr_cnt
        int cnt
    
    @staticmethod
    cdef SlurmList wrap(List, owned=*)

    @staticmethod
    cdef SlurmList create(slurm.ListDelF delf, owned=*)
