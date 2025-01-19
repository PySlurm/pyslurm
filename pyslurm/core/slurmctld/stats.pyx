#########################################################################
# slurmctld/stats.pyx - pyslurm slurmctld statistics api (sdiag)
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

from pyslurm.core.error import verify_rpc, RPCError
from pyslurm.utils.uint import (
    u16_parse,
    u32_parse,
    u64_parse,
)
from pyslurm.constants import UNLIMITED
from pyslurm.utils.ctime import _raw_time
from pyslurm.utils.helpers import (
    instance_to_dict,
    uid_to_name,
)
from pyslurm.utils import cstr
from pyslurm import xcollections


cdef class RPCTypeStatistic:

    def __init__(self):
        self.id = 0
        self.name = None
        self.count = 0
        self.time = 0
        self.average_time = 0
        self.queued = 0
        self.dropped = 0
        self.cycle_last = 0
        self.cycle_max = 0

    def to_dict(self):
        return instance_to_dict(self)


cdef class RPCUserStatistic:

    def __init__(self):
        self.user_id = 0
        self.user_name = None
        self.count = 0
        self.time = 0
        self.average_time = 0

    def to_dict(self):
        return instance_to_dict(self)


cdef class RPCTypeStatistics(dict):

    def __init__(self):
        super().__init__()

    @staticmethod
    cdef RPCTypeStatistics from_ptr(stats_info_response_msg_t *ptr,
                                   rpc_queue_enabled):
        out = RPCTypeStatistics()

        for i in range(ptr.rpc_type_size):
            stats = RPCTypeStatistic()
            stats.id = ptr.rpc_type_id[i]
            stats.name = rpc_num2string(ptr.rpc_type_id[i])
            stats.count = ptr.rpc_type_cnt[i]
            stats.time = ptr.rpc_type_time[i]

            if ptr.rpc_type_cnt[i]:
                stats.average_time = ptr.rpc_type_time[i] / ptr.rpc_type_cnt[i]

            if rpc_queue_enabled:
                stats.queued = ptr.rpc_type_queued[i]
                stats.dropped = ptr.rpc_type_dropped[i]
                stats.cycle_last = ptr.rpc_type_cycle_last[i]
                stats.cycle_max = ptr.rpc_type_cycle_max[i]

            if stats.name:
                out[stats.name] = stats

        return out

    @property
    def total_queued(self):
        return xcollections.sum_property(self, RPCTypeStatistic.queued)

    @property
    def total_count(self):
        return xcollections.sum_property(self, RPCTypeStatistic.count)

    @property
    def total_time(self):
        return xcollections.sum_property(self, RPCTypeStatistic.time)

    @property
    def total_dropped(self):
        return xcollections.sum_property(self, RPCTypeStatistic.dropped)


cdef class RPCUserStatistics(dict):

    def __init__(self):
        super().__init__()

    @staticmethod
    cdef RPCUserStatistics from_ptr(stats_info_response_msg_t *ptr):
        out = RPCUserStatistics()

        for i in range(ptr.rpc_user_size):
            user_id = ptr.rpc_user_id[i]
            user = uid_to_name(user_id)
            if not user:
                continue

            stats = RPCUserStatistic()
            stats.user_id = ptr.rpc_user_id[i]
            stats.user_name = user
            stats.count = ptr.rpc_user_cnt[i]
            stats.time = ptr.rpc_user_time[i]

            if ptr.rpc_user_cnt[i]:
                stats.average_time = ptr.rpc_user_time[i] / ptr.rpc_user_cnt[i]

            out[user] = stats

        return out

    @property
    def total_queued(self):
        return xcollections.sum_attr(self, "queued")


