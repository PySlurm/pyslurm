from common cimport *

cdef extern from "slurm/slurm.h" nogil:
    enum:
        STAT_COMMAND_RESET
        STAT_COMMAND_GET

    ctypedef struct stats_info_response_msg_t:
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

    ctypedef struct stats_info_request_msg_t:
            uint16_t command_id


    int slurm_get_statistics(stats_info_response_msg_t **buf,
                             stats_info_request_msg_t *req)

    int slurm_reset_statistics(stats_info_request_msg_t *req)

#
# Statistics declarations outside of slurm.h
#

cdef extern void slurm_free_stats_response_msg(
    stats_info_response_msg_t *msg
)
