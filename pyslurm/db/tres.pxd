#########################################################################
# tres.pxd - pyslurm slurmdbd tres api
#########################################################################
# Copyright (C) 2023 Toni Harzendorf <toni.harzendorf@gmail.com>
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
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3

from pyslurm cimport slurm
from pyslurm.utils cimport cstr
from libc.stdint cimport uint64_t
from pyslurm.slurm cimport (
    slurmdb_tres_rec_t,
    slurmdb_tres_cond_t,
    slurmdb_destroy_tres_cond,
    slurmdb_init_tres_cond,
    slurmdb_destroy_tres_rec,
    slurmdb_find_tres_count_in_string,
    slurmdb_tres_get,
    try_xmalloc,
)
from pyslurm.db.util cimport (
    SlurmList,
    SlurmListItem,
)
from pyslurm.db.connection cimport Connection

cdef find_tres_count(char *tres_str, typ, on_noval=*, on_inf=*)
cdef find_tres_limit(char *tres_str, typ)
cdef merge_tres_str(char **tres_str, typ, val)
cdef _tres_ids_to_names(char *tres_str, TrackableResources tres_data)
cdef _set_tres_limits(char **dest, TrackableResourceLimits src,
                          TrackableResources tres_data)


cdef class TrackableResourceLimits:

    cdef public:
        cpu
        mem
        energy
        node
        billing
        fs
        vmem
        pages
        gres
        license

    @staticmethod
    cdef from_ids(char *tres_id_str, TrackableResources tres_data)


cdef class TrackableResourceFilter:
    cdef slurmdb_tres_cond_t *ptr


cdef class TrackableResources(list):
    cdef public raw_str

    @staticmethod
    cdef TrackableResources from_str(char *tres_str)

    @staticmethod
    cdef find_count_in_str(char *tres_str, typ, on_noval=*, on_inf=*)


cdef class TrackableResource:
    cdef slurmdb_tres_rec_t *ptr  

    @staticmethod
    cdef TrackableResource from_ptr(slurmdb_tres_rec_t *in_ptr)
