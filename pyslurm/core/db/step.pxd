#########################################################################
# step.pxd - pyslurm slurmdbd step api
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
from pyslurm.core.db.stats cimport JobStats


cdef class JobSteps(dict):
    """A collection of [`pyslurm.db.JobStep`][] objects"""
    pass


cdef class JobStep:
    """A Slurm Database JobStep.

    Attributes:
        stats (JobStats):
            Utilization statistics for this Step
        num_nodes (int):
            Amount of nodes this Step has allocated
        cpus (int):
            Amount of CPUs the Step has/had allocated
        memory (int):
            Amount of memory the Step requested
        container (str):
            Path to OCI Container bundle
        elapsed_time (int):
            Amount of seconds elapsed for the Step
        end_time (int):
            When the Step ended, as a unix timestamp
        eligible_time (int):
            When the Step became eligible to run, as a unix timestamp
        start_time (int):
            Time when the Step started, as a unix timestamp
        exit_code (int):
            Exit code of the step
        ntasks (int):
            Number of tasks the Step uses
        cpu_frequency_min (str):
            Minimum CPU-Frequency requested for the Step
        cpu_frequency_max (str):
            Maximum CPU-Frequency requested for the Step
        cpu_frequency_governor (str):
            CPU-Frequency Governor requested for the Step
        nodelist (str):
            Nodes this Step is using
        id (Union[str, int]):
            ID of the Step
        job_id (int):
            ID of the Job this Step is a part of
        state (str):
            State of the Step
        cancelled_by (str):
            Name of the User who cancelled this Step
        submit_command (str):
            Full command issued to start the Step
        suspended_time (int):
            Amount of seconds the Step was suspended
    """
    cdef slurmdb_step_rec_t *ptr
    cdef public JobStats stats

    @staticmethod
    cdef JobStep from_ptr(slurmdb_step_rec_t *step)
