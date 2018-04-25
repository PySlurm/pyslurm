# cython: embedsignature=True
# cython: profile=False

from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libc.stdint cimport int64_t, int32_t
from libc.string cimport strlen, memset, memcpy
from libc.stdlib cimport malloc, free
from libcpp cimport bool
from posix.unistd cimport uid_t

from cpython.version cimport PY_MAJOR_VERSION

cdef extern from 'stdlib.h':
    ctypedef long size_t
    ctypedef long long size_t

cdef extern from 'stdio.h':
    ctypedef struct FILE
    cdef FILE *stdout

cdef extern from 'Python.h':
    cdef FILE *PyFile_AsFile(object file)
    cdef int __LINE__
    char *__FILE__
    char *__FUNCTION__

cdef extern from 'time.h' nogil:
    ctypedef long time_t

cdef extern from *:
    ctypedef char* const_char_ptr "const char*"

# ctypedef struct sockaddr_in slurm_addr_t

#
# PySlurm helper functions
#

cdef inline listOrNone(char* value, char* sep_char):
    if value is NULL:
        return []
    if sep_char is NULL:
        return value

    if sep_char == b'':
        return value

    return value.split(sep_char)


cdef inline stringOrNone(char* value, value2):
    if value is NULL:
        if value2 is '':
            return None
        return u"%s" % value2
    return u"%s" % value.decode('utf-8', 'replace')

cdef inline boolToString(int value):
    if value == 0:
        return u'False'
    return u'True'

#
# Slurm spank API - Love the name !
#

cdef extern from 'slurm/spank.h' nogil:
    cdef extern void slurm_verbose (char *, ...)

#
# Slurm error API
#

cdef extern from 'slurm/slurm_errno.h' nogil:
    int SLURM_SUCCESS
    int SLURM_ERROR
    int SLURM_FAILURE

    cdef extern char * slurm_strerror (int)
    cdef void slurm_seterrno (int)
    cdef int slurm_get_errno ()
    cdef void slurm_perror (char *)

#
# Main Slurm API
#

