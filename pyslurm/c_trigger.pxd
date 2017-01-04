# c_trigger.pxd
#
from libc.stdint cimport uint16_t, uint32_t

cdef extern from "slurm/slurm.h" nogil:

    ctypedef struct trigger_info_t:
        uint16_t flags
        uint32_t trig_id
        uint16_t res_type
        char *res_id
        uint32_t trig_type
        uint16_t offset
        uint32_t user_id
        char *program

    ctypedef struct trigger_info_msg_t:
        uint32_t record_count
        trigger_info_t *trigger_array

    int slurm_set_trigger(trigger_info_t *trigger_set)
    int slurm_clear_trigger(trigger_info_t *trigger_clear)
    int slurm_get_triggers(trigger_info_msg_t **trigger_get)
    int slurm_pull_trigger(trigger_info_t *trigger_pull)
    void slurm_free_trigger_msg(trigger_info_msg_t *trigger_free)
    void slurm_init_trigger_msg(trigger_info_t *trigger_info_msg)
