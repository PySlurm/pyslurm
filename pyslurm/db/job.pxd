#########################################################################
# job.pxd - pyslurm slurmdbd job api
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
    slurm_destroy_selected_step,
    slurm_selected_step_t,
    slurm_list_create,
    slurm_list_append,
    try_xmalloc,
    slurmdb_job_cond_def_start_end,
    slurm_job_state_string,
    slurm_job_reason_string,
)
from pyslurm.db.util cimport (
    SlurmList,
    SlurmListItem,
    make_char_list,
)
from pyslurm.db.step cimport JobStep, JobSteps
from pyslurm.db.stats cimport JobStatistics
from pyslurm.db.connection cimport Connection
from pyslurm.utils cimport cstr
from pyslurm.db.qos cimport QualitiesOfService
from pyslurm.db.tres cimport TrackableResources, TrackableResource


cdef class JobSearchFilter:
    """Search conditions for Slurm database Jobs.

    Args:
        **kwargs (Any, optional=None):
            Any valid attribute of the object.

    Attributes:
        ids (list):
            A list of Job ids to search for.
        start_time (Union[str, int, datetime.datetime]):
            Search for Jobs which started after this time.
        end_time (Union[str, int, datetime.datetime]):
            Search for Jobs which ended before this time.
        accounts (list):
            Search for Jobs with these account names.
        association_ids (list):
            Search for Jobs with these association ids.
        clusters (list):
            Search for Jobs running in these clusters.
        constraints (list):
            Search for Jobs with these constraints.
        cpus (int):
            Search for Jobs with exactly this many CPUs.
            Note: If you also specify max_cpus, then this value will act as
            the minimum.
        max_cpus (int):
            Search for Jobs with no more than this amount of CPUs.
            Note: This value has no effect without also setting cpus.
        nodes (int):
            Search for Jobs with exactly this many nodes.
            Note: If you also specify max_nodes, then this value will act as
            the minimum.
        max_nodes (int):
            Search for Jobs with no more than this amount of nodes.
            Note: This value has no effect without also setting nodes.
        qos (list):
            Search for Jobs with these Qualities of Service.
        names (list):
            Search for Jobs with these job names.
        partitions (list):
            Search for Jobs with these partition names.
        groups (list):
            Search for Jobs with these group names. You can both specify the
            groups as string or by their GID.
        timelimit (Union[str, int]):
            Search for Jobs with exactly this timelimit.
            Note: If you also specify max_timelimit, then this value will act
            as the minimum.
        max_timelimit (Union[str, int]):
            Search for Jobs which run no longer than this timelimit
            Note: This value has no effect without also setting timelimit
        users (list):
            Search for Jobs with these user names. You can both specify the
            users as string or by their UID.
        wckeys (list):
            Search for Jobs with these WCKeys
        nodelist (list):
            Search for Jobs that ran on any of these Nodes
        with_script (bool):
            Instruct the slurmdbd to also send the job script(s)
            Note: This requires specifying explictiy job ids, and is mutually
            exclusive with with_env
        with_env (bool):
            Instruct the slurmdbd to also send the job environment(s)
            Note: This requires specifying explictiy job ids, and is mutually
            exclusive with with_script
    """
    cdef slurmdb_job_cond_t *ptr

    cdef public:
        ids
        start_time
        end_time
        accounts
        association_ids
        clusters
        constraints
        cpus
        max_cpus
        nodes
        max_nodes
        qos
        names
        partitions
        groups
        timelimit
        max_timelimit
        users
        wckeys
        nodelist
        with_script
        with_env


cdef class Jobs(dict):
    """A collection of [pyslurm.db.Job][] objects."""
    cdef:
        SlurmList info
        Connection db_conn


cdef class Job:
    """A Slurm Database Job.

    Args:
        job_id (int, optional=0):
            An Integer representing a Job-ID.

    Raises:
        MemoryError: If malloc fails to allocate memory.

    Attributes:
        steps (pyslurm.db.JobSteps):
            Steps this Job has
        stats (pyslurm.db.JobStatistics):
            Utilization statistics of this Job
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
        association_id (int):
            ID of the Association this job runs in.
        block_id (str):
            Name of the block used (for BlueGene Systems) 
        cluster (str):
            Cluster this Job belongs to
        constraints (str):
            Constraints of the Job
        container (str):
            Path to OCI Container bundle
        db_index (int):
            Unique database index of the Job in the job table
        derived_exit_code (int):
            Highest exit code of all the Job steps
        derived_exit_code_signal (int):
            Signal of the derived exit code
        comment (str):
            Comment for the Job
        elapsed_time (int):
            Amount of seconds elapsed for the Job
        eligible_time (int):
            When the Job became eligible to run, as a unix timestamp
        end_time (int):
            When the Job ended, as a unix timestamp
        exit_code (int):
            Exit code of the job script or salloc.
        exit_code_signal (int):
            Signal of the exit code for this Job.
        group_id (int):
            ID of the group for this Job
        group_name (str):
            Name of the group for this Job
        id (int):
            ID of the Job
        name (str):
            Name of the Job
        mcs_label (str):
            MCS Label of the Job
        nodelist (str):
            Nodes this Job is using
        partition (str):
            Name of the Partition for this Job
        priority (int):
            Priority for the Job
        qos (str):
            Name of the Quality of Service for the Job
        cpus (int):
            Amount of CPUs the Job has/had allocated, or, if the Job is still
            pending, this will reflect the amount requested.
        memory (int):
            Amount of memory the Job requested in total
        reservation (str):
            Name of the Reservation for this Job
        script (str):
            The batch script for this Job.
            Note: Only available if the "with_script" condition was given
        start_time (int):
            Time when the Job started, as a unix timestamp
        state (str):
            State of the Job
        state_reason (str):
            Last reason a Job was blocked from running
        cancelled_by (str):
            Name of the User who cancelled this Job
        submit_time (int):
            Time the Job was submitted, as a unix timestamp
        submit_command (str):
            Full command issued to submit the Job
        suspended_time (int):
            Amount of seconds the Job was suspended
        system_comment (str):
            Arbitrary System comment for the Job
        time_limit (int):
            Time limit of the Job in minutes
        user_id (int):
            UID of the User this Job belongs to
        user_name (str):
            Name of the User this Job belongs to
        wckey (str):
            Name of the WCKey for this Job
        working_directory (str):
            Working directory of the Job
    """
    cdef:
        slurmdb_job_rec_t *ptr
        QualitiesOfService qos_data

    cdef public:
        JobSteps steps
        JobStatistics stats

    @staticmethod
    cdef Job from_ptr(slurmdb_job_rec_t *in_ptr)
