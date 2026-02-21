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
    slurmdb_destroy_assoc_rec,
    slurmdb_destroy_assoc_cond,
    slurmdb_init_assoc_rec,
    slurmdb_associations_get,
    slurmdb_associations_modify,
    slurmdb_associations_add,
    slurmdb_associations_remove,
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
    _set_tres_limits,
    TrackableResources,
)
from pyslurm.db.connection cimport Connection
from pyslurm.utils cimport cstr
from pyslurm.utils.uint cimport *
from pyslurm.db.qos cimport QualitiesOfService, _set_qos_list
from pyslurm.xcollections cimport MultiClusterMap

cdef _parse_assoc_ptr(Association ass)
cdef _create_assoc_ptr(Association ass, conn=*)


cdef class Associations(MultiClusterMap):
    pass


cdef class AssociationFilter:
    cdef slurmdb_assoc_cond_t *ptr

    cdef public:
        users
        ids
        accounts
        parent_accounts
        clusters
        partitions
        qos


cdef class Association:
    cdef:
        slurmdb_assoc_rec_t *ptr
        slurmdb_assoc_rec_t *umsg
        QualitiesOfService qos_data
        TrackableResources tres_data
        owned

    cdef public:
        default_qos

        group_tres
        group_tres_mins
        group_tres_run_mins
        max_tres_mins_per_job
        max_tres_run_mins_per_user
        max_tres_per_job
        max_tres_per_node
        qos
        group_jobs
        group_jobs_accrue
        group_submit_jobs
        group_wall_time
        max_jobs
        max_jobs_accrue
        max_submit_jobs
        max_wall_time_per_job
        min_priority_threshold
        priority
        shares

    @staticmethod
    cdef Association from_ptr(slurmdb_assoc_rec_t *in_ptr)


cdef class AssociationList(SlurmList):
    pass
