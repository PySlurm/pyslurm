# cython: embedsignature=True
# cython: profile=False


from libcpp cimport bool
from posix.unistd cimport uid_t, pid_t
from libc.stdint cimport int32_t, int64_t, uint8_t, uint16_t, uint32_t, uint64_t
from cpython.version cimport PY_MAJOR_VERSION
from posix.unistd cimport uid_t, pid_t, gid_t
from libc.stdint cimport uint32_t, uint16_t, uint64_t


cdef extern from "<netinet/in.h>" nogil:
    ctypedef struct sockaddr_in
    ctypedef struct sockaddr_storage

cdef extern from '<stdio.h>' nogil:
    ctypedef struct FILE
    cdef FILE *stdout


cdef extern from '<Python.h>' nogil:
    cdef FILE *PyFile_AsFile(object file)
    char *__FILE__
    cdef int __LINE__
    char *__FUNCTION__


cdef extern from '<time.h>' nogil:
    ctypedef long time_t


cdef extern from "<netinet/in.h>" nogil:
    ctypedef struct sockaddr_in


cdef extern from "<pthread.h>" nogil:
    ctypedef union pthread_mutex_t


cdef extern from *:
    ctypedef struct slurm_job_credential
    ctypedef struct switch_jobinfo
    ctypedef struct job_resources
    ctypedef struct select_jobinfo
    ctypedef struct select_nodeinfo
    ctypedef struct jobacctinfo
    ctypedef struct allocation_msg_thread
    ctypedef struct sbcast_cred
    ctypedef struct hostlist
    ctypedef struct xlist
    ctypedef struct listIterator
    ctypedef struct slurm_step_ctx_struct
    ctypedef char const_char "const char"
    ctypedef struct slurm_ctl_conf_t
    ctypedef char* const_char_ptr "const char*"
    ctypedef char** const_char_pptr "const char**"


cdef extern from "slurm/slurm_errno.h":

    int SLURM_SUCCESS
    int SLURM_ERROR

    cdef enum:
        SLURM_UNEXPECTED_MSG_ERROR
        SLURM_COMMUNICATIONS_CONNECTION_ERROR
        SLURM_COMMUNICATIONS_SEND_ERROR
        SLURM_COMMUNICATIONS_RECEIVE_ERROR
        SLURM_COMMUNICATIONS_SHUTDOWN_ERROR
        SLURM_PROTOCOL_VERSION_ERROR
        SLURM_PROTOCOL_IO_STREAM_VERSION_ERROR
        SLURM_PROTOCOL_AUTHENTICATION_ERROR
        SLURM_PROTOCOL_INSANE_MSG_LENGTH
        SLURM_MPI_PLUGIN_NAME_INVALID
        SLURM_MPI_PLUGIN_PRELAUNCH_SETUP_FAILED
        SLURM_PLUGIN_NAME_INVALID
        SLURM_UNKNOWN_FORWARD_ADDR
        SLURMCTLD_COMMUNICATIONS_CONNECTION_ERROR
        SLURMCTLD_COMMUNICATIONS_SEND_ERROR
        SLURMCTLD_COMMUNICATIONS_RECEIVE_ERROR
        SLURMCTLD_COMMUNICATIONS_SHUTDOWN_ERROR
        SLURM_NO_CHANGE_IN_DATA
        ESLURM_INVALID_PARTITION_NAME
        ESLURM_DEFAULT_PARTITION_NOT_SET
        ESLURM_ACCESS_DENIED
        ESLURM_JOB_MISSING_REQUIRED_PARTITION_GROUP
        ESLURM_REQUESTED_NODES_NOT_IN_PARTITION
        ESLURM_TOO_MANY_REQUESTED_CPUS
        ESLURM_INVALID_NODE_COUNT
        ESLURM_ERROR_ON_DESC_TO_RECORD_COPY
        ESLURM_JOB_MISSING_SIZE_SPECIFICATION
        ESLURM_JOB_SCRIPT_MISSING
        ESLURM_USER_ID_MISSING
        ESLURM_DUPLICATE_JOB_ID
        ESLURM_PATHNAME_TOO_LONG
        ESLURM_NOT_TOP_PRIORITY
        ESLURM_REQUESTED_NODE_CONFIG_UNAVAILABLE
        ESLURM_REQUESTED_PART_CONFIG_UNAVAILABLE
        ESLURM_NODES_BUSY
        ESLURM_INVALID_JOB_ID
        ESLURM_INVALID_NODE_NAME
        ESLURM_WRITING_TO_FILE
        ESLURM_TRANSITION_STATE_NO_UPDATE
        ESLURM_ALREADY_DONE
        ESLURM_INTERCONNECT_FAILURE
        ESLURM_BAD_DIST
        ESLURM_JOB_PENDING
        ESLURM_BAD_TASK_COUNT
        ESLURM_INVALID_JOB_CREDENTIAL
        ESLURM_IN_STANDBY_MODE
        ESLURM_INVALID_NODE_STATE
        ESLURM_INVALID_FEATURE
        ESLURM_INVALID_AUTHTYPE_CHANGE
        ESLURM_ACTIVE_FEATURE_NOT_SUBSET
        ESLURM_INVALID_SCHEDTYPE_CHANGE
        ESLURM_INVALID_SELECTTYPE_CHANGE
        ESLURM_INVALID_SWITCHTYPE_CHANGE
        ESLURM_FRAGMENTATION
        ESLURM_NOT_SUPPORTED
        ESLURM_DISABLED
        ESLURM_DEPENDENCY
        ESLURM_BATCH_ONLY
        ESLURM_TASKDIST_ARBITRARY_UNSUPPORTED
        ESLURM_TASKDIST_REQUIRES_OVERCOMMIT
        ESLURM_JOB_HELD
        ESLURM_INVALID_CRED_TYPE_CHANGE
        ESLURM_INVALID_TASK_MEMORY
        ESLURM_INVALID_ACCOUNT
        ESLURM_INVALID_PARENT_ACCOUNT
        ESLURM_SAME_PARENT_ACCOUNT
        ESLURM_INVALID_LICENSES
        ESLURM_NEED_RESTART
        ESLURM_ACCOUNTING_POLICY
        ESLURM_INVALID_TIME_LIMIT
        ESLURM_RESERVATION_ACCESS
        ESLURM_RESERVATION_INVALID
        ESLURM_INVALID_TIME_VALUE
        ESLURM_RESERVATION_BUSY
        ESLURM_RESERVATION_NOT_USABLE
        ESLURM_INVALID_WCKEY
        ESLURM_RESERVATION_OVERLAP
        ESLURM_PORTS_BUSY
        ESLURM_PORTS_INVALID
        ESLURM_PROLOG_RUNNING
        ESLURM_NO_STEPS
        ESLURM_INVALID_BLOCK_STATE
        ESLURM_INVALID_BLOCK_LAYOUT
        ESLURM_INVALID_BLOCK_NAME
        ESLURM_INVALID_QOS
        ESLURM_QOS_PREEMPTION_LOOP
        ESLURM_NODE_NOT_AVAIL
        ESLURM_INVALID_CPU_COUNT
        ESLURM_PARTITION_NOT_AVAIL
        ESLURM_CIRCULAR_DEPENDENCY
        ESLURM_INVALID_GRES
        ESLURM_JOB_NOT_PENDING
        ESLURM_QOS_THRES
        ESLURM_PARTITION_IN_USE
        ESLURM_STEP_LIMIT
        ESLURM_JOB_SUSPENDED
        ESLURM_CAN_NOT_START_IMMEDIATELY
        ESLURM_INTERCONNECT_BUSY
        ESLURM_RESERVATION_EMPTY
        ESLURM_INVALID_ARRAY
        ESLURM_RESERVATION_NAME_DUP
        ESLURM_JOB_STARTED
        ESLURM_JOB_FINISHED
        ESLURM_JOB_NOT_RUNNING
        ESLURM_JOB_NOT_PENDING_NOR_RUNNING
        ESLURM_JOB_NOT_SUSPENDED
        ESLURM_JOB_NOT_FINISHED
        ESLURM_TRIGGER_DUP
        ESLURM_INTERNAL
        ESLURM_INVALID_BURST_BUFFER_CHANGE
        ESLURM_BURST_BUFFER_PERMISSION
        ESLURM_BURST_BUFFER_LIMIT
        ESLURM_INVALID_BURST_BUFFER_REQUEST
        ESLURM_PRIO_RESET_FAIL
        ESLURM_CANNOT_MODIFY_CRON_JOB
        ESLURM_INVALID_MCS_LABEL
        ESLURM_BURST_BUFFER_WAIT
        ESLURM_PARTITION_DOWN
        ESLURM_DUPLICATE_GRES
        ESLURM_JOB_SETTING_DB_INX
        ESLURM_RSV_ALREADY_STARTED
        ESLURM_SUBMISSIONS_DISABLED
        ESLURM_NOT_HET_JOB
        ESLURM_NOT_HET_JOB_LEADER
        ESLURM_NOT_WHOLE_HET_JOB
        ESLURM_CORE_RESERVATION_UPDATE
        ESLURM_DUPLICATE_STEP_ID
        ESLURM_INVALID_CORE_CNT
        ESLURM_X11_NOT_AVAIL
        ESLURM_GROUP_ID_MISSING
        ESLURM_BATCH_CONSTRAINT
        ESLURM_INVALID_TRES
        ESLURM_INVALID_TRES_BILLING_WEIGHTS
        ESLURM_INVALID_JOB_DEFAULTS
        ESLURM_RESERVATION_MAINT
        ESLURM_INVALID_GRES_TYPE
        ESLURM_REBOOT_IN_PROGRESS
        ESLURM_MULTI_KNL_CONSTRAINT
        ESLURM_UNSUPPORTED_GRES
        ESLURM_INVALID_NICE
        ESLURM_INVALID_TIME_MIN_LIMIT
        ESLURM_DEFER
        ESLURM_CONFIGLESS_DISABLED
        ESLURM_ENVIRONMENT_MISSING
        ESLURM_RESERVATION_NO_SKIP
        ESLURM_RESERVATION_USER_GROUP
        ESLURM_PARTITION_ASSOC
        ESLURMD_PIPE_ERROR_ON_TASK_SPAWN
        ESLURMD_KILL_TASK_FAILED
        ESLURMD_KILL_JOB_ALREADY_COMPLETE
        ESLURMD_INVALID_ACCT_FREQ
        ESLURMD_INVALID_JOB_CREDENTIAL
        ESLURMD_UID_NOT_FOUND
        ESLURMD_GID_NOT_FOUND
        ESLURMD_CREDENTIAL_EXPIRED
        ESLURMD_CREDENTIAL_REVOKED
        ESLURMD_CREDENTIAL_REPLAYED
        ESLURMD_CREATE_BATCH_DIR_ERROR
        ESLURMD_MODIFY_BATCH_DIR_ERROR
        ESLURMD_CREATE_BATCH_SCRIPT_ERROR
        ESLURMD_MODIFY_BATCH_SCRIPT_ERROR
        ESLURMD_SETUP_ENVIRONMENT_ERROR
        ESLURMD_SHARED_MEMORY_ERROR
        ESLURMD_SET_UID_OR_GID_ERROR
        ESLURMD_SET_SID_ERROR
        ESLURMD_CANNOT_SPAWN_IO_THREAD
        ESLURMD_FORK_FAILED
        ESLURMD_EXECVE_FAILED
        ESLURMD_IO_ERROR
        ESLURMD_PROLOG_FAILED
        ESLURMD_EPILOG_FAILED
        ESLURMD_SESSION_KILLED
        ESLURMD_TOOMANYSTEPS
        ESLURMD_STEP_EXISTS
        ESLURMD_JOB_NOTRUNNING
        ESLURMD_STEP_SUSPENDED
        ESLURMD_STEP_NOTSUSPENDED
        ESLURMD_INVALID_SOCKET_NAME_LEN
        ESCRIPT_CHDIR_FAILED
        ESCRIPT_OPEN_OUTPUT_FAILED
        ESCRIPT_NON_ZERO_RETURN
        SLURM_PROTOCOL_SOCKET_IMPL_ZERO_RECV_LENGTH
        SLURM_PROTOCOL_SOCKET_IMPL_NEGATIVE_RECV_LENGTH
        SLURM_PROTOCOL_SOCKET_IMPL_NOT_ALL_DATA_SENT
        ESLURM_PROTOCOL_INCOMPLETE_PACKET
        SLURM_PROTOCOL_SOCKET_IMPL_TIMEOUT
        SLURM_PROTOCOL_SOCKET_ZERO_BYTES_SENT
        ESLURM_AUTH_CRED_INVALID
        ESLURM_AUTH_FOPEN_ERROR
        ESLURM_AUTH_NET_ERROR
        ESLURM_AUTH_UNABLE_TO_SIGN
        ESLURM_AUTH_BADARG
        ESLURM_AUTH_MEMORY
        ESLURM_AUTH_INVALID
        ESLURM_AUTH_UNPACK
        ESLURM_AUTH_SKIP
        ESLURM_DB_CONNECTION
        ESLURM_JOBS_RUNNING_ON_ASSOC
        ESLURM_CLUSTER_DELETED
        ESLURM_ONE_CHANGE
        ESLURM_BAD_NAME
        ESLURM_OVER_ALLOCATE
        ESLURM_RESULT_TOO_LARGE
        ESLURM_DB_QUERY_TOO_WIDE
        ESLURM_DB_CONNECTION_INVALID
        ESLURM_FED_CLUSTER_MAX_CNT
        ESLURM_FED_CLUSTER_MULTIPLE_ASSIGNMENT
        ESLURM_INVALID_CLUSTER_FEATURE
        ESLURM_JOB_NOT_FEDERATED
        ESLURM_INVALID_CLUSTER_NAME
        ESLURM_FED_JOB_LOCK
        ESLURM_FED_NO_VALID_CLUSTERS
        ESLURM_MISSING_TIME_LIMIT
        ESLURM_INVALID_KNL
        ESLURM_REST_INVALID_QUERY
        ESLURM_REST_FAIL_PARSING
        ESLURM_REST_INVALID_JOBS_DESC
        ESLURM_REST_EMPTY_RESULT
        ESLURM_DATA_PATH_NOT_FOUND
        ESLURM_DATA_PTR_NULL
        ESLURM_DATA_CONV_FAILED
        ESLURM_DATA_REGEX_COMPILE

    char* slurm_strerror(int errnum)

    void slurm_seterrno(int errnum)

    int slurm_get_errno()

    void slurm_perror(char* msg)


