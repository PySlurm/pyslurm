# slurm_common.pxd
#
# Slurm declarations common to all other extension files.
#
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libc.stdint cimport int32_t
from posix.types cimport time_t

cdef extern from "slurm/slurm.h" nogil:
    # NOTE: should this just be enums?
    uint32_t INFINITE
    uint64_t INFINITE64
    uint32_t NO_VAL
    uint64_t NO_VAL64

    enum:
        CR_CORE
        CR_SOCKET

    enum:
        MEM_PER_CPU
        SHARED_FORCE

    enum:
        SHOW_ALL
        SHOW_DETAIL
        SHOW_DETAIL2
        SHOW_MIXED

    ctypedef struct dynamic_plugin_data_t:
        void *data
        uint32_t plugin_id


cdef extern from "slurm/slurmdb.h" nogil:
    enum:
        CLUSTER_FLAG_BG


cdef extern from "slurm/slurm_errno.h" nogil:
    enum:
        SLURM_SUCCESS
        SLURM_ERROR
        SLURM_FAILURE
        SLURM_PROTOCOL_SUCCESS

    char *slurm_strerror(int errnum)
    int slurm_get_errno()
    int slurm_seterrno(int errnum)
    int slurm_perror(char *msg)


#
# Declarations outside of slurm.h
#

cdef extern void slurm_make_time_str(time_t *time, char *string, int size)
cdef extern void convert_num_unit(double num, char *buf, int buf_size,
                                  int orig_type, int spec_type, uint32_t flags)
cdef extern uint16_t slurm_get_preempt_mode()
cdef extern char *slurm_preempt_mode_string(uint16_t preempt_mode)

cdef enum:
    CONVERT_NUM_UNIT_EXACT
    UNIT_NONE

#
# Declarations outside of slurmdb.h
#

cdef extern uint32_t slurmdb_setup_cluster_flags()
