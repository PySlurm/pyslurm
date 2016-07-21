# cython: c_string_type=unicode, c_string_encoding=utf8
# cython: cdivision=True

from __future__ import print_function, division, unicode_literals

from common cimport *
from utils cimport *
from exceptions import PySlurmError

cdef class Stats:
    cdef:
        uint32_t parts_packed
        time_t req_time
        time_t req_time_start
        uint32_t server_thread_count
        uint32_t agent_queue_size
        uint32_t schedule_cycle_max
        uint32_t schedule_cycle_last
        uint32_t schedule_cycle_sum
        uint32_t schedule_cycle_counter
        uint32_t schedule_cycle_depth
        uint32_t schedule_queue_len
        uint32_t jobs_submitted
        uint32_t jobs_started
        uint32_t jobs_completed
        uint32_t jobs_canceled
        uint32_t jobs_failed
        uint32_t bf_backfilled_jobs
        uint32_t bf_last_backfilled_jobs
        uint32_t bf_cycle_counter
        uint64_t bf_cycle_sum
        uint32_t bf_cycle_last
        uint32_t bf_cycle_max
        uint32_t bf_last_depth
        uint32_t bf_last_depth_try
        uint32_t bf_depth_sum
        uint32_t bf_depth_try_sum
        uint32_t bf_queue_len
        uint32_t bf_queue_len_sum
        time_t bf_when_last_cycle
        uint32_t bf_active
        uint32_t rpc_type_size
        uint16_t *rpc_type_id
        uint32_t *rpc_type_cnt
        uint64_t *rpc_type_time
        uint32_t rpc_user_size
        uint32_t *rpc_user_id
        uint32_t *rpc_user_cnt
        uint64_t *rpc_user_time

    property parts_packed:
        def __get__(self):
            return self.parts_packed

    property req_time:
        def __get__(self):
            return self.req_time

    property req_time_start:
        def __get__(self):
            return self.req_time_start

    property server_thread_count:
        def __get__(self):
            return self.server_thread_count

    property agent_queue_size:
        def __get__(self):
            return self.agent_queue_size

    property schedule_cycle_max:
        def __get__(self):
            return self.schedule_cycle_max

    property schedule_cycle_last:
        def __get__(self):
            return self.schedule_cycle_last

    property schedule_cycle_sum:
        def __get__(self):
            return self.schedule_cycle_sum

    property schedule_cycle_counter:
        def __get__(self):
            return self.schedule_cycle_counter

    property schedule_cycle_depth:
        def __get__(self):
            return self.schedule_cycle_depth

    property schedule_queue_len:
        def __get__(self):
            return self.schedule_queue_len

    property jobs_submitted:
        def __get__(self):
            return self.jobs_submitted

    property jobs_started:
        def __get__(self):
            return self.jobs_started

    property jobs_completed:
        def __get__(self):
            return self.jobs_completed

    property jobs_canceled:
        def __get__(self):
            return self.jobs_canceled

    property jobs_failed:
        def __get__(self):
            return self.jobs_failed

    property bf_backfilled_jobs:
        def __get__(self):
            return self.bf_backfilled_jobs

    property bf_last_backfilled_jobs:
        def __get__(self):
            return self.bf_last_backfilled_jobs

    property bf_cycle_counter:
        def __get__(self):
            return self.bf_cycle_counter

    property bf_cycle_sum:
        def __get__(self):
            return self.bf_cycle_sum

    property bf_cycle_last:
        def __get__(self):
            return self.bf_cycle_last

    property bf_cycle_max:
        def __get__(self):
            return self.bf_cycle_max

    property bf_last_depth:
        def __get__(self):
            return self.bf_last_depth

    property bf_last_depth_try:
        def __get__(self):
            return self.bf_last_depth_try

    property bf_depth_sum:
        def __get__(self):
            return self.bf_depth_sum

    property bf_depth_try_sum:
        def __get__(self):
            return self.bf_depth_try_sum

    property bf_queue_len:
        def __get__(self):
            return self.bf_queue_len

    property bf_queue_len_sum:
        def __get__(self):
            return self.bf_queue_len_sum

    property bf_when_last_cycle:
        def __get__(self):
            return self.bf_when_last_cycle

    property bf_active:
        def __get__(self):
            return self.bf_active


cpdef get_statistics():
    cdef:
        stats_info_request_msg_t req
        stats_info_response_msg_t *buf = NULL
        int rc
        int errnum
        uint32_t i
        dict rpc_type_stats
        dict rpc_user_stats

    req.command_id = STAT_COMMAND_GET
    rc = slurm_get_statistics(&buf, <stats_info_request_msg_t*>&req)

    if rc == SLURM_SUCCESS:
        stats = Stats()

        stats.parts_packed = buf.parts_packed
        stats.req_time = buf.req_time
        stats.req_time_start = buf.req_time_start
        stats.server_thread_count = buf.server_thread_count
        stats.agent_queue_size = buf.agent_queue_size

        stats.schedule_cycle_max = buf.schedule_cycle_max
        stats.schedule_cycle_last = buf.schedule_cycle_last
        stats.schedule_cycle_sum = buf.schedule_cycle_sum
        stats.schedule_cycle_counter = buf.schedule_cycle_counter
        stats.schedule_cycle_depth = buf.schedule_cycle_depth
        stats.schedule_queue_len = buf.schedule_queue_len

        stats.jobs_submitted = buf.jobs_submitted
        stats.jobs_started = buf.jobs_started
        stats.jobs_completed = buf.jobs_completed
        stats.jobs_canceled = buf.jobs_canceled
        stats.jobs_failed = buf.jobs_failed

        stats.bf_backfilled_jobs = buf.bf_backfilled_jobs
        stats.bf_last_backfilled_jobs = buf.bf_last_backfilled_jobs
        stats.bf_cycle_counter = buf.bf_cycle_counter
        stats.bf_cycle_sum = buf.bf_cycle_sum
        stats.bf_cycle_last = buf.bf_cycle_last
        stats.bf_cycle_max = buf.bf_cycle_max
        stats.bf_last_depth = buf.bf_last_depth
        stats.bf_last_depth_try = buf.bf_last_depth_try
        stats.bf_depth_sum = buf.bf_depth_sum
        stats.bf_depth_try_sum = buf.bf_depth_try_sum
        stats.bf_queue_len = buf.bf_queue_len
        stats.bf_queue_len_sum = buf.bf_queue_len_sum
        stats.bf_when_last_cycle = buf.bf_when_last_cycle
        stats.bf_active = buf.bf_active

        rpc_type_stats = {}

