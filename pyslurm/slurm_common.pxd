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
        INFINITE8
        INFINITE16
        INFINITE64
        NO_VAL
        NO_VAL8
        NO_VAL16
        NO_VAL64
        MAX_TASKS_PER_NODE
        MAX_JOB_ID
        MAX_FED_CLUSTERS

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
        SHOW_FED_TRACK

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

    ctypedef enum node_use_type:
        SELECT_COPROCESSOR_MODE
        SELECT_VIRTUAL_NODE_MODE
        SELECT_NAV_MODE

    ctypedef struct xlist:
        pass

    ctypedef xlist *List

    ctypedef struct listIterator:
        pass

    ctypedef listIterator *ListIterator

    ListIterator slurm_list_iterator_create(List l)
    void *slurm_list_next(ListIterator i)
    int slurm_list_count(List l)
    void *slurm_list_peek(List l)


cdef extern from "slurm/slurmdb.h" nogil:
    enum:
        CLUSTER_FLAG_BG
        CLUSTER_FLAG_BGL
        CLUSTER_FLAG_BGP
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

cdef enum:
    CONVERT_NUM_UNIT_EXACT
    UNIT_NONE
    UNIT_MEGA

cdef extern void slurm_make_time_str(time_t *time, char *string, int size)
cdef extern uint16_t slurm_get_preempt_mode()
cdef extern char *slurm_preempt_mode_string(uint16_t preempt_mode)
cdef extern void slurm_secs2time_str(time_t time, char *string, int size)
cdef extern void slurm_mins2time_str(uint32_t time, char *string, int size)
cdef extern char *slurm_bg_block_state_string(uint16_t state)
cdef extern char *slurm_conn_type_string_full(uint16_t *conn_type)

# NOTE: node_use_type should be in signature
#cdef extern char *slurm_node_use_string(node_use_type node_use)
cdef extern char *slurm_node_use_string(uint16_t node_use)

cdef extern void slurm_convert_num_unit(
    double num,
    char *buf,
    int buf_size,
    int orig_type,
    int spec_type,
    uint32_t flags
)

#
# Declarations outside of slurmdb.h
#

cdef extern uint32_t slurmdb_setup_cluster_flags()