cdef parse_response(stats_info_response_msg_t *ptr):
    cdef Statistics out = Statistics()

    cycle_count = ptr.schedule_cycle_counter
    bf_cycle_count = ptr.bf_cycle_counter

    out.server_thread_count = ptr.server_thread_count
    out.rpc_queue_enabled = True if ptr.rpc_queue_enabled else False
    out.agent_queue_size = ptr.agent_queue_size
    out.agent_count = ptr.agent_count
    out.agent_thread_count = ptr.agent_thread_count
    out.dbd_agent_queue_size = ptr.dbd_agent_queue_size
    out.jobs_submitted = ptr.jobs_submitted
    out.jobs_started = ptr.jobs_started
    out.jobs_completed = ptr.jobs_completed
    out.jobs_canceled = ptr.jobs_canceled
    out.jobs_failed = ptr.jobs_failed
    out.jobs_pending = ptr.jobs_pending
    out.jobs_running = ptr.jobs_running
    out.schedule_cycle_max = ptr.schedule_cycle_max
    out.schedule_cycle_last = ptr.schedule_cycle_last
    out.schedule_cycle_counter = cycle_count
    out.schedule_queue_len = ptr.schedule_queue_len

    # TODO: job_states_ts ?
    # TODO: scheduler exits

    if cycle_count > 0:
        out.schedule_cycle_mean = ptr.schedule_cycle_sum / cycle_count
        out.schedule_cycle_mean_depth = ptr.schedule_cycle_depth / cycle_count

    ts = ptr.req_time - ptr.req_time_start
    if ts > 60:
        out.cycles_per_minute = cycle_count / (ts / 60)


    out.backfill_active = bool(ptr.bf_active)
    out.backfilled_jobs = ptr.bf_backfilled_jobs
    out.last_backfilled_jobs = ptr.bf_last_backfilled_jobs
    out.backfilled_het_jobs = ptr.bf_backfilled_het_jobs
    out.backfill_last_cycle_when = ptr.bf_when_last_cycle
    out.backfill_last_cycle = ptr.bf_cycle_last
    out.backfill_cycle_max = ptr.bf_cycle_max
    out.backfill_total_cycles = bf_cycle_count
    out.backfill_last_depth_cycle = ptr.bf_last_depth
    out.backfill_last_depth_cycle_try_sched = ptr.bf_last_depth_try
    out.backfill_queue_len = ptr.bf_queue_len
    out.backfill_table_size = ptr.bf_table_size

    if bf_cycle_count > 0:
        out.backfill_cycle_mean = ptr.bf_cycle_sum / bf_cycle_count
        out.backfill_mean_depth_cycle = ptr.bf_depth_sum / bf_cycle_count
        out.backfill_mean_depth_cycle_try_sched = ptr.bf_depth_try_sum / bf_cycle_count
        out.backfill_queue_len_mean = ptr.bf_queue_len_sum / bf_cycle_count
        out.backfill_table_size_mean = ptr.bf_table_size_sum / bf_cycle_count

    out.gettimeofday_latency = ptr.gettimeofday_latency

    out.rpc_type_stats = RPCTypeStatistics.from_ptr(ptr, out.rpc_queue_enabled)
    out.rpc_user_stats = RPCUserStatistics.from_ptr(ptr)

    return out


cdef class Statistics:

    def __init__(self):
        self.schedule_cycle_mean = 0
        self.schedule_cycle_mean_depth = 0
        self.cycles_per_minute = 0
        self.backfill_cycle_mean = 0
        self.backfill_mean_depth_cycle = 0
        self.backfill_mean_depth_cycle_try_sched = 0
        self.backfill_queue_len_mean = 0
        self.backfill_table_size_mean = 0

    @staticmethod
    def load():
        cdef:
            stats_info_request_msg_t req
            stats_info_response_msg_t *resp = NULL
            Statistics out = None

        req.command_id = slurm.STAT_COMMAND_GET
        verify_rpc(slurm_get_statistics(&resp, &req))

        try:
            out = parse_response(resp)
        except Exception as e:
            raise e
        finally:
            slurm_free_stats_response_msg(resp)

        return out

    @staticmethod
    def reset():
        cdef stats_info_request_msg_t req
        verify_rpc(slurm_reset_statistics(&req))

    def to_dict(self):
        out = instance_to_dict(self)
        out["rpc_type_stats"] = xcollections.dict_recursive(self.rpc_type_stats)
        out["rpc_user_stats"] = xcollections.dict_recursive(self.rpc_user_stats)
        return out