cdef extern from "slurm/slurm.h":

    enum:
        SLURM_VERSION_NUMBER



    uint8_t SYSTEM_DIMENSIONS
    uint8_t HIGHEST_DIMENSIONS

    uint8_t INFINITE8
    uint16_t INFINITE16
    uint32_t INFINITE
    uint64_t INFINITE64
    uint8_t NO_VAL8
    uint16_t NO_VAL16
    uint32_t NO_VAL
    uint64_t NO_VAL64
    uint64_t NO_CONSUME_VAL64
    uint16_t MAX_TASKS_PER_NODE
    uint32_t MAX_JOB_ID
    uint8_t MAX_FED_CLUSTERS

    uint32_t SLURM_PENDING_STEP
    uint32_t SLURM_BATCH_SCRIPT
    uint32_t SLURM_EXTERN_CONT

    uint8_t DEFAULT_EIO_SHUTDOWN_WAIT

    uint16_t SLURM_SSL_SIGNATURE_LENGTH

    uint8_t JOB_STATE_BASE
    uint32_t JOB_STATE_FLAGS
    uint16_t JOB_LAUNCH_FAILED
    uint16_t JOB_UPDATE_DB
    uint16_t JOB_REQUEUE
    uint16_t JOB_REQUEUE_HOLD
    uint16_t JOB_SPECIAL_EXIT
    uint16_t JOB_RESIZING
    uint16_t JOB_CONFIGURING
    uint16_t JOB_COMPLETING
    uint32_t JOB_STOPPED
    uint32_t JOB_RECONFIG_FAIL
    uint32_t JOB_POWER_UP_NODE
    uint32_t JOB_REVOKED
    uint32_t JOB_REQUEUE_FED
    uint32_t JOB_RESV_DEL_HOLD
    uint32_t JOB_SIGNALING
    uint32_t JOB_STAGE_OUT

    uint8_t READY_JOB_ERROR
    uint8_t READY_JOB_FATAL

    uint8_t MAIL_JOB_BEGIN
    uint8_t MAIL_JOB_END
    uint8_t MAIL_JOB_FAIL
    uint8_t MAIL_JOB_REQUEUE
    uint8_t MAIL_JOB_TIME100
    uint8_t MAIL_JOB_TIME90
    uint8_t MAIL_JOB_TIME80
    uint8_t MAIL_JOB_TIME50
    uint16_t MAIL_JOB_STAGE_OUT
    uint16_t MAIL_ARRAY_TASKS

    uint8_t ARRAY_TASK_REQUEUED

    uint32_t NICE_OFFSET

    uint8_t PARTITION_SUBMIT
    uint8_t PARTITION_SCHED

    uint8_t PARTITION_DOWN
    uint8_t PARTITION_UP
    uint8_t PARTITION_DRAIN
    uint8_t PARTITION_INACTIVE
    uint8_t PARTITION_ENFORCE_NONE
    uint8_t PARTITION_ENFORCE_ALL
    uint8_t PARTITION_ENFORCE_ANY

    uint8_t ACCT_GATHER_PROFILE_NOT_SET
    uint8_t ACCT_GATHER_PROFILE_NONE
    uint8_t ACCT_GATHER_PROFILE_ENERGY
    uint8_t ACCT_GATHER_PROFILE_TASK
    uint8_t ACCT_GATHER_PROFILE_LUSTRE
    uint8_t ACCT_GATHER_PROFILE_NETWORK
    uint32_t ACCT_GATHER_PROFILE_ALL

    uint16_t SLURM_DIST_STATE_BASE
    uint32_t SLURM_DIST_STATE_FLAGS
    uint32_t SLURM_DIST_PACK_NODES
    uint32_t SLURM_DIST_NO_PACK_NODES

    uint16_t SLURM_DIST_NODEMASK
    uint16_t SLURM_DIST_SOCKMASK
    uint16_t SLURM_DIST_COREMASK
    uint16_t SLURM_DIST_NODESOCKMASK

    uint8_t OPEN_MODE_APPEND
    uint8_t OPEN_MODE_TRUNCATE

    uint32_t CPU_FREQ_RANGE_FLAG
    uint32_t CPU_FREQ_LOW
    uint32_t CPU_FREQ_MEDIUM
    uint32_t CPU_FREQ_HIGH
    uint32_t CPU_FREQ_HIGHM1
    uint32_t CPU_FREQ_CONSERVATIVE
    uint32_t CPU_FREQ_ONDEMAND
    uint32_t CPU_FREQ_PERFORMANCE
    uint32_t CPU_FREQ_POWERSAVE
    uint32_t CPU_FREQ_USERSPACE
    uint32_t CPU_FREQ_GOV_MASK
    uint32_t CPU_FREQ_PERFORMANCE_OLD
    uint32_t CPU_FREQ_POWERSAVE_OLD
    uint32_t CPU_FREQ_USERSPACE_OLD
    uint32_t CPU_FREQ_ONDEMAND_OLD
    uint32_t CPU_FREQ_CONSERVATIVE_OLD

    uint8_t NODE_STATE_BASE
    uint32_t NODE_STATE_FLAGS
    uint8_t NODE_STATE_NET
    uint8_t NODE_STATE_RES
    uint8_t NODE_STATE_UNDRAIN
    uint8_t NODE_STATE_CLOUD
    uint16_t NODE_RESUME
    uint16_t NODE_STATE_DRAIN
    uint16_t NODE_STATE_COMPLETING
    uint16_t NODE_STATE_NO_RESPOND
    uint16_t NODE_STATE_POWER_SAVE
    uint16_t NODE_STATE_FAIL
    uint16_t NODE_STATE_POWER_UP
    uint16_t NODE_STATE_MAINT
    uint32_t NODE_STATE_REBOOT
    uint32_t NODE_STATE_CANCEL_REBOOT
    uint32_t NODE_STATE_POWERING_DOWN

    uint8_t SHOW_ALL
    uint8_t SHOW_DETAIL
    uint8_t SHOW_MIXED
    uint8_t SHOW_LOCAL
    uint8_t SHOW_SIBLING
    uint8_t SHOW_FEDERATION
    uint8_t SHOW_FUTURE

    uint8_t CR_CPU
    uint8_t CR_SOCKET
    uint8_t CR_CORE
    uint8_t CR_BOARD
    uint8_t CR_MEMORY
    uint8_t CR_OTHER_CONS_RES
    uint16_t CR_ONE_TASK_PER_CORE
    uint16_t CR_PACK_NODES
    uint16_t CR_OTHER_CONS_TRES
    uint16_t CR_CORE_DEFAULT_DIST_BLOCK
    uint16_t CR_LLN

    uint64_t MEM_PER_CPU
    uint16_t SHARED_FORCE

    uint8_t PRIVATE_DATA_JOBS
    uint8_t PRIVATE_DATA_NODES
    uint8_t PRIVATE_DATA_PARTITIONS
    uint8_t PRIVATE_DATA_USAGE
    uint8_t PRIVATE_DATA_USERS
    uint8_t PRIVATE_DATA_ACCOUNTS
    uint8_t PRIVATE_DATA_RESERVATIONS
    uint8_t PRIVATE_CLOUD_NODES
    uint16_t PRIVATE_DATA_EVENTS

    uint8_t PRIORITY_RESET_NONE
    uint8_t PRIORITY_RESET_NOW
    uint8_t PRIORITY_RESET_DAILY
    uint8_t PRIORITY_RESET_WEEKLY
    uint8_t PRIORITY_RESET_MONTHLY
    uint8_t PRIORITY_RESET_QUARTERLY
    uint8_t PRIORITY_RESET_YEARLY

    uint8_t PROP_PRIO_OFF
    uint8_t PROP_PRIO_ON
    uint8_t PROP_PRIO_NICER

    uint8_t PRIORITY_FLAGS_ACCRUE_ALWAYS
    uint8_t PRIORITY_FLAGS_MAX_TRES
    uint8_t PRIORITY_FLAGS_SIZE_RELATIVE
    uint8_t PRIORITY_FLAGS_DEPTH_OBLIVIOUS
    uint8_t PRIORITY_FLAGS_CALCULATE_RUNNING
    uint8_t PRIORITY_FLAGS_FAIR_TREE
    uint8_t PRIORITY_FLAGS_INCR_ONLY
    uint8_t PRIORITY_FLAGS_NO_NORMAL_ASSOC
    uint16_t PRIORITY_FLAGS_NO_NORMAL_PART
    uint16_t PRIORITY_FLAGS_NO_NORMAL_QOS
    uint16_t PRIORITY_FLAGS_NO_NORMAL_TRES

    uint8_t KILL_INV_DEP
    uint8_t NO_KILL_INV_DEP
    uint8_t HAS_STATE_DIR
    uint8_t BACKFILL_TEST
    uint8_t GRES_ENFORCE_BIND
    uint8_t TEST_NOW_ONLY
    uint8_t NODE_REBOOT
    uint16_t SPREAD_JOB
    uint16_t USE_MIN_NODES
    uint16_t JOB_KILL_HURRY
    uint16_t TRES_STR_CALC

    uint16_t SIB_JOB_FLUSH
    uint16_t HET_JOB_FLAG
    uint16_t JOB_NTASKS_SET
    uint16_t JOB_CPUS_SET
    uint32_t BF_WHOLE_NODE_TEST
    uint32_t TOP_PRIO_TMP

    uint32_t JOB_ACCRUE_OVER

    uint32_t GRES_DISABLE_BIND
    uint32_t JOB_WAS_RUNNING
    uint32_t RESET_ACCRUE_TIME


    uint32_t JOB_MEM_SET
    uint32_t JOB_RESIZED
    uint32_t USE_DEFAULT_ACCT
    uint32_t USE_DEFAULT_PART
    uint32_t USE_DEFAULT_QOS
    uint32_t USE_DEFAULT_WCKEY
    uint32_t JOB_DEPENDENT

    uint8_t X11_FORWARD_ALL
    uint8_t X11_FORWARD_BATCH
    uint8_t X11_FORWARD_FIRST
    uint8_t X11_FORWARD_LAST

    uint8_t ALLOC_SID_ADMIN_HOLD
    uint8_t ALLOC_SID_USER_HOLD

    uint8_t JOB_SHARED_NONE
    uint8_t JOB_SHARED_OK
    uint8_t JOB_SHARED_USER
    uint8_t JOB_SHARED_MCS

    uint8_t SLURM_POWER_FLAGS_LEVEL

    uint16_t CORE_SPEC_THREAD

    uint8_t JOB_DEF_CPU_PER_GPU
    uint8_t JOB_DEF_MEM_PER_GPU

    uint8_t PART_FLAG_DEFAULT
    uint8_t PART_FLAG_HIDDEN
    uint8_t PART_FLAG_NO_ROOT
    uint8_t PART_FLAG_ROOT_ONLY
    uint8_t PART_FLAG_REQ_RESV
    uint8_t PART_FLAG_LLN
    uint8_t PART_FLAG_EXCLUSIVE_USER

    uint16_t PART_FLAG_DEFAULT_CLR
    uint16_t PART_FLAG_HIDDEN_CLR
    uint16_t PART_FLAG_NO_ROOT_CLR
    uint16_t PART_FLAG_ROOT_ONLY_CLR
    uint16_t PART_FLAG_REQ_RESV_CLR
    uint16_t PART_FLAG_LLN_CLR
    uint16_t PART_FLAG_EXC_USER_CLR

    uint8_t RESERVE_FLAG_MAINT
    uint8_t RESERVE_FLAG_NO_MAINT
    uint8_t RESERVE_FLAG_DAILY
    uint8_t RESERVE_FLAG_NO_DAILY
    uint8_t RESERVE_FLAG_WEEKLY
    uint8_t RESERVE_FLAG_NO_WEEKLY
    uint8_t RESERVE_FLAG_IGN_JOBS
    uint8_t RESERVE_FLAG_NO_IGN_JOB

    uint16_t RESERVE_FLAG_ANY_NODES
    uint16_t RESERVE_FLAG_NO_ANY_NODES
    uint16_t RESERVE_FLAG_STATIC
    uint16_t RESERVE_FLAG_NO_STATIC
    uint16_t RESERVE_FLAG_PART_NODES
    uint16_t RESERVE_FLAG_NO_PART_NODES
    uint16_t RESERVE_FLAG_OVERLAP
    uint16_t RESERVE_FLAG_SPEC_NODES
    uint32_t RESERVE_FLAG_FIRST_CORES
    uint32_t RESERVE_FLAG_TIME_FLOAT
    uint32_t RESERVE_FLAG_REPLACE
    uint32_t RESERVE_FLAG_ALL_NODES
    uint32_t RESERVE_FLAG_PURGE_COMP
    uint32_t RESERVE_FLAG_WEEKDAY
    uint32_t RESERVE_FLAG_NO_WEEKDAY
    uint32_t RESERVE_FLAG_WEEKEND
    uint32_t RESERVE_FLAG_NO_WEEKEND
    uint32_t RESERVE_FLAG_FLEX
    uint32_t RESERVE_FLAG_NO_FLEX
    uint32_t RESERVE_FLAG_DUR_PLUS
    uint32_t RESERVE_FLAG_DUR_MINUS

    uint32_t RESERVE_FLAG_NO_HOLD_JOBS
    uint32_t RESERVE_FLAG_REPLACE_DOWN
    uint32_t RESERVE_FLAG_NO_PURGE_COMP

    uint8_t DEBUG_FLAG_SELECT_TYPE
    uint8_t DEBUG_FLAG_STEPS
    uint8_t DEBUG_FLAG_TRIGGERS
    uint8_t DEBUG_FLAG_CPU_BIND
    uint8_t DEBUG_FLAG_NO_CONF_HASH
    uint8_t DEBUG_FLAG_GRES
    uint8_t DEBUG_FLAG_TRES_NODE
    uint16_t DEBUG_FLAG_DATA
    uint16_t DEBUG_FLAG_WORKQ
    uint16_t DEBUG_FLAG_NET
    uint16_t DEBUG_FLAG_PRIO
    uint16_t DEBUG_FLAG_BACKFILL
    uint16_t DEBUG_FLAG_GANG
    uint16_t DEBUG_FLAG_RESERVATION
    uint16_t DEBUG_FLAG_FRONT_END
    uint32_t DEBUG_FLAG_NO_REALTIME
    uint32_t DEBUG_FLAG_SWITCH
    uint32_t DEBUG_FLAG_ENERGY
    uint32_t DEBUG_FLAG_EXT_SENSORS
    uint32_t DEBUG_FLAG_LICENSE
    uint32_t DEBUG_FLAG_PROFILE
    uint32_t DEBUG_FLAG_INTERCONNECT
    uint32_t DEBUG_FLAG_FILESYSTEM
    uint32_t DEBUG_FLAG_JOB_CONT
    uint32_t DEBUG_FLAG_TASK
    uint32_t DEBUG_FLAG_PROTOCOL
    uint32_t DEBUG_FLAG_BACKFILL_MAP
    uint32_t DEBUG_FLAG_TRACE_JOBS
    uint32_t DEBUG_FLAG_ROUTE
    uint32_t DEBUG_FLAG_DB_ASSOC
    uint32_t DEBUG_FLAG_DB_EVENT
    uint64_t DEBUG_FLAG_DB_JOB
    uint64_t DEBUG_FLAG_DB_QOS
    uint64_t DEBUG_FLAG_DB_QUERY
    uint64_t DEBUG_FLAG_DB_RESV
    uint64_t DEBUG_FLAG_DB_RES
    uint64_t DEBUG_FLAG_DB_STEP
    uint64_t DEBUG_FLAG_DB_USAGE
    uint64_t DEBUG_FLAG_DB_WCKEY
    uint64_t DEBUG_FLAG_BURST_BUF
    uint64_t DEBUG_FLAG_CPU_FREQ
    uint64_t DEBUG_FLAG_POWER
    uint64_t DEBUG_FLAG_TIME_CRAY
    uint64_t DEBUG_FLAG_DB_ARCHIVE
    uint64_t DEBUG_FLAG_DB_TRES
    uint64_t DEBUG_FLAG_ESEARCH
    uint64_t DEBUG_FLAG_NODE_FEATURES
    uint64_t DEBUG_FLAG_FEDR
    uint64_t DEBUG_FLAG_HETJOB
    uint64_t DEBUG_FLAG_ACCRUE
    uint64_t DEBUG_FLAG_POWER_SAVE
    uint64_t DEBUG_FLAG_AGENT
    uint64_t DEBUG_FLAG_DEPENDENCY

    uint8_t PREEMPT_MODE_OFF
    uint8_t PREEMPT_MODE_SUSPEND
    uint8_t PREEMPT_MODE_REQUEUE
    uint8_t PREEMPT_MODE_CANCEL
    uint16_t PREEMPT_MODE_GANG

    uint8_t RECONFIG_KEEP_PART_INFO
    uint8_t RECONFIG_KEEP_PART_STAT

    uint8_t HEALTH_CHECK_NODE_IDLE
    uint8_t HEALTH_CHECK_NODE_ALLOC
    uint8_t HEALTH_CHECK_NODE_MIXED
    uint16_t HEALTH_CHECK_CYCLE
    uint8_t HEALTH_CHECK_NODE_ANY

    uint8_t PROLOG_FLAG_ALLOC
    uint8_t PROLOG_FLAG_NOHOLD
    uint8_t PROLOG_FLAG_CONTAIN
    uint8_t PROLOG_FLAG_SERIAL
    uint8_t PROLOG_FLAG_X11

    uint8_t CTL_CONF_OR
    uint8_t CTL_CONF_SJC
    uint8_t CTL_CONF_DRJ
    uint8_t CTL_CONF_ASRU
    uint8_t CTL_CONF_PAM
    uint8_t CTL_CONF_WCKEY

    uint8_t LOG_FMT_ISO8601_MS
    uint8_t LOG_FMT_ISO8601
    uint8_t LOG_FMT_RFC5424_MS
    uint8_t LOG_FMT_RFC5424
    uint8_t LOG_FMT_CLOCK
    uint8_t LOG_FMT_SHORT
    uint8_t LOG_FMT_THREAD_ID

    uint8_t STAT_COMMAND_RESET
    uint8_t STAT_COMMAND_GET

    uint8_t TRIGGER_FLAG_PERM

    uint8_t TRIGGER_RES_TYPE_JOB
    uint8_t TRIGGER_RES_TYPE_NODE
    uint8_t TRIGGER_RES_TYPE_SLURMCTLD
    uint8_t TRIGGER_RES_TYPE_SLURMDBD
    uint8_t TRIGGER_RES_TYPE_DATABASE
    uint8_t TRIGGER_RES_TYPE_FRONT_END
    uint8_t TRIGGER_RES_TYPE_OTHER

    uint8_t TRIGGER_TYPE_UP
    uint8_t TRIGGER_TYPE_DOWN
    uint8_t TRIGGER_TYPE_FAIL
    uint8_t TRIGGER_TYPE_TIME
    uint8_t TRIGGER_TYPE_FINI
    uint8_t TRIGGER_TYPE_RECONFIG
    uint8_t TRIGGER_TYPE_IDLE
    uint16_t TRIGGER_TYPE_DRAINED
    uint16_t TRIGGER_TYPE_PRI_CTLD_FAIL
    uint16_t TRIGGER_TYPE_PRI_CTLD_RES_OP
    uint16_t TRIGGER_TYPE_PRI_CTLD_RES_CTRL
    uint16_t TRIGGER_TYPE_PRI_CTLD_ACCT_FULL
    uint16_t TRIGGER_TYPE_BU_CTLD_FAIL
    uint16_t TRIGGER_TYPE_BU_CTLD_RES_OP
    uint16_t TRIGGER_TYPE_BU_CTLD_AS_CTRL
    uint32_t TRIGGER_TYPE_PRI_DBD_FAIL
    uint32_t TRIGGER_TYPE_PRI_DBD_RES_OP
    uint32_t TRIGGER_TYPE_PRI_DB_FAIL
    uint32_t TRIGGER_TYPE_PRI_DB_RES_OP
    uint32_t TRIGGER_TYPE_BURST_BUFFER

    uint8_t KILL_JOB_BATCH
    uint8_t KILL_JOB_ARRAY
    uint8_t KILL_STEPS_ONLY
    uint8_t KILL_FULL_JOB
    uint8_t KILL_FED_REQUEUE
    uint8_t KILL_HURRY
    uint8_t KILL_OOM
    uint8_t KILL_NO_SIBS
    uint16_t KILL_JOB_RESV

    uint16_t WARN_SENT

    uint8_t BB_FLAG_DISABLE_PERSISTENT
    uint8_t BB_FLAG_ENABLE_PERSISTENT
    uint8_t BB_FLAG_EMULATE_CRAY
    uint8_t BB_FLAG_PRIVATE_DATA
    uint8_t BB_FLAG_TEARDOWN_FAILURE
    uint64_t BB_SIZE_IN_NODES
    uint8_t BB_STATE_PENDING
    uint8_t BB_STATE_ALLOCATING
    uint8_t BB_STATE_ALLOCATED
    uint8_t BB_STATE_DELETING
    uint8_t BB_STATE_DELETED
    uint8_t BB_STATE_STAGING_IN
    uint8_t BB_STATE_STAGED_IN
    uint8_t BB_STATE_PRE_RUN
    uint8_t BB_STATE_ALLOC_REVOKE
    uint8_t BB_STATE_RUNNING
    uint8_t BB_STATE_SUSPEND
    uint8_t BB_STATE_POST_RUN
    uint8_t BB_STATE_STAGING_OUT
    uint8_t BB_STATE_STAGED_OUT
    uint8_t BB_STATE_TEARDOWN
    uint8_t BB_STATE_TEARDOWN_FAIL
    uint8_t BB_STATE_COMPLETE

    uint8_t ASSOC_MGR_INFO_FLAG_ASSOC
    uint8_t ASSOC_MGR_INFO_FLAG_USERS
    uint8_t ASSOC_MGR_INFO_FLAG_QOS


    ctypedef sockaddr_storage slurm_addr_t

    ctypedef slurmdb_cluster_rec slurmdb_cluster_rec_t

    ctypedef slurm_job_credential slurm_cred_t

    ctypedef switch_jobinfo switch_jobinfo_t

    ctypedef job_resources job_resources_t

    ctypedef select_jobinfo select_jobinfo_t

    ctypedef select_nodeinfo select_nodeinfo_t

    ctypedef jobacctinfo jobacctinfo_t

    ctypedef allocation_msg_thread allocation_msg_thread_t

    ctypedef sbcast_cred sbcast_cred_t

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
        JOB_OOM
        JOB_END

    ctypedef enum job_node_ready_state_t:
        READY_NONE
        READY_NODE_STATE
        READY_JOB_STATE
        READY_PROLOG_STATE

    cdef enum job_state_reason:
        WAIT_NO_REASON
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
        FAIL_DEFER
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
        WAIT_FED_JOB_LOCK
        FAIL_OOM
        WAIT_PN_MEM_LIMIT
        WAIT_ASSOC_GRP_BILLING
        WAIT_ASSOC_GRP_BILLING_MIN
        WAIT_ASSOC_GRP_BILLING_RUN_MIN
        WAIT_ASSOC_MAX_BILLING_PER_JOB
        WAIT_ASSOC_MAX_BILLING_PER_NODE
        WAIT_ASSOC_MAX_BILLING_MINS_PER_JOB
        WAIT_QOS_GRP_BILLING
        WAIT_QOS_GRP_BILLING_MIN
        WAIT_QOS_GRP_BILLING_RUN_MIN
        WAIT_QOS_MAX_BILLING_PER_JOB
        WAIT_QOS_MAX_BILLING_PER_NODE
        WAIT_QOS_MAX_BILLING_PER_USER
        WAIT_QOS_MAX_BILLING_MINS_PER_JOB
        WAIT_QOS_MAX_BILLING_PER_ACCT
        WAIT_QOS_MIN_BILLING
        WAIT_RESV_DELETED

    cdef enum job_acct_types:
        JOB_START
        JOB_STEP
        JOB_SUSPEND
        JOB_TERMINATED

    cdef enum auth_plugin_type:
        AUTH_PLUGIN_NONE
        AUTH_PLUGIN_MUNGE
        AUTH_PLUGIN_JWT

    cdef enum select_plugin_type:
        SELECT_PLUGIN_CONS_RES
        SELECT_PLUGIN_LINEAR
        SELECT_PLUGIN_SERIAL
        SELECT_PLUGIN_CRAY_LINEAR
        SELECT_PLUGIN_CRAY_CONS_RES
        SELECT_PLUGIN_CONS_TRES
        SELECT_PLUGIN_CRAY_CONS_TRES

    cdef enum switch_plugin_type:
        SWITCH_PLUGIN_NONE
        SWITCH_PLUGIN_GENERIC
        SWITCH_PLUGIN_CRAY

    cdef enum select_jobdata_type:
        SELECT_JOBDATA_PAGG_ID
        SELECT_JOBDATA_PTR
        SELECT_JOBDATA_CLEANING
        SELECT_JOBDATA_NETWORK
        SELECT_JOBDATA_RELEASED

    cdef enum select_nodedata_type:
        SELECT_NODEDATA_SUBCNT
        SELECT_NODEDATA_PTR
        SELECT_NODEDATA_MEM_ALLOC
        SELECT_NODEDATA_TRES_ALLOC_FMT_STR
        SELECT_NODEDATA_TRES_ALLOC_WEIGHTED

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
        JOBACCT_DATA_TOT_VSIZE
        JOBACCT_DATA_TOT_RSS

    cdef enum acct_energy_type:
        ENERGY_DATA_JOULES_TASK
        ENERGY_DATA_STRUCT
        ENERGY_DATA_RECONFIG
        ENERGY_DATA_PROFILE
        ENERGY_DATA_LAST_POLL
        ENERGY_DATA_SENSOR_CNT
        ENERGY_DATA_NODE_ENERGY
        ENERGY_DATA_NODE_ENERGY_UP
        ENERGY_DATA_STEP_PTR

    cdef enum task_dist_states:
        SLURM_DIST_CYCLIC
        SLURM_DIST_BLOCK
        SLURM_DIST_ARBITRARY
        SLURM_DIST_PLANE
        SLURM_DIST_CYCLIC_CYCLIC
        SLURM_DIST_CYCLIC_BLOCK
        SLURM_DIST_CYCLIC_CFULL
        SLURM_DIST_BLOCK_CYCLIC
        SLURM_DIST_BLOCK_BLOCK
        SLURM_DIST_BLOCK_CFULL
        SLURM_DIST_CYCLIC_CYCLIC_CYCLIC
        SLURM_DIST_CYCLIC_CYCLIC_BLOCK
        SLURM_DIST_CYCLIC_CYCLIC_CFULL
        SLURM_DIST_CYCLIC_BLOCK_CYCLIC
        SLURM_DIST_CYCLIC_BLOCK_BLOCK
        SLURM_DIST_CYCLIC_BLOCK_CFULL
        SLURM_DIST_CYCLIC_CFULL_CYCLIC
        SLURM_DIST_CYCLIC_CFULL_BLOCK
        SLURM_DIST_CYCLIC_CFULL_CFULL
        SLURM_DIST_BLOCK_CYCLIC_CYCLIC
        SLURM_DIST_BLOCK_CYCLIC_BLOCK
        SLURM_DIST_BLOCK_CYCLIC_CFULL
        SLURM_DIST_BLOCK_BLOCK_CYCLIC
        SLURM_DIST_BLOCK_BLOCK_BLOCK
        SLURM_DIST_BLOCK_BLOCK_CFULL
        SLURM_DIST_BLOCK_CFULL_CYCLIC
        SLURM_DIST_BLOCK_CFULL_BLOCK
        SLURM_DIST_BLOCK_CFULL_CFULL
        SLURM_DIST_NODECYCLIC
        SLURM_DIST_NODEBLOCK
        SLURM_DIST_SOCKCYCLIC
        SLURM_DIST_SOCKBLOCK
        SLURM_DIST_SOCKCFULL
        SLURM_DIST_CORECYCLIC
        SLURM_DIST_COREBLOCK
        SLURM_DIST_CORECFULL
        SLURM_DIST_NO_LLLP
        SLURM_DIST_UNKNOWN

    ctypedef task_dist_states task_dist_states_t

    cdef enum cpu_bind_type:
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
        CPU_AUTO_BIND_TO_THREADS
        CPU_AUTO_BIND_TO_CORES
        CPU_AUTO_BIND_TO_SOCKETS
        SLURMD_OFF_SPEC
        CPU_BIND_OFF

    ctypedef cpu_bind_type cpu_bind_type_t

    cdef enum mem_bind_type:
        MEM_BIND_VERBOSE
        MEM_BIND_NONE
        MEM_BIND_RANK
        MEM_BIND_MAP
        MEM_BIND_MASK
        MEM_BIND_LOCAL
        MEM_BIND_SORT
        MEM_BIND_PREFER

    ctypedef mem_bind_type mem_bind_type_t

    cdef enum accel_bind_type:
        ACCEL_BIND_VERBOSE
        ACCEL_BIND_CLOSEST_GPU
        ACCEL_BIND_CLOSEST_MIC
        ACCEL_BIND_CLOSEST_NIC

    ctypedef accel_bind_type accel_bind_type_t

    cdef enum node_states:
        NODE_STATE_UNKNOWN
        NODE_STATE_DOWN
        NODE_STATE_IDLE
        NODE_STATE_ALLOCATED
        NODE_STATE_ERROR
        NODE_STATE_MIXED
        NODE_STATE_FUTURE
        NODE_STATE_END

    cdef enum ctx_keys:
        SLURM_STEP_CTX_STEPID
        SLURM_STEP_CTX_TASKS
        SLURM_STEP_CTX_TID
        SLURM_STEP_CTX_RESP
        SLURM_STEP_CTX_CRED
        SLURM_STEP_CTX_SWITCH_JOB
        SLURM_STEP_CTX_NUM_HOSTS
        SLURM_STEP_CTX_HOST
        SLURM_STEP_CTX_JOBID
        SLURM_STEP_CTX_USER_MANAGED_SOCKETS
        SLURM_STEP_CTX_NODE_LIST
        SLURM_STEP_CTX_TIDS
        SLURM_STEP_CTX_DEF_CPU_BIND_TYPE
        SLURM_STEP_CTX_STEP_HET_COMP
        SLURM_STEP_CTX_STEP_ID

    ctypedef enum step_spec_flags_t:
        SSF_NONE
        SSF_EXCLUSIVE
        SSF_NO_KILL
        SSF_OVERCOMMIT
        SSF_WHOLE
        SSF_INTERACTIVE

    void slurm_init(char* conf)

    void slurm_fini()

    ctypedef hostlist* hostlist_t

    hostlist_t slurm_hostlist_create(char* hostlist)

    int slurm_hostlist_count(hostlist_t hl)

    void slurm_hostlist_destroy(hostlist_t hl)

    int slurm_hostlist_find(hostlist_t hl, char* hostname)

    int slurm_hostlist_push(hostlist_t hl, char* hosts)

    int slurm_hostlist_push_host(hostlist_t hl, char* host)

    ssize_t slurm_hostlist_ranged_string(hostlist_t hl, size_t n, char* buf)

    char* slurm_hostlist_ranged_string_malloc(hostlist_t hl)

    char* slurm_hostlist_ranged_string_xmalloc(hostlist_t hl)

    char* slurm_hostlist_shift(hostlist_t hl)

    void slurm_hostlist_uniq(hostlist_t hl)

    ctypedef xlist* List

    ctypedef listIterator* ListIterator

    ctypedef void (*ListDelF)(void* x)

    ctypedef int (*ListCmpF)(void* x, void* y)

    ctypedef int (*ListFindF)(void* x, void* key)

    ctypedef int (*ListForF)(void* x, void* arg)

    void* slurm_list_append(List l, void* x)

    int slurm_list_count(List l)

    List slurm_list_create(ListDelF f)

    void slurm_list_destroy(List l)

    void* slurm_list_find(ListIterator i, ListFindF f, void* key)

    int slurm_list_is_empty(List l)

    ListIterator slurm_list_iterator_create(List l)

    void slurm_list_iterator_reset(ListIterator i)

    void slurm_list_iterator_destroy(ListIterator i)

    void* slurm_list_next(ListIterator i)

    void slurm_list_sort(List l, ListCmpF f)

    void* slurm_list_pop(List l)

    ctypedef int64_t bitstr_t

    ctypedef bitstr_t bitoff_t

    cdef struct dynamic_plugin_data:
        void* data
        uint32_t plugin_id

    ctypedef dynamic_plugin_data dynamic_plugin_data_t

    cdef struct acct_gather_energy:
        uint32_t ave_watts
        uint64_t base_consumed_energy
        uint64_t consumed_energy
        uint32_t current_watts
        uint64_t previous_consumed_energy
        time_t poll_time

    ctypedef acct_gather_energy acct_gather_energy_t

    cdef struct ext_sensors_data:
        uint64_t consumed_energy
        uint32_t temperature
        time_t energy_update_time
        uint32_t current_watts

    ctypedef ext_sensors_data ext_sensors_data_t

    cdef struct power_mgmt_data:
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

    cdef struct job_descriptor:
        char* account
        char* acctg_freq
        char* admin_comment
        char* alloc_node
        uint16_t alloc_resp_port
        uint32_t alloc_sid
        uint32_t argc
        char** argv
        char* array_inx
        void* array_bitmap
        char* batch_features
        time_t begin_time
        uint32_t bitflags
        char* burst_buffer
        char* clusters
        char* cluster_features
        char* comment
        uint16_t contiguous
        uint16_t core_spec
        char* cpu_bind
        uint16_t cpu_bind_type
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        char* cpus_per_tres
        void* crontab_entry
        time_t deadline
        uint32_t delay_boot
        char* dependency
        time_t end_time
        char** environment
        uint32_t env_size
        char* extra
        char* exc_nodes
        char* features
        uint64_t fed_siblings_active
        uint64_t fed_siblings_viable
        uint32_t group_id
        uint32_t het_job_offset
        uint16_t immediate
        uint32_t job_id
        char* job_id_str
        uint16_t kill_on_node_fail
        char* licenses
        uint16_t mail_type
        char* mail_user
        char* mcs_label
        char* mem_bind
        uint16_t mem_bind_type
        char* mem_per_tres
        char* name
        char* network
        uint32_t nice
        uint32_t num_tasks
        uint8_t open_mode
        char* origin_cluster
        uint16_t other_port
        uint8_t overcommit
        char* partition
        uint16_t plane_size
        uint8_t power_flags
        uint32_t priority
        uint32_t profile
        char* qos
        uint16_t reboot
        char* resp_host
        uint16_t restart_cnt
        char* req_nodes
        uint16_t requeue
        char* reservation
        char* script
        void* script_buf
        uint16_t shared
        uint32_t site_factor
        char** spank_job_env
        uint32_t spank_job_env_size
        uint32_t task_dist
        uint32_t time_limit
        uint32_t time_min
        char* tres_bind
        char* tres_freq
        char* tres_per_job
        char* tres_per_node
        char* tres_per_socket
        char* tres_per_task
        uint32_t user_id
        uint16_t wait_all_nodes
        uint16_t warn_flags
        uint16_t warn_signal
        uint16_t warn_time
        char* work_dir
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
        uint16_t ntasks_per_tres
        uint16_t pn_min_cpus
        uint64_t pn_min_memory
        uint32_t pn_min_tmp_disk
        uint32_t req_switch
        dynamic_plugin_data_t* select_jobinfo
        char* std_err
        char* std_in
        char* std_out
        uint64_t* tres_req_cnt
        uint32_t wait4switch
        char* wckey
        uint16_t x11
        char* x11_magic_cookie
        char* x11_target
        uint16_t x11_target_port

    ctypedef job_descriptor job_desc_msg_t

    cdef struct job_info:
        char* account
        time_t accrue_time
        char* admin_comment
        char* alloc_node
        uint32_t alloc_sid
        void* array_bitmap
        uint32_t array_job_id
        uint32_t array_task_id
        uint32_t array_max_tasks
        char* array_task_str
        uint32_t assoc_id
        char* batch_features
        uint16_t batch_flag
        char* batch_host
        uint32_t bitflags
        uint16_t boards_per_node
        char* burst_buffer
        char* burst_buffer_state
        char* cluster
        char* cluster_features
        char* command
        char* comment
        uint16_t contiguous
        uint16_t core_spec
        uint16_t cores_per_socket
        double billable_tres
        uint16_t cpus_per_task
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        char* cpus_per_tres
        char* cronspec
        time_t deadline
        uint32_t delay_boot
        char* dependency
        uint32_t derived_ec
        time_t eligible_time
        time_t end_time
        char* exc_nodes
        int32_t* exc_node_inx
        uint32_t exit_code
        char* features
        char* fed_origin_str
        uint64_t fed_siblings_active
        char* fed_siblings_active_str
        uint64_t fed_siblings_viable
        char* fed_siblings_viable_str
        uint32_t gres_detail_cnt
        char** gres_detail_str
        char* gres_total
        uint32_t group_id
        uint32_t het_job_id
        char* het_job_id_set
        uint32_t het_job_offset
        uint32_t job_id
        job_resources_t* job_resrcs
        uint32_t job_state
        time_t last_sched_eval
        char* licenses
        uint16_t mail_type
        char* mail_user
        uint32_t max_cpus
        uint32_t max_nodes
        char* mcs_label
        char* mem_per_tres
        char* name
        char* network
        char* nodes
        uint32_t nice
        int32_t* node_inx
        uint16_t ntasks_per_core
        uint16_t ntasks_per_tres
        uint16_t ntasks_per_node
        uint16_t ntasks_per_socket
        uint16_t ntasks_per_board
        uint32_t num_cpus
        uint32_t num_nodes
        uint32_t num_tasks
        char* partition
        uint64_t pn_min_memory
        uint16_t pn_min_cpus
        uint32_t pn_min_tmp_disk
        uint8_t power_flags
        time_t preempt_time
        time_t preemptable_time
        time_t pre_sus_time
        uint32_t priority
        uint32_t profile
        char* qos
        uint8_t reboot
        char* req_nodes
        int32_t* req_node_inx
        uint32_t req_switch
        uint16_t requeue
        time_t resize_time
        uint16_t restart_cnt
        char* resv_name
        char* sched_nodes
        dynamic_plugin_data_t* select_jobinfo
        uint16_t shared
        uint16_t show_flags
        uint32_t site_factor
        uint16_t sockets_per_board
        uint16_t sockets_per_node
        time_t start_time
        uint16_t start_protocol_ver
        char* state_desc
        uint16_t state_reason
        char* std_err
        char* std_in
        char* std_out
        time_t submit_time
        time_t suspend_time
        char* system_comment
        uint32_t time_limit
        uint32_t time_min
        uint16_t threads_per_core
        char* tres_bind
        char* tres_freq
        char* tres_per_job
        char* tres_per_node
        char* tres_per_socket
        char* tres_per_task
        char* tres_req_str
        char* tres_alloc_str
        uint32_t user_id
        char* user_name
        uint32_t wait4switch
        char* wckey
        char* work_dir

    ctypedef job_info slurm_job_info_t

    cdef struct priority_factors_object:
        char* cluster_name
        uint32_t job_id
        char* partition
        uint32_t user_id
        double priority_age
        double priority_assoc
        double priority_fs
        double priority_js
        double priority_part
        double priority_qos
        double direct_prio
        uint32_t priority_site
        double* priority_tres
        uint32_t tres_cnt
        char** tres_names
        double* tres_weights
        uint32_t nice

    ctypedef priority_factors_object priority_factors_object_t

    cdef struct priority_factors_response_msg:
        List priority_factors_list

    ctypedef priority_factors_response_msg priority_factors_response_msg_t

    ctypedef slurm_job_info_t job_info_t

    cdef struct job_info_msg:
        time_t last_update
        uint32_t record_count
        slurm_job_info_t* job_array

    ctypedef job_info_msg job_info_msg_t

    cdef struct step_update_request_msg:
        time_t end_time
        uint32_t exit_code
        uint32_t job_id
        jobacctinfo_t* jobacct
        char* name
        time_t start_time
        uint32_t step_id
        uint32_t time_limit

    ctypedef step_update_request_msg step_update_request_msg_t

    ctypedef struct slurm_step_layout_req_t:
        char* node_list
        uint16_t* cpus_per_node
        uint32_t* cpu_count_reps
        uint32_t num_hosts
        uint32_t num_tasks
        uint16_t* cpus_per_task
        uint32_t* cpus_task_reps
        uint32_t task_dist
        uint16_t plane_size

    cdef struct slurm_step_layout:
        char* front_end
        uint32_t node_cnt
        char* node_list
        uint16_t plane_size
        uint16_t start_protocol_ver
        uint16_t* tasks
        uint32_t task_cnt
        uint32_t task_dist
        uint32_t** tids

    ctypedef slurm_step_layout slurm_step_layout_t

    cdef struct slurm_step_id_msg:
        uint32_t job_id
        uint32_t step_het_comp
        uint32_t step_id

    ctypedef slurm_step_id_msg slurm_step_id_t

    cdef struct _slurm_step_io_fds_t_slurm_step_io_fds_t_slurm_step_io_fds_input_s:
        int fd
        uint32_t taskid
        uint32_t nodeid

    cdef struct _slurm_step_io_fds_t_slurm_step_io_fds_t_slurm_step_io_fds_out_s:
        int fd
        uint32_t taskid
        uint32_t nodeid

    cdef struct _slurm_step_io_fds_t_slurm_step_io_fds_t_slurm_step_io_fds_err_s:
        int fd
        uint32_t taskid
        uint32_t nodeid

    cdef struct slurm_step_io_fds:
        _slurm_step_io_fds_t_slurm_step_io_fds_t_slurm_step_io_fds_input_s input
        _slurm_step_io_fds_t_slurm_step_io_fds_t_slurm_step_io_fds_out_s out
        _slurm_step_io_fds_t_slurm_step_io_fds_t_slurm_step_io_fds_err_s err

    ctypedef slurm_step_io_fds slurm_step_io_fds_t

    cdef struct launch_tasks_response_msg:
        uint32_t return_code
        char* node_name
        uint32_t srun_node_id
        uint32_t count_of_pids
        uint32_t* local_pids
        slurm_step_id_t step_id
        uint32_t* task_ids

    ctypedef launch_tasks_response_msg launch_tasks_response_msg_t

    cdef struct task_ext_msg:
        uint32_t num_tasks
        uint32_t* task_id_list
        uint32_t return_code
        slurm_step_id_t step_id

    ctypedef task_ext_msg task_exit_msg_t

    ctypedef struct net_forward_msg_t:
        uint32_t job_id
        uint32_t flags
        uint16_t port
        char* target

    cdef struct srun_ping_msg:
        uint32_t job_id

    ctypedef srun_ping_msg srun_ping_msg_t

    ctypedef slurm_step_id_t srun_job_complete_msg_t

    cdef struct srun_timeout_msg:
        slurm_step_id_t step_id
        time_t timeout

    ctypedef srun_timeout_msg srun_timeout_msg_t

    cdef struct srun_user_msg:
        uint32_t job_id
        char* msg

    ctypedef srun_user_msg srun_user_msg_t

    cdef struct srun_node_fail_msg:
        char* nodelist
        slurm_step_id_t step_id

    ctypedef srun_node_fail_msg srun_node_fail_msg_t

    cdef struct srun_step_missing_msg:
        char* nodelist
        slurm_step_id_t step_id

    ctypedef srun_step_missing_msg srun_step_missing_msg_t

    cdef enum suspend_opts:
        SUSPEND_JOB
        RESUME_JOB

    cdef struct suspend_msg:
        uint16_t op
        uint32_t job_id
        char* job_id_str

    ctypedef suspend_msg suspend_msg_t

    cdef struct top_job_msg:
        uint16_t op
        uint32_t job_id
        char* job_id_str

    ctypedef top_job_msg top_job_msg_t

    ctypedef struct slurm_step_ctx_params_t:
        uint32_t cpu_count
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        uint16_t ntasks_per_tres
        char* cpus_per_tres
        char* exc_nodes
        char* features
        uint32_t flags
        uint16_t immediate
        uint64_t pn_min_memory
        char* name
        char* network
        uint32_t profile
        uint32_t min_nodes
        uint32_t max_nodes
        char* mem_per_tres
        char* node_list
        uint16_t plane_size
        uint16_t relative
        uint16_t resv_port_cnt
        char* step_het_grps
        slurm_step_id_t step_id
        uint32_t step_het_comp_cnt
        uint32_t task_count
        uint32_t task_dist
        uint32_t time_limit
        uint16_t threads_per_core
        char* tres_bind
        char* tres_freq
        char* tres_per_step
        char* tres_per_node
        char* tres_per_socket
        char* tres_per_task
        uid_t uid
        uint16_t verbose_level

    ctypedef struct slurm_step_launch_params_t:
        char* alias_list
        uint32_t argc
        char** argv
        uint32_t envc
        char** env
        char* cwd
        bool user_managed_io
        uint32_t msg_timeout
        uint16_t ntasks_per_board
        uint16_t ntasks_per_core
        uint16_t ntasks_per_tres
        uint16_t ntasks_per_socket
        bool buffered_stdio
        bool labelio
        char* remote_output_filename
        char* remote_error_filename
        char* remote_input_filename
        slurm_step_io_fds_t local_fds
        uint32_t gid
        bool multi_prog
        bool no_alloc
        uint32_t slurmd_debug
        uint32_t het_job_node_offset
        uint32_t het_job_id
        uint32_t het_job_nnodes
        uint32_t het_job_ntasks
        uint32_t het_job_step_cnt
        uint16_t* het_job_task_cnts
        uint32_t** het_job_tids
        uint32_t* het_job_tid_offsets
        uint32_t het_job_offset
        uint32_t het_job_task_offset
        char* het_job_node_list
        bool parallel_debug
        uint32_t profile
        char* task_prolog
        char* task_epilog
        uint16_t cpu_bind_type
        char* cpu_bind
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        uint16_t mem_bind_type
        char* mem_bind
        uint16_t accel_bind_type
        uint16_t max_sockets
        uint16_t max_cores
        uint16_t max_threads
        uint16_t cpus_per_task
        uint16_t threads_per_core
        uint32_t task_dist
        char* partition
        bool preserve_env
        char* mpi_plugin_name
        uint8_t open_mode
        char* acctg_freq
        bool pty
        char** spank_job_env
        uint32_t spank_job_env_size
        char* tres_bind
        char* tres_freq

    ctypedef void (*_slurm_step_launch_callbacks_t_slurm_step_launch_callbacks_t_step_complete_ft)(srun_job_complete_msg_t*)

    ctypedef void (*_slurm_step_launch_callbacks_t_slurm_step_launch_callbacks_t_step_signal_ft)(int)

    ctypedef void (*_slurm_step_launch_callbacks_t_slurm_step_launch_callbacks_t_step_timeout_ft)(srun_timeout_msg_t*)

    ctypedef void (*_slurm_step_launch_callbacks_t_slurm_step_launch_callbacks_t_task_start_ft)(launch_tasks_response_msg_t*)

    ctypedef void (*_slurm_step_launch_callbacks_t_slurm_step_launch_callbacks_t_task_finish_ft)(task_exit_msg_t*)

    ctypedef struct slurm_step_launch_callbacks_t:
        _slurm_step_launch_callbacks_t_slurm_step_launch_callbacks_t_step_complete_ft step_complete
        _slurm_step_launch_callbacks_t_slurm_step_launch_callbacks_t_step_signal_ft step_signal
        _slurm_step_launch_callbacks_t_slurm_step_launch_callbacks_t_step_timeout_ft step_timeout
        _slurm_step_launch_callbacks_t_slurm_step_launch_callbacks_t_task_start_ft task_start
        _slurm_step_launch_callbacks_t_slurm_step_launch_callbacks_t_task_finish_ft task_finish

    ctypedef void (*_slurm_allocation_callbacks_t_slurm_allocation_callbacks_t_job_complete_ft)(srun_job_complete_msg_t*)

    ctypedef void (*_slurm_allocation_callbacks_t_slurm_allocation_callbacks_t_timeout_ft)(srun_timeout_msg_t*)

    ctypedef void (*_slurm_allocation_callbacks_t_slurm_allocation_callbacks_t_user_msg_ft)(srun_user_msg_t*)

    ctypedef void (*_slurm_allocation_callbacks_t_slurm_allocation_callbacks_t_node_fail_ft)(srun_node_fail_msg_t*)

    ctypedef void (*_slurm_allocation_callbacks_t_slurm_allocation_callbacks_t_job_suspend_ft)(suspend_msg_t*)

    ctypedef struct slurm_allocation_callbacks_t:
        _slurm_allocation_callbacks_t_slurm_allocation_callbacks_t_job_complete_ft job_complete
        _slurm_allocation_callbacks_t_slurm_allocation_callbacks_t_timeout_ft timeout
        _slurm_allocation_callbacks_t_slurm_allocation_callbacks_t_user_msg_ft user_msg
        _slurm_allocation_callbacks_t_slurm_allocation_callbacks_t_node_fail_ft node_fail
        _slurm_allocation_callbacks_t_slurm_allocation_callbacks_t_job_suspend_ft job_suspend

    ctypedef void (*_slurm_trigger_callbacks_t_slurm_trigger_callbacks_t_acct_full_ft)()

    ctypedef void (*_slurm_trigger_callbacks_t_slurm_trigger_callbacks_t_dbd_fail_ft)()

    ctypedef void (*_slurm_trigger_callbacks_t_slurm_trigger_callbacks_t_dbd_resumed_ft)()

    ctypedef void (*_slurm_trigger_callbacks_t_slurm_trigger_callbacks_t_db_fail_ft)()

    ctypedef void (*_slurm_trigger_callbacks_t_slurm_trigger_callbacks_t_db_resumed_ft)()

    ctypedef struct slurm_trigger_callbacks_t:
        _slurm_trigger_callbacks_t_slurm_trigger_callbacks_t_acct_full_ft acct_full
        _slurm_trigger_callbacks_t_slurm_trigger_callbacks_t_dbd_fail_ft dbd_fail
        _slurm_trigger_callbacks_t_slurm_trigger_callbacks_t_dbd_resumed_ft dbd_resumed
        _slurm_trigger_callbacks_t_slurm_trigger_callbacks_t_db_fail_ft db_fail
        _slurm_trigger_callbacks_t_slurm_trigger_callbacks_t_db_resumed_ft db_resumed

    ctypedef struct job_step_info_t:
        uint32_t array_job_id
        uint32_t array_task_id
        char* cluster
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        char* cpus_per_tres
        char* mem_per_tres
        char* name
        char* network
        char* nodes
        int32_t* node_inx
        uint32_t num_cpus
        uint32_t num_tasks
        char* partition
        char* resv_ports
        time_t run_time
        dynamic_plugin_data_t* select_jobinfo
        char* srun_host
        uint32_t srun_pid
        time_t start_time
        uint16_t start_protocol_ver
        uint32_t state
        slurm_step_id_t step_id
        uint32_t task_dist
        uint32_t time_limit
        char* tres_alloc_str
        char* tres_bind
        char* tres_freq
        char* tres_per_step
        char* tres_per_node
        char* tres_per_socket
        char* tres_per_task
        uint32_t user_id

    cdef struct job_step_info_response_msg:
        time_t last_update
        uint32_t job_step_count
        job_step_info_t* job_steps

    ctypedef job_step_info_response_msg job_step_info_response_msg_t

    ctypedef struct job_step_pids_t:
        char* node_name
        uint32_t* pid
        uint32_t pid_cnt

    ctypedef struct job_step_pids_response_msg_t:
        List pid_list
        slurm_step_id_t step_id

    ctypedef struct job_step_stat_t:
        jobacctinfo_t* jobacct
        uint32_t num_tasks
        uint32_t return_code
        job_step_pids_t* step_pids

    ctypedef struct job_step_stat_response_msg_t:
        List stats_list
        slurm_step_id_t step_id

    cdef struct node_info:
        char* arch
        char* bcast_address
        uint16_t boards
        time_t boot_time
        char* cluster_name
        uint16_t cores
        uint16_t core_spec_cnt
        uint32_t cpu_bind
        uint32_t cpu_load
        uint64_t free_mem
        uint16_t cpus
        char* cpu_spec_list
        acct_gather_energy_t* energy
        ext_sensors_data_t* ext_sensors
        power_mgmt_data_t* power
        char* features
        char* features_act
        char* gres
        char* gres_drain
        char* gres_used
        char* mcs_label
        uint64_t mem_spec_limit
        char* name
        uint32_t next_state
        char* node_addr
        char* node_hostname
        uint32_t node_state
        char* os
        uint32_t owner
        char* partitions
        uint16_t port
        uint64_t real_memory
        char* comment
        char* reason
        time_t reason_time
        uint32_t reason_uid
        dynamic_plugin_data_t* select_nodeinfo
        time_t slurmd_start_time
        uint16_t sockets
        uint16_t threads
        uint32_t tmp_disk
        uint32_t weight
        char* tres_fmt_str
        char* version

    ctypedef node_info node_info_t

    cdef struct node_info_msg:
        time_t last_update
        uint32_t record_count
        node_info_t* node_array

    ctypedef node_info_msg node_info_msg_t

    cdef struct front_end_info:
        char* allow_groups
        char* allow_users
        time_t boot_time
        char* deny_groups
        char* deny_users
        char* name
        uint32_t node_state
        char* reason
        time_t reason_time
        uint32_t reason_uid
        time_t slurmd_start_time
        char* version

    ctypedef front_end_info front_end_info_t

    cdef struct front_end_info_msg:
        time_t last_update
        uint32_t record_count
        front_end_info_t* front_end_array

    ctypedef front_end_info_msg front_end_info_msg_t

    cdef struct topo_info:
        uint16_t level
        uint32_t link_speed
        char* name
        char* nodes
        char* switches

    ctypedef topo_info topo_info_t

    cdef struct topo_info_response_msg:
        uint32_t record_count
        topo_info_t* topo_array

    ctypedef topo_info_response_msg topo_info_response_msg_t

    cdef struct job_alloc_info_msg:
        uint32_t job_id
        char* req_cluster

    ctypedef job_alloc_info_msg job_alloc_info_msg_t

    ctypedef struct slurm_selected_step_t:
        uint32_t array_task_id
        uint32_t het_job_offset
        slurm_step_id_t step_id

    ctypedef slurm_selected_step_t step_alloc_info_msg_t

    cdef struct acct_gather_node_resp_msg:
        acct_gather_energy_t* energy
        char* node_name
        uint16_t sensor_cnt

    ctypedef acct_gather_node_resp_msg acct_gather_node_resp_msg_t

    cdef struct acct_gather_energy_req_msg:
        uint16_t context_id
        uint16_t delta

    ctypedef acct_gather_energy_req_msg acct_gather_energy_req_msg_t

    cdef struct job_defaults:
        uint16_t type
        uint64_t value

    ctypedef job_defaults job_defaults_t

    cdef struct partition_info:
        char* allow_alloc_nodes
        char* allow_accounts
        char* allow_groups
        char* allow_qos
        char* alternate
        char* billing_weights_str
        char* cluster_name
        uint16_t cr_type
        uint32_t cpu_bind
        uint64_t def_mem_per_cpu
        uint32_t default_time
        char* deny_accounts
        char* deny_qos
        uint16_t flags
        uint32_t grace_time
        List job_defaults_list
        char* job_defaults_str
        uint32_t max_cpus_per_node
        uint64_t max_mem_per_cpu
        uint32_t max_nodes
        uint16_t max_share
        uint32_t max_time
        uint32_t min_nodes
        char* name
        int32_t* node_inx
        char* nodes
        uint16_t over_time_limit
        uint16_t preempt_mode
        uint16_t priority_job_factor
        uint16_t priority_tier
        char* qos_char
        uint16_t state_up
        uint32_t total_cpus
        uint32_t total_nodes
        char* tres_fmt_str

    ctypedef partition_info partition_info_t

    cdef struct delete_partition_msg:
        char* name

    ctypedef delete_partition_msg delete_part_msg_t

    cdef struct resource_allocation_response_msg:
        char* account
        uint32_t job_id
        char* alias_list
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        uint16_t* cpus_per_node
        uint32_t* cpu_count_reps
        uint32_t env_size
        char** environment
        uint32_t error_code
        char* job_submit_user_msg
        slurm_addr_t* node_addr
        uint32_t node_cnt
        char* node_list
        uint16_t ntasks_per_board
        uint16_t ntasks_per_core
        uint16_t ntasks_per_tres
        uint16_t ntasks_per_socket
        uint32_t num_cpu_groups
        char* partition
        uint64_t pn_min_memory
        char* qos
        char* resv_name
        dynamic_plugin_data_t* select_jobinfo
        void* working_cluster_rec

    ctypedef resource_allocation_response_msg resource_allocation_response_msg_t

    cdef struct partition_info_msg:
        time_t last_update
        uint32_t record_count
        partition_info_t* partition_array

    ctypedef partition_info_msg partition_info_msg_t

    cdef struct will_run_response_msg:
        uint32_t job_id
        char* job_submit_user_msg
        char* node_list
        char* part_name
        List preemptee_job_id
        uint32_t proc_cnt
        time_t start_time
        double sys_usage_per

    ctypedef will_run_response_msg will_run_response_msg_t

    cdef struct resv_core_spec:
        char* node_name
        char* core_id

    ctypedef resv_core_spec resv_core_spec_t

    cdef struct reserve_info:
        char* accounts
        char* burst_buffer
        uint32_t core_cnt
        uint32_t core_spec_cnt
        resv_core_spec_t* core_spec
        time_t end_time
        char* features
        uint64_t flags
        char* groups
        char* licenses
        uint32_t max_start_delay
        char* name
        uint32_t node_cnt
        int32_t* node_inx
        char* node_list
        char* partition
        uint32_t purge_comp_time
        time_t start_time
        uint32_t resv_watts
        char* tres_str
        char* users

    ctypedef reserve_info reserve_info_t

    cdef struct reserve_info_msg:
        time_t last_update
        uint32_t record_count
        reserve_info_t* reservation_array

    ctypedef reserve_info_msg reserve_info_msg_t

    cdef struct resv_desc_msg:
        char* accounts
        char* burst_buffer
        uint32_t* core_cnt
        uint32_t duration
        time_t end_time
        char* features
        uint64_t flags
        char* groups
        char* licenses
        uint32_t max_start_delay
        char* name
        uint32_t* node_cnt
        char* node_list
        char* partition
        uint32_t purge_comp_time
        time_t start_time
        uint32_t resv_watts
        char* tres_str
        char* users

    ctypedef resv_desc_msg resv_desc_msg_t

    cdef struct reserve_response_msg:
        char* name

    ctypedef reserve_response_msg reserve_response_msg_t

    cdef struct reservation_name_msg:
        char* name

    ctypedef reservation_name_msg reservation_name_msg_t

    ctypedef struct slurm_conf_t:
        time_t last_update
        char* accounting_storage_tres
        uint16_t accounting_storage_enforce
        char* accounting_storage_backup_host
        char* accounting_storage_ext_host
        char* accounting_storage_host
        char* accounting_storage_params
        char* accounting_storage_pass
        uint16_t accounting_storage_port
        char* accounting_storage_type
        char* accounting_storage_user
        void* acct_gather_conf
        char* acct_gather_energy_type
        char* acct_gather_profile_type
        char* acct_gather_interconnect_type
        char* acct_gather_filesystem_type
        uint16_t acct_gather_node_freq
        char* authalttypes
        char* authinfo
        char* authalt_params
        char* authtype
        uint16_t batch_start_timeout
        char* bb_type
        time_t boot_time
        void* cgroup_conf
        char* cli_filter_plugins
        char* core_spec_plugin
        char* cluster_name
        char* comm_params
        uint16_t complete_wait
        uint32_t conf_flags
        char** control_addr
        uint32_t control_cnt
        char** control_machine
        uint32_t cpu_freq_def
        uint32_t cpu_freq_govs
        char* cred_type
        uint64_t debug_flags
        uint64_t def_mem_per_cpu
        char* dependency_params
        uint16_t eio_timeout
        uint16_t enforce_part_limits
        char* epilog
        uint32_t epilog_msg_time
        char* epilog_slurmctld
        char* ext_sensors_type
        uint16_t ext_sensors_freq
        void* ext_sensors_conf
        char* fed_params
        uint32_t first_job_id
        uint16_t fs_dampening_factor
        uint16_t get_env_timeout
        char* gres_plugins
        uint16_t group_time
        uint16_t group_force
        char* gpu_freq_def
        uint32_t hash_val
        uint16_t health_check_interval
        uint16_t health_check_node_state
        char* health_check_program
        uint16_t inactive_limit
        char* interactive_step_opts
        char* job_acct_gather_freq
        char* job_acct_gather_type
        char* job_acct_gather_params
        uint16_t job_acct_oom_kill
        char* job_comp_host
        char* job_comp_loc
        char* job_comp_params
        char* job_comp_pass
        uint32_t job_comp_port
        char* job_comp_type
        char* job_comp_user
        char* job_container_plugin
        char* job_credential_private_key
        char* job_credential_public_certificate
        List job_defaults_list
        uint16_t job_file_append
        uint16_t job_requeue
        char* job_submit_plugins
        uint16_t keep_alive_time
        uint16_t kill_on_bad_exit
        uint16_t kill_wait
        char* launch_params
        char* launch_type
        char* licenses
        uint16_t log_fmt
        char* mail_domain
        char* mail_prog
        uint32_t max_array_sz
        uint32_t max_dbd_msgs
        uint32_t max_job_cnt
        uint32_t max_job_id
        uint64_t max_mem_per_cpu
        uint32_t max_step_cnt
        uint16_t max_tasks_per_node
        char* mcs_plugin
        char* mcs_plugin_params
        uint32_t min_job_age
        char* mpi_default
        char* mpi_params
        uint16_t msg_timeout
        uint32_t next_job_id
        void* node_features_conf
        char* node_features_plugins
        char* node_prefix
        uint16_t over_time_limit
        char* plugindir
        char* plugstack
        char* power_parameters
        char* power_plugin
        uint32_t preempt_exempt_time
        uint16_t preempt_mode
        char* preempt_type
        char* prep_params
        char* prep_plugins
        uint32_t priority_decay_hl
        uint32_t priority_calc_period
        uint16_t priority_favor_small
        uint16_t priority_flags
        uint32_t priority_max_age
        char* priority_params
        uint16_t priority_reset_period
        char* priority_type
        uint32_t priority_weight_age
        uint32_t priority_weight_assoc
        uint32_t priority_weight_fs
        uint32_t priority_weight_js
        uint32_t priority_weight_part
        uint32_t priority_weight_qos
        char* priority_weight_tres
        uint16_t private_data
        char* proctrack_type
        char* prolog
        uint16_t prolog_epilog_timeout
        char* prolog_slurmctld
        uint16_t propagate_prio_process
        uint16_t prolog_flags
        char* propagate_rlimits
        char* propagate_rlimits_except
        char* reboot_program
        uint16_t reconfig_flags
        char* requeue_exit
        char* requeue_exit_hold
        char* resume_fail_program
        char* resume_program
        uint16_t resume_rate
        uint16_t resume_timeout
        char* resv_epilog
        uint16_t resv_over_run
        char* resv_prolog
        uint16_t ret2service
        char* route_plugin
        char* sbcast_parameters
        char* sched_logfile
        uint16_t sched_log_level
        char* sched_params
        uint16_t sched_time_slice
        char* schedtype
        char* scron_params
        char* select_type
        void* select_conf_key_pairs
        uint16_t select_type_param
        char* site_factor_plugin
        char* site_factor_params
        char* slurm_conf
        uint32_t slurm_user_id
        char* slurm_user_name
        uint32_t slurmd_user_id
        char* slurmd_user_name
        char* slurmctld_addr
        uint16_t slurmctld_debug
        char* slurmctld_logfile
        char* slurmctld_pidfile
        char* slurmctld_plugstack
        void* slurmctld_plugstack_conf
        uint32_t slurmctld_port
        uint16_t slurmctld_port_count
        char* slurmctld_primary_off_prog
        char* slurmctld_primary_on_prog
        uint16_t slurmctld_syslog_debug
        uint16_t slurmctld_timeout
        char* slurmctld_params
        uint16_t slurmd_debug
        char* slurmd_logfile
        char* slurmd_params
        char* slurmd_pidfile
        uint32_t slurmd_port
        char* slurmd_spooldir
        uint16_t slurmd_syslog_debug
        uint16_t slurmd_timeout
        char* srun_epilog
        uint16_t* srun_port_range
        char* srun_prolog
        char* state_save_location
        char* suspend_exc_nodes
        char* suspend_exc_parts
        char* suspend_program
        uint16_t suspend_rate
        uint32_t suspend_time
        uint16_t suspend_timeout
        char* switch_type
        char* task_epilog
        char* task_plugin
        uint32_t task_plugin_param
        char* task_prolog
        uint16_t tcp_timeout
        char* tmp_fs
        char* topology_param
        char* topology_plugin
        uint16_t tree_width
        char* unkillable_program
        uint16_t unkillable_timeout
        char* version
        uint16_t vsize_factor
        uint16_t wait_time
        char* x11_params

    cdef struct slurmd_status_msg:
        time_t booted
        time_t last_slurmctld_msg
        uint16_t slurmd_debug
        uint16_t actual_cpus
        uint16_t actual_boards
        uint16_t actual_sockets
        uint16_t actual_cores
        uint16_t actual_threads
        uint64_t actual_real_mem
        uint32_t actual_tmp_disk
        uint32_t pid
        char* hostname
        char* slurmd_logfile
        char* step_list
        char* version

    ctypedef slurmd_status_msg slurmd_status_t

    cdef struct submit_response_msg:
        uint32_t job_id
        uint32_t step_id
        uint32_t error_code
        char* job_submit_user_msg

    ctypedef submit_response_msg submit_response_msg_t

    cdef struct slurm_update_node_msg:
        char* comment
        uint32_t cpu_bind
        char* features
        char* features_act
        char* gres
        char* node_addr
        char* node_hostname
        char* node_names
        uint32_t node_state
        char* reason
        uint32_t reason_uid
        uint32_t weight

    ctypedef slurm_update_node_msg update_node_msg_t

    cdef struct slurm_update_front_end_msg:
        char* name
        uint32_t node_state
        char* reason
        uint32_t reason_uid

    ctypedef slurm_update_front_end_msg update_front_end_msg_t

    ctypedef partition_info update_part_msg_t

    cdef struct job_sbcast_cred_msg:
        uint32_t job_id
        char* node_list
        sbcast_cred_t* sbcast_cred

    ctypedef job_sbcast_cred_msg job_sbcast_cred_msg_t

    ctypedef struct token_request_msg_t:
        uint32_t lifespan
        char* username

    ctypedef struct token_response_msg_t:
        char* token

    ctypedef slurm_step_ctx_struct slurm_step_ctx_t

    cdef struct stats_info_request_msg:
        uint16_t command_id

    ctypedef stats_info_request_msg stats_info_request_msg_t

    cdef struct stats_info_response_msg:
        uint32_t parts_packed
        time_t req_time
        time_t req_time_start
        uint32_t server_thread_count
        uint32_t agent_queue_size
        uint32_t agent_count
        uint32_t agent_thread_count
        uint32_t dbd_agent_queue_size
        uint32_t gettimeofday_latency
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
        uint32_t jobs_pending
        uint32_t jobs_running
        time_t job_states_ts
        uint32_t bf_backfilled_jobs
        uint32_t bf_last_backfilled_jobs
        uint32_t bf_backfilled_het_jobs
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
        uint32_t bf_table_size
        uint32_t bf_table_size_sum
        time_t bf_when_last_cycle
        uint32_t bf_active
        uint32_t rpc_type_size
        uint16_t* rpc_type_id
        uint32_t* rpc_type_cnt
        uint64_t* rpc_type_time
        uint32_t rpc_user_size
        uint32_t* rpc_user_id
        uint32_t* rpc_user_cnt
        uint64_t* rpc_user_time
        uint32_t rpc_queue_type_count
        uint32_t* rpc_queue_type_id
        uint32_t* rpc_queue_count
        uint32_t rpc_dump_count
        uint32_t* rpc_dump_types
        char** rpc_dump_hostlist

    ctypedef stats_info_response_msg stats_info_response_msg_t

    cdef struct trigger_info:
        uint16_t flags
        uint32_t trig_id
        uint16_t res_type
        char* res_id
        uint32_t control_inx
        uint32_t trig_type
        uint16_t offset
        uint32_t user_id
        char* program

    ctypedef trigger_info trigger_info_t

    cdef struct trigger_info_msg:
        uint32_t record_count
        trigger_info_t* trigger_array

    ctypedef trigger_info_msg trigger_info_msg_t

    cdef struct slurm_license_info:
        char* name
        uint32_t total
        uint32_t in_use
        uint32_t available
        uint8_t remote
        uint32_t reserved

    ctypedef slurm_license_info slurm_license_info_t

    cdef struct license_info_msg:
        time_t last_update
        uint32_t num_lic
        slurm_license_info_t* lic_array

    ctypedef license_info_msg license_info_msg_t

    ctypedef struct job_array_resp_msg_t:
        uint32_t job_array_count
        char** job_array_id
        uint32_t* error_code

    ctypedef struct assoc_mgr_info_msg_t:
        List assoc_list
        List qos_list
        uint32_t tres_cnt
        char** tres_names
        List user_list

    ctypedef struct assoc_mgr_info_request_msg_t:
        List acct_list
        uint32_t flags
        List qos_list
        List user_list

    cdef struct network_callerid_msg:
        unsigned char ip_src[16]
        unsigned char ip_dst[16]
        uint32_t port_src
        uint32_t port_dst
        int32_t af

    ctypedef network_callerid_msg network_callerid_msg_t

    void slurm_init_job_desc_msg(job_desc_msg_t* job_desc_msg)

    int slurm_allocate_resources(job_desc_msg_t* job_desc_msg, resource_allocation_response_msg_t** job_alloc_resp_msg)

    ctypedef void (*_slurm_allocate_resources_blocking_pending_callback_ft)(uint32_t job_id)

    resource_allocation_response_msg_t* slurm_allocate_resources_blocking(job_desc_msg_t* user_req, time_t timeout, _slurm_allocate_resources_blocking_pending_callback_ft pending_callback)

    void slurm_free_resource_allocation_response_msg(resource_allocation_response_msg_t* msg)

    ctypedef void (*_slurm_allocate_het_job_blocking_pending_callback_ft)(uint32_t job_id)

    List slurm_allocate_het_job_blocking(List job_req_list, time_t timeout, _slurm_allocate_het_job_blocking_pending_callback_ft pending_callback)

    int slurm_allocation_lookup(uint32_t job_id, resource_allocation_response_msg_t** resp)

    int slurm_het_job_lookup(uint32_t jobid, List* resp)

    char* slurm_read_hostfile(char* filename, int n)

    allocation_msg_thread_t* slurm_allocation_msg_thr_create(uint16_t* port, slurm_allocation_callbacks_t* callbacks)

    void slurm_allocation_msg_thr_destroy(allocation_msg_thread_t* msg_thr)

    int slurm_submit_batch_job(job_desc_msg_t* job_desc_msg, submit_response_msg_t** slurm_alloc_msg)

    int slurm_submit_batch_het_job(List job_req_list, submit_response_msg_t** slurm_alloc_msg)

    void slurm_free_submit_response_response_msg(submit_response_msg_t* msg)

    int slurm_job_batch_script(FILE* out, uint32_t jobid)

    int slurm_job_will_run(job_desc_msg_t* job_desc_msg)

    int slurm_het_job_will_run(List job_req_list)

    int slurm_job_will_run2(job_desc_msg_t* req, will_run_response_msg_t** will_run_resp)

    int slurm_sbcast_lookup(slurm_selected_step_t* selected_step, job_sbcast_cred_msg_t** info)

    void slurm_free_sbcast_cred_msg(job_sbcast_cred_msg_t* msg)

    int slurm_load_licenses(time_t, license_info_msg_t**, uint16_t)

    void slurm_free_license_info_msg(license_info_msg_t*)

    int slurm_load_assoc_mgr_info(assoc_mgr_info_request_msg_t*, assoc_mgr_info_msg_t**)

    void slurm_free_assoc_mgr_info_msg(assoc_mgr_info_msg_t*)

    void slurm_free_assoc_mgr_info_request_members(assoc_mgr_info_request_msg_t*)

    void slurm_free_assoc_mgr_info_request_msg(assoc_mgr_info_request_msg_t*)

    cdef struct job_step_kill_msg:
        char* sjob_id
        uint16_t signal
        uint16_t flags
        char* sibling
        slurm_step_id_t step_id

    ctypedef job_step_kill_msg job_step_kill_msg_t

    int slurm_kill_job(uint32_t job_id, uint16_t signal, uint16_t flags)

    int slurm_kill_job_step(uint32_t job_id, uint32_t step_id, uint16_t signal)

    int slurm_kill_job2(char* job_id, uint16_t signal, uint16_t flags)

    int slurm_kill_job_msg(uint16_t msg_type, job_step_kill_msg_t* kill_msg)

    int slurm_signal_job(uint32_t job_id, uint16_t signal)

    int slurm_signal_job_step(uint32_t job_id, uint32_t step_id, uint32_t signal)

    int slurm_complete_job(uint32_t job_id, uint32_t job_return_code)

    int slurm_terminate_job_step(uint32_t job_id, uint32_t step_id)

    void slurm_step_ctx_params_t_init(slurm_step_ctx_params_t* ptr)

    slurm_step_ctx_t* slurm_step_ctx_create(slurm_step_ctx_params_t* step_params)

    slurm_step_ctx_t* slurm_step_ctx_create_timeout(slurm_step_ctx_params_t* step_params, int timeout)

    bool slurm_step_retry_errno(int rc)

    slurm_step_ctx_t* slurm_step_ctx_create_no_alloc(slurm_step_ctx_params_t* step_params, uint32_t step_id)

    int slurm_step_ctx_get(slurm_step_ctx_t* ctx, int ctx_key)

    int slurm_jobinfo_ctx_get(dynamic_plugin_data_t* jobinfo, int data_type, void* data)

    int slurm_step_ctx_daemon_per_node_hack(slurm_step_ctx_t* ctx, char* node_list, uint32_t node_cnt, uint32_t* curr_task_num)

    int slurm_step_ctx_destroy(slurm_step_ctx_t* ctx)

    void slurm_step_launch_params_t_init(slurm_step_launch_params_t* ptr)

    int slurm_step_launch(slurm_step_ctx_t* ctx, slurm_step_launch_params_t* params, slurm_step_launch_callbacks_t* callbacks)

    int slurm_step_launch_add(slurm_step_ctx_t* ctx, slurm_step_ctx_t* first_ctx, slurm_step_launch_params_t* params, char* node_list, int start_nodeid)

    int slurm_step_launch_wait_start(slurm_step_ctx_t* ctx)

    void slurm_step_launch_wait_finish(slurm_step_ctx_t* ctx)

    void slurm_step_launch_abort(slurm_step_ctx_t* ctx)

    void slurm_step_launch_fwd_signal(slurm_step_ctx_t* ctx, int signo)

    void slurm_step_launch_fwd_wake(slurm_step_ctx_t* ctx)

    int slurm_mpi_plugin_init(char* plugin_name)

    long slurm_api_version()

    int slurm_load_ctl_conf(time_t update_time, slurm_conf_t** slurm_ctl_conf_ptr)

    void slurm_free_ctl_conf(slurm_conf_t* slurm_ctl_conf_ptr)

    void slurm_print_ctl_conf(FILE* out, slurm_conf_t* slurm_ctl_conf_ptr)

    void slurm_write_ctl_conf(slurm_conf_t* slurm_ctl_conf_ptr, node_info_msg_t* node_info_ptr, partition_info_msg_t* part_info_ptr)

    void* slurm_ctl_conf_2_key_pairs(slurm_conf_t* slurm_ctl_conf_ptr)

    void slurm_print_key_pairs(FILE* out, void* key_pairs, char* title)

    int slurm_load_slurmd_status(slurmd_status_t** slurmd_status_ptr)

    void slurm_free_slurmd_status(slurmd_status_t* slurmd_status_ptr)

    void slurm_print_slurmd_status(FILE* out, slurmd_status_t* slurmd_status_ptr)

    void slurm_init_update_step_msg(step_update_request_msg_t* step_msg)

    int slurm_get_statistics(stats_info_response_msg_t** buf, stats_info_request_msg_t* req)

    int slurm_reset_statistics(stats_info_request_msg_t* req)

    int slurm_job_cpus_allocated_on_node_id(job_resources_t* job_resrcs_ptr, int node_id)

    int slurm_job_cpus_allocated_on_node(job_resources_t* job_resrcs_ptr, char* node_name)

    int slurm_job_cpus_allocated_str_on_node_id(char* cpus, size_t cpus_len, job_resources_t* job_resrcs_ptr, int node_id)

    int slurm_job_cpus_allocated_str_on_node(char* cpus, size_t cpus_len, job_resources_t* job_resrcs_ptr, char* node_name)

    void slurm_free_job_info_msg(job_info_msg_t* job_buffer_ptr)

    void slurm_free_priority_factors_response_msg(priority_factors_response_msg_t* factors_resp)

    int slurm_get_end_time(uint32_t jobid, time_t* end_time_ptr)

    void slurm_get_job_stderr(char* buf, int buf_size, job_info_t* job_ptr)

    void slurm_get_job_stdin(char* buf, int buf_size, job_info_t* job_ptr)

    void slurm_get_job_stdout(char* buf, int buf_size, job_info_t* job_ptr)

    long slurm_get_rem_time(uint32_t jobid)

    int slurm_job_node_ready(uint32_t job_id)

    int slurm_load_job(job_info_msg_t** resp, uint32_t job_id, uint16_t show_flags)

    int slurm_load_job_prio(priority_factors_response_msg_t** factors_resp, List job_id_list, char* partitions, List uid_list, uint16_t show_flags)

    int slurm_load_job_user(job_info_msg_t** job_info_msg_pptr, uint32_t user_id, uint16_t show_flags)

    int slurm_load_jobs(time_t update_time, job_info_msg_t** job_info_msg_pptr, uint16_t show_flags)

    int slurm_notify_job(uint32_t job_id, char* message)

    int slurm_pid2jobid(pid_t job_pid, uint32_t* job_id_ptr)

    void slurm_print_job_info(FILE* out, slurm_job_info_t* job_ptr, int one_liner)

    void slurm_print_job_info_msg(FILE* out, job_info_msg_t* job_info_msg_ptr, int one_liner)

    char* slurm_sprint_job_info(slurm_job_info_t* job_ptr, int one_liner)

    int slurm_update_job(job_desc_msg_t* job_msg)

    int slurm_update_job2(job_desc_msg_t* job_msg, job_array_resp_msg_t** resp)

    uint32_t slurm_xlate_job_id(char* job_id_str)

    int slurm_get_job_steps(time_t update_time, uint32_t job_id, uint32_t step_id, job_step_info_response_msg_t** step_response_pptr, uint16_t show_flags)

    void slurm_free_job_step_info_response_msg(job_step_info_response_msg_t* msg)

    void slurm_print_job_step_info_msg(FILE* out, job_step_info_response_msg_t* job_step_info_msg_ptr, int one_liner)

    void slurm_print_job_step_info(FILE* out, job_step_info_t* step_ptr, int one_liner)

    slurm_step_layout_t* slurm_job_step_layout_get(slurm_step_id_t* step_id)

    char* slurm_sprint_job_step_info(job_step_info_t* step_ptr, int one_liner)

    int slurm_job_step_stat(slurm_step_id_t* step_id, char* node_list, uint16_t use_protocol_ver, job_step_stat_response_msg_t** resp)

    int slurm_job_step_get_pids(slurm_step_id_t* step_id, char* node_list, job_step_pids_response_msg_t** resp)

    void slurm_job_step_layout_free(slurm_step_layout_t* layout)

    void slurm_job_step_pids_free(job_step_pids_t* object)

    void slurm_job_step_pids_response_msg_free(void* object)

    void slurm_job_step_stat_free(job_step_stat_t* object)

    void slurm_job_step_stat_response_msg_free(void* object)

    int slurm_update_step(step_update_request_msg_t* step_msg)

    void slurm_destroy_selected_step(void* object)

    int slurm_load_node(time_t update_time, node_info_msg_t** resp, uint16_t show_flags)

    int slurm_load_node2(time_t update_time, node_info_msg_t** resp, uint16_t show_flags, slurmdb_cluster_rec_t* cluster)

    int slurm_load_node_single(node_info_msg_t** resp, char* node_name, uint16_t show_flags)

    int slurm_load_node_single2(node_info_msg_t** resp, char* node_name, uint16_t show_flags, slurmdb_cluster_rec_t* cluster)

    void slurm_populate_node_partitions(node_info_msg_t* node_buffer_ptr, partition_info_msg_t* part_buffer_ptr)

    int slurm_get_node_energy(char* host, uint16_t context_id, uint16_t delta, uint16_t* sensors_cnt, acct_gather_energy_t** energy)

    void slurm_free_node_info_msg(node_info_msg_t* node_buffer_ptr)

    void slurm_print_node_info_msg(FILE* out, node_info_msg_t* node_info_msg_ptr, int one_liner)

    void slurm_print_node_table(FILE* out, node_info_t* node_ptr, int one_liner)

    char* slurm_sprint_node_table(node_info_t* node_ptr, int one_liner)

    void slurm_init_update_node_msg(update_node_msg_t* update_node_msg)

    int slurm_update_node(update_node_msg_t* node_msg)

    int slurm_load_front_end(time_t update_time, front_end_info_msg_t** resp)

    void slurm_free_front_end_info_msg(front_end_info_msg_t* front_end_buffer_ptr)

    void slurm_print_front_end_info_msg(FILE* out, front_end_info_msg_t* front_end_info_msg_ptr, int one_liner)

    void slurm_print_front_end_table(FILE* out, front_end_info_t* front_end_ptr, int one_liner)

    char* slurm_sprint_front_end_table(front_end_info_t* front_end_ptr, int one_liner)

    void slurm_init_update_front_end_msg(update_front_end_msg_t* update_front_end_msg)

    int slurm_update_front_end(update_front_end_msg_t* front_end_msg)

    int slurm_load_topo(topo_info_response_msg_t** topo_info_msg_pptr)

    void slurm_free_topo_info_msg(topo_info_response_msg_t* msg)

    void slurm_print_topo_info_msg(FILE* out, topo_info_response_msg_t* topo_info_msg_ptr, int one_liner)

    void slurm_print_topo_record(FILE* out, topo_info_t* topo_ptr, int one_liner)

    int slurm_get_select_nodeinfo(dynamic_plugin_data_t* nodeinfo, select_nodedata_type data_type, node_states state, void* data)

    void slurm_init_part_desc_msg(update_part_msg_t* update_part_msg)

    int slurm_load_partitions(time_t update_time, partition_info_msg_t** part_buffer_ptr, uint16_t show_flags)

    int slurm_load_partitions2(time_t update_time, partition_info_msg_t** resp, uint16_t show_flags, slurmdb_cluster_rec_t* cluster)

    void slurm_free_partition_info_msg(partition_info_msg_t* part_info_ptr)

    void slurm_print_partition_info_msg(FILE* out, partition_info_msg_t* part_info_ptr, int one_liner)

    void slurm_print_partition_info(FILE* out, partition_info_t* part_ptr, int one_liner)

    char* slurm_sprint_partition_info(partition_info_t* part_ptr, int one_liner)

    int slurm_create_partition(update_part_msg_t* part_msg)

    int slurm_update_partition(update_part_msg_t* part_msg)

    int slurm_delete_partition(delete_part_msg_t* part_msg)

    void slurm_init_resv_desc_msg(resv_desc_msg_t* update_resv_msg)

    char* slurm_create_reservation(resv_desc_msg_t* resv_msg)

    int slurm_update_reservation(resv_desc_msg_t* resv_msg)

    int slurm_delete_reservation(reservation_name_msg_t* resv_msg)

    int slurm_load_reservations(time_t update_time, reserve_info_msg_t** resp)

    void slurm_print_reservation_info_msg(FILE* out, reserve_info_msg_t* resv_info_ptr, int one_liner)

    void slurm_print_reservation_info(FILE* out, reserve_info_t* resv_ptr, int one_liner)

    char* slurm_sprint_reservation_info(reserve_info_t* resv_ptr, int one_liner)

    void slurm_free_reservation_info_msg(reserve_info_msg_t* resv_info_ptr)

    int slurm_ping(int dest)

    int slurm_reconfigure()

    int slurm_shutdown(uint16_t options)

    int slurm_takeover(int backup_inx)

    int slurm_set_debugflags(uint64_t debug_flags_plus, uint64_t debug_flags_minus)

    int slurm_set_debug_level(uint32_t debug_level)

    int slurm_set_schedlog_level(uint32_t schedlog_level)

    int slurm_set_fs_dampeningfactor(uint16_t factor)

    int slurm_suspend(uint32_t job_id)

    int slurm_suspend2(char* job_id, job_array_resp_msg_t** resp)

    int slurm_resume(uint32_t job_id)

    int slurm_resume2(char* job_id, job_array_resp_msg_t** resp)

    void slurm_free_job_array_resp(job_array_resp_msg_t* resp)

    int slurm_requeue(uint32_t job_id, uint32_t flags)

    int slurm_requeue2(char* job_id, uint32_t flags, job_array_resp_msg_t** resp)

    int slurm_set_trigger(trigger_info_t* trigger_set)

    int slurm_clear_trigger(trigger_info_t* trigger_clear)

    int slurm_get_triggers(trigger_info_msg_t** trigger_get)

    int slurm_pull_trigger(trigger_info_t* trigger_pull)

    void slurm_free_trigger_msg(trigger_info_msg_t* trigger_free)

    void slurm_init_trigger_msg(trigger_info_t* trigger_info_msg)

    ctypedef struct burst_buffer_pool_t:
        uint64_t granularity
        char* name
        uint64_t total_space
        uint64_t used_space
        uint64_t unfree_space

    ctypedef struct burst_buffer_resv_t:
        char* account
        uint32_t array_job_id
        uint32_t array_task_id
        time_t create_time
        uint32_t job_id
        char* name
        char* partition
        char* pool
        char* qos
        uint64_t size
        uint16_t state
        uint32_t user_id

    ctypedef struct burst_buffer_use_t:
        uint32_t user_id
        uint64_t used

    ctypedef struct burst_buffer_info_t:
        char* allow_users
        char* default_pool
        char* create_buffer
        char* deny_users
        char* destroy_buffer
        uint32_t flags
        char* get_sys_state
        char* get_sys_status
        uint64_t granularity
        uint32_t pool_cnt
        burst_buffer_pool_t* pool_ptr
        char* name
        uint32_t other_timeout
        uint32_t stage_in_timeout
        uint32_t stage_out_timeout
        char* start_stage_in
        char* start_stage_out
        char* stop_stage_in
        char* stop_stage_out
        uint64_t total_space
        uint64_t unfree_space
        uint64_t used_space
        uint32_t validate_timeout
        uint32_t buffer_count
        burst_buffer_resv_t* burst_buffer_resv_ptr
        uint32_t use_count
        burst_buffer_use_t* burst_buffer_use_ptr

    ctypedef struct burst_buffer_info_msg_t:
        burst_buffer_info_t* burst_buffer_array
        uint32_t record_count

    char* slurm_burst_buffer_state_string(uint16_t state)

    int slurm_load_burst_buffer_stat(int argc, char** argv, char** status_resp)

    int slurm_load_burst_buffer_info(burst_buffer_info_msg_t** burst_buffer_info_msg_pptr)

    void slurm_free_burst_buffer_info_msg(burst_buffer_info_msg_t* burst_buffer_info_msg)

    void slurm_print_burst_buffer_info_msg(FILE* out, burst_buffer_info_msg_t* info_ptr, int one_liner, int verbosity)

    void slurm_print_burst_buffer_record(FILE* out, burst_buffer_info_t* burst_buffer_ptr, int one_liner, int verbose)

    int slurm_network_callerid(network_callerid_msg_t req, uint32_t* job_id, char* node_name, int node_name_size)

    int slurm_top_job(char* job_id_str)

    char* slurm_fetch_token(char* username, int lifespan)

    int slurm_load_federation(void** fed_pptr)

    void slurm_print_federation(void* fed)

    void slurm_destroy_federation_rec(void* fed)

    int slurm_request_crontab(uid_t uid, char** crontab, char** disabled_lines)

    ctypedef struct crontab_update_response_msg_t:
        char* err_msg
        char* failed_lines
        uint32_t* jobids
        uint32_t jobids_count
        uint32_t return_code

    crontab_update_response_msg_t* slurm_update_crontab(uid_t uid, gid_t gid, char* crontab, List jobs)

    int slurm_remove_crontab(uid_t uid, gid_t gid)


