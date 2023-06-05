#########################################################################
# assoc.pxd - pyslurm slurmdbd association api
#########################################################################
# Copyright (C) 2023 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# This file is part of PySlurm
#
# PySlurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# PySlurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PySlurm; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3

from pyslurm cimport slurm
from pyslurm.slurm cimport (
    slurmdb_assoc_rec_t,
    slurmdb_assoc_cond_t,
    slurmdb_associations_get,
    slurmdb_destroy_assoc_rec,
    slurmdb_destroy_assoc_cond,
    slurmdb_init_assoc_rec,
    try_xmalloc,
)
from pyslurm.db.util cimport (
    SlurmList,
    SlurmListItem,
    make_char_list,
    slurm_list_to_pylist,
    qos_list_to_pylist,
)
from pyslurm.db.tres cimport (
    find_tres_limit,
    merge_tres_str,
)
from pyslurm.db.connection cimport Connection
from pyslurm.utils cimport cstr
from pyslurm.utils.uint cimport *
from pyslurm.db.qos cimport QualitiesOfService


cdef class Associations(dict):
    cdef SlurmList info


cdef class AssociationSearchFilter:
    cdef slurmdb_assoc_cond_t *ptr


cdef class Association:
    cdef:
        slurmdb_assoc_rec_t *ptr
        QualitiesOfService qos_data

    @staticmethod
    cdef Association from_ptr(slurmdb_assoc_rec_t *in_ptr)

