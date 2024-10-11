#########################################################################
# job/stats.pxd - interface to retrieve slurm job realtime stats
#########################################################################
# Copyright (C) 2024 Toni Harzendorf <toni.harzendorf@gmail.com>
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

from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libc.string cimport memcpy, memset
from pyslurm cimport slurm
from pyslurm.slurm cimport (
    slurm_job_step_stat,
    slurmdb_step_rec_t,
    slurmdb_stats_t,
    slurmdb_free_slurmdb_stats_members,
    job_step_stat_t,
    job_step_stat_response_msg_t,
    slurm_job_step_stat_response_msg_free,
    jobacctinfo_t,
    list_t,
    List,
    xfree,
    try_xmalloc,
)
from pyslurm.utils cimport cstr, ctime
from pyslurm.utils.uint cimport *
from pyslurm.utils.ctime cimport time_t
from pyslurm.db.util cimport SlurmList, SlurmListItem
from pyslurm.db.stats cimport JobStatistics
from posix.unistd cimport pid_t
from pyslurm.core.job.step cimport JobStep

cdef load_single(JobStep step)

# The real definition for this is too long, including too many other types that
# we don't have directly access to. Not sure if this is sane to do here.
ctypedef void* stepd_step_rec_t


# https://github.com/SchedMD/slurm/blob/slurm-24-05-3-1/src/interfaces/jobacct_gather.h#L75
ctypedef struct jobacct_id_t:
    uint32_t taskid
    uint32_t nodeid
    stepd_step_rec_t *step


# https://github.com/SchedMD/slurm/blob/slurm-24-05-3-1/src/interfaces/jobacct_gather.h#L81
ctypedef struct jobacctinfo:
    pid_t pid
    uint64_t sys_cpu_sec
    uint32_t sys_cpu_usec
    uint64_t user_cpu_sec
    uint32_t user_cpu_usec
    uint32_t act_cpufreq
    slurm.acct_gather_energy_t energy
    double last_total_cputime
    double this_sampled_cputime
    uint32_t current_weighted_freq
    uint32_t current_weighted_power
    uint32_t tres_count
    uint32_t *tres_ids
    List tres_list
    uint64_t *tres_usage_in_max
    uint64_t *tres_usage_in_max_nodeid
    uint64_t *tres_usage_in_max_taskid
    uint64_t *tres_usage_in_min
    uint64_t *tres_usage_in_min_nodeid
    uint64_t *tres_usage_in_min_taskid
    uint64_t *tres_usage_in_tot
    uint64_t *tres_usage_out_max
    uint64_t *tres_usage_out_max_nodeid
    uint64_t *tres_usage_out_max_taskid
    uint64_t *tres_usage_out_min
    uint64_t *tres_usage_out_min_nodeid
    uint64_t *tres_usage_out_min_taskid
    uint64_t *tres_usage_out_tot

    jobacct_id_t id
    int dataset_id

    double last_tres_usage_in_tot
    double last_tres_usage_out_tot
    time_t cur_time
    time_t last_time


ctypedef enum lock_level_t:
    NO_LOCK
    READ_LOCK
    WRITE_LOCK


ctypedef struct assoc_mgr_lock_t:
    lock_level_t assoc
    lock_level_t file
    lock_level_t qos
    lock_level_t res
    lock_level_t tres
    lock_level_t user
    lock_level_t wckey


cdef extern jobacctinfo_t *jobacctinfo_create(jobacct_id_t *jobacct_id)
cdef extern void jobacctinfo_destroy(void *object)
cdef extern void jobacctinfo_aggregate(jobacctinfo_t *dest, jobacctinfo_t *src)
cdef extern void jobacctinfo_2_stats(slurmdb_stats_t *stats, jobacctinfo_t *jobacct)

cdef extern list_t* assoc_mgr_tres_list
cdef extern void assoc_mgr_lock(assoc_mgr_lock_t *locks)
cdef extern void assoc_mgr_unlock(assoc_mgr_lock_t *locks)
cdef extern int assoc_mgr_post_tres_list(List new_list)

cdef extern char *slurmdb_ave_tres_usage(char *tres_string, int tasks);