cdef extern from 'slurm/slurm.h' nogil:

    enum: SLURM_ID_HASH_NUM = 10000000000
    enum: SLURM_VERSION_NUMBER = 0x0f0800
    enum: SYSTEM_DIMENSIONS = 1
    enum: HIGHEST_DIMENSIONS = 5

    uint32_t INFINITE
    uint64_t INFINITE64
    uint32_t NO_VAL
    uint64_t NO_VAL64

    cdef enum job_states:
        JOB_PENDING
        JOB_RUNNING
        JOB_SUSPENDED
        JOB_COMPLETE
        JOB_CANCELLED
        JOB_FAILED
        JOB_TIMEOUT
        JOB_NODE_FAIL
        JOB_PREEMPTED
        JOB_BOOT_FAIL
        JOB_DEADLINE
        JOB_END

    cdef enum job_state_reason:
        WAIT_NO_REASON = 0
        WAIT_PRIORITY
        WAIT_DEPENDENCY
        WAIT_RESOURCES
        WAIT_PART_NODE_LIMIT
        WAIT_PART_TIME_LIMIT
        WAIT_PART_DOWN
        WAIT_PART_INACTIVE
        WAIT_HELD
        WAIT_TIME
        WAIT_LICENSES
        WAIT_ASSOC_JOB_LIMIT
        WAIT_ASSOC_RESOURCE_LIMIT
        WAIT_ASSOC_TIME_LIMIT
        WAIT_RESERVATION
        WAIT_NODE_NOT_AVAIL
        WAIT_HELD_USER
        WAIT_FRONT_END
        FAIL_DOWN_PARTITION
        FAIL_DOWN_NODE
        FAIL_BAD_CONSTRAINTS
        FAIL_SYSTEM
        FAIL_LAUNCH
        FAIL_EXIT_CODE
        FAIL_TIMEOUT
        FAIL_INACTIVE_LIMIT
        FAIL_ACCOUNT
        FAIL_QOS
        WAIT_QOS_THRES
        WAIT_QOS_JOB_LIMIT
        WAIT_QOS_RESOURCE_LIMIT
        WAIT_QOS_TIME_LIMIT
        WAIT_POWER_NOT_AVAIL
        WAIT_POWER_RESERVED
        WAIT_BLOCK_MAX_ERR
        WAIT_BLOCK_D_ACTION
        WAIT_CLEANING
        WAIT_PROLOG
        WAIT_QOS
        WAIT_ACCOUNT
        WAIT_DEP_INVALID
        WAIT_QOS_GRP_CPU
        WAIT_QOS_GRP_CPU_MIN
        WAIT_QOS_GRP_CPU_RUN_MIN
        WAIT_QOS_GRP_JOB
        WAIT_QOS_GRP_MEM
        WAIT_QOS_GRP_NODE
        WAIT_QOS_GRP_SUB_JOB
        WAIT_QOS_GRP_WALL
        WAIT_QOS_MAX_CPU_PER_JOB
        WAIT_QOS_MAX_CPU_MINS_PER_JOB
        WAIT_QOS_MAX_NODE_PER_JOB
        WAIT_QOS_MAX_WALL_PER_JOB
        WAIT_QOS_MAX_CPU_PER_USER
        WAIT_QOS_MAX_JOB_PER_USER
        WAIT_QOS_MAX_NODE_PER_USER
        WAIT_QOS_MAX_SUB_JOB
        WAIT_QOS_MIN_CPU
        WAIT_ASSOC_GRP_CPU
        WAIT_ASSOC_GRP_CPU_MIN
        WAIT_ASSOC_GRP_CPU_RUN_MIN
        WAIT_ASSOC_GRP_JOB
        WAIT_ASSOC_GRP_MEM
        WAIT_ASSOC_GRP_NODE
        WAIT_ASSOC_GRP_SUB_JOB
        WAIT_ASSOC_GRP_WALL
        WAIT_ASSOC_MAX_JOBS
        WAIT_ASSOC_MAX_CPU_PER_JOB
        WAIT_ASSOC_MAX_CPU_MINS_PER_JOB
        WAIT_ASSOC_MAX_NODE_PER_JOB
        WAIT_ASSOC_MAX_WALL_PER_JOB
        WAIT_ASSOC_MAX_SUB_JOB
        WAIT_MAX_REQUEUE
        WAIT_ARRAY_TASK_LIMIT
        WAIT_BURST_BUFFER_RESOURCE
        WAIT_BURST_BUFFER_STAGING
        FAIL_BURST_BUFFER_OP
        WAIT_POWER_NOT_AVAIL
        WAIT_POWER_RESERVED
        WAIT_ASSOC_GRP_UNK
        WAIT_ASSOC_GRP_UNK_MIN
        WAIT_ASSOC_GRP_UNK_RUN_MIN
        WAIT_ASSOC_MAX_UNK_PER_JOB
        WAIT_ASSOC_MAX_UNK_PER_NODE
        WAIT_ASSOC_MAX_UNK_MINS_PER_JOB
        WAIT_ASSOC_MAX_CPU_PER_NODE
        WAIT_ASSOC_GRP_MEM_MIN
        WAIT_ASSOC_GRP_MEM_RUN_MIN
        WAIT_ASSOC_MAX_MEM_PER_JOB
        WAIT_ASSOC_MAX_MEM_PER_NODE
        WAIT_ASSOC_MAX_MEM_MINS_PER_JOB
        WAIT_ASSOC_GRP_NODE_MIN
        WAIT_ASSOC_GRP_NODE_RUN_MIN
        WAIT_ASSOC_MAX_NODE_MINS_PER_JOB
        WAIT_ASSOC_GRP_ENERGY
        WAIT_ASSOC_GRP_ENERGY_MIN
        WAIT_ASSOC_GRP_ENERGY_RUN_MIN
        WAIT_ASSOC_MAX_ENERGY_PER_JOB
        WAIT_ASSOC_MAX_ENERGY_PER_NODE
        WAIT_ASSOC_MAX_ENERGY_MINS_PER_JOB
        WAIT_ASSOC_GRP_GRES
        WAIT_ASSOC_GRP_GRES_MIN
        WAIT_ASSOC_GRP_GRES_RUN_MIN
        WAIT_ASSOC_MAX_GRES_PER_JOB
        WAIT_ASSOC_MAX_GRES_PER_NODE
        WAIT_ASSOC_MAX_GRES_MINS_PER_JOB
        WAIT_ASSOC_GRP_LIC
        WAIT_ASSOC_GRP_LIC_MIN
        WAIT_ASSOC_GRP_LIC_RUN_MIN
        WAIT_ASSOC_MAX_LIC_PER_JOB
        WAIT_ASSOC_MAX_LIC_MINS_PER_JOB
        WAIT_ASSOC_GRP_BB
        WAIT_ASSOC_GRP_BB_MIN
        WAIT_ASSOC_GRP_BB_RUN_MIN
        WAIT_ASSOC_MAX_BB_PER_JOB
        WAIT_ASSOC_MAX_BB_PER_NODE
        WAIT_ASSOC_MAX_BB_MINS_PER_JOB
        WAIT_QOS_GRP_UNK
        WAIT_QOS_GRP_UNK_MIN
        WAIT_QOS_GRP_UNK_RUN_MIN
        WAIT_QOS_MAX_UNK_PER_JOB
        WAIT_QOS_MAX_UNK_PER_NODE
        WAIT_QOS_MAX_UNK_PER_USER
        WAIT_QOS_MAX_UNK_MINS_PER_JOB
        WAIT_QOS_MIN_UNK
        WAIT_QOS_MAX_CPU_PER_NODE
        WAIT_QOS_GRP_MEM_MIN
        WAIT_QOS_GRP_MEM_RUN_MIN
        WAIT_QOS_MAX_MEM_MINS_PER_JOB
        WAIT_QOS_MAX_MEM_PER_JOB
        WAIT_QOS_MAX_MEM_PER_NODE
        WAIT_QOS_MAX_MEM_PER_USER
        WAIT_QOS_MIN_MEM
        WAIT_QOS_GRP_ENERGY
        WAIT_QOS_GRP_ENERGY_MIN
        WAIT_QOS_GRP_ENERGY_RUN_MIN
        WAIT_QOS_MAX_ENERGY_PER_JOB
        WAIT_QOS_MAX_ENERGY_PER_NODE
        WAIT_QOS_MAX_ENERGY_PER_USER
        WAIT_QOS_MAX_ENERGY_MINS_PER_JOB
        WAIT_QOS_MIN_ENERGY
        WAIT_QOS_GRP_NODE_MIN
        WAIT_QOS_GRP_NODE_RUN_MIN
        WAIT_QOS_MAX_NODE_MINS_PER_JOB
        WAIT_QOS_MIN_NODE
        WAIT_QOS_GRP_GRES
        WAIT_QOS_GRP_GRES_MIN
        WAIT_QOS_GRP_GRES_RUN_MIN
        WAIT_QOS_MAX_GRES_PER_JOB
        WAIT_QOS_MAX_GRES_PER_NODE
        WAIT_QOS_MAX_GRES_PER_USER
        WAIT_QOS_MAX_GRES_MINS_PER_JOB
        WAIT_QOS_MIN_GRES
        WAIT_QOS_GRP_LIC
        WAIT_QOS_GRP_LIC_MIN
        WAIT_QOS_GRP_LIC_RUN_MIN
        WAIT_QOS_MAX_LIC_PER_JOB
        WAIT_QOS_MAX_LIC_PER_USER
        WAIT_QOS_MAX_LIC_MINS_PER_JOB
        WAIT_QOS_MIN_LIC
        WAIT_QOS_GRP_BB
        WAIT_QOS_GRP_BB_MIN
        WAIT_QOS_GRP_BB_RUN_MIN
        WAIT_QOS_MAX_BB_PER_JOB
        WAIT_QOS_MAX_BB_PER_NODE
        WAIT_QOS_MAX_BB_PER_USER
        WAIT_QOS_MAX_BB_MINS_PER_JOB
        WAIT_QOS_MIN_BB
        FAIL_DEADLINE
        WAIT_QOS_MAX_BB_PER_ACCT
        WAIT_QOS_MAX_CPU_PER_ACCT
        WAIT_QOS_MAX_ENERGY_PER_ACCT
        WAIT_QOS_MAX_GRES_PER_ACCT
        WAIT_QOS_MAX_NODE_PER_ACCT
        WAIT_QOS_MAX_LIC_PER_ACCT
        WAIT_QOS_MAX_MEM_PER_ACCT
        WAIT_QOS_MAX_UNK_PER_ACCT
        WAIT_QOS_MAX_JOB_PER_ACCT
        WAIT_QOS_MAX_SUB_JOB_PER_ACCT
        WAIT_PART_CONFIG
        WAIT_ACCOUNT_POLICY

    cdef enum select_jobdata_type:
        SELECT_JOBDATA_GEOMETRY
        SELECT_JOBDATA_ROTATE
        SELECT_JOBDATA_CONN_TYPE
        SELECT_JOBDATA_BLOCK_ID
        SELECT_JOBDATA_NODES
        SELECT_JOBDATA_IONODES
        SELECT_JOBDATA_NODE_CNT
        SELECT_JOBDATA_ALTERED
        SELECT_JOBDATA_BLRTS_IMAGE
        SELECT_JOBDATA_LINUX_IMAGE
        SELECT_JOBDATA_MLOADER_IMAGE
        SELECT_JOBDATA_RAMDISK_IMAGE
        SELECT_JOBDATA_REBOOT
        SELECT_JOBDATA_RESV_ID
        SELECT_JOBDATA_PAGG_ID
        SELECT_JOBDATA_PTR
        SELECT_JOBDATA_BLOCK_PTR
        SELECT_JOBDATA_DIM_CNT
        SELECT_JOBDATA_BLOCK_NODE_CNT
        SELECT_JOBDATA_START_LOC
        SELECT_JOBDATA_USER_NAME
        SELECT_JOBDATA_CONFIRMED
        SELECT_JOBDATA_CLEANING
        SELECT_JOBDATA_NETWORK

    cdef enum select_nodedata_type:
        SELECT_NODEDATA_BITMAP_SIZE
        SELECT_NODEDATA_SUBGRP_SIZE
        SELECT_NODEDATA_SUBCNT
        SELECT_NODEDATA_BITMAP
        SELECT_NODEDATA_STR
        SELECT_NODEDATA_PTR
        SELECT_NODEDATA_EXTRA_INFO
        SELECT_NODEDATA_RACK_MP
        SELECT_NODEDATA_MEM_ALLOC

    cdef enum select_print_mode:
        SELECT_PRINT_HEAD
        SELECT_PRINT_DATA
        SELECT_PRINT_MIXED
        SELECT_PRINT_MIXED_SHORT
        SELECT_PRINT_BG_ID
        SELECT_PRINT_NODES
        SELECT_PRINT_CONNECTION
        SELECT_PRINT_ROTATE
        SELECT_PRINT_GEOMETRY
        SELECT_PRINT_START
        SELECT_PRINT_BLRTS_IMAGE
        SELECT_PRINT_LINUX_IMAGE
        SELECT_PRINT_MLOADER_IMAGE
        SELECT_PRINT_RAMDISK_IMAGE
        SELECT_PRINT_REBOOT
        SELECT_PRINT_RESV_ID
        SELECT_PRINT_START_LOC

    cdef enum select_node_cnt:
        SELECT_GET_NODE_SCALING
        SELECT_GET_NODE_CPU_CNT
        SELECT_GET_MP_CPU_CNT
        SELECT_APPLY_NODE_MIN_OFFSET
        SELECT_APPLY_NODE_MAX_OFFSET
        SELECT_SET_NODE_CNT
        SELECT_SET_MP_CNT

    cdef enum acct_gather_profile_info:
        ACCT_GATHER_PROFILE_DIR
        ACCT_GATHER_PROFILE_DEFAULT
        ACCT_GATHER_PROFILE_RUNNING

    cdef enum jobacct_data_type:
        JOBACCT_DATA_TOTAL
        JOBACCT_DATA_PIPE
        JOBACCT_DATA_RUSAGE
        JOBACCT_DATA_MAX_VSIZE
        JOBACCT_DATA_MAX_VSIZE_ID
        JOBACCT_DATA_TOT_VSIZE
        JOBACCT_DATA_MAX_RSS
        JOBACCT_DATA_MAX_RSS_ID
        JOBACCT_DATA_TOT_RSS
        JOBACCT_DATA_MAX_PAGES
        JOBACCT_DATA_MAX_PAGES_ID
        JOBACCT_DATA_TOT_PAGES
        JOBACCT_DATA_MIN_CPU
        JOBACCT_DATA_MIN_CPU_ID
        JOBACCT_DATA_TOT_CPU
        JOBACCT_DATA_ACT_CPUFREQ
        JOBACCT_DATA_CONSUMED_ENERGY
        JOBACCT_DATA_MAX_DISK_READ
        JOBACCT_DATA_MAX_DISK_READ_ID
        JOBACCT_DATA_TOT_DISK_READ
        JOBACCT_DATA_MAX_DISK_WRITE
        JOBACCT_DATA_MAX_DISK_WRITE_ID
        JOBACCT_DATA_TOT_DISK_WRITE

    cdef enum job_acct_types:
        JOB_START
        JOB_STEP
        JOB_SUSPEND
        JOB_TERMINATED

    cdef enum node_states:
        NODE_STATE_UNKNOWN
        NODE_STATE_DOWN
        NODE_STATE_IDLE
        NODE_STATE_ALLOCATED
        NODE_STATE_ERROR
        NODE_STATE_MIXED
        NODE_STATE_FUTURE
        NODE_STATE_END

    uint16_t SHOW_ALL
    uint16_t SHOW_DETAIL
    uint16_t SHOW_DETAIL2
    uint16_t SHOW_MIXED

    uint32_t MEM_PER_CPU

    ctypedef enum acct_energy_type:
        ENERGY_DATA_JOULES_TASK
        ENERGY_DATA_STRUCT
        ENERGY_DATA_RECONFIG
        ENERGY_DATA_PROFILE
        ENERGY_DATA_LAST_POLL
        ENERGY_DATA_SENSOR_CNT
        ENERGY_DATA_NODE_ENERGY
        ENERGY_DATA_NODE_ENERGY_UP

    ctypedef enum task_dist_states:
        SLURM_DIST_CYCLIC = 0x0001
        SLURM_DIST_BLOCK = 0x0002
        SLURM_DIST_ARBITRARY = 0x0003
        SLURM_DIST_PLANE = 0x0004
        SLURM_DIST_CYCLIC_CYCLIC = 0x0011
        SLURM_DIST_CYCLIC_BLOCK = 0x0021
        SLURM_DIST_CYCLIC_CFULL = 0x0031
        SLURM_DIST_BLOCK_CYCLIC = 0x0012
        SLURM_DIST_BLOCK_BLOCK = 0x0022
        SLURM_DIST_BLOCK_CFULL = 0x0032
        SLURM_DIST_CYCLIC_CYCLIC_CYCLIC = 0x0111
        SLURM_DIST_CYCLIC_CYCLIC_BLOCK = 0x0211
        SLURM_DIST_CYCLIC_CYCLIC_CFULL = 0x0311
        SLURM_DIST_CYCLIC_BLOCK_CYCLIC = 0x0121
        SLURM_DIST_CYCLIC_BLOCK_BLOCK = 0x0221
        SLURM_DIST_CYCLIC_BLOCK_CFULL = 0x0321
        SLURM_DIST_CYCLIC_CFULL_CYCLIC = 0x0131
        SLURM_DIST_CYCLIC_CFULL_BLOCK = 0x0231
        SLURM_DIST_CYCLIC_CFULL_CFULL = 0x0331
        SLURM_DIST_BLOCK_CYCLIC_CYCLIC = 0x0112
        SLURM_DIST_BLOCK_CYCLIC_BLOCK = 0x0212
        SLURM_DIST_BLOCK_CYCLIC_CFULL = 0x0312
        SLURM_DIST_BLOCK_BLOCK_CYCLIC = 0x0122
        SLURM_DIST_BLOCK_BLOCK_BLOCK = 0x0222
        SLURM_DIST_BLOCK_BLOCK_CFULL = 0x0322
        SLURM_DIST_BLOCK_CFULL_CYCLIC = 0x0132
        SLURM_DIST_BLOCK_CFULL_BLOCK = 0x0232
        SLURM_DIST_BLOCK_CFULL_CFULL = 0x0332
        SLURM_DIST_NODECYCLIC = 0x0001
        SLURM_DIST_NODEBLOCK = 0x0002
        SLURM_DIST_SOCKCYCLIC = 0x0010
        SLURM_DIST_SOCKBLOCK = 0x0020
        SLURM_DIST_SOCKCFULL = 0x0030
        SLURM_DIST_CORECYCLIC = 0x0100
        SLURM_DIST_COREBLOCK = 0x0200
        SLURM_DIST_CORECFULL = 0x0300
        SLURM_DIST_NO_LLLP = 0x1000
        SLURM_DIST_UNKNOWN = 0x2000

    ctypedef task_dist_states task_dist_states_t

    ctypedef enum cpu_bind_type:
        CPU_BIND_VERBOSE = 0x0001
        CPU_BIND_TO_THREADS = 0x0002
        CPU_BIND_TO_CORES = 0x0004
        CPU_BIND_TO_SOCKETS = 0x0008
        CPU_BIND_TO_LDOMS = 0x0010
        CPU_BIND_TO_BOARDS = 0x1000
        CPU_BIND_NONE = 0x0020
        CPU_BIND_RANK = 0x0040
        CPU_BIND_MAP = 0x0080
        CPU_BIND_MASK = 0x0100
        CPU_BIND_LDRANK = 0x0200
        CPU_BIND_LDMAP = 0x0400
        CPU_BIND_LDMASK = 0x0800
        CPU_BIND_ONE_THREAD_PER_CORE = 0x2000
        CPU_BIND_CPUSETS = 0x8000
        CPU_AUTO_BIND_TO_THREADS = 0x04000
        CPU_AUTO_BIND_TO_CORES = 0x10000
        CPU_AUTO_BIND_TO_SOCKETS = 0x20000

    ctypedef cpu_bind_type cpu_bind_type_t

    ctypedef enum mem_bind_type:
        MEM_BIND_VERBOSE = 0x01
        MEM_BIND_NONE = 0x02
        MEM_BIND_RANK = 0x04
        MEM_BIND_MAP = 0x08
        MEM_BIND_MASK = 0x10
        MEM_BIND_LOCAL = 0x20

    ctypedef mem_bind_type mem_bind_type_t

    ctypedef enum accel_bind_type:
        ACCEL_BIND_VERBOSE = 0x01
        ACCEL_BIND_CLOSEST_GPU = 0x02
        ACCEL_BIND_CLOSEST_MIC = 0x04
        ACCEL_BIND_CLOSEST_NIC = 0x08

    ctypedef accel_bind_type accel_bind_type_t

    cdef enum connection_type:
        SELECT_MESH
        SELECT_TORUS
        SELECT_NAV
        SELECT_SMALL
        SELECT_HTC_S
        SELECT_HTC_D
        SELECT_HTC_V
        SELECT_HTC_L

    cdef enum node_use_type:
        SELECT_COPROCESSOR_MODE
        SELECT_VIRTUAL_NODE_MODE
        SELECT_NAV_MODE

    cdef enum select_plugin_type:
        SELECT_PLUGIN_BLUEGENE = 100
        SELECT_PLUGIN_CONS_RES = 101
        SELECT_PLUGIN_LINEAR = 102
        SELECT_PLUGIN_ALPS = 104
        SELECT_PLUGIN_SERIAL = 106
        SELECT_PLUGIN_CRAY_LINEAR = 107
        SELECT_PLUGIN_CRAY_CONS_RES = 108

    enum: STAT_COMMAND_RESET = 0x0000
    enum: STAT_COMMAND_GET = 0x0001

    ctypedef struct stats_info_request_msg:
        uint16_t command_id

    ctypedef stats_info_request_msg stats_info_request_msg_t

    ctypedef struct stats_info_response_msg:
        uint32_t parts_packed
        time_t req_time
        time_t req_time_start
        uint32_t server_thread_count
        uint32_t agent_queue_size
        uint32_t schedule_cycle_max
        uint32_t schedule_cycle_last
        uint32_t schedule_cycle_sum
        uint32_t schedule_cycle_counter
        uint32_t schedule_cycle_depth
        uint32_t schedule_queue_len
        uint32_t jobs_submitted
        uint32_t jobs_started
        uint32_t jobs_completed
        uint32_t jobs_canceled
        uint32_t jobs_failed
        uint32_t bf_backfilled_jobs
        uint32_t bf_last_backfilled_jobs
        uint32_t bf_cycle_counter
        uint64_t bf_cycle_sum
        uint32_t bf_cycle_last
        uint32_t bf_cycle_max
        uint32_t bf_last_depth
        uint32_t bf_last_depth_try
        uint32_t bf_depth_sum
        uint32_t bf_depth_try_sum
        uint32_t bf_queue_len
        uint32_t bf_queue_len_sum
        time_t bf_when_last_cycle
        uint32_t bf_active
        uint32_t rpc_type_size
        uint16_t *rpc_type_id
        uint32_t *rpc_type_cnt
        uint64_t *rpc_type_time
        uint32_t rpc_user_size
        uint32_t *rpc_user_id
        uint32_t *rpc_user_cnt
        uint64_t *rpc_user_time

    ctypedef stats_info_response_msg stats_info_response_msg_t

    #
    # Place holders for opaque data types
    #

    ctypedef struct list:
        pass

    ctypedef list *List

    ctypedef struct listIterator:
        pass

    ctypedef listIterator *ListIterator

    ctypedef void (*ListDelF) (void *x)

    ctypedef int (*ListCmpF) (void *x, void *y)

    ctypedef int (*ListFindF) (void *x, void *key)

    ctypedef int (*ListForF) (void *x, void *arg)

    ctypedef struct job_resources:
        pass

    ctypedef job_resources job_resources_t

    ctypedef struct select_jobinfo:
        pass

    ctypedef select_jobinfo select_jobinfo_t

    ctypedef struct select_nodeinfo:
        pass

    ctypedef select_nodeinfo select_nodeinfo_t

    ctypedef struct jobacctinfo:
        pass

    ctypedef jobacctinfo jobacctinfo_t

    ctypedef struct hostlist:
        pass

    ctypedef hostlist *hostlist_t

    ctypedef struct dynamic_plugin_data:
        void *data
        uint32_t plugin_id

    ctypedef dynamic_plugin_data dynamic_plugin_data_t

    ctypedef struct acct_gather_energy:
        uint64_t base_consumed_energy
        uint32_t base_watts
        uint64_t consumed_energy
        uint32_t current_watts
        uint64_t previous_consumed_energy
        time_t poll_time

    ctypedef acct_gather_energy acct_gather_energy_t

    ctypedef struct ext_sensors_data:
        uint64_t consumed_energy
        uint32_t temperature
        time_t energy_update_time
        uint32_t current_watts

    ctypedef ext_sensors_data ext_sensors_data_t

    ctypedef struct power_mgmt_data:
        uint32_t cap_watts
        uint32_t current_watts
        uint64_t joule_counter
        uint32_t new_cap_watts
        uint32_t max_watts
        uint32_t min_watts
        time_t new_job_time
        uint16_t state
        uint64_t time_usec

    ctypedef power_mgmt_data power_mgmt_data_t

    ctypedef struct job_descriptor:
        char *account
        char *acctg_freq
        char *alloc_node
        uint16_t alloc_resp_port
        uint32_t alloc_sid
        uint32_t argc
        char **argv
        char *array_inx
        void *array_bitmap
        time_t begin_time
        uint32_t bitflags
        char *burst_buffer
        uint16_t ckpt_interval
        char *ckpt_dir
        char *custers
        char *comment
        uint16_t contiguous
        uint16_t core_spec
        char *cpu_bind
        uint16_t cpu_bind_type
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        time_t deadline
        char *dependency
        time_t end_time
        char **environment
        uint32_t env_size
        char *exc_nodes
        char *features
        char *gres
        uint32_t group_id
        uint16_t immediate
        uint32_t job_id
        char *job_id_str
        uint16_t kill_on_node_fail
        char *licenses
        uint16_t mail_type
        char *mail_user
        char *mcs_label
        char *mem_bind
        uint16_t mem_bind_type
        char *name
        char *network
        uint32_t nice
        uint32_t num_tasks
        uint8_t open_mode
        uint16_t other_port
        uint8_t overcommit
        char *partition
        uint16_t plane_size
        uint8_t power_flags
        uint32_t priority
        uint32_t profile
        char *qos
        uint16_t reboot
        char *resp_host
        char *req_nodes
        uint16_t requeue
        char *reservation
        char *script
        uint16_t shared
        char **spank_job_env
        uint32_t spank_job_env_size
        uint32_t task_dist
        uint32_t time_limit
        uint32_t time_min
        uint32_t user_id
        uint16_t wait_all_nodes
        uint16_t warn_flags
        uint16_t warn_signal
        uint16_t warn_time
        char *work_dir
        uint16_t cpus_per_task
        uint32_t min_cpus
        uint32_t max_cpus
        uint32_t min_nodes
        uint32_t max_nodes
        uint16_t boards_per_node
        uint16_t sockets_per_board
        uint16_t sockets_per_node
        uint16_t cores_per_socket
        uint16_t threads_per_core
        uint16_t ntasks_per_node
        uint16_t ntasks_per_socket
        uint16_t ntasks_per_core
        uint16_t ntasks_per_board
        uint16_t pn_min_cpus
        uint32_t pn_min_memory
        uint32_t pn_min_tmp_disk
        uint16_t geometry[HIGHEST_DIMENSIONS]
        uint16_t conn_type[HIGHEST_DIMENSIONS]
        uint16_t rotate
        char *blrtsimage
        char *linuximage
        char *mloaderimage
        char *ramdiskimage
        uint32_t req_switch
        dynamic_plugin_data_t *select_jobinfo
        char *std_err
        char *std_in
        char *std_out
        uint64_t *tres_req_cnt
        uint32_t wait4switch
        char *wckey

    ctypedef job_descriptor job_desc_msg_t

    ctypedef struct slurm_ctl_conf:
        time_t last_update
        char *accounting_storage_tres
        uint16_t accounting_storage_enforce
        char *accounting_storage_backup_host
        char *accounting_storage_host
        char *accounting_storage_loc
        char *accounting_storage_pass
        uint32_t accounting_storage_port
        char *accounting_storage_type
        char *accounting_storage_user
        uint16_t acctng_store_job_comment
        void *acct_gather_conf
        char *acct_gather_energy_type
        char *acct_gather_profile_type
        char *acct_gather_infiniband_type
        char *acct_gather_filesystem_type
        uint16_t acct_gather_node_freq
        char *authinfo
        char *authtype
        char *backup_addr
        char *backup_controller
        uint16_t batch_start_timeout
        char *bb_type
        time_t boot_time
        char *checkpoint_type
        char *chos_loc
        char *core_spec_plugin
        char *cluster_name
        uint16_t complete_wait
        char *control_addr
        char *control_machine
        uint32_t cpu_freq_def
        uint32_t cpu_freq_govs
        char *crypto_type
        uint64_t debug_flags
        uint32_t def_mem_per_cpu
        uint16_t disable_root_jobs
        uint16_t eio_timeout
        uint16_t enforce_part_limits
        char *epilog
        uint32_t epilog_msg_time
        char *epilog_slurmctld
        char *ext_sensors_type
        uint16_t ext_sensors_freq
        void *ext_sensors_conf
        uint16_t fast_schedule
        uint32_t first_job_id
        uint16_t fs_dampening_factor
        uint16_t get_env_timeout
        char *gres_plugins
        uint16_t group_info
        uint32_t hash_val
        uint16_t health_check_interval
        uint16_t health_check_node_state
        char * health_check_program
        uint16_t inactive_limit
        char* job_acct_gather_freq
        char *job_acct_gather_type
        char *job_acct_gather_params
        char *job_ckpt_dir
        char *job_comp_host
        char *job_comp_loc
        char *job_comp_pass
        uint32_t job_comp_port
        char *job_comp_type
        char *job_comp_user
        char *job_container_plugin
        char *job_credential_private_key
        char *job_credential_public_certificate
        uint16_t job_file_append
        uint16_t job_requeue
        char *job_submit_plugins
        uint16_t keep_alive_time
        uint16_t kill_on_bad_exit
        uint16_t kill_wait
        char *launch_params
        char *launch_type
        char *layouts
        char *licenses
        char *licenses_used
        uint16_t log_fmt
        char *mail_prog
        uint32_t max_array_sz
        uint32_t max_job_cnt
        uint32_t max_job_id
        uint32_t max_mem_per_cpu
        uint32_t max_step_cnt
        uint16_t max_tasks_per_node
        uint16_t mem_limit_enforce
        uint32_t min_job_age
        char *mpi_default
        char *mpi_params
        char *msg_aggr_params
        uint16_t msg_timeout
        uint16_t tcp_timeout
        uint32_t next_job_id
        char *node_features_plugins
        char *node_prefix
        uint16_t over_time_limit
        char *plugindir
        char *plugstack
        char *power_parameters
        char *power_plugin
        uint16_t preempt_mode
        char *preempt_type
        uint32_t priority_decay_hl
        uint32_t priority_calc_period
        uint16_t priority_favor_small
        uint16_t priority_flags
        uint32_t priority_max_age
        char *priority_params
        uint16_t priority_reset_period
        char *priority_type
        uint32_t priority_weight_age
        uint32_t priority_weight_fs
        uint32_t priority_weight_js
        uint32_t priority_weight_part
        uint32_t priority_weight_qos
        char *priority_weight_tres
        uint16_t private_data
        char *proctrack_type
        char *prolog
        uint16_t prolog_epilog_timeout
        char *prolog_slurmctld
        uint16_t propagate_prio_process
        uint16_t prolog_flags
        char *propagate_rlimits
        char *propagate_rlimits_except
        char *reboot_program
        uint16_t reconfig_flags
        char *requeue_exit
        char *requeue_exit_hold
        char *resume_program
        uint16_t resume_rate
        uint16_t resume_timeout
        char *resv_epilog
        uint16_t resv_over_run
        char *resv_prolog
        uint16_t ret2service
        char *route_plugin
        char *salloc_default_command
        char *sched_logfile
        uint16_t sched_log_level
        char *sched_params
        uint16_t sched_time_slice
        char *schedtype
        uint16_t schedport
        uint16_t schedrootfltr
        char *select_type
        void *select_conf_key_pairs
        uint16_t select_type_param
        char *slurm_conf
        uint32_t slurm_user_id
        char *slurm_user_name
        uint32_t slurmd_user_id
        char *slurmd_user_name
        uint16_t slurmctld_debug
        char *slurmctld_logfile
        char *slurmctld_pidfile
        char *slurmctld_plugstack
        uint32_t slurmctld_port
        uint16_t slurmctld_port_count
        uint16_t slurmctld_timeout
        uint16_t slurmd_debug
        char *slurmd_logfile
        char *slurmd_pidfile
        char *slurmd_plugstack
        uint32_t slurmd_port
        char *slurmd_spooldir
        uint16_t slurmd_timeout
        char *srun_epilog
        uint16_t *srun_port_range
        char *srun_prolog
        char *state_save_location
        char *suspend_exc_nodes
        char *suspend_exc_parts
        char *suspend_program
        uint16_t suspend_rate
        uint32_t suspend_time
        uint16_t suspend_timeout
        char *switch_type
        char *task_epilog
        char *task_plugin
        uint32_t task_plugin_param
        char *task_prolog
        char *tmp_fs
        char *topology_param
        char *topology_plugin
        uint16_t track_wckey
        uint16_t tree_width
        char *unkillable_program
        uint16_t unkillable_timeout
        uint16_t use_pam
        uint16_t use_spec_resources
        char *version
        uint16_t vsize_factor
        uint16_t wait_time
        uint16_t z_16
        uint32_t z_32
        char *z_char

    ctypedef slurm_ctl_conf slurm_ctl_conf_t

    ctypedef struct job_info:
        char *account
        char *alloc_node
        uint32_t alloc_sid
        # void *arrray_bitmap
        uint32_t array_job_id
        uint32_t array_task_id
        uint32_t array_max_tasks
        char *array_task_str
        uint32_t assoc_id
        uint16_t batch_flag
        char *batch_host
        char *batch_script
        uint32_t bitflags
        uint16_t boards_per_node
        char *burst_buffer
        char *command
        char *comment
        uint16_t contiguous
        uint16_t core_spec
        uint16_t cores_per_socket
        double billable_tres
        uint16_t cpus_per_task
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        time_t daedline
        char *dependency
        uint32_t derived_ec
        time_t eligible_time
        time_t end_time
        char *exc_nodes
        int32_t *exc_node_inx
        uint32_t exit_code
        char *features
        char *gres
        uint32_t group_id
        uint32_t job_id
        job_resources_t *job_resrcs
        uint32_t job_state
        char *licenses
        uint32_t max_cpus
        uint32_t max_nodes
        char *mcs_label
        char *name
        char *network
        char *nodes
        uint32_t nice
        int32_t *node_inx
        uint16_t ntasks_per_core
        uint16_t ntasks_per_node
        uint16_t ntasks_per_socket
        uint16_t ntasks_per_board
        uint32_t num_cpus
        uint32_t num_nodes
        uint32_t num_tasks
        char *partition
        uint32_t pn_min_memory
        uint16_t pn_min_cpus
        uint32_t pn_min_tmp_disk
        uint8_t power_flags
        time_t preempt_time
        time_t pre_sus_time
        uint32_t priority
        uint32_t profile
        char *qos
        uint8_t reboot
        char *req_nodes
        int32_t *req_node_inx
        uint32_t req_switch
        uint16_t requeue
        time_t resize_time
        uint16_t restart_cnt
        char *resv_name
        char *sched_nodes
        dynamic_plugin_data_t *select_jobinfo
        uint16_t shared
        uint16_t show_flags
        uint16_t sockets_per_board
        uint16_t sockets_per_node
        time_t start_time
        uint16_t start_protocol_ver
        char *state_desc
        uint16_t state_reason
        char *std_err
        char *std_in
        char *std_out
        time_t submit_time
        time_t suspend_time
        uint32_t time_limit
        uint32_t time_min
        uint16_t threads_per_core
        char *tres_req_str
        char *tres_alloc_str
        uint32_t user_id
        uint32_t wait4switch
        char *wckey
        char *work_dir

    ctypedef job_info slurm_job_info_t
    ctypedef slurm_job_info_t job_info_t

    ctypedef struct job_info_msg:
        time_t last_update
        uint32_t record_count
        slurm_job_info_t *job_array

    ctypedef job_info_msg job_info_msg_t

    ctypedef struct step_update_request_msg:
        time_t end_time
        uint32_t exit_code
        uint32_t job_id
        jobacctinfo_t *jobacct
        char *name
        time_t start_time
        uint32_t step_id
        uint32_t time_limit

    ctypedef step_update_request_msg step_update_request_msg_t

    ctypedef struct job_step_pids_t:
        char *node_name
        uint32_t *pid
        uint32_t pid_cnt

    ctypedef struct job_step_pids_reponse_msg_t:
        uint32_t job_id
        List pid_list
        uint32_t step_id

    ctypedef struct job_step_stat_t:
        jobacctinfo_t *jobacct
        uint32_t num_tasks
        uint32_t return_code
        job_step_pids_t *step_pids

    ctypedef struct job_step_stat_response_msg_t:
        uint32_t job_id
        List stats_list
        uint32_t step_id

    ctypedef struct partition_info:
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
        uint16_t priority_job_factor
        uint16_t priority_tier
        char *qos_char
        uint16_t state_up
        uint32_t total_cpus
        uint32_t total_nodes
        char *tres_fmt_str

    ctypedef partition_info partition_info_t

    ctypedef struct delete_partition_msg:
        char *name

    ctypedef delete_partition_msg delete_part_msg_t

    ctypedef struct partition_info_msg_t:
        time_t last_update
        uint32_t record_count
        partition_info_t *partition_array

    ctypedef partition_info update_part_msg_t

    ctypedef struct will_run_response_msg:
        uint32_t job_id
        char *node_list
        List preemptee_job_id
        uint32_t proc_cnt
        time_t start_time

    ctypedef will_run_response_msg will_run_response_msg_t

    ctypedef struct resource_allocation_response_msg:
        char *account
        uint32_t job_id
        char *alias_list
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        uint16_t *cpus_per_node
        uint32_t *cpu_count_reps
        uint32_t error_code
        uint32_t node_cnt
        char *node_list
        uint16_t ntasks_per_board
        uint16_t ntasks_per_core
        uint16_t ntasks_per_socket
        uint32_t num_cpu_groups
        char *partition
        uint32_t pn_min_memory
        char *qos
        char *resv_name
        dynamic_plugin_data_t *select_jobinfo

    ctypedef resource_allocation_response_msg resource_allocation_response_msg_t

    ctypedef struct job_alloc_info_response_msg:
        uint32_t job_id
        char *node_list
        uint32_t num_cpu_groups
        uint16_t *cpus_per_node
        uint32_t *cpu_count_reps
        uint32_t node_cnt
        # slurm_addr_t *node_addr
        uint32_t error_code
        dynamic_plugin_data_t *select_jobinfo

    ctypedef job_alloc_info_response_msg job_alloc_info_response_msg_t

    ctypedef struct node_info:
        char *arch
        uint16_t boards
        time_t boot_time
        uint16_t cores
        uint16_t core_spec_cnt
        uint32_t cpu_load
        uint32_t free_mem
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
        uint32_t mem_spec_limit
        char *name
        char *node_addr
        char *node_hostname
        uint32_t node_state
        char *os
        uint32_t owner
        uint32_t real_memory
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

    ctypedef node_info node_info_t

    ctypedef struct node_info_msg:
        time_t last_update
        uint32_t node_scaling
        uint32_t record_count
        node_info_t *node_array

    ctypedef node_info_msg node_info_msg_t

    ctypedef struct front_end_info:
        char *allow_groups
        char *allow_users
        time_t boot_time
        char *deny_groups
        char *deny_users
        char *name
        uint32_t node_state
        char *reason
        time_t reason_time
        uint32_t reason_uid
        time_t slurmd_start_time
        char *version

    ctypedef front_end_info front_end_info_t

    ctypedef struct front_end_info_msg:
        time_t last_update
        uint32_t record_count
        front_end_info_t *front_end_array

    ctypedef front_end_info_msg front_end_info_msg_t

    #
    # NOTE: If setting node_addr and/or node_hostname then comma
    #       separate names and include an equal number of node_names
    #

    ctypedef struct slurm_update_node_msg:
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

    ctypedef slurm_update_node_msg update_node_msg_t

    ctypedef struct slurm_update_front_end_msg:
        char *name
        uint32_t node_state
        char *reason
        uint32_t reason_uid

    ctypedef slurm_update_front_end_msg update_front_end_msg_t

    ctypedef struct topo_info:
        uint16_t level
        uint32_t link_speed
        char *name
        char *nodes
        char *switches

    ctypedef topo_info topo_info_t

    ctypedef struct topo_info_response_msg:
        uint32_t record_count
        topo_info_t *topo_array

    ctypedef topo_info_response_msg topo_info_response_msg_t

    ctypedef struct job_alloc_info_msg:
        uint32_t job_id

    ctypedef job_alloc_info_msg job_alloc_info_msg_t

    ctypedef struct layout_info_msg:
        uint32_t record_count
        char **records

    ctypedef layout_info_msg layout_info_msg_t

    ctypedef struct update_layout_msg:
        char *layout
        char *arg

    ctypedef update_layout_msg update_layout_msg_t

    ctypedef struct step_alloc_info_msg:
        uint32_t job_id
        uint32_t step_id

    ctypedef step_alloc_info_msg step_alloc_info_msg_t

    ctypedef struct powercap_info_msg:
        uint32_t power_cap
        uint32_t power_floor
        uint32_t power_change
        uint32_t min_watts
        uint32_t cur_max_watts
        uint32_t adj_max_watts
        uint32_t max_watts

    ctypedef powercap_info_msg powercap_info_msg_t

    ctypedef powercap_info_msg update_powercap_msg_t

    ctypedef struct acct_gather_node_resp_msg:
        acct_gather_energy_t *energy
        char *node_name
        uint16_t sensor_cnt

    ctypedef acct_gather_node_resp_msg acct_gather_node_resp_msg_t

    ctypedef struct acct_gather_energy_req_msg:
        uint16_t delta

    ctypedef acct_gather_energy_req_msg acct_gather_energy_req_msg_t

    ctypedef struct slurmd_status_msg:
        time_t booted
        time_t last_slurmctld_msg
        uint16_t slurmd_debug
        uint16_t actual_cpus
        uint16_t actual_boards
        uint16_t actual_sockets
        uint16_t actual_cores
        uint16_t actual_threads
        uint32_t actual_real_mem
        uint32_t actual_tmp_disk
        uint32_t pid
        char *hostname
        char *slurmd_logfile
        char *step_list
        char *version

    ctypedef slurmd_status_msg slurmd_status_t

    ctypedef struct submit_response_msg:
        uint32_t job_id
        uint32_t step_id
        uint32_t error_code

    ctypedef submit_response_msg submit_response_msg_t

    ctypedef struct job_step_info_t:
        uint32_t array_job_id
        uint32_t array_task_id
        char *ckpt_dir
        uint16_t ckpt_interval
        char *gres
        uint32_t job_id
        char *name
        char *network
        char *nodes
        int32_t *node_inx
        uint32_t num_cpus
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        uint32_t num_tasks
        char *partition
        char *resv_ports
        time_t run_time
        dynamic_plugin_data_t *select_jobinfo
        time_t start_time
        uint16_t start_protocol_ver
        uint32_t state
        uint32_t step_id
        uint32_t task_dist
        uint32_t time_limit
        char *tres_alloc_str
        uint32_t user_id

    ctypedef struct job_step_info_response_msg:
        time_t last_update
        uint32_t job_step_count
        job_step_info_t *job_steps

    ctypedef job_step_info_response_msg job_step_info_response_msg_t

    ctypedef struct slurm_step_layout:
        char *front_end
        uint32_t node_cnt
        char *node_list
        uint16_t plane_size
        uint16_t start_protocol_ver
        uint16_t *tasks
        uint32_t task_cnt
        uint32_t task_dist
        uint32_t **tids

    ctypedef slurm_step_layout slurm_step_layout_t

    ctypedef struct job_step_pids_t:
        char *node_name
        uint32_t *pid
        uint32_t pid_cnt

    ctypedef struct job_step_pids_response_msg_t:
        uint32_t job_id
        List pid_list
        uint32_t step_id

    ctypedef struct job_step_stat_t:
        jobacctinfo_t *jobacct
        uint32_t num_tasks
        uint32_t return_code
        job_step_pids_t *step_pids

    ctypedef struct job_step_stat_response_msg_t:
        uint32_t job_id
        List stats_list
        uint32_t step_id

    ctypedef struct reserve_info:
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

    ctypedef reserve_info reserve_info_t

    ctypedef struct reserve_info_msg:
        time_t last_update
        uint32_t record_count
        reserve_info_t *reservation_array

    ctypedef reserve_info_msg reserve_info_msg_t

    ctypedef struct resv_desc_msg:
        char *accounts
        char *burst_buffer
        uint32_t core_cnt
        uint32_t duration
        time_t end_time
        char *features
        uint32_t flags
        char *licenses
        char *name
        uint32_t *node_cnt
        char *node_list
        char *partition
        time_t start_time
        uint32_t resv_watts
        char *tres_str
        char *users

    ctypedef resv_desc_msg resv_desc_msg_t

    ctypedef struct reserve_response_msg:
        char *name

    ctypedef reserve_response_msg reserve_response_msg_t

    ctypedef struct trigger_info:
        uint16_t flags
        uint32_t trig_id
        uint16_t res_type
        char *res_id
        uint32_t trig_type
        uint16_t offset
        uint32_t user_id
        char *program

    ctypedef trigger_info trigger_info_t

    ctypedef struct trigger_info_msg:
        uint32_t record_count
        trigger_info_t *trigger_array

    ctypedef trigger_info_msg trigger_info_msg_t

    ctypedef struct slurm_license_info:
        char *name
        uint32_t total
        uint32_t in_use
        uint32_t available
        uint8_t remote

    ctypedef slurm_license_info slurm_license_info_t

    ctypedef struct license_info_msg:
        time_t last_update
        uint32_t num_lic
        slurm_license_info_t *lic_array

    ctypedef license_info_msg license_info_msg_t

    ctypedef struct job_array_resp_msg_t:
        uint32_t job_array_count
        char **job_array_id
        uint32_t *error_code

    ctypedef struct assoc_mgr_info_msg_t:
        List assoc_list
        List qos_list
        uint32_t tres_cnt
        char **tres_names
        List user_list

    ctypedef struct assoc_mgr_info_request_msg_t:
        List acct_list
        uint32_t flags
        List qos_list
        List user_list

    ctypedef struct network_callerid_msg:
        unsigned char ip_src[16]
        unsigned char ip_dst[16]
        uint32_t port_src
        uint32_t port_dst
        int32_t af

    ctypedef network_callerid_msg network_callerid_msg_t

    ctypedef struct reservation_name_msg:
        char *name

    ctypedef reservation_name_msg reservation_name_msg_t

    ctypedef struct dynamic_plugin_data:
        void *data
        uint32_t plugin_id

    ctypedef dynamic_plugin_data dynamic_plugin_data_t

    ctypedef int64_t bitstr_t
    ctypedef bitstr_t bitoff_t

    ctypedef struct block_job_info_t:
        char *cnodes
        int32_t *cnode_inx
        uint32_t job_id
        void *job_ptr
        uint32_t user_id
        char *user_name

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

    ctypedef block_info_t update_block_msg_t

    ctypedef struct config_key_pair_t:
        char *name
        char *value

    ctypedef enum suspend_opts:
        SUSPEND_JOB
        RESUME_JOB

    ctypedef struct suspend_msg:
        uint16_t op
        uint32_t job_id
        char *job_id_str

    ctypedef suspend_msg suspend_msg_t

    ctypedef struct top_job_msg:
        uint16_t op
        uint32_t job_id
        char *job_id_str

    ctypedef top_job_msg top_job_msg_t

    ctypedef struct slurm_step_ctx_params_t:
        uint16_t ckpt_interval
        uint32_t cpu_count
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        uint16_t exclusive
        char *features
        uint16_t immediate
        uint32_t job_id
        uint32_t pn_min_memory
        char *ckpt_dir
        char *gres
        char *name
        char *network
        uint32_t profile
        uint8_t no_kill
        uint32_t min_nodes
        uint32_t max_nodes
        char *node_list
        bool overcommit
        uint16_t plane_size
        uint16_t relative
        uint16_t resv_port_cnt
        uint32_t task_count
        uint32_t task_dist
        uint32_t time_limit
        uid_t uid
        uint16_t verbose_level

    ctypedef struct slurm_step_launch_params_t:
        char *alias_list
        uint32_t argc
        char **argv
        uint32_t envc
        char **env
        char *cwd
        bool user_managed_io
        uint32_t msg_timeout
        uint16_t ntasks_per_board
        uint16_t ntasks_per_core
        uint16_t ntasks_per_socket
        bool buffered_stdio
        bool labelio
        char *remote_output_filename
        char *remote_error_filename
        char *remote_input_filename
        uint32_t gid
        bool multi_prog
        uint32_t slurmd_debug
        bool parallel_debug
        uint32_t profile
        char *task_prolog
        char *task_epilog
        uint16_t cpu_bind_type
        char *cpu_bind
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        uint16_t mem_bind_type
        char *mem_bind
        uint16_t accel_bind_type
        uint16_t max_sockets
        uint16_t max_cores
        uint16_t max_threads
        uint16_t cpus_per_task
        uint32_t task_dist
        char *partition
        bool preserve_env
        char *mpi_plugin_name
        uint8_t open_mode
        char *acctg_freq
        bool pty
        char *ckpt_dir
        char *restart_dir
        char **spank_job_env
        uint32_t spank_job_env_size

    ctypedef struct burst_buffer_pool_t:
        uint64_t total_space
        uint64_t granularity
        char *name
        uint64_t used_space

    ctypedef struct burst_buffer_resv_t:
        char *account
        uint32_t array_job_id
        uint32_t array_task_id
        time_t create_time
        uint32_t job_id
        char *name
        char *partition
        char *pool
        char *qos
        uint64_t size
        uint16_t state
        uint32_t user_id

    ctypedef struct burst_buffer_use_t:
        uint32_t user_id
        uint64_t used

    ctypedef struct burst_buffer_info_t:
        char *allow_users
        char *default_pool
        char *create_buffer
        char *deny_users
        char *destroy_buffer
        uint32_t flags
        char *get_sys_state
        uint64_t granularity
        uint32_t pool_cnt
        burst_buffer_pool_t *pool_ptr
        char *name
        uint32_t other_timeout
        uint32_t stage_in_timeout
        uint32_t stage_out_timeout
        char *start_stage_in
        char *start_stage_out
        char *stop_stage_in
        char *stop_stage_out
        uint64_t total_space
        uint64_t used_space
        uint64_t validate_timeout
        uint32_t  buffer_count
        burst_buffer_resv_t *burst_buffer_resv_ptr
        uint32_t use_count
        burst_buffer_use_t *burst_buffer_use_ptr

    ctypedef struct burst_buffer_info_msg_t:
        burst_buffer_info_t *burst_buffer_array
        uint32_t  record_count

    #
    # List
    #

    cdef extern void *slurm_list_append (List l, void *x)
    cdef extern int slurm_list_count (List l)
    cdef extern List slurm_list_create (ListDelF f)
    cdef extern void slurm_list_destroy (List l)
    cdef extern void *slurm_list_find (ListIterator i, ListFindF f, void *key)
    cdef extern int slurm_list_is_empty (List l)
    cdef extern ListIterator slurm_list_iterator_create (List l)
    cdef extern void slurm_list_iterator_reset (ListIterator i)
    cdef extern void slurm_list_iterator_destroy (ListIterator i)
    cdef extern void *slurm_list_next (ListIterator i)
    cdef extern void slurm_list_sort (List l, ListCmpF f)
    cdef extern void *slurm_list_pop (List l)

    #
    # Control Config Read/Print/Update
    #

    cdef extern long slurm_api_version ()
    cdef extern int slurm_load_ctl_conf (time_t, slurm_ctl_conf **)
    cdef extern void slurm_free_ctl_conf (slurm_ctl_conf_t *)
    cdef extern void slurm_print_ctl_conf (FILE *, slurm_ctl_conf_t *)
    cdef extern void slurm_write_ctl_conf (slurm_ctl_conf_t* slurm_ctl_conf_ptr,
                                           node_info_msg_t* node_info_ptr,
                                           partition_info_msg_t* part_info_ptr)
    cdef extern void *slurm_ctl_conf_2_key_pairs (slurm_ctl_conf_t*)
    cdef extern int slurm_load_slurmd_status (slurmd_status_t **)
    cdef extern void slurm_free_slurmd_status (slurmd_status_t *)
    cdef extern int slurm_print_slurmd_status (FILE *, slurmd_status_t **)
    cdef extern void slurm_print_key_pairs (FILE *, void* key_pairs, char *)
    cdef extern int slurm_get_statistics (stats_info_response_msg_t **buf,
                                          stats_info_request_msg_t *req)
    cdef extern int slurm_reset_statistics (stats_info_request_msg_t *req)

    #
    # Partitions
    #

    cdef extern void slurm_init_part_desc_msg (update_part_msg_t *)
    cdef extern int slurm_load_partitions (time_t, partition_info_msg_t **, uint16_t)
    cdef extern void slurm_free_partition_info_msg (partition_info_msg_t *)
    cdef extern void slurm_print_partition_info_msg (FILE *, partition_info_msg_t *, int)
    cdef extern void slurm_print_partition_info (FILE *, partition_info_t *, int)
    cdef extern char *slurm_sprint_partition_info (partition_info_t *, int)
    cdef extern int slurm_create_partition (update_part_msg_t *)
    cdef extern int slurm_update_partition (update_part_msg_t *)
    cdef extern int slurm_delete_partition (delete_part_msg_t *)

    #
    # Reservations
    #

    cdef extern void slurm_init_resv_desc_msg (resv_desc_msg_t *)
    cdef extern char* slurm_create_reservation (resv_desc_msg_t *)
    cdef extern int slurm_update_reservation (resv_desc_msg_t *)
    cdef extern int slurm_delete_reservation (reservation_name_msg_t *)
    cdef extern int slurm_load_reservations (time_t, reserve_info_msg_t **)
    cdef extern void slurm_print_reservation_info_msg (FILE *, reserve_info_msg_t *, int)
    cdef extern void slurm_print_reservation_info (FILE *, reserve_info_t *, int)
    cdef extern char* slurm_sprint_reservation_info (reserve_info_t *, int)
    cdef extern void slurm_free_reservation_info_msg (reserve_info_msg_t *)

    #
    # Job/Node Info Selection
    #
    cdef extern int slurm_get_select_jobinfo (dynamic_plugin_data_t *, int, void *)
    cdef extern int slurm_get_select_nodeinfo (dynamic_plugin_data_t *,
                                               uint32_t, uint32_t, void *)

    #
    # Job Resource Read/Print
    #

    cdef extern int slurm_job_cpus_allocated_on_node_id (job_resources_t *, int)
    cdef extern int slurm_job_cpus_allocated_on_node (job_resources_t *, char *)
    cdef extern int slurm_job_cpus_allocated_str_on_node_id (char *, size_t,
                                                             job_resources_t *, int)
    cdef extern int slurm_job_cpus_allocated_str_on_node (char *, size_t,
                                                          job_resources_t *, const_char_ptr)

    #
    # Job Control Config
    #

    cdef extern void slurm_free_job_info_msg (job_info_msg_t *)
    cdef extern int slurm_get_end_time (uint32_t, time_t *)
    cdef extern void slurm_get_job_stderr (char *buf, int buf_size, job_info_t * job_ptr)
    cdef extern void slurm_get_job_stdin (char *buf, int buf_size, job_info_t * job_ptr)
    cdef extern void slurm_get_job_stdout (char *buf, int buf_size, job_info_t * job_ptr)
    cdef extern long slurm_get_rem_time (uint32_t)
    cdef extern int slurm_job_node_ready (uint32_t)
    cdef extern int slurm_load_job (job_info_msg_t **, uint32_t, uint16_t)
    cdef extern int slurm_load_job_user (job_info_msg_t **job_info_msg_pptr,
                                         uint32_t user_id, uint16_t show_flags)
    cdef extern int slurm_load_jobs (time_t, job_info_msg_t **, uint16_t)
    cdef extern int slurm_notify_job (uint32_t, char *)
    cdef extern int slurm_pid2jobid (uint32_t, uint32_t *)
    cdef extern void slurm_print_job_info (FILE *, slurm_job_info_t *, int)
    cdef extern void slurm_print_job_info_msg (FILE *, job_info_msg_t *, int)
    cdef extern char *slurm_sprint_job_info (slurm_job_info_t *, int)
    cdef extern int slurm_update_job (job_desc_msg_t *)
    cdef extern int slurm_update_job2 (job_desc_msg_t * job_msg,
                                       job_array_resp_msg_t **resp)
    cdef extern uint32_t slurm_xlate_job_id (char *job_id_str)
    cdef extern int slurm_top_job (char *job_id_str)

    #
    # Ping/Reconfigure/Shutdown
    #

    cdef extern int slurm_ping (int)
    cdef extern int slurm_reconfigure ()
    cdef extern int slurm_shutdown (uint16_t)
    cdef extern int slurm_takeover ()
    cdef extern int slurm_set_debug_level (uint32_t)
    cdef extern int slurm_set_debugflags (uint64_t debug_flags_plus,
                                          uint64_t debug_flags_minus)
    cdef extern int slurm_set_schedlog_level (uint32_t)

    #
    # Resource Allocation
    #

    cdef extern int slurm_load_licenses (time_t, license_info_msg_t **, uint16_t)
    cdef extern void slurm_free_license_info_msg (license_info_msg_t *)

    cdef extern int slurm_load_assoc_mgr_info (assoc_mgr_info_request_msg_t *,
                                               assoc_mgr_info_msg_t **)
    cdef extern void slurm_free_assoc_mgr_info_msg (assoc_mgr_info_msg_t *)
    cdef extern void slurm_free_assoc_mgr_info_request_msg (assoc_mgr_info_request_msg_t *)

    #
    # Job/Job Step Signaling
    #

    cdef extern int slurm_kill_job (uint32_t, uint16_t, uint16_t)
    cdef extern int slurm_kill_job_step (uint32_t, uint32_t, uint16_t)
    cdef extern int slurm_kill_job2 (char *, uint16_t, uint16_t)
    cdef extern int slurm_kill_job_step2 (char *, uint16_t, uint16_t)
    cdef extern int slurm_signal_job (uint32_t, uint16_t)
    cdef extern int slurm_signal_job_step (uint32_t, uint32_t, uint32_t)

    #
    # Job Completion/Terminate
    #

    cdef extern int slurm_complete_job (uint32_t, uint32_t)
    cdef extern int slurm_terminate_job_step (uint32_t, uint32_t)

    #
    # Job Suspend/Resume/Requeue
    #

    cdef extern int slurm_suspend (uint32_t)
    cdef extern int slurm_suspend2 (char *job_id, job_array_resp_msg_t **resp)
    cdef extern int slurm_resume (uint32_t)
    cdef extern int slurm_resume2 (char *job_id, job_array_resp_msg_t **resp)
    cdef extern void slurm_free_job_array_resp (job_array_resp_msg_t *resp)
    cdef extern int slurm_requeue (uint32_t, uint32_t)
    cdef extern int slurm_requeue2 (char *job_id, uint32_t state, job_array_resp_msg_t **resp)

    #
    # Checkpoint
    #

    cdef extern int slurm_checkpoint_able (uint32_t, uint32_t, time_t *)
    cdef extern int slurm_checkpoint_disable (uint32_t, uint32_t)
    cdef extern int slurm_checkpoint_enable (uint32_t, uint32_t)
    cdef extern int slurm_checkpoint_create (uint32_t, uint32_t, uint16_t, char*)
    cdef extern int slurm_checkpoint_requeue (uint32_t job_id, uint16_t max_wait, char *image_dir)
    cdef extern int slurm_checkpoint_vacate (uint32_t, uint32_t, uint16_t, char *)
    cdef extern int slurm_checkpoint_restart (uint32_t, uint32_t, uint16_t, char *)
    cdef extern int slurm_checkpoint_complete (uint32_t, uint32_t, time_t, uint32_t, char *)
    cdef extern int slurm_checkpoint_task_complete (uint32_t, uint32_t,
                                                    uint32_t, time_t, uint32_t, char *)
    cdef extern int slurm_checkpoint_error (uint32_t, uint32_t, uint32_t *, char **)
    cdef extern int slurm_checkpoint_tasks (uint32_t, uint16_t, time_t, char *, uint16_t, char *)

    #
    # Node Configuration Read/Print/Update
    #

    cdef extern int slurm_load_node (time_t, node_info_msg_t **, uint16_t)
    cdef extern int slurm_load_node_single (node_info_msg_t **resp,
                                            char *node_name, uint16_t show_flags)
    cdef extern int slurm_get_node_energy (char *host, uint16_t delta,
                                           uint16_t *sensors_cnt,
                                           acct_gather_energy_t **energy)
    cdef extern void slurm_free_node_info_msg (node_info_msg_t *)
    cdef extern void slurm_print_node_info_msg (FILE *, node_info_msg_t *, int)
    cdef extern void slurm_print_node_table (FILE *, node_info_t *, int)
    cdef extern char *slurm_sprint_node_table (node_info_t *, int)
    cdef extern void slurm_init_update_node_msg (update_node_msg_t *)
    cdef extern int slurm_update_node (update_node_msg_t *)

    #
    # JobSteps
    #

    cdef extern int slurm_get_job_steps (time_t, uint32_t, uint32_t,
                                         job_step_info_response_msg_t **, uint16_t)
    cdef extern void slurm_free_job_step_info_response_msg (job_step_info_response_msg_t *)
    cdef extern slurm_step_layout_t *slurm_job_step_layout_get (uint32_t, uint32_t)
    cdef extern void slurm_job_step_layout_free (slurm_step_layout *)
    cdef extern int slurm_job_step_stat (uint32_t, uint32_t, char *,
                                         job_step_stat_response_msg_t **)
    cdef extern int slurm_job_step_get_pids (uint32_t, uint32_t, char *,
                                             job_step_pids_response_msg_t **)
    cdef extern void slurm_job_step_pids_free (job_step_pids_t *)
    cdef extern void slurm_job_step_pids_response_msg_free (void *)
    cdef extern void slurm_job_step_stat_free (job_step_stat_t *)
    cdef extern void slurm_job_step_stat_response_msg_free (void *)
    cdef extern int slurm_update_step (step_update_request_msg_t * step_msg)

    #
    # Triggers
    #

    cdef extern int slurm_set_trigger (trigger_info_t *)
    cdef extern int slurm_clear_trigger (trigger_info_t *)
    cdef extern int slurm_get_triggers (trigger_info_msg_t **)
    cdef extern int slurm_pull_trigger (trigger_info_t *)
    cdef extern void slurm_free_trigger_msg (trigger_info_msg_t *)
    cdef extern void slurm_init_trigger_msg (trigger_info_t *trigger_info_msg)

    #
    # Hostlists
    #

    cdef extern hostlist_t slurm_hostlist_create (char *)
    cdef extern int slurm_hostlist_count (hostlist_t hl)
    cdef extern void slurm_hostlist_destroy (hostlist_t hl)
    cdef extern int slurm_hostlist_find (hostlist_t hl, char *)
    cdef extern int slurm_hostlist_push (hostlist_t hl, char *)
    cdef extern int slurm_hostlist_push_host (hostlist_t hl, char *)
    cdef extern ssize_t slurm_hostlist_ranged_string (hostlist_t hl, size_t, char *)
    cdef extern char *slurm_hostlist_ranged_string_malloc (hostlist_t hl)
    cdef extern char *slurm_hostlist_ranged_string_xmalloc (hostlist_t hl)
    cdef extern void slurm_hostlist_uniq (hostlist_t hl)
    cdef extern char *slurm_hostlist_shift (hostlist_t hl)

    #
    # Topology
    #

    cdef extern int slurm_load_topo (topo_info_response_msg_t **)
    cdef extern void slurm_free_topo_info_msg (topo_info_response_msg_t *)
    cdef extern void slurm_print_topo_info_msg (FILE *, topo_info_response_msg_t *, int)
    cdef extern void slurm_print_topo_record (FILE * out, topo_info_t *, int one_liner)

    #
    # Power Capping
    #

    cdef extern int slurm_load_powercap (powercap_info_msg_t **powercap_info_msg_pptr)
    cdef extern void slurm_free_powercap_info_msg (powercap_info_msg_t *msg)
    cdef extern void slurm_print_powercap_info_msg (FILE * out,
                                                    powercap_info_msg_t *powercap_info_msg_ptr,
                                                    int one_liner)
    cdef extern int slurm_update_powercap (update_powercap_msg_t * powercap_msg)

    #
    # Burst Buffer
    #

    cdef extern char *slurm_burst_buffer_state_string (uint16_t state)
    cdef extern int slurm_load_burst_buffer_info (
        burst_buffer_info_msg_t **burst_buffer_info_msg_pptr)
    cdef extern void slurm_free_burst_buffer_info_msg (
        burst_buffer_info_msg_t *burst_buffer_info_msg)
    cdef extern void slurm_print_burst_buffer_info_msg (FILE *out,
                                                        burst_buffer_info_msg_t *info_ptr,
                                                        int one_liner, int verbosity)
    cdef extern void slurm_print_burst_buffer_record (FILE *out,
                                                      burst_buffer_info_t *burst_buffer_ptr,
                                                      int one_liner, int verbose)
    cdef extern int slurm_network_callerid (network_callerid_msg_t req,
                                            uint32_t *job_id,
                                            char *node_name, int node_name_size)

    #
    # Blue Gene
    #

    cdef extern void slurm_print_block_info_msg (FILE *out, block_info_msg_t *info_ptr, int)
    cdef extern void slurm_print_block_info (FILE *out, block_info_t *bg_info_ptr, int)
    cdef extern char *slurm_sprint_block_info (block_info_t * bg_info_ptr, int)
    cdef extern int slurm_load_block_info (time_t update_time,
                                           block_info_msg_t **block_info_msg_pptr,
                                           uint16_t)
    cdef extern void slurm_free_block_info_msg (block_info_msg_t *block_info_msg)
    cdef extern int slurm_update_block (update_block_msg_t *block_msg)
    cdef extern void slurm_init_update_block_msg (update_block_msg_t *update_block_msg)

    #
    # Front End Node
    #

    cdef extern int slurm_load_front_end (time_t update_time, front_end_info_msg_t **resp)
    cdef extern void slurm_free_front_end_info_msg (front_end_info_msg_t * front_end_buffer_ptr)
    cdef extern void slurm_print_front_end_info_msg (FILE * out,
                                                     front_end_info_msg_t * front_end_info_msg_ptr,
                                                     int one_liner)
    cdef extern void slurm_print_front_end_table (FILE * out,
                                                  front_end_info_t * front_end_ptr,
                                                  int one_liner)
    cdef extern char *slurm_sprint_front_end_table (front_end_info_t * front_end_ptr,
                                                    int one_liner)
    cdef void slurm_init_update_front_end_msg (update_front_end_msg_t * update_front_end_msg)
    cdef extern int slurm_update_front_end (update_front_end_msg_t * front_end_msg)

    #
    # End
    #

