# c_block.pxd
#
from libc.stdint cimport uint16_t, uint32_t
from libc.stdint cimport int32_t
from posix.types cimport time_t
from libc.stdio cimport FILE
from .slurmdb_common cimport List

cdef extern from "slurm/slurm.h" nogil:
    enum:
        HIGHEST_DIMENSIONS

    ctypedef struct block_info_t:
        char *bg_block_id
        char *blrtsimage
        uint16_t conn_type[HIGHEST_DIMENSIONS]
        uint32_t cnode_cnt
        uint32_t cnode_err_cnt
        int32_t *ionode_inx
        char *ionode_str
        List job_list
        char *linuximage
        char *mloaderimage
        int32_t *mp_inx
        char *mp_str
        uint16_t node_use
        char *ramdiskimage
        char *reason
        uint16_t state

    ctypedef struct block_info_msg_t:
        block_info_t *block_array
        time_t last_update
        uint32_t record_count


    void slurm_free_block_info_msg(block_info_msg_t *block_info_msg)
    int slurm_update_block(update_block_msg_t *block_msg)
    void slurm_init_update_block_msg(update_block_msg_t *update_block_msg)

    int slurm_load_block_info(
        time_t update_time,
        block_info_msg_t **block_info_msg_pptr,
        uint16_t show_flags
    )

    void slurm_print_block_info_msg(
        FILE *out,
        block_info_msg_t *info_ptr,
        int one_liner
    )

    void slurm_print_block_info(
        FILE *out,
        block_info_msg_t *bg_info_ptr,
        int one_liner
    )
