from libc.stdint cimport uint16_t, uint32_t, uint64_t
from libc.stdio cimport FILE
from posix.types cimport time_t
from .slurm_common cimport dynamic_plugin_data_t
from .c_partition cimport partition_info_msg_t

include "node.pxi"

cdef extern from "slurm/slurm.h" nogil:
    ctypedef struct acct_gather_energy_t:
        uint64_t base_consumed_energy
        uint32_t base_watts
        uint64_t consumed_energy
        uint32_t current_watts
        uint64_t previous_consumed_energy
        time_t poll_time

    ctypedef struct ext_sensors_data_t:
        uint64_t consumed_energy
        uint32_t temperature
        time_t energy_update_time
        uint32_t current_watts

    ctypedef struct power_mgmt_data_t:
        uint32_t cap_watts
        uint32_t current_watts
        uint64_t joule_counter
        uint32_t new_cap_watts
        uint32_t max_watts
        uint32_t min_watts
        time_t new_job_time
        uint16_t state
        uint64_t time_usec

    ctypedef struct node_info_t:
        char *arch
        uint16_t boards
        time_t boot_time
        uint16_t cores
        uint16_t core_spec_cnt
        uint32_t cpu_load
        uint64_t free_mem
        uint16_t cpus
        char *cpu_spec_list
        acct_gather_energy_t *energy
        ext_sensors_data_t *ext_sensors
        power_mgmt_data_t *power
        char *features
        char *features_act
        char *gres
        char *gres_drain
        char *gres_used
        char *mcs_label
        uint64_t mem_spec_limit
        char *name
        char *node_addr
        char *node_hostname
        uint32_t node_state
        char *os
        uint32_t owner
        char *partitions
        uint16_t port
        uint64_t real_memory
        char *reason
        time_t reason_time
        uint32_t reason_uid
        dynamic_plugin_data_t *select_nodeinfo
        time_t slurmd_start_time
        uint16_t sockets
        uint16_t threads
        uint32_t tmp_disk
        uint32_t weight
        char *tres_fmt_str
        char *version

    ctypedef struct node_info_msg_t:
        time_t last_update
        uint32_t record_count
        node_info_t *node_array

    cdef enum node_states:
        NODE_STATE_UNKNOWN
        NODE_STATE_DOWN
        NODE_STATE_IDLE
        NODE_STATE_ALLOCATED
        NODE_STATE_ERROR
        NODE_STATE_MIXED
        NODE_STATE_FUTURE
        NODE_STATE_END

    enum select_nodedata_type:
        SELECT_NODEDATA_BITMAP_SIZE
        SELECT_NODEDATA_SUBGRP_SIZE
        SELECT_NODEDATA_SUBCNT
        SELECT_NODEDATA_BITMAP
        SELECT_NODEDATA_STR
        SELECT_NODEDATA_PTR
        SELECT_NODEDATA_EXTRA_INFO
        SELECT_NODEDATA_RACK_MP
        SELECT_NODEDATA_MEM_ALLOC
        SELECT_NODEDATA_TRES_ALLOC_FMT_STR
        SELECT_NODEDATA_TRES_ALLOC_WEIGHTED

    ctypedef struct update_node_msg_t:
        char *features
        char *features_act
        char *gres
        char *node_addr
        char *node_hostname
        char *node_names
        uint32_t node_state
        char *reason
        uint32_t reason_uid
        uint32_t weight


    int slurm_load_node(time_t update_time,
                        node_info_msg_t **resp,
                        uint16_t show_flags)

    int slurm_load_node_single(node_info_msg_t **resp,
                               char *node_name,
                               uint16_t show_flags)

    int slurm_get_select_nodeinfo(dynamic_plugin_data_t *nodeinfo,
                                  select_nodedata_type data_type,
                                  node_states state, void *data)

    void slurm_print_node_info_msg(FILE *out,
                                   node_info_msg_t *node_info_msg_ptr,
                                   int one_liner)

    void slurm_print_node_table(FILE *out, node_info_t *node_ptr,
                                int node_scaling, int one_liner)

    int slurm_update_node(update_node_msg_t *node_msg)
    void slurm_init_update_node_msg(update_node_msg_t *update_node_msg)
    void slurm_free_node_info_msg(node_info_msg_t *node_buffer_ptr)
    void slurm_populate_node_partitions(node_info_msg_t *node_buffer_ptr,
                                    partition_info_msg_t *part_buffer_ptr)



#
# Node declarations outside of slurm.h
#

cdef extern char *slurm_node_state_string(uint32_t inx)

#
# Defined node states
#

cdef inline IS_NODE_ALLOCATED(node_info_t _X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_ALLOCATED

cdef inline IS_NODE_DOWN(node_info_t _X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_DOWN

cdef inline IS_NODE_ERROR(node_info_t _X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_ERROR

cdef inline IS_NODE_MIXED(node_info_t _X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_MIXED

cdef inline IS_NODE_IDLE(node_info_t _X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_IDLE

cdef inline IS_NODE_COMPLETING(node_info_t _X):
    return (_X.node_state & NODE_STATE_COMPLETING)

cdef inline IS_NODE_DRAIN(node_info_t _X):
    return (_X.node_state & NODE_STATE_DRAIN)

cdef inline IS_NODE_DRAINING(node_info_t _X):
    return (_X.node_state & NODE_STATE_DRAIN) and (IS_NODE_ALLOCATED(_X) or
                                                   IS_NODE_ERROR(_X) or
                                                   IS_NODE_MIXED(_X))
