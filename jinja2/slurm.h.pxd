cdef extern from "slurm/slurm.h":

    enum:
        SLURM_VERSION_NUMBER


{% include 'jinja2/defines/slurm_defines.pxd' %}

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
