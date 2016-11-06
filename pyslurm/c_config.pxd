# c_config.pxd
#
from libc.stdint cimport uint16_t, uint32_t, uint64_t
from libc.stdio cimport FILE
from posix.types cimport time_t

cdef extern from "slurm/slurm.h" nogil:
    long SLURM_VERSION_NUMBER
    long SLURM_VERSION_MAJOR(long a)
    long SLURM_VERSION_MINOR(long a)
    long SLURM_VERSION_MICRO(long a)

    enum:
        GROUP_CACHE
        GROUP_FORCE
        GROUP_TIME_MASK

    ctypedef struct slurm_ctl_conf_t:
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
        char *mcs_plugin
        char *mcs_plugin_params
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

    enum:
        CPU_FREQ_RANGE_FLAG
        CPU_FREQ_LOW
        CPU_FREQ_MEDIUM
        CPU_FREQ_HIGH
        CPU_FREQ_HIGHM1
        CPU_FREQ_CONSERVATIVE
        CPU_FREQ_ONDEMAND
        CPU_FREQ_PERFORMANCE
        CPU_FREQ_POWERSAVE
        CPU_FREQ_USERSPACE
        CPU_FREQ_GOV_MASK

    enum:
        DEBUG_FLAG_SELECT_TYPE
        DEBUG_FLAG_STEPS
        DEBUG_FLAG_TRIGGERS
        DEBUG_FLAG_CPU_BIND
        DEBUG_FLAG_WIKI
        DEBUG_FLAG_NO_CONF_HASH
        DEBUG_FLAG_GRES
        DEBUG_FLAG_BG_PICK
        DEBUG_FLAG_BG_WIRES
        DEBUG_FLAG_BG_ALGO
        DEBUG_FLAG_BG_ALGO_DEEP
        DEBUG_FLAG_PRIO
        DEBUG_FLAG_BACKFILL
        DEBUG_FLAG_GANG
        DEBUG_FLAG_RESERVATION
        DEBUG_FLAG_FRONT_END
        DEBUG_FLAG_NO_REALTIME
        DEBUG_FLAG_SWITCH
        DEBUG_FLAG_ENERGY
        DEBUG_FLAG_EXT_SENSORS
        DEBUG_FLAG_LICENSE
        DEBUG_FLAG_PROFILE
        DEBUG_FLAG_INFINIBAND
        DEBUG_FLAG_FILESYSTEM
        DEBUG_FLAG_JOB_CONT
        DEBUG_FLAG_TASK
        DEBUG_FLAG_PROTOCOL
        DEBUG_FLAG_BACKFILL_MAP
        DEBUG_FLAG_TRACE_JOBS
        DEBUG_FLAG_ROUTE
        DEBUG_FLAG_DB_ASSOC
        DEBUG_FLAG_DB_EVENT
        DEBUG_FLAG_DB_JOB
        DEBUG_FLAG_DB_QOS
        DEBUG_FLAG_DB_QUERY
        DEBUG_FLAG_DB_RESV
        DEBUG_FLAG_DB_RES
        DEBUG_FLAG_DB_STEP
        DEBUG_FLAG_DB_USAGE
        DEBUG_FLAG_DB_WCKEY
        DEBUG_FLAG_BURST_BUF
        DEBUG_FLAG_CPU_FREQ
        DEBUG_FLAG_POWER
        DEBUG_FLAG_TIME_CRAY
        DEBUG_FLAG_DB_ARCHIVE
        DEBUG_FLAG_DB_TRES
        DEBUG_FLAG_ESEARCH
        DEBUG_FLAG_NODE_FEATURES

    enum:
        HEALTH_CHECK_NODE_IDLE
        HEALTH_CHECK_NODE_ALLOC
        HEALTH_CHECK_NODE_MIXED
        HEALTH_CHECK_CYCLE
        HEALTH_CHECK_NODE_ANY

    enum:
        PRIORITY_RESET_NONE
        PRIORITY_RESET_NOW
        PRIORITY_RESET_DAILY
        PRIORITY_RESET_WEEKLY
        PRIORITY_RESET_MONTHLY
        PRIORITY_RESET_QUARTERLY
        PRIORITY_RESET_YEARLY

    enum:
        PRIORITY_FLAGS_ACCRUE_ALWAYS
        PRIORITY_FLAGS_MAX_TRES
        PRIORITY_FLAGS_SIZE_RELATIVE
        PRIORITY_FLAGS_DEPTH_OBLIVIOUS
        PRIORITY_FLAGS_CALCULATE_RUNNING
        PRIORITY_FLAGS_FAIR_TREE

    enum:
        PROLOG_FLAG_ALLOC
        PROLOG_FLAG_NOHOLD
        PROLOG_FLAG_CONTAIN

    enum:
        RECONFIG_KEEP_PART_INFO
        RECONFIG_KEEP_PART_STAT

    enum:
        CR_CPU
        CR_SOCKET
        CR_CORE
        CR_BOARD
        CR_MEMORY
        CR_OTHER_CONS_RES
        CR_NHC_STEP_NO
        CR_NHC_NO
        CR_ONE_TASK_PER_CORE
        CR_PACK_NODES
        CR_NHC_ABSOLUTELY_NO
        CR_CORE_DEFAULT_DIST_BLOCK
        CR_LLN


    void slurm_free_ctl_conf(slurm_ctl_conf_t *slurm_ctl_conf_ptr)

    int slurm_load_ctl_conf(time_t update_time,
                            slurm_ctl_conf_t **slurm_ctl_conf_ptr)

    void slurm_print_ctl_conf(FILE *out,
                              slurm_ctl_conf_t *slurm_ctl_conf_ptr)

#
# Config declarations outside of slurm.h
#

cdef extern void slurm_accounting_enforce_string(uint16_t enforce,
                                                 char *s,
                                                 int str_len)

cdef extern void slurm_private_data_string(uint16_t private_data,
                                           char *s, int str_len)