cdef extern from "slurm/slurmdb.h":


    uint32_t QOS_FLAG_BASE
    uint32_t QOS_FLAG_NOTSET
    uint32_t QOS_FLAG_ADD
    uint32_t QOS_FLAG_REMOVE

    uint8_t QOS_FLAG_PART_MIN_NODE
    uint8_t QOS_FLAG_PART_MAX_NODE
    uint8_t QOS_FLAG_PART_TIME_LIMIT
    uint8_t QOS_FLAG_ENFORCE_USAGE_THRES
    uint8_t QOS_FLAG_NO_RESERVE
    uint8_t QOS_FLAG_REQ_RESV
    uint8_t QOS_FLAG_DENY_LIMIT
    uint8_t QOS_FLAG_OVER_PART_QOS
    uint16_t QOS_FLAG_NO_DECAY
    uint16_t QOS_FLAG_USAGE_FACTOR_SAFE

    uint32_t SLURMDB_RES_FLAG_BASE
    uint32_t SLURMDB_RES_FLAG_NOTSET
    uint32_t SLURMDB_RES_FLAG_ADD
    uint32_t SLURMDB_RES_FLAG_REMOVE

    uint32_t FEDERATION_FLAG_BASE
    uint32_t FEDERATION_FLAG_NOTSET
    uint32_t FEDERATION_FLAG_ADD
    uint32_t FEDERATION_FLAG_REMOVE

    uint8_t CLUSTER_FED_STATE_BASE
    uint16_t CLUSTER_FED_STATE_FLAGS
    uint8_t CLUSTER_FED_STATE_DRAIN
    uint8_t CLUSTER_FED_STATE_REMOVE

    uint8_t SLURMDB_JOB_FLAG_NONE
    uint8_t SLURMDB_JOB_CLEAR_SCHED
    uint8_t SLURMDB_JOB_FLAG_NOTSET
    uint8_t SLURMDB_JOB_FLAG_SUBMIT
    uint8_t SLURMDB_JOB_FLAG_SCHED
    uint8_t SLURMDB_JOB_FLAG_BACKFILL

    uint8_t JOBCOND_FLAG_DUP
    uint8_t JOBCOND_FLAG_NO_STEP
    uint8_t JOBCOND_FLAG_NO_TRUNC
    uint8_t JOBCOND_FLAG_RUNAWAY
    uint8_t JOBCOND_FLAG_WHOLE_HETJOB
    uint8_t JOBCOND_FLAG_NO_WHOLE_HETJOB
    uint8_t JOBCOND_FLAG_NO_WAIT
    uint8_t JOBCOND_FLAG_NO_DEFAULT_USAGE

    uint16_t SLURMDB_PURGE_BASE
    uint32_t SLURMDB_PURGE_FLAGS
    uint32_t SLURMDB_PURGE_HOURS
    uint32_t SLURMDB_PURGE_DAYS
    uint32_t SLURMDB_PURGE_MONTHS
    uint32_t SLURMDB_PURGE_ARCHIVE

    uint32_t SLURMDB_FS_USE_PARENT

    uint16_t SLURMDB_CLASSIFIED_FLAG
    uint8_t SLURMDB_CLASS_BASE

    uint8_t CLUSTER_FLAG_A1
    uint8_t CLUSTER_FLAG_A2
    uint8_t CLUSTER_FLAG_A3
    uint8_t CLUSTER_FLAG_A4
    uint8_t CLUSTER_FLAG_A5
    uint8_t CLUSTER_FLAG_A6
    uint8_t CLUSTER_FLAG_A7
    uint8_t CLUSTER_FLAG_MULTSD
    uint16_t CLUSTER_FLAG_A9
    uint16_t CLUSTER_FLAG_A10
    uint16_t CLUSTER_FLAG_FE
    uint16_t CLUSTER_FLAG_CRAY_N
    uint16_t CLUSTER_FLAG_FED
    uint16_t CLUSTER_FLAG_EXT
    uint16_t CLUSTER_FLAG_CRAY

    uint8_t SLURMDB_ASSOC_FLAG_NONE
    uint8_t SLURMDB_ASSOC_FLAG_DELETED
    uint8_t SLURMDB_USER_FLAG_NONE
    uint8_t SLURMDB_USER_FLAG_DELETED
    uint8_t SLURMDB_WCKEY_FLAG_NONE
    uint8_t SLURMDB_WCKEY_FLAG_DELETED


    ctypedef enum slurmdb_admin_level_t:
        SLURMDB_ADMIN_NOTSET
        SLURMDB_ADMIN_NONE
        SLURMDB_ADMIN_OPERATOR
        SLURMDB_ADMIN_SUPER_USER

    ctypedef enum slurmdb_classification_type_t:
        SLURMDB_CLASS_NONE
        SLURMDB_CLASS_CAPABILITY
        SLURMDB_CLASS_CAPACITY
        SLURMDB_CLASS_CAPAPACITY

    ctypedef enum slurmdb_event_type_t:
        SLURMDB_EVENT_ALL
        SLURMDB_EVENT_CLUSTER
        SLURMDB_EVENT_NODE

    ctypedef enum slurmdb_problem_type_t:
        SLURMDB_PROBLEM_NOT_SET
        SLURMDB_PROBLEM_ACCT_NO_ASSOC
        SLURMDB_PROBLEM_ACCT_NO_USERS
        SLURMDB_PROBLEM_USER_NO_ASSOC
        SLURMDB_PROBLEM_USER_NO_UID

    ctypedef enum slurmdb_report_sort_t:
        SLURMDB_REPORT_SORT_TIME
        SLURMDB_REPORT_SORT_NAME

    ctypedef enum slurmdb_report_time_format_t:
        SLURMDB_REPORT_TIME_SECS
        SLURMDB_REPORT_TIME_MINS
        SLURMDB_REPORT_TIME_HOURS
        SLURMDB_REPORT_TIME_PERCENT
        SLURMDB_REPORT_TIME_SECS_PER
        SLURMDB_REPORT_TIME_MINS_PER
        SLURMDB_REPORT_TIME_HOURS_PER

    ctypedef enum slurmdb_resource_type_t:
        SLURMDB_RESOURCE_NOTSET
        SLURMDB_RESOURCE_LICENSE

    ctypedef enum slurmdb_update_type_t:
        SLURMDB_UPDATE_NOTSET
        SLURMDB_ADD_USER
        SLURMDB_ADD_ASSOC
        SLURMDB_ADD_COORD
        SLURMDB_MODIFY_USER
        SLURMDB_MODIFY_ASSOC
        SLURMDB_REMOVE_USER
        SLURMDB_REMOVE_ASSOC
        SLURMDB_REMOVE_COORD
        SLURMDB_ADD_QOS
        SLURMDB_REMOVE_QOS
        SLURMDB_MODIFY_QOS
        SLURMDB_ADD_WCKEY
        SLURMDB_REMOVE_WCKEY
        SLURMDB_MODIFY_WCKEY
        SLURMDB_ADD_CLUSTER
        SLURMDB_REMOVE_CLUSTER
        SLURMDB_REMOVE_ASSOC_USAGE
        SLURMDB_ADD_RES
        SLURMDB_REMOVE_RES
        SLURMDB_MODIFY_RES
        SLURMDB_REMOVE_QOS_USAGE
        SLURMDB_ADD_TRES
        SLURMDB_UPDATE_FEDS

    cdef enum cluster_fed_states:
        CLUSTER_FED_STATE_NA
        CLUSTER_FED_STATE_ACTIVE
        CLUSTER_FED_STATE_INACTIVE

    ctypedef struct slurmdb_tres_rec_t:
        uint64_t alloc_secs
        uint32_t rec_count
        uint64_t count
        uint32_t id
        char* name
        char* type

    ctypedef struct slurmdb_assoc_cond_t:
        List acct_list
        List cluster_list
        List def_qos_id_list
        List format_list
        List id_list
        uint16_t only_defs
        List parent_acct_list
        List partition_list
        List qos_list
        time_t usage_end
        time_t usage_start
        List user_list
        uint16_t with_usage
        uint16_t with_deleted
        uint16_t with_raw_qos
        uint16_t with_sub_accts
        uint16_t without_parent_info
        uint16_t without_parent_limits

    ctypedef struct slurmdb_job_cond_t:
        List acct_list
        List associd_list
        List cluster_list
        List constraint_list
        uint32_t cpus_max
        uint32_t cpus_min
        uint32_t db_flags
        int32_t exitcode
        uint32_t flags
        List format_list
        List groupid_list
        List jobname_list
        uint32_t nodes_max
        uint32_t nodes_min
        List partition_list
        List qos_list
        List reason_list
        List resv_list
        List resvid_list
        List state_list
        List step_list
        uint32_t timelimit_max
        uint32_t timelimit_min
        time_t usage_end
        time_t usage_start
        char* used_nodes
        List userid_list
        List wckey_list

    ctypedef struct slurmdb_stats_t:
        double act_cpufreq
        uint64_t consumed_energy
        char* tres_usage_in_ave
        char* tres_usage_in_max
        char* tres_usage_in_max_nodeid
        char* tres_usage_in_max_taskid
        char* tres_usage_in_min
        char* tres_usage_in_min_nodeid
        char* tres_usage_in_min_taskid
        char* tres_usage_in_tot
        char* tres_usage_out_ave
        char* tres_usage_out_max
        char* tres_usage_out_max_nodeid
        char* tres_usage_out_max_taskid
        char* tres_usage_out_min
        char* tres_usage_out_min_nodeid
        char* tres_usage_out_min_taskid
        char* tres_usage_out_tot

    ctypedef struct slurmdb_account_cond_t:
        slurmdb_assoc_cond_t* assoc_cond
        List description_list
        List organization_list
        uint16_t with_assocs
        uint16_t with_coords
        uint16_t with_deleted

    ctypedef struct slurmdb_account_rec_t:
        List assoc_list
        List coordinators
        char* description
        uint32_t flags
        char* name
        char* organization

    ctypedef struct slurmdb_accounting_rec_t:
        uint64_t alloc_secs
        uint32_t id
        time_t period_start
        slurmdb_tres_rec_t tres_rec

    ctypedef struct slurmdb_archive_cond_t:
        char* archive_dir
        char* archive_script
        slurmdb_job_cond_t* job_cond
        uint32_t purge_event
        uint32_t purge_job
        uint32_t purge_resv
        uint32_t purge_step
        uint32_t purge_suspend
        uint32_t purge_txn
        uint32_t purge_usage

    ctypedef struct slurmdb_archive_rec_t:
        char* archive_file
        char* insert

    ctypedef struct slurmdb_tres_cond_t:
        uint64_t count
        List format_list
        List id_list
        List name_list
        List type_list
        uint16_t with_deleted

    ctypedef slurmdb_assoc_usage slurmdb_assoc_usage_t

    ctypedef slurmdb_bf_usage slurmdb_bf_usage_t

    ctypedef slurmdb_user_rec slurmdb_user_rec_t

    cdef struct slurmdb_assoc_rec:
        List accounting_list
        char* acct
        slurmdb_assoc_rec* assoc_next
        slurmdb_assoc_rec* assoc_next_id
        slurmdb_bf_usage_t* bf_usage
        char* cluster
        uint32_t def_qos_id
        uint16_t flags
        uint32_t grp_jobs
        uint32_t grp_jobs_accrue
        uint32_t grp_submit_jobs
        char* grp_tres
        uint64_t* grp_tres_ctld
        char* grp_tres_mins
        uint64_t* grp_tres_mins_ctld
        char* grp_tres_run_mins
        uint64_t* grp_tres_run_mins_ctld
        uint32_t grp_wall
        uint32_t id
        uint16_t is_def
        uint32_t lft
        uint32_t max_jobs
        uint32_t max_jobs_accrue
        uint32_t max_submit_jobs
        char* max_tres_mins_pj
        uint64_t* max_tres_mins_ctld
        char* max_tres_run_mins
        uint64_t* max_tres_run_mins_ctld
        char* max_tres_pj
        uint64_t* max_tres_ctld
        char* max_tres_pn
        uint64_t* max_tres_pn_ctld
        uint32_t max_wall_pj
        uint32_t min_prio_thresh
        char* parent_acct
        uint32_t parent_id
        char* partition
        uint32_t priority
        List qos_list
        uint32_t rgt
        uint32_t shares_raw
        uint32_t uid
        slurmdb_assoc_usage_t* usage
        char* user
        slurmdb_user_rec_t* user_rec

    ctypedef slurmdb_assoc_rec slurmdb_assoc_rec_t

    cdef struct slurmdb_assoc_usage:
        uint32_t accrue_cnt
        List children_list
        bitstr_t* grp_node_bitmap
        uint16_t* grp_node_job_cnt
        uint64_t* grp_used_tres
        uint64_t* grp_used_tres_run_secs
        double grp_used_wall
        double fs_factor
        uint32_t level_shares
        slurmdb_assoc_rec_t* parent_assoc_ptr
        double priority_norm
        slurmdb_assoc_rec_t* fs_assoc_ptr
        double shares_norm
        uint32_t tres_cnt
        long double usage_efctv
        long double usage_norm
        long double usage_raw
        long double* usage_tres_raw
        uint32_t used_jobs
        uint32_t used_submit_jobs
        long double level_fs
        bitstr_t* valid_qos

    cdef struct slurmdb_bf_usage:
        uint64_t count
        time_t last_sched

    ctypedef struct slurmdb_cluster_cond_t:
        uint16_t classification
        List cluster_list
        List federation_list
        uint32_t flags
        List format_list
        List plugin_id_select_list
        List rpc_version_list
        time_t usage_end
        time_t usage_start
        uint16_t with_deleted
        uint16_t with_usage

    ctypedef struct slurmdb_cluster_fed_t:
        List feature_list
        uint32_t id
        char* name
        void* recv
        void* send
        uint32_t state
        bool sync_recvd
        bool sync_sent

    cdef struct slurmdb_cluster_rec:
        List accounting_list
        uint16_t classification
        time_t comm_fail_time
        # slurm_addr_t control_addr
        char* control_host
        uint32_t control_port
        uint16_t dimensions
        int* dim_size
        slurmdb_cluster_fed_t fed
        uint32_t flags
        # pthread_mutex_t lock
        char* name
        char* nodes
        uint32_t plugin_id_select
        slurmdb_assoc_rec_t* root_assoc
        uint16_t rpc_version
        List send_rpc
        char* tres_str

    ctypedef struct slurmdb_cluster_accounting_rec_t:
        uint64_t alloc_secs
        uint64_t down_secs
        uint64_t idle_secs
        uint64_t over_secs
        uint64_t pdown_secs
        time_t period_start
        uint64_t resv_secs
        slurmdb_tres_rec_t tres_rec

    ctypedef struct slurmdb_clus_res_rec_t:
        char* cluster
        uint16_t percent_allowed

    ctypedef struct slurmdb_coord_rec_t:
        char* name
        uint16_t direct

    ctypedef struct slurmdb_event_cond_t:
        List cluster_list
        uint32_t cpus_max
        uint32_t cpus_min
        uint16_t event_type
        List format_list
        char* node_list
        time_t period_end
        time_t period_start
        List reason_list
        List reason_uid_list
        List state_list

    ctypedef struct slurmdb_event_rec_t:
        char* cluster
        char* cluster_nodes
        uint16_t event_type
        char* node_name
        time_t period_end
        time_t period_start
        char* reason
        uint32_t reason_uid
        uint32_t state
        char* tres_str

    ctypedef struct slurmdb_federation_cond_t:
        List cluster_list
        List federation_list
        List format_list
        uint16_t with_deleted

    ctypedef struct slurmdb_federation_rec_t:
        char* name
        uint32_t flags
        List cluster_list

    ctypedef struct slurmdb_job_rec_t:
        char* account
        char* admin_comment
        uint32_t alloc_nodes
        uint32_t array_job_id
        uint32_t array_max_tasks
        uint32_t array_task_id
        char* array_task_str
        uint32_t associd
        char* blockid
        char* cluster
        char* constraints
        uint64_t db_index
        uint32_t derived_ec
        char* derived_es
        uint32_t elapsed
        time_t eligible
        time_t end
        uint32_t exitcode
        uint32_t flags
        void* first_step_ptr
        uint32_t gid
        uint32_t het_job_id
        uint32_t het_job_offset
        uint32_t jobid
        char* jobname
        uint32_t lft
        char* mcs_label
        char* nodes
        char* partition
        uint32_t priority
        uint32_t qosid
        uint32_t req_cpus
        uint64_t req_mem
        uint32_t requid
        uint32_t resvid
        char* resv_name
        uint32_t show_full
        time_t start
        uint32_t state
        uint32_t state_reason_prev
        slurmdb_stats_t stats
        List steps
        time_t submit
        uint32_t suspended
        char* system_comment
        uint32_t sys_cpu_sec
        uint32_t sys_cpu_usec
        uint32_t timelimit
        uint32_t tot_cpu_sec
        uint32_t tot_cpu_usec
        uint16_t track_steps
        char* tres_alloc_str
        char* tres_req_str
        uint32_t uid
        char* used_gres
        char* user
        uint32_t user_cpu_sec
        uint32_t user_cpu_usec
        char* wckey
        uint32_t wckeyid
        char* work_dir

    ctypedef struct slurmdb_qos_usage_t:
        uint32_t accrue_cnt
        List acct_limit_list
        List job_list
        bitstr_t* grp_node_bitmap
        uint16_t* grp_node_job_cnt
        uint32_t grp_used_jobs
        uint32_t grp_used_submit_jobs
        uint64_t* grp_used_tres
        uint64_t* grp_used_tres_run_secs
        double grp_used_wall
        double norm_priority
        uint32_t tres_cnt
        long double usage_raw
        long double* usage_tres_raw
        List user_limit_list

    ctypedef struct slurmdb_qos_rec_t:
        char* description
        uint32_t id
        uint32_t flags
        uint32_t grace_time
        uint32_t grp_jobs_accrue
        uint32_t grp_jobs
        uint32_t grp_submit_jobs
        char* grp_tres
        uint64_t* grp_tres_ctld
        char* grp_tres_mins
        uint64_t* grp_tres_mins_ctld
        char* grp_tres_run_mins
        uint64_t* grp_tres_run_mins_ctld
        uint32_t grp_wall
        uint32_t max_jobs_pa
        uint32_t max_jobs_pu
        uint32_t max_jobs_accrue_pa
        uint32_t max_jobs_accrue_pu
        uint32_t max_submit_jobs_pa
        uint32_t max_submit_jobs_pu
        char* max_tres_mins_pj
        uint64_t* max_tres_mins_pj_ctld
        char* max_tres_pa
        uint64_t* max_tres_pa_ctld
        char* max_tres_pj
        uint64_t* max_tres_pj_ctld
        char* max_tres_pn
        uint64_t* max_tres_pn_ctld
        char* max_tres_pu
        uint64_t* max_tres_pu_ctld
        char* max_tres_run_mins_pa
        uint64_t* max_tres_run_mins_pa_ctld
        char* max_tres_run_mins_pu
        uint64_t* max_tres_run_mins_pu_ctld
        uint32_t max_wall_pj
        uint32_t min_prio_thresh
        char* min_tres_pj
        uint64_t* min_tres_pj_ctld
        char* name
        bitstr_t* preempt_bitstr
        List preempt_list
        uint16_t preempt_mode
        uint32_t preempt_exempt_time
        uint32_t priority
        slurmdb_qos_usage_t* usage
        double usage_factor
        double usage_thres
        time_t blocked_until

    ctypedef struct slurmdb_qos_cond_t:
        List description_list
        List id_list
        List format_list
        List name_list
        uint16_t preempt_mode
        uint16_t with_deleted

    ctypedef struct slurmdb_reservation_cond_t:
        List cluster_list
        uint64_t flags
        List format_list
        List id_list
        List name_list
        char* nodes
        time_t time_end
        time_t time_start
        uint16_t with_usage

    ctypedef struct slurmdb_reservation_rec_t:
        char* assocs
        char* cluster
        uint64_t flags
        uint32_t id
        char* name
        char* nodes
        char* node_inx
        time_t time_end
        time_t time_start
        time_t time_start_prev
        char* tres_str
        double unused_wall
        List tres_list

    ctypedef struct slurmdb_step_rec_t:
        uint32_t elapsed
        time_t end
        int32_t exitcode
        slurmdb_job_rec_t* job_ptr
        uint32_t nnodes
        char* nodes
        uint32_t ntasks
        char* pid_str
        uint32_t req_cpufreq_min
        uint32_t req_cpufreq_max
        uint32_t req_cpufreq_gov
        uint32_t requid
        time_t start
        uint32_t state
        slurmdb_stats_t stats
        slurm_step_id_t step_id
        char* stepname
        uint32_t suspended
        uint32_t sys_cpu_sec
        uint32_t sys_cpu_usec
        uint32_t task_dist
        uint32_t tot_cpu_sec
        uint32_t tot_cpu_usec
        char* tres_alloc_str
        uint32_t user_cpu_sec
        uint32_t user_cpu_usec

    ctypedef struct slurmdb_res_cond_t:
        List cluster_list
        List description_list
        uint32_t flags
        List format_list
        List id_list
        List manager_list
        List name_list
        List percent_list
        List server_list
        List type_list
        uint16_t with_deleted
        uint16_t with_clusters

    ctypedef struct slurmdb_res_rec_t:
        List clus_res_list
        slurmdb_clus_res_rec_t* clus_res_rec
        uint32_t count
        char* description
        uint32_t flags
        uint32_t id
        char* manager
        char* name
        uint16_t percent_used
        char* server
        uint32_t type

    ctypedef struct slurmdb_txn_cond_t:
        List acct_list
        List action_list
        List actor_list
        List cluster_list
        List format_list
        List id_list
        List info_list
        List name_list
        time_t time_end
        time_t time_start
        List user_list
        uint16_t with_assoc_info

    ctypedef struct slurmdb_txn_rec_t:
        char* accts
        uint16_t action
        char* actor_name
        char* clusters
        uint32_t id
        char* set_info
        time_t timestamp
        char* users
        char* where_query

    ctypedef struct slurmdb_used_limits_t:
        uint32_t accrue_cnt
        char* acct
        uint32_t jobs
        uint32_t submit_jobs
        uint64_t* tres
        uint64_t* tres_run_mins
        bitstr_t* node_bitmap
        uint16_t* node_job_cnt
        uint32_t uid

    ctypedef struct slurmdb_user_cond_t:
        uint16_t admin_level
        slurmdb_assoc_cond_t* assoc_cond
        List def_acct_list
        List def_wckey_list
        uint16_t with_assocs
        uint16_t with_coords
        uint16_t with_deleted
        uint16_t with_wckeys
        uint16_t without_defaults

    cdef struct slurmdb_user_rec:
        uint16_t admin_level
        List assoc_list
        slurmdb_bf_usage_t* bf_usage
        List coord_accts
        char* default_acct
        char* default_wckey
        uint32_t flags
        char* name
        char* old_name
        uint32_t uid
        List wckey_list

    ctypedef struct slurmdb_update_object_t:
        List objects
        uint16_t type

    ctypedef struct slurmdb_wckey_cond_t:
        List cluster_list
        List format_list
        List id_list
        List name_list
        uint16_t only_defs
        time_t usage_end
        time_t usage_start
        List user_list
        uint16_t with_usage
        uint16_t with_deleted

    ctypedef struct slurmdb_wckey_rec_t:
        List accounting_list
        char* cluster
        uint32_t flags
        uint32_t id
        uint16_t is_def
        char* name
        uint32_t uid
        char* user

    ctypedef struct slurmdb_print_tree_t:
        char* name
        char* print_name
        char* spaces
        uint16_t user

    ctypedef struct slurmdb_hierarchical_rec_t:
        slurmdb_assoc_rec_t* assoc
        char* sort_name
        List children

    ctypedef struct slurmdb_report_assoc_rec_t:
        char* acct
        char* cluster
        char* parent_acct
        List tres_list
        char* user

    ctypedef struct slurmdb_report_user_rec_t:
        char* acct
        List acct_list
        List assoc_list
        char* name
        List tres_list
        uid_t uid

    ctypedef struct slurmdb_report_cluster_rec_t:
        List accounting_list
        List assoc_list
        char* name
        List tres_list
        List user_list

    ctypedef struct slurmdb_report_job_grouping_t:
        uint32_t count
        List jobs
        uint32_t min_size
        uint32_t max_size
        List tres_list

    ctypedef struct slurmdb_report_acct_grouping_t:
        char* acct
        uint32_t count
        List groups
        uint32_t lft
        uint32_t rgt
        List tres_list

    ctypedef struct slurmdb_report_cluster_grouping_t:
        List acct_list
        char* cluster
        uint32_t count
        List tres_list

    cdef enum:
        DBD_ROLLUP_HOUR
        DBD_ROLLUP_DAY
        DBD_ROLLUP_MONTH
        DBD_ROLLUP_COUNT

    ctypedef struct slurmdb_rollup_stats_t:
        char* cluster_name
        uint16_t count[4]
        time_t timestamp[4]
        uint64_t time_last[4]
        uint64_t time_max[4]
        uint64_t time_total[4]

    ctypedef struct slurmdb_rpc_obj_t:
        uint32_t cnt
        uint32_t id
        uint64_t time
        uint64_t time_ave

    ctypedef struct slurmdb_stats_rec_t:
        slurmdb_rollup_stats_t* dbd_rollup_stats
        List rollup_stats
        List rpc_list
        time_t time_start
        List user_list

    slurmdb_cluster_rec_t* working_cluster_rec

    int slurmdb_accounts_add(void* db_conn, List acct_list)

    List slurmdb_accounts_get(void* db_conn, slurmdb_account_cond_t* acct_cond)

    List slurmdb_accounts_modify(void* db_conn, slurmdb_account_cond_t* acct_cond, slurmdb_account_rec_t* acct)

    List slurmdb_accounts_remove(void* db_conn, slurmdb_account_cond_t* acct_cond)

    int slurmdb_archive(void* db_conn, slurmdb_archive_cond_t* arch_cond)

    int slurmdb_archive_load(void* db_conn, slurmdb_archive_rec_t* arch_rec)

    int slurmdb_associations_add(void* db_conn, List assoc_list)

    List slurmdb_associations_get(void* db_conn, slurmdb_assoc_cond_t* assoc_cond)

    List slurmdb_associations_modify(void* db_conn, slurmdb_assoc_cond_t* assoc_cond, slurmdb_assoc_rec_t* assoc)

    List slurmdb_associations_remove(void* db_conn, slurmdb_assoc_cond_t* assoc_cond)

    int slurmdb_clusters_add(void* db_conn, List cluster_list)

    List slurmdb_clusters_get(void* db_conn, slurmdb_cluster_cond_t* cluster_cond)

    List slurmdb_clusters_modify(void* db_conn, slurmdb_cluster_cond_t* cluster_cond, slurmdb_cluster_rec_t* cluster)

    List slurmdb_clusters_remove(void* db_conn, slurmdb_cluster_cond_t* cluster_cond)

    List slurmdb_report_cluster_account_by_user(void* db_conn, slurmdb_assoc_cond_t* assoc_cond)

    List slurmdb_report_cluster_user_by_account(void* db_conn, slurmdb_assoc_cond_t* assoc_cond)

    List slurmdb_report_cluster_wckey_by_user(void* db_conn, slurmdb_wckey_cond_t* wckey_cond)

    List slurmdb_report_cluster_user_by_wckey(void* db_conn, slurmdb_wckey_cond_t* wckey_cond)

    List slurmdb_report_job_sizes_grouped_by_account(void* db_conn, slurmdb_job_cond_t* job_cond, List grouping_list, bool flat_view, bool acct_as_parent)

    List slurmdb_report_job_sizes_grouped_by_wckey(void* db_conn, slurmdb_job_cond_t* job_cond, List grouping_list)

    List slurmdb_report_job_sizes_grouped_by_account_then_wckey(void* db_conn, slurmdb_job_cond_t* job_cond, List grouping_list, bool flat_view, bool acct_as_parent)

    List slurmdb_report_user_top_usage(void* db_conn, slurmdb_user_cond_t* user_cond, bool group_accounts)

    void* slurmdb_connection_get(uint16_t* persist_conn_flags)

    int slurmdb_connection_close(void** db_conn)

    int slurmdb_connection_commit(void* db_conn, bool commit)

    int slurmdb_coord_add(void* db_conn, List acct_list, slurmdb_user_cond_t* user_cond)

    List slurmdb_coord_remove(void* db_conn, List acct_list, slurmdb_user_cond_t* user_cond)

    int slurmdb_federations_add(void* db_conn, List federation_list)

    List slurmdb_federations_modify(void* db_conn, slurmdb_federation_cond_t* fed_cond, slurmdb_federation_rec_t* fed)

    List slurmdb_federations_remove(void* db_conn, slurmdb_federation_cond_t* fed_cond)

    List slurmdb_federations_get(void* db_conn, slurmdb_federation_cond_t* fed_cond)

    List slurmdb_job_modify(void* db_conn, slurmdb_job_cond_t* job_cond, slurmdb_job_rec_t* job)

    List slurmdb_jobs_get(void* db_conn, slurmdb_job_cond_t* job_cond)

    int slurmdb_jobs_fix_runaway(void* db_conn, List jobs)

    int slurmdb_jobcomp_init(char* jobcomp_loc)

    int slurmdb_jobcomp_fini()

    List slurmdb_jobcomp_jobs_get(slurmdb_job_cond_t* job_cond)

    int slurmdb_reconfig(void* db_conn)

    int slurmdb_shutdown(void* db_conn)

    int slurmdb_clear_stats(void* db_conn)

    int slurmdb_get_stats(void* db_conn, slurmdb_stats_rec_t** stats_pptr)

    List slurmdb_config_get(void* db_conn)

    List slurmdb_events_get(void* db_conn, slurmdb_event_cond_t* event_cond)

    List slurmdb_problems_get(void* db_conn, slurmdb_assoc_cond_t* assoc_cond)

    List slurmdb_reservations_get(void* db_conn, slurmdb_reservation_cond_t* resv_cond)

    List slurmdb_txn_get(void* db_conn, slurmdb_txn_cond_t* txn_cond)

    List slurmdb_get_info_cluster(char* cluster_names)

    int slurmdb_get_first_avail_cluster(job_desc_msg_t* req, char* cluster_names, slurmdb_cluster_rec_t** cluster_rec)

    int slurmdb_get_first_het_job_cluster(List job_req_list, char* cluster_names, slurmdb_cluster_rec_t** cluster_rec)

    void slurmdb_destroy_assoc_usage(void* object)

    void slurmdb_destroy_bf_usage(void* object)

    void slurmdb_destroy_bf_usage_members(void* object)

    void slurmdb_destroy_qos_usage(void* object)

    void slurmdb_destroy_user_rec(void* object)

    void slurmdb_destroy_account_rec(void* object)

    void slurmdb_destroy_coord_rec(void* object)

    void slurmdb_destroy_clus_res_rec(void* object)

    void slurmdb_destroy_cluster_accounting_rec(void* object)

    void slurmdb_destroy_cluster_rec(void* object)

    void slurmdb_destroy_federation_rec(void* object)

    void slurmdb_destroy_accounting_rec(void* object)

    void slurmdb_free_assoc_mgr_state_msg(void* object)

    void slurmdb_free_assoc_rec_members(slurmdb_assoc_rec_t* assoc)

    void slurmdb_destroy_assoc_rec(void* object)

    void slurmdb_destroy_event_rec(void* object)

    void slurmdb_destroy_job_rec(void* object)

    void slurmdb_free_qos_rec_members(slurmdb_qos_rec_t* qos)

    void slurmdb_destroy_qos_rec(void* object)

    void slurmdb_destroy_reservation_rec(void* object)

    void slurmdb_destroy_step_rec(void* object)

    void slurmdb_destroy_res_rec(void* object)

    void slurmdb_destroy_txn_rec(void* object)

    void slurmdb_destroy_wckey_rec(void* object)

    void slurmdb_destroy_archive_rec(void* object)

    void slurmdb_destroy_tres_rec_noalloc(void* object)

    void slurmdb_destroy_tres_rec(void* object)

    void slurmdb_destroy_report_assoc_rec(void* object)

    void slurmdb_destroy_report_user_rec(void* object)

    void slurmdb_destroy_report_cluster_rec(void* object)

    void slurmdb_destroy_user_cond(void* object)

    void slurmdb_destroy_account_cond(void* object)

    void slurmdb_destroy_cluster_cond(void* object)

    void slurmdb_destroy_federation_cond(void* object)

    void slurmdb_destroy_tres_cond(void* object)

    void slurmdb_destroy_assoc_cond(void* object)

    void slurmdb_destroy_event_cond(void* object)

    void slurmdb_destroy_job_cond(void* object)

    void slurmdb_destroy_qos_cond(void* object)

    void slurmdb_destroy_reservation_cond(void* object)

    void slurmdb_destroy_res_cond(void* object)

    void slurmdb_destroy_txn_cond(void* object)

    void slurmdb_destroy_wckey_cond(void* object)

    void slurmdb_destroy_archive_cond(void* object)

    void slurmdb_destroy_update_object(void* object)

    void slurmdb_destroy_used_limits(void* object)

    void slurmdb_destroy_print_tree(void* object)

    void slurmdb_destroy_hierarchical_rec(void* object)

    void slurmdb_destroy_report_job_grouping(void* object)

    void slurmdb_destroy_report_acct_grouping(void* object)

    void slurmdb_destroy_report_cluster_grouping(void* object)

    void slurmdb_destroy_rpc_obj(void* object)

    void slurmdb_destroy_rollup_stats(void* object)

    void slurmdb_free_stats_rec_members(void* object)

    void slurmdb_destroy_stats_rec(void* object)

    void slurmdb_free_slurmdb_stats_members(slurmdb_stats_t* stats)

    void slurmdb_destroy_slurmdb_stats(slurmdb_stats_t* stats)

    void slurmdb_init_assoc_rec(slurmdb_assoc_rec_t* assoc, bool free_it)

    void slurmdb_init_clus_res_rec(slurmdb_clus_res_rec_t* clus_res, bool free_it)

    void slurmdb_init_cluster_rec(slurmdb_cluster_rec_t* cluster, bool free_it)

    void slurmdb_init_federation_rec(slurmdb_federation_rec_t* federation, bool free_it)

    void slurmdb_init_qos_rec(slurmdb_qos_rec_t* qos, bool free_it, uint32_t init_val)

    void slurmdb_init_res_rec(slurmdb_res_rec_t* res, bool free_it)

    void slurmdb_init_wckey_rec(slurmdb_wckey_rec_t* wckey, bool free_it)

    void slurmdb_init_tres_cond(slurmdb_tres_cond_t* tres, bool free_it)

    void slurmdb_init_cluster_cond(slurmdb_cluster_cond_t* cluster, bool free_it)

    void slurmdb_init_federation_cond(slurmdb_federation_cond_t* federation, bool free_it)

    void slurmdb_init_res_cond(slurmdb_res_cond_t* cluster, bool free_it)

    List slurmdb_get_hierarchical_sorted_assoc_list(List assoc_list, bool use_lft)

    List slurmdb_get_acct_hierarchical_rec_list(List assoc_list)

    char* slurmdb_tree_name_get(char* name, char* parent, List tree_list)

    int slurmdb_res_add(void* db_conn, List res_list)

    List slurmdb_res_get(void* db_conn, slurmdb_res_cond_t* res_cond)

    List slurmdb_res_modify(void* db_conn, slurmdb_res_cond_t* res_cond, slurmdb_res_rec_t* res)

    List slurmdb_res_remove(void* db_conn, slurmdb_res_cond_t* res_cond)

    int slurmdb_qos_add(void* db_conn, List qos_list)

    List slurmdb_qos_get(void* db_conn, slurmdb_qos_cond_t* qos_cond)

    List slurmdb_qos_modify(void* db_conn, slurmdb_qos_cond_t* qos_cond, slurmdb_qos_rec_t* qos)

    List slurmdb_qos_remove(void* db_conn, slurmdb_qos_cond_t* qos_cond)

    int slurmdb_tres_add(void* db_conn, List tres_list)

    List slurmdb_tres_get(void* db_conn, slurmdb_tres_cond_t* tres_cond)

    int slurmdb_usage_get(void* db_conn, void* in_, int type, time_t start, time_t end)

    int slurmdb_usage_roll(void* db_conn, time_t sent_start, time_t sent_end, uint16_t archive_data, List* rollup_stats_list_in)

    int slurmdb_users_add(void* db_conn, List user_list)

    List slurmdb_users_get(void* db_conn, slurmdb_user_cond_t* user_cond)

    List slurmdb_users_modify(void* db_conn, slurmdb_user_cond_t* user_cond, slurmdb_user_rec_t* user)

    List slurmdb_users_remove(void* db_conn, slurmdb_user_cond_t* user_cond)

    int slurmdb_wckeys_add(void* db_conn, List wckey_list)

    List slurmdb_wckeys_get(void* db_conn, slurmdb_wckey_cond_t* wckey_cond)

    List slurmdb_wckeys_modify(void* db_conn, slurmdb_wckey_cond_t* wckey_cond, slurmdb_wckey_rec_t* wckey)

    List slurmdb_wckeys_remove(void* db_conn, slurmdb_wckey_cond_t* wckey_cond)



