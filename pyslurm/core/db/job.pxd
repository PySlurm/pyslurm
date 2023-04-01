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
from pyslurm.core.db.step cimport JobStep, JobSteps
from pyslurm.core.db.stats cimport JobStats
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


cdef class Jobs(dict):
    cdef:
        SlurmList info
        Connection db_conn


cdef class Job:
    """A Slurm Database Job.

    All attributes in this class are read-only.

    Args:
        job_id (int):
            An Integer representing a Job-ID.

    Raises:
        MemoryError: If malloc fails to allocate memory.

    Attributes:
        steps (pyslurm.db.JobSteps):
            Steps this Job has.
        account (str):
            Account of the Job.
        admin_comment (str):
            Admin comment for the Job.
        num_nodes (int):
            Amount of nodes this Job has allocated (if it is running) or
            requested (if it is still pending).
        array_id (int):
            The master Array-Job ID.
        array_tasks_parallel (int):
            Max number of array tasks allowed to run simultaneously.
        array_task_id (int):
            Array Task ID of this Job if it is an Array-Job.
        array_tasks_waiting (str):
            Array Tasks that are still waiting.
        name (str):
            Name of the Job.
    """
    cdef slurmdb_job_rec_t *ptr
    cdef public:
        JobSteps steps
        JobStats stats

    @staticmethod
    cdef Job from_ptr(slurmdb_job_rec_t *in_ptr)
