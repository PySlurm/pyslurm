#########################################################################
# job.pxd - pyslurm slurmdbd job api
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

from pyslurm cimport slurm
from pyslurm.slurm cimport (
    slurmdb_job_rec_t,
    slurmdb_job_cond_t,
    slurmdb_step_rec_t,
    slurmdb_jobs_get,
    slurmdb_destroy_job_cond,
    slurmdb_destroy_job_rec,
    slurmdb_destroy_step_rec,
    try_xmalloc,
    slurmdb_job_cond_def_start_end,
    slurm_job_state_string,
    slurm_job_reason_string,
)
from pyslurm.core.db.util cimport SlurmList, SlurmListItem
from pyslurm.core.db.connection cimport Connection
from pyslurm.core.common cimport cstr


cdef class JobConditions:
    cdef slurmdb_job_cond_t *ptr

    cdef public:
        start_time
        end_time
        accounts
        association_ids
        clusters
        constraints


cdef class JobSteps(dict):
    pass


cdef class JobStep:
    cdef slurmdb_step_rec_t *ptr

    @staticmethod
    cdef JobStep from_ptr(slurmdb_step_rec_t *step)


cdef class Jobs(dict):
    cdef SlurmList info


cdef class Job:
    cdef slurmdb_job_rec_t *ptr
    cdef public JobSteps steps

    @staticmethod
    cdef Job from_ptr(slurmdb_job_rec_t *in_ptr)

