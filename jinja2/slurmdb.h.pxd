cdef extern from "slurm/slurmdb.h":

{% include 'jinja2/defines/slurmdb_defines.pxd' %}

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
