#########################################################################
# slurmctld/stats.pxd - pyslurm slurmctld statistics api (sdiag)
#########################################################################
# Copyright (C) 2025 Toni Harzendorf <toni.harzendorf@gmail.com>
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
    stats_info_response_msg_t,
    stats_info_request_msg_t,
    slurm_get_statistics,
    slurm_reset_statistics,
    slurm_free_stats_response_msg,
    xfree,
)
from pyslurm.utils cimport cstr
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t, int64_t
from pyslurm.utils.uint cimport (
    u16_parse,
    u32_parse,
    u64_parse,
    u16_parse_bool,
)

cdef extern const char *rpc_num2string(uint16_t msg_type)

cdef parse_response(stats_info_response_msg_t *ptr)


cdef class RPCTypeStatistic:

    cdef public:
        id
        name
        count
        time
        average_time
        queued
        dropped
        cycle_last
        cycle_max


cdef class RPCUserStatistic:

    cdef public:
        user_id
        user_name
        count
        time
        average_time


cdef class RPCTypeStatistics(dict):

    @staticmethod
    cdef RPCTypeStatistics from_ptr(stats_info_response_msg_t *ptr, rpc_queue_enabled)


cdef class RPCUserStatistics(dict):

    @staticmethod
    cdef RPCUserStatistics from_ptr(stats_info_response_msg_t *ptr)


cdef class Statistics:

    cdef public:
        request_time
        data_since
        server_thread_count
        agent_queue_size
        agent_count
        agent_thread_count
        dbd_agent_queue_size
        rpc_queue_enabled

        jobs_submitted
        jobs_started
        jobs_completed
        jobs_canceled
        jobs_failed
        jobs_pending
        jobs_running
        job_states_ts

        schedule_cycle_max
        schedule_cycle_last
        schedule_cycle_counter
        schedule_cycle_mean
        schedule_cycle_mean_depth
        schedule_queue_len
        cycles_per_minute
        schedule_exit

        backfill_active
        backfilled_jobs
        last_backfilled_jobs
        backfilled_het_jobs
        backfill_last_cycle_when
        backfill_last_cycle
        backfill_cycle_last
        backfill_cycle_max
        backfill_total_cycles
        backfill_cycle_mean
        backfill_last_depth_cycle
        backfill_last_depth_cycle_try_sched
        backfill_mean_depth_cycle
        backfill_mean_depth_cycle_try_sched
        backfill_queue_len
        backfill_queue_len_mean
        backfill_table_size
        backfill_table_size_mean

        gettimeofday_latency

        rpc_type_stats
        rpc_user_stats
