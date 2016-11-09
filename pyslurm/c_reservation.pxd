# c_reservation.pxd
#
from libc.stdint cimport uint32_t
from libc.stdint cimport int32_t
from libc.stdio cimport FILE
from posix.types cimport time_t

cdef extern from "slurm/slurm.h" nogil:
    ctypedef struct reserve_info_t:
        char *accounts
        char *burst_buffer
        uint32_t core_cnt
        time_t end_time
        char *features
        uint32_t flags
        char *licenses
        char *name
        uint32_t node_cnt
        int32_t *node_inx
        char *node_list
        char *partition
        time_t start_time
        uint32_t resv_watts
        char *tres_str
        char *users

    ctypedef struct reserve_info_msg_t:
        time_t last_update
        uint32_t record_count
        reserve_info_t *reservation_array

    int slurm_load_reservations(time_t update_time, reserve_info_msg_t **resp)
    void slurm_free_reservation_info_msg(reserve_info_msg_t *resv_info_ptr)

    void slurm_print_reservation_info_msg(FILE *out,
                                          reserve_info_msg_t *resv_info_ptr,
                                          int one_liner)

    void slurm_print_reservation_info(FILE *out,
                                      reserve_info_t *resv_ptr,
                                      int one_liner)

#
# Job declarations outside of slurm.h
#

# src/common/slurm_protocol_defs.h
cdef extern char *slurm_reservation_flags_string(uint32_t flags)
