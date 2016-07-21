from common cimport *

cdef extern from "slurm/slurm.h" nogil:
    ctypedef struct job_resources_t:
        pass

    ctypedef struct slurm_job_info_t:
        char *account
        char *alloc_node
        uint32_t alloc_sid
        void *array_bitmap
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
        time_t deadline
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

    ctypedef slurm_job_info_t job_info_t

    ctypedef struct job_info_msg_t:
        time_t last_update
        uint32_t record_count
        slurm_job_info_t *job_array

    int slurm_load_jobs(time_t update_time,
                        job_info_msg_t **job_info_msg_pptr,
                        uint16_t show_flags)

    int slurm_load_job_user(job_info_msg_t **job_info_msg_pptr,
                            uint32_t user_id, uint16_t show_flags)

    void slurm_free_job_info_msg(job_info_msg_t *job_buffer_ptr)
