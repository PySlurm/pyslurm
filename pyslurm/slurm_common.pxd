# slurm_common.pxd
#
# Slurm declarations common to all other extension files.
#
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libc.stdint cimport int32_t
from posix.types cimport time_t

cdef extern from "slurm/slurm.h" nogil:
    enum:
        INFINITE
        INFINITE64
        NO_VAL
        NO_VAL64

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

    ctypedef enum cpu_bind_type_t:
        CPU_BIND_VERBOSE
        CPU_BIND_TO_THREADS
        CPU_BIND_TO_CORES
        CPU_BIND_TO_SOCKETS
        CPU_BIND_TO_LDOMS
        CPU_BIND_TO_BOARDS
        CPU_BIND_NONE
        CPU_BIND_RANK
        CPU_BIND_MAP
        CPU_BIND_MASK
        CPU_BIND_LDRANK
        CPU_BIND_LDMAP
        CPU_BIND_LDMASK
        CPU_BIND_ONE_THREAD_PER_CORE
        CPU_BIND_CPUSETS
        CPU_AUTO_BIND_TO_THREADS
        CPU_AUTO_BIND_TO_CORES
        CPU_AUTO_BIND_TO_SOCKETS


cdef extern from "slurm/slurmdb.h" nogil:
    enum:
        CLUSTER_FLAG_BG
        CLUSTER_FLAG_BGQ
        CLUSTER_FLAG_MULTSD


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
