# cython: embedsignature=True
# cython: cdivision=True
"""
=================
:mod:`statistics`
=================

The statistics extension module retrieves information related to slurmctld
execution, including:

    - threads
    - agents
    - jobs
    - scheduling algorithms

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

    - slurm_free_stats_response_msg
    - slurm_get_statistics
    - slurm_reset_statistics


Stats Objects
-------------

Functions in this module wrap the ``stats_info_response_msg_t`` struct found in
`slurm.h`. This struct is converted to a :class:`Stats` object, which implement
Python properties to retrieve the value of each element.

"""
from __future__ import division, unicode_literals

from c_statistics cimport *
from slurm_common cimport *
from exceptions import PySlurmError
from pwd import getpwuid

cdef class Stats:
    """
    An object to wrap ``stats_info_response_msg_t`` structs.
    """
    cdef:
        readonly uint32_t parts_packed
        readonly time_t req_time
        readonly time_t req_time_start
        readonly uint32_t server_thread_count
        readonly uint32_t agent_queue_size
        readonly uint32_t agent_count
        readonly uint32_t dbd_agent_queue_size
        readonly uint32_t gettimeofday_latency
        readonly uint32_t schedule_cycle_max
        readonly uint32_t schedule_cycle_last
        readonly uint32_t schedule_cycle_sum
        readonly uint32_t schedule_cycle_counter
        readonly uint32_t schedule_cycle_depth
        readonly uint32_t mean_cycle_schedule
        readonly uint32_t mean_depth_cycle_schedule
        readonly uint32_t cycles_per_minute
        readonly uint32_t last_queue_len
        readonly uint32_t jobs_submitted
        readonly uint32_t jobs_started
        readonly uint32_t jobs_completed
        readonly uint32_t jobs_canceled
        readonly uint32_t jobs_failed
        readonly uint32_t jobs_pending
        readonly uint32_t jobs_running
        readonly time_t job_states_ts
        readonly uint32_t total_backfilled_jobs_slurm_start
        readonly uint32_t total_backfilled_jobs_stats_cycle_start
        readonly uint32_t total_backfilled_heterogeneous_job_components
        readonly uint32_t total_cycles
        readonly uint64_t bf_cycle_sum
        readonly uint32_t last_cycle
        readonly uint32_t max_cycle
        readonly uint32_t mean_cycle_backfill
        readonly uint32_t last_depth_cycle
        readonly uint32_t last_depth_cycle_try_sched
        readonly uint32_t depth_mean
        readonly uint32_t depth_mean_try_depth
        readonly uint32_t bf_depth_sum
        readonly uint32_t bf_depth_try_sum
        readonly uint32_t last_queue_length
        readonly unit32_t queue_length_mean
        readonly uint32_t bf_queue_len_sum
        readonly time_t last_cycle_when
        readonly uint32_t bf_active
        readonly uint32_t rpc_type_size
        readonly uint32_t rpc_user_size
        readonly dict rpc_type_stats
        readonly dict rpc_user_stats
        readonly dict rpc_pending_stats


