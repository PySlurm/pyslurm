# c_trigger.pxd
#
from libc.stdint cimport uint16_t, uint32_t

cdef extern from "slurm/slurm.h" nogil:
    enum: TRIGGER_FLAG_PERM

    enum:
        TRIGGER_RES_TYPE_JOB
        TRIGGER_RES_TYPE_NODE
        TRIGGER_RES_TYPE_SLURMCTLD
        TRIGGER_RES_TYPE_SLURMDBD
        TRIGGER_RES_TYPE_DATABASE
        TRIGGER_RES_TYPE_FRONT_END
        TRIGGER_RES_TYPE_OTHER

    enum:
        TRIGGER_TYPE_UP
        TRIGGER_TYPE_DOWN
        TRIGGER_TYPE_FAIL
        TRIGGER_TYPE_TIME
        TRIGGER_TYPE_FINI
        TRIGGER_TYPE_RECONFIG
        TRIGGER_TYPE_IDLE
        TRIGGER_TYPE_DRAINED
        TRIGGER_TYPE_PRI_CTLD_FAIL
        TRIGGER_TYPE_PRI_CTLD_RES_OP
        TRIGGER_TYPE_PRI_CTLD_RES_CTRL
        TRIGGER_TYPE_PRI_CTLD_ACCT_FULL
        TRIGGER_TYPE_BU_CTLD_FAIL
        TRIGGER_TYPE_BU_CTLD_RES_OP
        TRIGGER_TYPE_BU_CTLD_AS_CTRL
        TRIGGER_TYPE_PRI_DBD_FAIL
        TRIGGER_TYPE_PRI_DBD_RES_OP
        TRIGGER_TYPE_PRI_DB_FAIL
        TRIGGER_TYPE_PRI_DB_RES_OP
        TRIGGER_TYPE_BURST_BUFFER

    ctypedef struct trigger_info_t:
        uint16_t flags
        uint32_t trig_id
        uint16_t res_type
        char *res_id
        uint32_t control_inx
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