#
# PySlurm helper functions
#


cdef inline listOrNone(char* value, sep_char):
    if value is NULL:
        return []

    if not sep_char:
        return value.decode("UTF-8", "replace")

    if sep_char == b'':
        return value.decode("UTF-8", "replace")

    return value.decode("UTF_8", "replace").split(sep_char)


cdef inline stringOrNone(char* value, value2):
    if value is NULL:
        if value2 is '':
            return None
        return u"%s" % value2
    return u"%s" % value.decode("UTF-8", "replace")


cdef inline int16orNone(uint16_t value):
    if value is NO_VAL16:
        return None
    else:
        return value


cdef inline int32orNone(uint32_t value):
    if value is NO_VAL:
        return None
    else:
        return value


cdef inline int64orNone(uint64_t value):
    if value is NO_VAL64:
        return None
    else:
        return value


cdef inline int16orUnlimited(uint16_t value, return_type):
    if value is INFINITE16:
        if return_type is "int":
            return None
        else:
            return u"UNLIMITED"
    else:
        if return_type is "int":
            return value
        else:
            return str(value)


cdef inline boolToString(int value):
    if value == 0:
        return u'False'
    return u'True'


cdef extern char **environ

cdef extern char *slurm_preempt_mode_string (uint16_t preempt_mode)
cdef extern void slurm_make_time_str (time_t *time, char *string, int size)
cdef extern char *slurm_job_state_string (uint16_t inx)
cdef extern char *slurm_job_reason_string (int inx)
cdef extern void slurm_env_array_merge(char ***dest_array, const_char_pptr src_array)
cdef extern char **slurm_env_array_create()
cdef extern int slurm_env_array_overwrite(char ***array_ptr, const_char_ptr name, const_char_ptr value)
cdef extern char *slurm_node_state_string (uint32_t inx)
cdef extern char *slurm_step_layout_type_name (task_dist_states_t task_dist)
cdef extern void slurm_xfree (void **, const_char_ptr, int, const_char_ptr)
cdef extern char *slurm_reservation_flags_string (reserve_info_t *resv_ptr)
cdef extern void slurm_free_stats_response_msg (stats_info_response_msg_t *msg)
cdef extern int slurm_addto_char_list_with_case(List char_list, char *names, bool lower_case_noralization)
cdef extern int slurm_addto_step_list(List step_list, char *names)
cdef extern time_t slurm_parse_time(char *time_str, int past)
cdef extern int slurmdb_report_set_start_end_time(time_t *start, time_t *end)

cdef inline xfree(void *__p):
    slurm_xfree(&__p, __FILE__, __LINE__, __FUNCTION__)