#
# Main Slurmdb API
#

cdef extern from 'slurm/slurmdb.h' nogil:
    ctypedef struct slurmdb_cluster_cond:
        uint16_t classification
        List cluster_list
        uint32_t flags
        List plugin_id_select_list
        List rpc_version_list
        time_t usage_end
        time_t usage_start
        uint16_t with_deleted
        uint16_t with_usage

    ctypedef slurmdb_cluster_cond slurmdb_cluster_cond_t

    ctypedef struct slurmdb_tres_rec:
        uint64_t alloc_secs
        uint32_t rec_count
        uint64_t count
        uint32_t id
        char *name
        char *type

    ctypedef slurmdb_tres_rec slurmdb_tres_rec_t

    ctypedef struct slurmdb_cluster_accounting_rec:
        uint64_t alloc_secs
        uint64_t down_secs
        uint64_t idle_secs
        uint64_t over_secs
        uint64_t pdown_secs
        time_t period_start
        uint64_t resv_secs
        slurmdb_tres_rec_t tres_rec

    ctypedef slurmdb_cluster_accounting_rec slurmdb_cluster_accounting_rec_t

    ctypedef struct slurmdb_assoc_usage:
        List children_list
        uint64_t *grp_used_tres
        uint64_t *grp_used_tres_run_secs
        double grp_used_wall
        double fs_factor
        uint32_t level_shares
