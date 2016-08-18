# c_powercap.pxd
#
from libc.stdint cimport uint32_t
from libc.stdio cimport FILE

cdef extern from "slurm/slurm.h" nogil:
    ctypedef struct powercap_info_msg_t:
        uint32_t power_cap
        uint32_t power_floor
        uint32_t power_change
        uint32_t min_watts
        uint32_t cur_max_watts
        uint32_t adj_max_watts
        uint32_t max_watts

    ctypedef powercap_info_msg_t update_powercap_msg_t

    int slurm_load_powercap(powercap_info_msg_t **powercap_info_msg_pptr)
    void slurm_free_powercap_info_msg(powercap_info_msg_t *msg)
    int slurm_update_powercap(update_powercap_msg_t *powercap_msg)

    void slurm_print_powercap_info_msg(FILE *out,
                                       powercap_info_msg_t *powercap_info_msg_ptr,
                                       int one_liner)
