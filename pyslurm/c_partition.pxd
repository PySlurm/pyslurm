from libc.stdint cimport int32_t, uint16_t, uint32_t
from libc.stdio cimport FILE
from posix.types cimport time_t

cdef extern from "slurm/slurm.h" nogil:
    ctypedef struct partition_info_t:
        char *allow_alloc_nodes
        char *allow_accounts
        char *allow_groups
        char *allow_qos
        char *alternate
        char *billing_weights_str
        uint16_t cr_type
        uint32_t def_mem_per_cpu
        uint32_t default_time
        char *deny_accounts
        char *deny_qos
        uint16_t flags
        uint32_t grace_time
        uint32_t max_cpus_per_node
        uint32_t max_mem_per_cpu
        uint32_t max_nodes
        uint16_t max_share
        uint32_t max_time
        uint32_t min_nodes
        char *name
        int32_t *node_inx
        char *nodes
        uint16_t preempt_mode
        uint16_t priority
        char *qos_char
        uint16_t state_up
        uint32_t total_cpus
        uint32_t total_nodes
        char *tres_fmt_str

    ctypedef struct partition_info_msg_t:
        time_t last_update
        uint32_t record_count
        partition_info_t *partition_array

    ctypedef struct delete_part_msg_t:
        char *name

    ctypedef partition_info_t update_part_msg_t

    int slurm_create_partition(update_part_msg_t * part_msg)
    int slurm_update_partition(update_part_msg_t * part_msg)
    int slurm_delete_partition(delete_part_msg_t * part_msg)
    void slurm_init_part_desc_msg(update_part_msg_t * update_part_msg)
    void slurm_free_partition_info_msg(partition_info_msg_t * part_info_ptr)

    int slurm_load_partitions(time_t update_time,
                              partition_info_msg_t **part_buffer_ptr,
                              uint16_t show_flags)

    void slurm_print_partition_info_msg(FILE *out,
                                        partition_info_msg_t *part_info_ptr,
                                        int one_liner)

    void slurm_print_partition_info(FILE *out,
                                    partition_info_t *part_ptr,
                                    int one_liner)