#        slurmdb_assoc_rec_t *parent_assoc_ptr
#        slurmdb_assoc_rec_t *fs_assoc_ptr # need some definition
        double shares_norm
        uint32_t tres_cnt
        long double usage_efctv
        long double usage_norm
        long double usage_raw
        long double *usage_tres_raw
        uint32_t used_jobs
        uint32_t used_submit_jobs
        long double level_fs
        bitstr_t *valid_qos

    ctypedef slurmdb_assoc_usage slurmdb_assoc_usage_t

    ctypedef struct slurmdb_assoc_rec:
        List accounting_list
        char *acct
        slurmdb_assoc_rec *assoc_next
        slurmdb_assoc_rec *assoc_next_id
        char *cluster
        uint32_t def_qos_id
        uint32_t grp_jobs
        uint32_t grp_submit_jobs
        char *grp_tres
        uint64_t *grp_tres_ctld
        char *grp_tres_min
        uint64_t *grp_tres_mins_ctld
        char *grp_tres_run_mins
        uint64_t *grp_tres_run_mins_ctld
        uint32_t grp_wall
        uint32_t id
        uint16_t is_def
        uint32_t lft
        uint32_t max_jobs
        uint32_t max_submit_jobs
        char *max_tres_mins_pj
        uint64_t *max_tres_mins_ctldi
        char *max_tres_run_mins
        uint64_t *max_tres_run_mins_ctld
        char *max_tres_pj
        uint64_t *max_tres_ctld
        char *max_tres_pn
        uint64_t *max_tres_pn_ctld
        uint32_t max_wall_pj
        char *parent_acct
        uint32_t parent_id
        char *partition
        List qos_list
        uint32_t rgt
        uint32_t shares_raw
        uint32_t uid
        slurmdb_assoc_usage_t *usage
        char *user

    ctypedef slurmdb_assoc_rec slurmdb_assoc_rec_t

    ctypedef struct slurmdb_cluster_rec:
        List accounting_list
        uint16_t classification
        char *control_host
        uint32_t control_port
        uint16_t dimensions
        int *dim_size
        uint32_t flags
        char *name
        char *nodes
        uint32_t plugin_id_select
        slurmdb_assoc_rec_t *root_assoc #It is not required to support now
        uint16_t rpc_version
        char *tres_str

    ctypedef slurmdb_cluster_rec slurmdb_cluster_rec_t

    ctypedef struct slurmdb_job_cond:
        List acct_list
        List associd_list
        List cluster_list
        uint32_t cpus_max
        uint32_t cpus_min
        uint16_t duplicates
        int32_t exitcode
        List groupid_list
        List jobname_list
        uint32_t nodes_max
        uint32_t nodes_min
        List partition_list
        List qos_list
        List resv_list
        List resvid_list
        List state_list
        List step_list
        uint32_t timelimit_max
        uint32_t timelimit_min
        time_t usage_end
        time_t usage_start
        char *used_nodes
        List userid_list
        List wckey_list
        uint16_t without_steps
        uint16_t without_usage_truncation

    ctypedef slurmdb_job_cond slurmdb_job_cond_t

    ctypedef struct slurmdb_stats:
        double act_cpufreq
        double cpu_ave
        double consumed_energy
        uint32_t cpu_min
        uint32_t cpu_min_nodeid
        uint32_t cpu_min_taskid
        double disk_read_ave
        double disk_read_max
        uint32_t disk_read_max_nodeid
        uint32_t disk_read_max_taskid
        double disk_write_ave
        double disk_write_max
        uint32_t disk_write_max_nodeid
        uint32_t disk_write_max_taskid
        double pages_ave
        uint64_t pages_max
        uint32_t pages_max_nodeid
        uint32_t pages_max_taskid
        double rss_ave
        uint64_t rss_max
        uint32_t rss_max_nodeid
        uint32_t rss_max_taskid
        double vsize_ave
        uint64_t vsize_max
        uint32_t vsize_max_nodeid
        uint32_t vsize_max_taskid

    ctypedef slurmdb_stats slurmdb_stats_t

    ctypedef struct slurmdb_job_rec:
        char *account
        char *alloc_gres
        uint32_t alloc_nodes
        uint32_t array_job_id
        uint32_t array_max_tasks
        uint32_t array_task_id
        char *array_task_str
        uint32_t associd
        char *blockid
        char *cluster
        uint32_t derived_ec
        char *derived_es
        uint32_t elapsed
        time_t eligible
        time_t end
        uint32_t exitcode
        void *first_step_ptr
        uint32_t gid
        uint32_t jobid
        char *jobname
        uint32_t lft
        char *partition
        char *nodes
        uint32_t priority
        uint32_t qosid
        uint32_t req_cpus
        char *req_gres
        uint32_t req_mem
        uint32_t requid
        uint32_t resvid
        char *resv_name
        uint32_t show_full
        time_t start
        uint32_t state
        slurmdb_stats_t stats
        List steps
        time_t submit
        uint32_t suspended
        uint32_t sys_cpu_sec
        uint32_t sys_cpu_usec
        uint32_t timelimit
        uint32_t tot_cpu_sec
        uint32_t tot_cpu_usec
        uint16_t track_steps
        char *tres_alloc_str
        char *tres_req_str
        uint32_t uid
        char *used_gres
        char *user
        uint32_t user_cpu_sec
        uint32_t user_cpu_usec
        char *wckey
        uint32_t wckeyid

    ctypedef slurmdb_job_rec slurmdb_job_rec_t

    ctypedef struct slurmdb_step_rec:
        uint32_t elapsed
        time_t end
        int32_t exitcode
        slurmdb_job_rec_t *job_ptr
        uint32_t nnodes
        char *nodes
        uint32_t ntasks
        char *pid_str
        uint32_t req_cpufreq_min
        uint32_t req_cpufreq_max
        uint32_t req_cpufreq_gov
        uint32_t requid
        time_t start
        uint32_t state
        slurmdb_stats_t stats
        uint32_t stepid    #	/* job's step number */
        char *stepname
        uint32_t suspended
        uint32_t sys_cpu_sec
        uint32_t sys_cpu_usec
        uint32_t task_dist
        uint32_t tot_cpu_sec
        uint32_t tot_cpu_usec
        char *tres_alloc_str
        uint32_t user_cpu_sec
        uint32_t user_cpu_usec

    ctypedef slurmdb_step_rec slurmdb_step_rec_t

    # Reservations
    ctypedef struct slurmdb_reservation_cond:
        List cluster_list
        uint16_t flags
        List id_list
        List name_list
        char *nodes
        time_t time_end
        time_t time_start
        uint16_t with_usage

    ctypedef slurmdb_reservation_cond slurmdb_reservation_cond_t

    ctypedef struct slurmdb_reservation_rec:
        char *assocs
        char *cluster
        uint32_t flags
        uint32_t id
        char *name
        char *nodes
        char *node_inx
        time_t time_end
        time_t time_start
        time_t time_start_prev
        char *tres_str
        List tres_list

    ctypedef slurmdb_reservation_rec slurmdb_reservation_rec_t

    # Qos
    ctypedef struct slurmdb_qos_usage_t:
        List job_list
        uint32_t grp_used_jobs
        uint32_t grp_used_submit_jobs
        uint64_t *grp_used_tres
        uint64_t *grp_used_tres_run_secs
        double grp_used_wall
        double norm_priority
        uint32_t tres_cnt
        long double usage_raw
        long double *usage_tres_raw
        List user_limit_list

    ctypedef struct slurmdb_qos_rec:
        char *description
        uint32_t id
        uint32_t flags
        uint32_t grace_time
        uint32_t grp_jobs
        uint32_t grp_submit_jobs
        char *grp_tres
        uint64_t *grp_tres_ctld
        char *grp_tres_mins
        uint64_t *grp_tres_mins_ctld
        char *grp_tres_run_mins
        uint64_t *grp_tres_run_mins_ctld
        uint32_t grp_wall
        uint32_t max_jobs_pu
        uint32_t max_submit_jobs_pu
        char *max_tres_mins_pj
        uint64_t *max_tres_mins_pj_ctld
        char *max_tres_pj
        uint64_t *max_tres_pj_ctld
        char *max_tres_pn
        uint64_t *max_tres_pn_ctld
        char *max_tres_pu
        uint64_t *max_tres_pu_ctld
        char *max_tres_run_mins_pu
        uint64_t *max_tres_run_mins_pu_ctld
        uint32_t max_wall_pj
        char *min_tres_pj
        uint64_t *min_tres_pj_ctld
        char *name
        bitstr_t *preempt_bitstr
        List preempt_list
        uint16_t preempt_mode
        uint32_t priority
        slurmdb_qos_usage_t *usage
        double usage_factor
        double usage_thres

    ctypedef slurmdb_qos_rec slurmdb_qos_rec_t

    ctypedef struct slurmdb_qos_cond:
        List description_list
        List id_list
        List name_list
        uint16_t preempt_mode
        uint16_t with_deleted

    ctypedef slurmdb_qos_cond slurmdb_qos_cond_t

    # Events
    ctypedef struct slurmdb_event_cond:
        List cluster_list
        uint32_t cpus_max
        uint32_t cpus_min
        uint16_t event_type
        List node_list
        time_t period_end
        time_t period_start
        List reason_list
        List reason_uid_list
        List state_list

    ctypedef slurmdb_event_cond slurmdb_event_cond_t

    ctypedef struct slurmdb_event_rec:
        char *cluster
        char *cluster_nodes
        uint16_t event_type
        char *node_name
        time_t period_end
        time_t period_start
        char *reason
        uint32_t reason_uid
        uint16_t state
        char *tres_str

    ctypedef slurmdb_event_rec slurmdb_event_rec_t

    ctypedef struct slurmdb_selected_step:
        uint32_t array_task_id
        uint32_t jobid
        uint32_t stepid

    ctypedef slurmdb_selected_step slurmdb_selected_step_t

    #
    # Accounting Storage
    #

    cdef extern void *slurmdb_connection_get ()
    cdef extern int slurmdb_connection_close (void **db_conn)
    cdef extern List slurmdb_config_get (void *db_conn)

    #
    # QOS
    #

    cdef extern int slurmdb_qos_add (void *db_conn, uint32_t uid, List qos_list)
    cdef extern List slurmdb_qos_get (void *db_conn, slurmdb_qos_cond_t *qos_cond)
    cdef extern List slurmdb_qos_modify (void *db_conn,
                                         slurmdb_qos_cond_t *qos_cond,
                                         slurmdb_qos_rec_t *qos)
    cdef extern List slurmdb_qos_remove (void *db_conn, slurmdb_qos_cond_t *qos_cond)

    # jobs accounting C APIs
    cdef extern List slurmdb_jobs_get(void *db_conn, slurmdb_job_cond_t *job_cond)
    cdef extern void slurmdb_destroy_job_cond(void *object)
    cdef extern void slurmdb_destroy_job_rec(void *object)
    cdef extern void slurmdb_destroy_selected_step(void *object)

    # reservation accounting details
    cdef extern List slurmdb_reservations_get(void *db_conn,
                         slurmdb_reservation_cond_t *resv_cond)
    cdef extern void slurmdb_destroy_reservation_cond(void *object)
    cdef extern void slurmdb_destroy_reservation_rec(void *object);

    # clusters accounting and report APIs
    cdef extern List slurmdb_clusters_get(void *db_conn, slurmdb_cluster_cond_t *cluster_cond)
    cdef extern void slurmdb_init_cluster_cond(slurmdb_cluster_cond_t *cluster, bool free_it)
    cdef extern void slurmdb_destroy_cluster_cond(void *object)
    #cdef extern void slurmdb_init_cluster_rec(slurmdb_cluster_rec_t *cluster, bool free_it)
    cdef extern void slurmdb_destroy_cluster_rec(void *object)
    #cdef extern void slurmdb_destroy_report_cluster_rec(void *object)

    # event accounting details
    cdef extern List slurmdb_events_get(void *db_conn,
                         slurmdb_event_cond_t *resv_cond)
    cdef extern void slurmdb_destroy_event_cond(void *object)
    cdef extern void slurmdb_destroy_event_rec(void *object);

