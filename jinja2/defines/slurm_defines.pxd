{% filter indent(width=4) %}
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
uint8_t READY_NODE_STATE
uint8_t READY_JOB_STATE

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
uint8_t NODE_MEM_CALC
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
uint32_t JOB_PROM

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
uint64_t RESERVE_FLAG_PROM
uint64_t RESERVE_FLAG_NO_PROM

uint8_t DEBUG_FLAG_SELECT_TYPE
uint8_t DEBUG_FLAG_STEPS
uint8_t DEBUG_FLAG_TRIGGERS
uint8_t DEBUG_FLAG_CPU_BIND
uint8_t DEBUG_FLAG_WIKI
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
{%- endfilter %}