def get_statistics():
    """
    Return scheduling statistics.

    This function wraps the `slurm_get_statistics` function and returns metrics
    for the main scheduler algorithm, backfill scheduler and slurmctld
    execution, similar to the output of `sdiag`.

    This function wraps the ``_print_stats`` function in `src/sdiag/sdiag.c`.

    Returns:
        Stats: Statistics object with all scheduler statistics.
    """
    cdef:
        stats_info_response_msg_t *buf
        stats_info_request_msg_t req
        int rc
        uint32_t i

    req.command_id = STAT_COMMAND_GET
    rc = slurm_get_statistics(&buf, <stats_info_request_msg_t*>&req)

    if rc == SLURM_SUCCESS:
        stats = Stats()

        stats.req_time = buf.req_time
        stats.req_time_start = buf.req_time_start

        stats.server_thread_count = buf.server_thread_count
        stats.agent_queue_size = buf.agent_queue_size
        stats.agent_count = buf.agent_count
        stats.dbd_agent_queue_size = buf.dbd_agent_queue_size

        stats.jobs_submitted = buf.jobs_submitted
        stats.jobs_started = buf.jobs_started
        stats.jobs_completed = buf.jobs_completed
        stats.jobs_canceled = buf.jobs_canceled
        stats.jobs_failed = buf.jobs_failed

        stats.job_states_ts = buf.jobs_states_ts
        stats.job_pending = buf.jobs_pending
        stats.job_running = buf.jobs_running

        stats.schedule_cycle_last = buf.schedule_cycle_last
        stats.schedule_cycle_max = buf.schedule_cycle_max
        stats.schedule_cycle_counter = buf.schedule_cycle_counter
        stats.schedule_cycle_sum = buf.schedule_cycle_sum
        stats.schedule_cycle_depth = buf.schedule_cycle_depth

        if buf.schedule_cycle_counter > 0:
            stats.mean_cycle_schedule = buf.schedule_cycle_sum / buf.schedule_cycle_counter
            stats.mean_depth_cycle_schedule = buf.schedule_cycle_depth / buf.schedule_cycle_counter

        if (buf.req_time - buf.req_time_start) > 60:
            stats.cycles_per_minute = <uint32_t>(buf.schedule_cycle_counter / ((buf.req_time - buf.req_time_start) / 60))

        stats.last_queue_len = buf.schedule_queue_len

        stats.bf_active = buf.bf_active
        stats.total_backfilled_jobs_slurm_start = buf.bf_backfilled_jobs
        stats.total_backfilled_jobs_stats_cycle_start = buf.bf_last_backfilled_jobs
        stats.total_backfilled_heterogeneous_job_components = buf.bf_backfilled_pack_jobs
        stats.total_cycles = buf.bf_cycle_counter
        stats.last_cycle_when = buf.bf_when_last_cycle
        stats.last_cycle = buf.bf_cycle_last
        stats.max_cycle = buf.bf_cycle_max
        stats.bf_cycle_sum = buf.bf_cycle_sum

        if buf.bf_cycle_counter > 0:
            stats.mean_cycle_backfill = buf.bf_cycle_sum / buf.bf_cycle_counter

        stats.last_depth_cycle = buf.bf_last_depth
        stats.last_depth_cycle_try_sched = buf.bf_last_depth_try
        stats.bf_depth_sum = buf.bf_depth_sum
        stats.bf_depth_try_sum = buf.bf_depth_try_sum

        if buf.bf_cycle_counter > 0:
            stats.depth_mean = buf.bf_depth_sum / buf.bf_cycle_counter
            stats.depth_mean_try_depth = buf.bf_depth_try_sum / buf.bf_cycle_counter

        stats.last_queue_length = buf.bf_queue_len
        stats.bf_queue_len_sum = buf.bf_queue_len_sum

        if buf.bf_cycle_counter > 0:
            stats.queue_length_mean = buf.bf_queue_len_sum / buf.bf_cycle_counter

        stats.latency_for_gettimeofday = buf.gettimeofday_latency


        rpc_type_stats = {}

        for i in range(buf.rpc_type_size):
            rpc_type = rpc_num2string(buf.rpc_type_id[i])
            rpc_type_stats[rpc_type] = {}
            rpc_type_stats[rpc_type]['id'] = buf.rpc_type_id[i]
            rpc_type_stats[rpc_type]['count'] = buf.rpc_type_cnt[i]
            if buf.rpc_type_cnt[i] == 0:
                rpc_type_stats[rpc_type]['ave_time'] = 0
            else:
                rpc_type_stats[rpc_type]['ave_time'] = int(buf.rpc_type_time[i] /
                                                           buf.rpc_type_cnt[i])
            rpc_type_stats[rpc_type]['total_time'] = int(buf.rpc_type_time[i])
        stats.rpc_type_stats = rpc_type_stats

        rpc_user_stats = {}

        for i in range(buf.rpc_user_size):
            try:
                rpc_user = getpwuid(buf.rpc_user_id[i])[0]
            except KeyError:
                rpc_user = buf.rpc_user_id[i]
            rpc_user_stats[rpc_user] = {}
            rpc_user_stats[rpc_user]["id"] = buf.rpc_user_id[i]
            rpc_user_stats[rpc_user]["count"] = buf.rpc_user_cnt[i]
            if buf.rpc_user_cnt[i] == 0:
                rpc_user_stats[rpc_user]["ave_time"] = 0
            else:
                rpc_user_stats[rpc_user]["ave_time"] = int(buf.rpc_user_time[i] /
                                                           buf.rpc_user_cnt[i])
            rpc_user_stats[rpc_user]["total_time"] = int(buf.rpc_user_time[i])
        stats.rpc_user_stats = rpc_user_stats

        rpc_pending_stats = {}

        for i in range(buf.rpc_queue_type_count):
            rpc_queue_type = rpc_num2string(buf.rpc_queue_type_id[i])
            rpc_pending_stats[rpc_queue_type] = {}
            rpc_pending_stats[rpc_queue_type]["id"] = buf.rpc_queue_type_id[i]
            rpc_pending_stats[rpc_queue_type]["count"] = buf.rpc_queue_count[i]
        stats.rpc_pending_stats = rpc_pending_stats

        # TODO: rpc_dump_count

        slurm_free_stats_response_msg(buf)
        buf = NULL
        return stats
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


