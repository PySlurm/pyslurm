# c_frontend.pxd
#
from libc.stdint cimport uint32_t
from posix.types cimport time_t
from libc.stdio cimport FILE

cdef extern from "slurm/slurm.h" nogil:
    ctypedef struct front_end_info_t:
        char *allow_groups
        char *allow_users
        time_t boot_time
        char *deny_groups
        char *deny_users
        char *name
        uint32_t node_state
        char *reason
        time_t reason_time
        uint32_t reason_uid
        time_t slurmd_start_time
        char *version

    ctypedef struct front_end_info_msg_t:
        time_t last_update
        uint32_t record_count
        front_end_info_t *front_end_array

    ctypedef struct update_front_end_msg_t:
        char *name
        uint32_t node_state
        char *reason
        uint32_t reason_uid

    void slurm_free_front_end_info_msg(front_end_info_msg_t *front_end_buffer_ptr)
    int slurm_load_front_end(time_t update_time, front_end_info_msg_t **resp)

    void slurm_print_front_end_info_msg(
        FILE *out,
        front_end_info_msg_t *front_end_info_msg_ptr,
        int one_liner
    )

    void slurm_print_front_end_table(
        FILE *out,
        front_end_info_t *front_end_ptr,
        int one_liner
    )

    char *slurm_sprint_front_end_table(front_end_info_t *front_end_ptr, int one_liner)
    void slurm_init_update_front_end_msg(update_front_end_msg_t *update_front_end_msg)
    int slurm_update_front_end(update_front_end_msg_t *front_end_msg)