#        for i in range(buf.rpc_type_size):
#            rpc_type = self.__rpc_num2string(buf.rpc_type_id[i])
#            rpc_type_stats[rpc_type] = {}
#            rpc_type_stats[rpc_type][u'id = buf.rpc_type_id[i]
#            rpc_type_stats[rpc_type][u'count = buf.rpc_type_cnt[i]
#            if buf.rpc_type_cnt[i] == 0:
#                rpc_type_stats[rpc_type][u'ave_time = 0
#            else:
#                rpc_type_stats[rpc_type][u'ave_time = int(buf.rpc_type_time[i] /
#                                                            buf.rpc_type_cnt[i])
#            rpc_type_stats[rpc_type][u'total_time = int(buf.rpc_type_time[i])
#        stats.rpc_type_stats = rpc_type_stats
#
#        rpc_user_stats = {}
#
#        for i in range(buf.rpc_user_size):
#            try:
#                rpc_user = getpwuid(buf.rpc_user_id[i])[0]
#            except KeyError:
#                rpc_user = str(buf.rpc_user_id[i])
#            rpc_user_stats[rpc_user] = {}
#            rpc_user_stats[rpc_user][u"id"] = buf.rpc_user_id[i]
#            rpc_user_stats[rpc_user][u"count"] = buf.rpc_user_cnt[i]
#            if buf.rpc_user_cnt[i] == 0:
#                rpc_user_stats[rpc_user][u"ave_time"] = 0
#            else:
#                rpc_user_stats[rpc_user][u"ave_time"] = int(buf.rpc_user_time[i] /
#                                                            buf.rpc_user_cnt[i])
#            rpc_user_stats[rpc_user][u"total_time"] = int(buf.rpc_user_time[i])
#        stats.rpc_user_stats = rpc_user_stats
#
        slurm_free_stats_response_msg(buf)
        buf = NULL
        return stats
    else:
        errnum = slurm_get_errno()
        raise PySlurmError(slurm_strerror(errnum))


cpdef int reset_statistics(self):
    """
    Reset scheduling statistics

    This method required root privileges.
    """
    cdef:
        stats_info_request_msg_t req
        int errnum
        int rc

    req.command_id = STAT_COMMAND_RESET
    rc = slurm_reset_statistics(<stats_info_request_msg_t*>&req)

    if rc == SLURM_SUCCESS:
        return rc
    else:
        errnum = slurm_get_errno()
        raise PySlurmError(slurm_strerror(errnum))


cdef rpc_num2string(uint16_t opcode):
    """
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
        2015: "REQUEST_BLOCK_INFO",
        2016: "RESPONSE_BLOCK_INFO",
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
        2045: "REQUEST_SICP_INFO_DEFUNCT",
        2046: "RESPONSE_SICP_INFO_DEFUNCT",
        2047: "REQUEST_LAYOUT_INFO",
        2048: "RESPONSE_LAYOUT_INFO",

        3001: "REQUEST_UPDATE_JOB",
        3002: "REQUEST_UPDATE_NODE",
        3003: "REQUEST_CREATE_PARTITION",
        3004: "REQUEST_DELETE_PARTITION",
        3005: "REQUEST_UPDATE_PARTITION",
        3006: "REQUEST_CREATE_RESERVATION",
        3007: "RESPONSE_CREATE_RESERVATION",
        3008: "REQUEST_DELETE_RESERVATION",
        3009: "REQUEST_UPDATE_RESERVATION",
        3010: "REQUEST_UPDATE_BLOCK",
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
        4016: "REQUEST_JOB_ALLOCATION_INFO_LITE",
        4017: "RESPONSE_JOB_ALLOCATION_INFO_LITE",
        4018: "REQUEST_UPDATE_JOB_TIME",
        4019: "REQUEST_JOB_READY",
        4020: "RESPONSE_JOB_READY",
        4021: "REQUEST_JOB_END_TIME",
        4022: "REQUEST_JOB_NOTIFY",
        4023: "REQUEST_JOB_SBCAST_CRED",
        4024: "RESPONSE_JOB_SBCAST_CRED",

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
        6010: "REQUEST_SIGNAL_JOB",
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

        7201: "PMI_KVS_PUT_REQ",
        7202: "PMI_KVS_PUT_RESP",
        7203: "PMI_KVS_GET_REQ",
        7204: "PMI_KVS_GET_RESP",

        8001: "RESPONSE_SLURM_RC",
        8002: "RESPONSE_SLURM_RC_MSG",

        9001: "RESPONSE_FORWARD_FAILED",

        10001: "ACCOUNTING_UPDATE_MSG",
        10002: "ACCOUNTING_FIRST_REG",
        10003: "ACCOUNTING_REGISTER_CTLD",

        11001: "MESSAGE_COMPOSITE",
        11002: "RESPONSE_MESSAGE_COMPOSITE"
    }
    return num2string[opcode]