#
# Slurm declarations not in slurm.h
#

cdef inline void* xmalloc(__sz):
    return slurm_xmalloc(__sz, __FILE__, __LINE__, __FUNCTION__)

cdef inline xfree(void *__p):
    slurm_xfree(&__p, __FILE__, __LINE__, __FUNCTION__)

cdef extern void slurm_accounting_enforce_string (uint16_t enforce,
                                                  char *, int)
cdef extern void slurm_api_clear_config ()
cdef extern void slurm_api_set_conf_file (char *)
cdef extern char *slurm_bg_block_state_string (uint16_t)
cdef extern char *slurm_conn_type_string (enum)
cdef extern uint16_t slurm_get_preempt_mode ()
cdef extern char *slurm_job_reason_string (int inx)
cdef extern int   slurm_job_state_num (char *state_name)
cdef extern char *slurm_job_state_string (uint16_t inx)
cdef extern char *slurm_node_state_string (uint32_t inx)
cdef extern char *slurm_node_state_string_compact (uint32_t inx)
cdef extern char *slurm_node_use_string (int)
cdef extern uint16_t slurm_preempt_mode_num (char *preempt_mode)
cdef extern char *slurm_preempt_mode_string (uint16_t preempt_mode)
cdef extern char *slurm_reservation_flags_string (uint32_t flags)
cdef extern void slurm_xfree (void **, const_char_ptr, int, const_char_ptr)
cdef extern void *slurm_xmalloc (size_t, const_char_ptr, int, const_char_ptr)
cdef extern void slurm_free_stats_response_msg (stats_info_response_msg_t *msg)
cdef extern char *slurm_step_layout_type_name (task_dist_states_t task_dist)