def reset_statistics(self):
    """
    Reset scheduling statistics

    Returns:
        int: Return code.

    Notes:
        #. This method requires **root** privileges.
        #. Use :func:`get_errno` to translate return code if not 0.

    """
    cdef:
        stats_info_request_msg_t req
        int rc

    req.command_id = STAT_COMMAND_RESET
    rc = slurm_reset_statistics(<stats_info_request_msg_t*>&req)

    if rc == SLURM_SUCCESS:
        return rc
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


cdef rpc_num2string(uint16_t opcode):
    """
    Return string mapping of opcode.

    Given a protocol opcode, this function returns its string description
    mapping of the ``slurm_msg_type_t`` to its name.

    rpc_num2string - src/common/slurm_protocol_defs.h

    Args:
        opcode (int): Protocol opcode
    Returns:
        str: Description of opcode
    """
    cdef dict num2string

    num2string = {
        1001: "REQUEST_NODE_REGISTRATION_STATUS",
        1002: "MESSAGE_NODE_REGISTRATION_STATUS",
        1003: "REQUEST_RECONFIGURE",
        1004: "RESPONSE_RECONFIGURE",
        1005: "REQUEST_SHUTDOWN",
        1006: "REQUEST_SHUTDOWN_IMMEDIATE",
        1007: "RESPONSE_SHUTDOWN",
        1008: "REQUEST_PING",
        1009: "REQUEST_CONTROL",
        1010: "REQUEST_SET_DEBUG_LEVEL",
        1011: "REQUEST_HEALTH_CHECK",
        1012: "REQUEST_TAKEOVER",
        1013: "REQUEST_SET_SCHEDLOG_LEVEL",
        1014: "REQUEST_SET_DEBUG_FLAGS",
        1015: "REQUEST_REBOOT_NODES",
        1016: "RESPONSE_PING_SLURMD",
        1017: "REQUEST_ACCT_GATHER_UPDATE",
        1018: "RESPONSE_ACCT_GATHER_UPDATE",
        1019: "REQUEST_ACCT_GATHER_ENERGY",
        1020: "RESPONSE_ACCT_GATHER_ENERGY",
        1021: "REQUEST_LICENSE_INFO",
        1022: "RESPONSE_LICENSE_INFO",
        1023: "REQUEST_SET_FS_DAMPENING_FACTOR",
        1024: "RESPONSE_NODE_REGISTRATION",

        1400: "DBD_MESSAGES_START",
        1433: "PERSIST_RC",
        2000: "DBD_MESSAGES_END",

        2001: "REQUEST_BUILD_INFO",
        2002: "RESPONSE_BUILD_INFO",
        2003: "REQUEST_JOB_INFO",
        2004: "RESPONSE_JOB_INFO",
        2005: "REQUEST_JOB_STEP_INFO",
        2006: "RESPONSE_JOB_STEP_INFO",
        2007: "REQUEST_NODE_INFO",
        2008: "RESPONSE_NODE_INFO",
        2009: "REQUEST_PARTITION_INFO",
        2010: "RESPONSE_PARTITION_INFO",
        2011: "REQUEST_ACCTING_INFO",
        2012: "RESPONSE_ACCOUNTING_INFO",
        2013: "REQUEST_JOB_ID",
        2014: "RESPONSE_JOB_ID",
        2015: "DEFUNCT_REQUEST_BLOCK_INFO",
        2016: "DEFUNCT_RESPONSE_BLOCK_INFO",
        2017: "REQUEST_TRIGGER_SET",
        2018: "REQUEST_TRIGGER_GET",
        2019: "REQUEST_TRIGGER_CLEAR",
        2020: "RESPONSE_TRIGGER_GET",
        2021: "REQUEST_JOB_INFO_SINGLE",
        2022: "REQUEST_SHARE_INFO",
        2023: "RESPONSE_SHARE_INFO",
        2024: "REQUEST_RESERVATION_INFO",
        2025: "RESPONSE_RESERVATION_INFO",
        2026: "REQUEST_PRIORITY_FACTORS",
        2027: "RESPONSE_PRIORITY_FACTORS",
        2028: "REQUEST_TOPO_INFO",
        2029: "RESPONSE_TOPO_INFO",
        2030: "REQUEST_TRIGGER_PULL",
        2031: "REQUEST_FRONT_END_INFO",
        2032: "RESPONSE_FRONT_END_INFO",
        2033: "REQUEST_SPANK_ENVIRONMENT",
        2034: "RESPONCE_SPANK_ENVIRONMENT",
        2035: "REQUEST_STATS_INFO",
        2036: "RESPONSE_STATS_INFO",
        2037: "REQUEST_BURST_BUFFER_INFO",
        2038: "RESPONSE_BURST_BUFFER_INFO",
        2039: "REQUEST_JOB_USER_INFO",
        2040: "REQUEST_NODE_INFO_SINGLE",
        2041: "REQUEST_POWERCAP_INFO",
        2042: "RESPONSE_POWERCAP_INFO",
        2043: "REQUEST_ASSOC_MGR_INFO",
        2044: "RESPONSE_ASSOC_MGR_INFO",
        2045: "REQUEST_EVENT_LOG",
        2046: "DEFUNCT_RESPONSE_SICP_INFO_DEFUNCT",
        2047: "REQUEST_LAYOUT_INFO",
        2048: "RESPONSE_LAYOUT_INFO",
        2049: "REQUEST_FED_INFO",
        2050: "RESPONSE_FED_INFO",
        2051: "REQUEST_BATCH_SCRIPT",
        2052: "RESPONSE_BATCH_SCRIPT",
        2052: "REQUEST_CONTROL_STATUS",
        2053: "RESPONSE_CONTROL_STATUS",
        2054: "REQUEST_BURST_BUFFER_STATUS",
        2055: "RESPONSE_BURST_BUFFER_STATUS",

        3001: "REQUEST_UPDATE_JOB",
        3002: "REQUEST_UPDATE_NODE",
        3003: "REQUEST_CREATE_PARTITION",
        3004: "REQUEST_DELETE_PARTITION",
        3005: "REQUEST_UPDATE_PARTITION",
        3006: "REQUEST_CREATE_RESERVATION",
        3007: "RESPONSE_CREATE_RESERVATION",
        3008: "REQUEST_DELETE_RESERVATION",
        3009: "REQUEST_UPDATE_RESERVATION",
        3010: "DEFUNCT_REQUEST_UPDATE_BLOCK",
        3011: "REQUEST_UPDATE_FRONT_END",
        3012: "REQUEST_UPDATE_LAYOUT",
        3013: "REQUEST_UPDATE_POWERCAP",

        4001: "REQUEST_RESOURCE_ALLOCATION",
        4002: "RESPONSE_RESOURCE_ALLOCATION",
        4003: "REQUEST_SUBMIT_BATCH_JOB",
        4004: "RESPONSE_SUBMIT_BATCH_JOB",
        4005: "REQUEST_BATCH_JOB_LAUNCH",
        4006: "REQUEST_CANCEL_JOB",
        4007: "RESPONSE_CANCEL_JOB",
        4008: "REQUEST_JOB_RESOURCE",
        4009: "RESPONSE_JOB_RESOURCE",
        4010: "REQUEST_JOB_ATTACH",
        4011: "RESPONSE_JOB_ATTACH",
        4012: "REQUEST_JOB_WILL_RUN",
        4013: "RESPONSE_JOB_WILL_RUN",
        4014: "REQUEST_JOB_ALLOCATION_INFO",
        4015: "RESPONSE_JOB_ALLOCATION_INFO",
        4016: "DEFUNCT_REQUEST_JOB_ALLOCATION_INFO_LITE",
        4017: "DEFUNCT_RESPONSE_JOB_ALLOCATION_INFO_LITE",
        4018: "REQUEST_UPDATE_JOB_TIME",
        4019: "REQUEST_JOB_READY",
        4020: "RESPONSE_JOB_READY",
        4021: "REQUEST_JOB_END_TIME",
        4022: "REQUEST_JOB_NOTIFY",
        4023: "REQUEST_JOB_SBCAST_CRED",
        4024: "RESPONSE_JOB_SBCAST_CRED",
        4025: "REQUEST_JOB_PACK_ALLOCATION",
        4026: "RESPONSE_JOB_PACK_ALLOCATION",
        4027: "REQUEST_JOB_PACK_ALLOC_INFO",
        4028: "REQUEST_SUBMIT_BATCH_JOB_PACK",

        4500: "REQUEST_CTLD_MULT_MSG",
        4501: "RESPONSE_CTLD_MULT_MSG",
        4502: "REQUEST_SIB_MSG",
        4503: "REQUEST_SIB_JOB_LOCK",
        4504: "REQUEST_SIB_JOB_UNLOCK",

        5001: "REQUEST_JOB_STEP_CREATE",
        5002: "RESPONSE_JOB_STEP_CREATE",
        5003: "REQUEST_RUN_JOB_STEP",
        5004: "RESPONSE_RUN_JOB_STEP",
        5005: "REQUEST_CANCEL_JOB_STEP",
        5006: "RESPONSE_CANCEL_JOB_STEP",
        5007: "REQUEST_UPDATE_JOB_STEP",
        5008: "DEFUNCT_RESPONSE_COMPLETE_JOB_STEP",
        5009: "REQUEST_CHECKPOINT",
        5010: "RESPONSE_CHECKPOINT",
        5011: "REQUEST_CHECKPOINT_COMP",
        5012: "REQUEST_CHECKPOINT_TASK_COMP",
        5013: "RESPONSE_CHECKPOINT_COMP",
        5014: "REQUEST_SUSPEND",
        5015: "RESPONSE_SUSPEND",
        5016: "REQUEST_STEP_COMPLETE",
        5017: "REQUEST_COMPLETE_JOB_ALLOCATION",
        5018: "REQUEST_COMPLETE_BATCH_SCRIPT",
        5019: "REQUEST_JOB_STEP_STAT",
        5020: "RESPONSE_JOB_STEP_STAT",
        5021: "REQUEST_STEP_LAYOUT",
        5022: "RESPONSE_STEP_LAYOUT",
        5023: "REQUEST_JOB_REQUEUE",
        5024: "REQUEST_DAEMON_STATUS",
        5025: "RESPONSE_SLURMD_STATUS",
        5026: "RESPONSE_SLURMCTLD_STATUS",
        5027: "REQUEST_JOB_STEP_PIDS",
        5028: "RESPONSE_JOB_STEP_PIDS",
        5029: "REQUEST_FORWARD_DATA",
        5030: "REQUEST_COMPLETE_BATCH_JOB",
        5031: "REQUEST_SUSPEND_INT",
        5032: "REQUEST_KILL_JOB",
        5033: "REQUEST_KILL_JOBSTEP",
        5034: "RESPONSE_JOB_ARRAY_ERRORS",
        5035: "REQUEST_NETWORK_CALLERID",
        5036: "RESPONSE_NETWORK_CALLERID",
        5037: "REQUEST_STEP_COMPLETE_AGGR",
        5038: "REQUEST_TOP_JOB",

        6001: "REQUEST_LAUNCH_TASKS",
        6002: "RESPONSE_LAUNCH_TASKS",
        6003: "MESSAGE_TASK_EXIT",
        6004: "REQUEST_SIGNAL_TASKS",
        6005: "REQUEST_CHECKPOINT_TASKS",
        6006: "REQUEST_TERMINATE_TASKS",
        6007: "REQUEST_REATTACH_TASKS",
        6008: "RESPONSE_REATTACH_TASKS",
        6009: "REQUEST_KILL_TIMELIMIT",
        6010: "DEFUNCT_REQUEST_SIGNAL_JOB",
        6011: "REQUEST_TERMINATE_JOB",
        6012: "MESSAGE_EPILOG_COMPLETE",
        6013: "REQUEST_ABORT_JOB",
        6014: "REQUEST_FILE_BCAST",
        6015: "TASK_USER_MANAGED_IO_STREAM",
        6016: "REQUEST_KILL_PREEMPTED",
        6017: "REQUEST_LAUNCH_PROLOG",
        6018: "REQUEST_COMPLETE_PROLOG",
        6019: "RESPONSE_PROLOG_EXECUTING",

        7001: "SRUN_PING",
        7002: "SRUN_TIMEOUT",
        7003: "SRUN_NODE_FAIL",
        7004: "SRUN_JOB_COMPLETE",
        7005: "SRUN_USER_MSG",
        7006: "SRUN_EXEC",
        7007: "SRUN_STEP_MISSING",
        7008: "SRUN_REQUEST_SUSPEND",
        7009: "SRUN_STEP_SIGNAL",

        7201: "PMI_KVS_PUT_REQ",
        7202: "PMI_KVS_PUT_RESP",
        7203: "PMI_KVS_GET_REQ",
        7204: "PMI_KVS_GET_RESP",

        8001: "RESPONSE_SLURM_RC",
        8002: "RESPONSE_SLURM_RC_MSG",
        8003: "RESPONSE_SLURM_REROUTE_MSG",

        9001: "RESPONSE_FORWARD_FAILED",

        10001: "ACCOUNTING_UPDATE_MSG",
        10002: "ACCOUNTING_FIRST_REG",
        10003: "ACCOUNTING_REGISTER_CTLD",
        10004: "ACCOUNTING_TRES_CHANGE_DB",
        10005: "ACCOUNTING_NODES_CHANGE_DB",

        11001: "MESSAGE_COMPOSITE",
        11002: "RESPONSE_MESSAGE_COMPOSITE"
    }
    return num2string[opcode]
