
import string

cdef extern from "stdlib.h":
    ctypedef long long size_t
    ctypedef unsigned char uint8_t
    ctypedef unsigned short int uint16_t
    ctypedef unsigned int uint32_t
    ctypedef signed long long int64_t
    ctypedef unsigned long long uint64_t
    void free(void *__ptr)
    void* malloc(size_t size)
    void* calloc(unsigned int nmemb, unsigned int size)
    object PyCObject_FromVoidPtr(void* cobj, void (*destr)(void *))
    void* PyCObject_AsVoidPtr(object)

cdef extern from "stdio.h":
    ctypedef struct FILE
    cdef FILE *stdout

cdef extern from "Python.h":
    cdef FILE *PyFile_AsFile(object file)

cdef ptr_wrapper(void* ptr):
    return PyCObject_FromVoidPtr(ptr, NULL)

cdef void *ptr_unwrapper(object obj):
    return PyCObject_AsVoidPtr(obj)

cdef extern from "time.h":
    ctypedef int time_t

cdef char** pyStringSeqToStringArray(seq):

    cdef char **msgArray

    msgArray = NULL
    i = 0
    length = len(seq)

    if length != 0:
        msgArray = <char**> malloc((length+1)*sizeof(char*))
        for line in seq:
            msgArray[i] = line
            i = i + 1

        msgArray[i] = NULL

    return msgArray

cdef int* pyIntSeqToIntArray(seq):

    cdef int *intArray

    intArray = NULL
    i = 0
    length= len(seq)

    if length != 0:
        intArray = <int*> malloc((length+1)*sizeof(int))
        for line in seq:
            intArray[i] = line
            i = i + 1

        intArray[i] = <int>NULL

    return intArray

cdef long* pyLongSeqToLongArray(seq):

    cdef long *intArray

    intArray = NULL
    i = 0
    length= len(seq)

    if length != 0:
        intArray = <long*> malloc((length+1)*sizeof(long))
        for line in seq:
            intArray[i] = line
            i = i + 1

        intArray[i] = <long>NULL

    return intArray

#cdef extern from "slurm/spank.h":
#
#    cdef extern void slurm_verbose (char *, ...)

cdef extern from "slurm/slurm_errno.h":

    cdef extern char * c_slurm_strerror "slurm_strerror" (int)

    cdef void c_slurm_seterrno "slurm_seterrno" (int)

    cdef int c_slurm_get_errno "slurm_get_errno" ()

    cdef void c_slurm_perror "slurm_perror" (char *)

cdef extern from "slurm/slurm.h":

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
        WAIT_TBD2
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

    cdef enum node_states:
        NODE_STATE_UNKNOWN
        NODE_STATE_DOWN
        NODE_STATE_IDLE
        NODE_STATE_ALLOCATED
        NODE_STATE_ERROR
        NODE_STATE_MIXED
        NODE_STATE_FUTURE
        NODE_STATE_END

    cdef struct job_descriptor:
        char *account
        uint16_t acctg_freq
        char *alloc_node
        uint16_t alloc_resp_port
        uint32_t alloc_sid
        uint32_t argc
        char **argv
        time_t begin_time
        uint16_t ckpt_interval
        char *ckpt_dir
        char *comment
        uint16_t contiguous
        char *cpu_bind
        uint16_t cpu_bind_type
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
        uint16_t kill_on_node_fail
        char *licenses
        uint16_t mail_type
        char *mail_user
        char *mem_bind
        uint16_t mem_bind_type
        char *name
        char *network
        uint16_t nice
        uint32_t num_tasks
        uint8_t open_mode
        uint16_t other_port
        uint8_t overcommit
        char *partition
        uint16_t plane_size
        uint32_t priority
        char *qos
        char *resp_host
        char *req_nodes
        uint16_t requeue
        char *reservation
        char *script
        uint16_t shared
        char **spank_job_env
        uint32_t spank_job_env_size
        uint16_t task_dist
        uint32_t time_limit
        uint32_t time_min
        uint32_t user_id
        uint16_t wait_all_nodes
        uint16_t warn_signal
        uint16_t warn_time
        char *work_dir
        uint16_t cpus_per_task
        uint32_t min_cpus
        uint32_t max_cpus
        uint32_t min_nodes
        uint32_t max_nodes
        uint16_t sockets_per_node
        uint16_t cores_per_socket
        uint16_t threads_per_core
        uint16_t ntasks_per_node
        uint16_t ntasks_per_socket
        uint16_t ntasks_per_core
        uint16_t pn_min_cpus
        uint32_t pn_min_memory
        uint32_t pn_min_tmp_disk
        #uint16_t geometry[HIGHEST_DIMENSIONS] # FIXME
        uint16_t conn_type
        uint16_t reboot
        uint16_t rotate
        char *blrtsimage
        char *linuximage
        char *mloaderimage
        char *ramdiskimage
        #dynamic_plugin_data_t *select_jobinfo # FIXME
        char *std_err
        char *std_in
        char *std_out
        char *wckey

    ctypedef job_descriptor job_desc_msg_t

    ctypedef struct slurm_ctl_conf:
        time_t last_update
        uint16_t accounting_storage_enforce
        char *accounting_storage_backup_host
        char *accounting_storage_host
        char *accounting_storage_loc
        char *accounting_storage_pass
        uint32_t accounting_storage_port
        char *accounting_storage_type
        char *accounting_storage_user
        char *authtype
        char *backup_addr
        char *backup_controller
        uint16_t batch_start_timeout
        time_t boot_time
        char *checkpoint_type
        char *cluster_name
        uint16_t complete_wait
        char *control_addr
        char *control_machine
        char *crypto_type
        uint32_t debug_flags
        uint32_t def_mem_per_cpu
        uint16_t disable_root_jobs
        uint16_t enforce_part_limits
        char *epilog
        uint32_t epilog_msg_time
        char *epilog_slurmctld
        uint16_t fast_schedule
        uint32_t first_job_id
        uint16_t get_env_timeout
        char * gres_plugins
        uint16_t group_info
        uint32_t hash_val
        uint16_t health_check_interval
        char * health_check_program
        uint16_t inactive_limit
        uint16_t job_acct_gather_freq
        char *job_acct_gather_type
        char *job_ckpt_dir
        char *job_comp_host
        char *job_comp_loc
        char *job_comp_pass
        uint32_t job_comp_port
        char *job_comp_type
        char *job_comp_user
        char *job_credential_private_key
        char *job_credential_public_certificate
        uint16_t job_file_append
        uint16_t job_requeue
        char *job_submit_plugins
        uint16_t kill_on_bad_exit
        uint16_t kill_wait
        char *licenses
        char *mail_prog
        uint32_t max_job_cnt
        uint32_t max_mem_per_cpu
        uint16_t max_tasks_per_node
        uint16_t min_job_age
        char *mpi_default
        char *mpi_params
        uint16_t msg_timeout
        uint32_t next_job_id
        char *node_prefix
        uint16_t over_time_limit
        char *plugindir
        char *plugstack
        uint16_t preempt_mode
        char *preempt_type
        uint32_t priority_decay_hl
        uint32_t priority_calc_period
        uint16_t priority_favor_small
        uint32_t priority_max_age
        uint16_t priority_reset_period
        char *priority_type
        uint32_t priority_weight_age
        uint32_t priority_weight_fs
        uint32_t priority_weight_js
        uint32_t priority_weight_part
        uint32_t priority_weight_qos
        uint16_t private_data
        char *proctrack_type
        char *prolog
        char *prolog_slurmctld
        uint16_t propagate_prio_process
        char *propagate_rlimits
        char *propagate_rlimits_except
        char *resume_program
        uint16_t resume_rate
        uint16_t resume_timeout
        uint16_t resv_over_run
        uint16_t ret2service
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
        uint32_t slurmctld_port
        uint16_t slurmctld_port_count
        uint16_t slurmctld_timeout
        uint16_t slurmd_debug
        char *slurmd_logfile
        char *slurmd_pidfile
        uint32_t slurmd_port
        char *slurmd_spooldir
        uint16_t slurmd_timeout
        char *srun_epilog
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
        uint16_t task_plugin_param
        char *task_prolog
        char *tmp_fs
        char *topology_plugin
        uint16_t track_wckey
        uint16_t tree_width
        char *unkillable_program
        uint16_t unkillable_timeout
        uint16_t use_pam
        char *version
        uint16_t vsize_factor
        uint16_t wait_time
        uint16_t z_16
        uint32_t z_32
        char *z_char

    ctypedef slurm_ctl_conf slurm_ctl_conf_t

    ctypedef struct job_info_t:
        char *account
        char    *alloc_node
        uint32_t alloc_sid
        uint32_t assoc_id
        uint16_t batch_flag
        char *command
        char *comment
        uint16_t contiguous
        uint16_t cpus_per_task
        char *dependency
        uint32_t derived_ec
        time_t eligible_time
        time_t end_time
        char *exc_nodes
        int *exc_node_inx
        uint32_t exit_code
        char *features
        char *gres
        uint32_t group_id
        uint32_t job_id
        uint16_t job_state
        char *licenses
        uint32_t max_cpus
        uint32_t max_nodes
        uint16_t sockets_per_node
        uint16_t cores_per_socket
        uint16_t threads_per_core
        char *name
        char *network
        char *nodes
        uint16_t nice
        int *node_inx
        uint16_t ntasks_per_core
        uint16_t ntasks_per_node
        uint16_t ntasks_per_socket
        uint32_t num_nodes
        uint32_t num_cpus
        char *partition
        uint32_t pn_min_memory
        uint16_t pn_min_cpus
        uint32_t pn_min_tmp_disk
        time_t pre_sus_time
        uint32_t priority
        char *qos
        char *req_nodes
        int *req_node_inx
        uint16_t requeue
        time_t resize_time
        uint16_t restart_cnt
        char *resv_name
        #dynamic_plugin_data_t *select_jobinfo #FIXME
        #job_resources_t *job_resrcs #FIXME
        uint16_t shared
        uint16_t show_flags
        time_t start_time
        char *state_desc
        uint16_t state_reason
        time_t submit_time
        time_t suspend_time
        uint32_t time_limit
        uint32_t time_min
        uint32_t user_id
        char *wckey
        char *work_dir

    cdef struct job_info_msg:
        time_t last_update
        uint32_t record_count
        job_info_t *job_array

    ctypedef job_info_msg job_info_msg_t

    ctypedef struct partition_info:
        char *allow_alloc_nodes
        char *allow_groups
        char *alternate
        uint32_t default_time
        uint16_t flags
        uint32_t max_nodes
        uint16_t max_share
        uint32_t max_time
        uint32_t min_nodes
        char *name
        int *node_inx
        char *nodes
        uint16_t preempt_mode
        uint16_t priority
        uint16_t state_up
        uint32_t total_cpus
        uint32_t total_nodes

    ctypedef partition_info partition_info_t

    ctypedef struct partition_info_msg_t:
        time_t last_update
        uint32_t record_count
        partition_info_t *partition_array

    ctypedef partition_info update_part_msg_t

    ctypedef struct node_info:
        char *arch
        time_t boot_time
        uint16_t cores
        uint16_t cpus
        char *features
        char *gres
        char *name
        uint16_t node_state
        char *os
        uint32_t real_memory
        char *reason
        time_t reason_time
        uint32_t reason_uid
        time_t slurmd_start_time
        uint16_t sockets
        uint16_t threads
        uint32_t tmp_disk
        uint32_t weight
        #dynamic_plugin_data_t *select_nodeinfo #FIXME

    ctypedef node_info node_info_t

    ctypedef struct node_info_msg:
        time_t last_update
        uint32_t node_scaling
        uint32_t record_count
        node_info_t *node_array

    ctypedef node_info_msg node_info_msg_t

    ctypedef struct slurmd_status_msg:
        time_t booted
        time_t last_slurmctld_msg
        uint16_t slurmd_debug
        uint16_t actual_cpus
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

    ctypedef struct job_step_info_t:
        char *ckpt_dir
        uint16_t ckpt_interval
        char *gres
        uint32_t job_id
        char *name
        char *network
        char *nodes
        int *node_inx
        uint32_t num_cpus
        uint32_t num_tasks
        char *partition
        char *resv_ports
        time_t run_time
        time_t start_time
        uint32_t step_id
        uint32_t time_limit
        uint32_t user_id

    ctypedef struct job_step_info_response_msg:
        time_t last_update
        uint32_t job_step_count
        job_step_info_t *job_steps

    ctypedef job_step_info_response_msg job_step_info_response_msg_t

    ctypedef struct slurm_step_layout:
        uint32_t node_cnt
        char *node_list
        uint16_t plane_size
        uint16_t *tasks
        uint32_t task_cnt
        uint16_t task_dist
        uint32_t **tids

    ctypedef slurm_step_layout slurm_step_layout_t

    cdef extern long c_slurm_api_version "slurm_api_version" ()

    cdef extern int c_slurm_load_ctl_conf "slurm_load_ctl_conf" (time_t, slurm_ctl_conf **)

    cdef extern void c_slurm_print_ctl_conf "slurm_print_ctl_conf" (FILE *, slurm_ctl_conf_t *)

    cdef extern void c_slurm_free_ctl_conf "slurm_free_ctl_conf" (slurm_ctl_conf_t *)

    cdef extern int c_slurm_load_partitions "slurm_load_partitions" (time_t, partition_info_msg_t **, uint16_t)

    #cdef extern void c_slurm_init_part_desc_msg "slurm_init_part_desc_msg" (update_part_msg_t *)

    cdef extern void c_slurm_print_partition_info_msg "slurm_print_partition_info_msg" (FILE *, partition_info_msg_t *,int)

    cdef extern void c_slurm_free_partition_info_msg "slurm_free_partition_info_msg" (partition_info_msg_t *)

    cdef extern void c_slurm_print_partition_info "slurm_print_partition_info" (FILE *, partition_info_t *, int)

    #cdef extern int c_slurm_update_partition "slurm_update_partition" (update_part_msg_t *)

    #cdef extern int c_slurm_delete_partition "slurm_delete_partition" (delete_part_msg_t *)

    cdef extern int c_slurm_load_jobs "slurm_load_jobs" (time_t, job_info_msg_t **, uint16_t)

    cdef extern void c_slurm_free_job_info_msg "slurm_free_job_info_msg" (job_info_msg_t *)

    cdef extern void c_slurm_print_job_info_msg "slurm_print_job_info_msg" (FILE *, job_info_msg_t *, int)

    cdef extern void c_slurm_print_job_info "slurm_print_job_info" (FILE *, job_info_t *, int)

    cdef extern char *c_slurm_sprint_job_info "slurm_sprint_job_info" (job_info_t *, int)

    cdef extern int c_slurm_get_end_time "slurm_get_end_time" (uint32_t, time_t *)

    cdef extern long c_slurm_get_rem_time "slurm_get_rem_time" (uint32_t)

    cdef extern int c_slurm_update_job "slurm_update_job" (job_desc_msg_t *)

    cdef extern int c_slurm_signal_job_step "slurm_signal_job_step" (uint32_t, uint32_t, uint16_t)

    cdef extern int c_slurm_ping "slurm_ping" (int)

    cdef extern int c_slurm_reconfigure "slurm_reconfigure" ()

    cdef extern int c_slurm_shutdown "slurm_shutdown" (uint16_t)

    cdef extern int c_slurm_suspend "slurm_suspend" (uint32_t)

    cdef extern int c_slurm_resume "slurm_resume" (uint32_t)

    cdef extern int c_slurm_requeue "slurm_requeue" (uint32_t)

    cdef extern int c_slurm_signal_job "slurm_signal_job" (uint32_t , uint16_t)

    #cdef extern int c_slurm_pid2jobid "slurm_pid2jobid" (uint32_t, uint32_t *) # pid_t ? FIXME or COMMENTME

    cdef extern int c_slurm_kill_job "slurm_kill_job" (uint32_t, uint16_t, uint16_t)

    cdef extern int c_slurm_complete_job "slurm_complete_job" (uint32_t, uint32_t)

    cdef extern int c_slurm_terminate_job "slurm_terminate_job" (uint32_t)

    cdef extern int c_slurm_terminate_job_step "slurm_terminate_job_step" (uint32_t, uint32_t)

    #cdef extern int c_slurm_checkpoint_able "slurm_checkpoint_able" (uint32_t, uint32_t, int) #time_t *start_time FIXME or COMMENTME

    cdef extern int c_slurm_checkpoint_enable "slurm_checkpoint_enable" (uint32_t, uint32_t)

    cdef extern int c_slurm_checkpoint_disable "slurm_checkpoint_disable" (uint32_t, uint32_t)

    #cdef extern int c_slurm_checkpoint_create "slurm_checkpoint_create" (uint32_t, uint32_t, uint16_t) # FIXME wrong number of argument

    #cdef extern int c_slurm_checkpoint_vacate "slurm_checkpoint_vacate" (uint32_t, uint32_t, uint16_t) # FIXME wrong number of argument

    #cdef extern int c_slurm_checkpoint_restart "slurm_checkpoint_restart" (uint32_t, uint32_t) # FIXME wrong number of argument

    #cdef extern int c_slurm_checkpoint_complete "slurm_checkpoint_complete" (uint32_t, uint32_t, int, uint32_t, char *) # FIXME wrong number of argument

    cdef extern int c_slurm_checkpoint_error "slurm_checkpoint_error" (uint32_t, uint32_t, uint32_t *, char **)

    cdef extern int c_slurm_load_node "slurm_load_node" (time_t, node_info_msg_t **, uint16_t)

    cdef extern void c_slurm_free_node_info_msg "slurm_free_node_info_msg" (node_info_msg_t *)

    cdef extern void c_slurm_print_node_info_msg "slurm_print_node_info_msg" (FILE *, node_info_msg_t *, int)

    #cdef extern void c_slurm_print_node_table "slurm_print_node_table" (FILE *, node_info_t *, int) # FIXME wrong number of argument

    cdef extern int c_slurm_load_slurmd_status "slurm_load_slurmd_status" (slurmd_status_t **)

    cdef extern void c_slurm_free_slurmd_status "slurm_free_slurmd_status" (slurmd_status_t *)

    cdef extern int c_slurm_get_job_steps "slurm_get_job_steps" (time_t, uint32_t, uint32_t, job_step_info_response_msg_t **, uint16_t)

    cdef extern void c_slurm_free_job_step_info_response_msg "slurm_free_job_step_info_response_msg" (job_step_info_response_msg_t *)

    cdef extern slurm_step_layout_t *c_slurm_job_step_layout_get "slurm_job_step_layout_get" (uint32_t, uint32_t)

    cdef void c_slurm_job_step_layout_free "slurm_job_step_layout_free" (slurm_step_layout *)


def slurm_api_version():

   cdef long version

   version = c_slurm_api_version()

   SLURM_VERSION_MAJOR = (((version) >> 16) & 0xff)
   SLURM_VERSION_MINOR = (((version) >> 8) & 0xff)
   SLURM_VERSION_MICRO = ((version) & 0xff)

   return (SLURM_VERSION_MAJOR, SLURM_VERSION_MINOR, SLURM_VERSION_MICRO)

def slurm_load_ctl_conf():

   cdef slurm_ctl_conf_t *slurm_ctl_conf_ptr
   cdef time_t Time

   Time = <time_t>NULL
   slurm_ctl_conf_ptr = NULL

   retval = c_slurm_load_ctl_conf(Time, &slurm_ctl_conf_ptr)

   Conf_ptr = ptr_wrapper(slurm_ctl_conf_ptr)

   return retval, Conf_ptr

def get_ctl_data(Conf_ptr):

   cdef slurm_ctl_conf_t *slurm_ctl_conf_ptr

   slurm_ctl_conf_ptr = <slurm_ctl_conf_t *>ptr_unwrapper(Conf_ptr)

   primary = ""
   if slurm_ctl_conf_ptr.control_machine != NULL:
     primary = slurm_ctl_conf_ptr.control_machine

   secondary = ""
   if slurm_ctl_conf_ptr.backup_controller != NULL:
     secondary = slurm_ctl_conf_ptr.backup_controller

   return (primary, secondary)

def slurm_free_ctl_conf(Conf_ptr):

   cdef slurm_ctl_conf_t *slurm_ctl_conf_ptr

   slurm_ctl_conf_ptr = <slurm_ctl_conf_t *>ptr_unwrapper(Conf_ptr)

   c_slurm_free_ctl_conf(slurm_ctl_conf_ptr)

   return

def slurm_print_ctl_conf(Conf_ptr):

   cdef slurm_ctl_conf_t *slurm_ctl_conf_ptr

   slurm_ctl_conf_ptr = <slurm_ctl_conf_t *>ptr_unwrapper(Conf_ptr)

   c_slurm_print_ctl_conf(stdout, slurm_ctl_conf_ptr)

   return

def slurm_load_slurmd_status():

   cdef slurmd_status_t *slurmd_status

   retval = c_slurm_load_slurmd_status(&slurmd_status)
   if retval == 0:
        booted         = slurmd_status.booted
        lastCtldMsg    =  slurmd_status.last_slurmctld_msg
        slurmdDebug    = slurmd_status.slurmd_debug
        actualCpus     = slurmd_status.actual_cpus
        actualSockets  = slurmd_status.actual_sockets
        actualCores    = slurmd_status.actual_cores
        actualThreads  = slurmd_status.actual_threads
        actualRealMem  = slurmd_status.actual_real_mem
        actualTmpDisk  = slurmd_status.actual_tmp_disk
        actualPid      = slurmd_status.pid
        hostname       = slurmd_status.hostname
        slurmd_logfile = slurmd_status.slurmd_logfile
        step_list      = slurmd_status.step_list
        version        = slurmd_status.version 

        c_slurm_free_slurmd_status(slurmd_status)

        return (booted, lastCtldMsg, actualPid, step_list, version)

   return ()
      
def slurm_load_partitions(ptr="", flags=0):

   """
   slurm_load_partitions : Load all the partition information

   Parameters            : A record pointer returned a by previous slurm_load_partitions call

   Returns               : A Tuple containing -

                           Error value,
                           Wrapped pointer that can be passed to get_partition_data
   """

   cdef partition_info_msg_t *old_part_ptr
   cdef partition_info_msg_t *new_part_ptr

   cdef time_t Time

   cdef int Show_flags

   Show_flags = flags

   if ptr:
      old_part_ptr = <partition_info_msg_t *>ptr_unwrapper(ptr)
      retval = c_slurm_load_partitions(old_part_ptr.last_update, &new_part_ptr, Show_flags)
      if retval == 0:
        c_slurm_free_partition_info_msg(old_part_ptr)
      elif ( c_slurm_get_errno() == 1 ):
        retval = 0
        new_part_ptr = old_part_ptr
   else:
     old_part_ptr = NULL
     new_part_ptr = NULL

     last_time = <time_t>NULL

     retval = c_slurm_load_partitions(last_time, &new_part_ptr, Show_flags)

   old_part_ptr = new_part_ptr

   Part_ptr = ptr_wrapper(new_part_ptr)

   return retval, Part_ptr

def get_partition_data(ptr):


   """
   get_partiton_data : Information on partition

   Parameters        : A record pointer returned by slurm_load_partitions

   Returns           : A dictionary whose key is the partition name, each entry contains a list

                       0  - last update time (epoch seconds),
                       1  - max time,
                       2  - max nodes,
                       3  - min nodes,
                       4  - total nodes,
                       5  - total cpus,
                       6  - node scaling,
                       7  - default partition, ( 1 - true )
                       8  - hidden, ( 1 - true)
                       9  - root_only, ( 1 - allocation by root )
                      10  - disable_root_jobs,    ( 0 - false, 1 - true )
                      11  - state_up,  ( 0 - false, 1 - true )
                      12  - nodes,
                      13  - allow groups
   """                                                                                                                      

   cdef partition_info_msg_t *old_part_ptr
   cdef partition_info_t *partition_ptr

   old_part_ptr = <partition_info_msg_t *>ptr_unwrapper(ptr)

   Partition = {}
   i = 0
   for i in range(old_part_ptr.record_count):

      name = old_part_ptr.partition_array[i].name
      max_time = old_part_ptr.partition_array[i].max_time
      max_nodes = old_part_ptr.partition_array[i].max_nodes
      min_nodes = old_part_ptr.partition_array[i].min_nodes
      total_nodes = old_part_ptr.partition_array[i].total_nodes
      total_cpus = old_part_ptr.partition_array[i].total_cpus

      state_up = "True"
      if old_part_ptr.partition_array[i].state_up == 0:
        state_up = "False"

      nodes = []
      if old_part_ptr.partition_array[i].nodes != NULL:
        nodes = old_part_ptr.partition_array[i].nodes

      allow_grps = "all"
      if old_part_ptr.partition_array[i].allow_groups != NULL:
         allow_grps = old_part_ptr.partition_array[i].allow_groups

      Partition[name] = [ old_part_ptr.last_update, max_time, max_nodes, min_nodes,
                          total_nodes, total_cpus, state_up, nodes, allow_grps ]

   return Partition

def slurm_print_partition_info_msg(Part_ptr, flag=0):

   cdef partition_info_msg_t *part_ptr
   cdef int Flag

   Flag = flag

   part_ptr = <partition_info_msg_t *>ptr_unwrapper(Part_ptr)

   c_slurm_print_partition_info_msg(stdout, part_ptr, Flag)

   return

def slurm_free_partition_info_msg(Part_ptr):

   cdef partition_info_msg_t *part_ptr

   part_ptr = <partition_info_msg_t *>ptr_unwrapper(Part_ptr)

   c_slurm_free_partition_info_msg(part_ptr)

   return

def slurm_print_partition_info(Part_ptr, flag=0):

   cdef partition_info_t *part_ptr
   cdef int Flag

   Flag = flag
   part_ptr = <partition_info_t*>ptr_unwrapper(Part_ptr)

   c_slurm_print_partition_info(stdout, part_ptr, Flag)

   return

def slurm_ping(controller):

   cdef int Controller

   Controller = controller

   retval = c_slurm_ping(Controller)

   return retval

def slurm_reconfigure():

   retval = c_slurm_reconfigure()

   return retval

def slurm_shutdown():

   retval = c_slurm_shutdown(0)

   return retval

def slurm_suspend(jobid):

   cdef uint32_t JobID

   JobID = jobid
   retval = c_slurm_suspend(JobID)

   return retval

def slurm_resume(jobid):

   cdef uint32_t JobID

   JobID = jobid
   retval = c_slurm_resume(JobID)

   return retval

def slurm_requeue(jobid):

   cdef uint32_t JobID

   JobID = jobid
   retval = c_slurm_requeue(JobID)

   return retval

def slurm_get_rem_time(jobid):

   cdef uint32_t JobID

   JobID = jobid
   retval = c_slurm_get_rem_time(JobID)

   return retval

def slurm_signal_job(jobid, signal):

   cdef uint32_t JobID
   cdef uint16_t Signal

   JobID = jobid
   Signal = signal

   retval = c_slurm_signal_job(JobID, Signal)

   return retval

def slurm_signal_job_step(jobid, jobstep, signal):

   cdef uint32_t JobID
   cdef uint32_t JobStep
   cdef uint16_t Signal

   JobID = jobid
   JobStep = jobstep
   Signal = signal

   retval = c_slurm_signal_job_step(JobID, JobStep, Signal)

   return retval

def slurm_kill_job(jobid, signal, batch_flag):

   cdef uint32_t JobID
   cdef uint16_t Signal
   cdef uint16_t BatchFlag

   JobID = jobid
   Signal = signal
   BatchFlag = batch_flag

   retval = c_slurm_kill_job(JobID, Signal, BatchFlag)

   return retval

#def slurm_kill_job_step(jobid, jobstep, signal, batch_flag):
#
#   cdef uint32_t JobID
#   cdef uint32_t JobStep
#   cdef uint16_t Signal
#   cdef uint16_t BatchFlag
#
#   JobID = jobid
#   JobStep = jobstep
#   Signal = signal
#   BatchFlag = batch_flag
#
#   retval = c_slurm_kill_job_step(JobID, JobStep, Signal, BatchFlag)
#
#   return retval

def slurm_complete_job(jobid, ret_code):

   cdef uint32_t JobID
   cdef uint32_t JobCode

   JobID = jobid
   JobCode = ret_code

   retval = c_slurm_complete_job(JobID, JobCode)

   return retval

def slurm_terminate_job(jobid):

   cdef uint32_t JobID

   JobID = jobid

   retval = c_slurm_terminate_job(JobID)

   return retval

def slurm_terminate_job_step(jobid, jobstep):

   cdef uint32_t JobID
   cdef uint32_t JobStep

   JobID = jobid
   JobStep = jobstep

   retval = c_slurm_terminate_job_step(JobID, JobStep)

   return retval

#def slurm_checkpoint_able(jobid, step_id, start_time):
#
#   cdef uint32_t JobID
#   cdef uint32_t JobStep
#   cdef time_t Time
#
#   JobID = jobid
#   JobStep = jobstep
#
#   Time = <time_t>NULL
#
#   retval = c_slurm_checkpoint_able(JobID, JobStep, Time)
#
#   return retval
#
#def slurm_checkpoint_enable(jobid, jobstep):
#
#   cdef uint32_t JobID
#   cdef uint32_t JobStep
#
#   JobID = jobid
#   JobStep = jobstep
#
#   retval = c_slurm_checkpoint_enable(JobID, JobStep)
#
#   return retval
#
#def slurm_checkpoint_disable(jobid, jobstep):
#
#   cdef uint32_t JobID
#   cdef uint32_t JobStep
#
#   JobID = jobid
#   JobStep = jobstep
#
#   retval = c_slurm_checkpoint_disable(JobID, JobStep)
#
#   return retval
#
#def slurm_checkpoint_create(jobid, jobstep, maxwait):
#
#   cdef uint32_t JobID
#   cdef uint32_t JobStep
#   cdef uint16_t MaxWait
#
#   JobID = jobid
#   JobStep = jobstep
#   MaxWait = maxwait
#
#   retval = c_slurm_checkpoint_create(JobID, JobStep, MaxWait)
#
#   return retval
#
#def slurm_checkpoint_vacate(jobid, jobstep, maxwait):
#
#   cdef uint32_t JobID
#   cdef uint32_t JobStep
#   cdef uint16_t MaxWait
#
#   JobID = jobid
#   JobStep = jobstep
#   MaxWait = maxwait
#
#   retval = c_slurm_checkpoint_vacate(JobID, JobStep, MaxWait)
#
#   return retval
#
#def slurm_checkpoint_restart(jobid, jobstep):
#
#   cdef uint32_t JobID
#   cdef uint32_t JobStep
#
#   JobID = jobid
#   JobStep = jobstep
#
#   retval = c_slurm_checkpoint_restart(JobID, JobStep)
#
#   return retval
#
#def slurm_checkpoint_complete(jobid, jobstep, begin_time, error_code, msg):
#
#   cdef uint32_t JobID
#   cdef uint32_t JobStep
#   cdef uint16_t MaxWait
#   cdef char *Msg
#
#   JobID = jobid
#   JobStep = jobstep
#   BeginTime = begin_time
#   ErrorCode = error_code
#   Msg = msg
#
#   return

def slurm_load_jobs(old_ptr="", show_flags=0):

   """
   slurm_load_jobs : Load the job information

   Parameters      : A record pointer returned a by previous slurm_load_jobs call

   Returns         : A Tuple containing -

                       Error value,
                       Wrapped pointer that can be passed to get_job_data
   """

   cdef job_info_msg_t *old_job_ptr
   cdef job_info_msg_t *new_job_ptr

   #cdef uint16_t show_flags
   cdef int Show_flags
   cdef time_t Time

   Time = <time_t>NULL

   Show_flags = show_flags

   if old_ptr:
      old_job_ptr = <job_info_msg_t*>ptr_unwrapper(old_ptr)
      retval = c_slurm_load_jobs(old_job_ptr.last_update, &new_job_ptr, Show_flags)
      if retval == 0:
        c_slurm_free_job_info_msg(old_job_ptr)
      elif ( c_slurm_get_errno() == 1 ):
        retval = 0
        new_job_ptr = old_job_ptr
   else:
     old_job_ptr = NULL
     new_job_ptr = NULL

     last_time = <time_t>NULL

     retval = c_slurm_load_jobs(last_time, &new_job_ptr, Show_flags)

   old_job_ptr = new_job_ptr

   Job_ptr = ptr_wrapper(new_job_ptr)

   return retval, Job_ptr

def get_job_data(ptr):

   """
   get_job_data : Information on jobs

   Parameters   : A record pointer returned by slurm_load_jobs

   Returns      : A dictionary whose key is the job name, each entry contains a list

                   0  - last update, (epoch seconds)
                   1  - job id,
                   2  - name,
                   3  - batch flag, (1 - if batch: queued job with script)
                   4  - user id,
                   5  - group id,
                   6  - job state,
                   7  - time limit,
                   8  - submit time, (epoch seconds)
                   9  - start time, (epoch seconds)
                   10 - end time, (epoch seconds)
                   11 - suspend time, (epoch seconds)
                   12 - pre suspend time, (epoch seconds)
                   13 - priority, ( 0 - held, 1 - required nodes down/drained)
                   14 - nodes,
                   15 - partition
                   16 - num_procs
                   17 - num_nodes
                   18 - exec_nodes
                   19 - shared
                   20 - contiguous
                   21 - cpus_per_task
                   22 - account
                   23 - comment
                   24 - state reason
   """

   cdef job_info_msg_t *old_job_ptr

   old_job_ptr = <job_info_msg_t*>ptr_unwrapper(ptr)

   Jobs = {}
   i = 0
   for i from 0 <=i < old_job_ptr.record_count:
      job_id = old_job_ptr.job_array[i].job_id
      name = old_job_ptr.job_array[i].name

      batch_flag = "False"
      if old_job_ptr.job_array[i].batch_flag == 1:
        batch_flag = "True"

      user_id = old_job_ptr.job_array[i].user_id
      group_id = old_job_ptr.job_array[i].group_id
      job_state = __get_job_state(old_job_ptr.job_array[i].job_state)
      time_limit = old_job_ptr.job_array[i].time_limit
      submit_time = old_job_ptr.job_array[i].submit_time
      start_time = old_job_ptr.job_array[i].start_time
      end_time = old_job_ptr.job_array[i].end_time
      suspend_time = old_job_ptr.job_array[i].suspend_time
      pre_sus_time = old_job_ptr.job_array[i].pre_sus_time
      priority = old_job_ptr.job_array[i].priority
      partition = old_job_ptr.job_array[i].partition
      num_cpus = old_job_ptr.job_array[i].num_cpus
      num_nodes = old_job_ptr.job_array[i].num_nodes

      nodes = ""
      if old_job_ptr.job_array[i].nodes != NULL:
        nodes = old_job_ptr.job_array[i].nodes

      exec_nodes = ""
      if old_job_ptr.job_array[i].exc_nodes != NULL:
        exec_nodes = old_job_ptr.job_array[i].exc_nodes

      shared = "False"
      if old_job_ptr.job_array[i].shared == 1:
        shared = "True"

      contiguous = "False"
      if old_job_ptr.job_array[i].contiguous == 1:
        contiguous = "True"
      cpus_per_task = old_job_ptr.job_array[i].cpus_per_task

      account = ""
      if old_job_ptr.job_array[i].account != NULL:
        account = old_job_ptr.job_array[i].account

      comment = ""
      if old_job_ptr.job_array[i].comment != NULL:
         comment = old_job_ptr.job_array[i].comment

      reason = __get_job_state_reason(old_job_ptr.job_array[i].state_reason)

      Jobs[job_id] = [ old_job_ptr.last_update, job_id , name, batch_flag, user_id, group_id,
                     job_state, time_limit, submit_time, start_time, end_time, suspend_time, pre_sus_time,
                     priority, nodes, partition, num_cpus, num_nodes, exec_nodes, shared, contiguous, 
                     cpus_per_task, account, comment, reason ]

   return Jobs

def slurm_free_job_info_msg(Job_ptr):

   cdef job_info_msg_t *job_ptr

   job_ptr = <job_info_msg_t *>ptr_unwrapper(Job_ptr)

   c_slurm_free_job_info_msg(job_ptr)

   return

def slurm_print_job_info_msg(Job_ptr, flag=0):

   cdef job_info_msg_t *job_ptr
   cdef int Flag

   Flag = flag
   job_ptr = <job_info_msg_t *>ptr_unwrapper(Job_ptr)

   c_slurm_print_job_info_msg(stdout, job_ptr, Flag)

   return

def slurm_sprint_job_info(Job_ptr):

   cdef job_info_t *job_ptr

   job_ptr = <job_info_t *>ptr_unwrapper(Job_ptr)

   c_slurm_sprint_job_info(job_ptr, 0)

   return

#def slurm_pid2jobid(job_pid):
#
#   cdef uint32_t Job_Pid
#   cdef uint32_t job_id
#
#   JobPID = job_pid
#   retval = c_slurm_pid2jobid(JobPID, &job_id)
#
#   JobID = int(job_id)
#
#   return retval, JobID

def slurm_get_errno():

   retval = c_slurm_get_errno()

   return retval

def slurm_strerror(errno):

   cdef int Errno

   Errno = errno

   retval = c_slurm_strerror(Errno)

   return retval

def slurm_seterrno(errno):

   cdef int Errno

   Errno = errno

   c_slurm_seterrno(Errno)

   return

def slurm_perror(msg):

   cdef char *Msg

   Msg = msg

   c_slurm_perror(Msg)

   return

def slurm_load_node(old_ptr="", flag=0):

   """
   slurm_load_node : Load node information

   Parameters      : A record pointer returned a by previous slurm_load_node call

   Returns         : A Tuple containing -

                       Error value,
                       Wrapped pointer that can be passed to get_node_data
   """

   cdef node_info_msg_t *old_node_ptr
   cdef node_info_msg_t *new_node_ptr

   #cdef uint16_t Show_flags
   cdef time_t last_time

   cdef int Show_flags

   Show_flags = 0

   if old_ptr:
      old_node_ptr = <node_info_msg_t*>ptr_unwrapper(old_ptr)
      retval = c_slurm_load_node(old_node_ptr.last_update, &new_node_ptr, Show_flags)
      if retval == 0:
        c_slurm_free_node_info_msg(old_node_ptr)
      elif ( c_slurm_get_errno() == 1 ):
        retval = 0
        new_node_ptr = old_node_ptr
   else:
     old_node_ptr = NULL
     new_node_ptr = NULL

     last_time = <time_t>NULL

     retval = c_slurm_load_node(last_time, &new_node_ptr, Show_flags)

   old_node_ptr = new_node_ptr

   Node_ptr = ptr_wrapper(new_node_ptr)

   return retval, Node_ptr

def slurm_free_node_info_msg(ptr):

   cdef node_info_msg_t *old_node_ptr

   old_node_ptr = <node_info_msg_t*>ptr_unwrapper(ptr)

   c_slurm_free_node_info_msg(old_node_ptr)

   return

def get_node_data(ptr):

   """
   get_node_data : Information on nodes

   Parameters    : A record pointer returned by slurm_load_node

   Returns       : A dictionary whose key is the node name, each entry contains a list

                   0  - last update time (epoch seconds),
                   1  - node state,
                   2  - cpus,
                   3  - sockets,
                   4  - cores,
                   5  - threads,
                   6  - real_memory,
                   7  - tmp_disk,
                   8  - weight,
                   9  - features,
                   10 - reason
   """

   cdef node_info_msg_t *old_node_ptr
   cdef node_info_t *node_ptr

   old_node_ptr = <node_info_msg_t*>ptr_unwrapper(ptr)

   Hosts = {}
   i = 0
   for i in range(old_node_ptr.record_count):
      name = old_node_ptr.node_array[i].name
      node_state = old_node_ptr.node_array[i].node_state
      cpus = old_node_ptr.node_array[i].cpus
      sockets = old_node_ptr.node_array[i].sockets
      cores = old_node_ptr.node_array[i].cores
      threads = old_node_ptr.node_array[i].threads
      real_memory = <uint32_t>old_node_ptr.node_array[i].real_memory
      tmp_disk = old_node_ptr.node_array[i].tmp_disk
      weight = old_node_ptr.node_array[i].weight

      features = ""
      if old_node_ptr.node_array[i].features != NULL:
        features = old_node_ptr.node_array[i].features

      reason = ""
      if old_node_ptr.node_array[i].reason != NULL:
        reason = old_node_ptr.node_array[i].reason

      node_state_string = string.lower(__get_part_state(node_state))

      Hosts[name] = [ old_node_ptr.last_update, node_state_string, cpus, sockets, cores, threads, real_memory, tmp_disk, weight, features, reason ]

   return Hosts

def slurm_get_job_steps(job=0, step=0, show_flags=0):

   cdef job_step_info_response_msg_t *job_step_info_ptr

   cdef uint32_t JobID
   cdef uint32_t StepID

   cdef int Show_flags
   cdef time_t last_time

   cdef int i

   JobID = int(job)
   StepID = int(step)

   last_time = <time_t>NULL
   Show_flags = show_flags

   retval = c_slurm_get_job_steps(last_time, JobID, StepID, &job_step_info_ptr, Show_flags)

   Steps = []
   if job_step_info_ptr != NULL:
     i = 0
     for i from 0 <= i < job_step_info_ptr.job_step_count:

        job_id = job_step_info_ptr.job_steps[i].job_id
        step_id = job_step_info_ptr.job_steps[i].step_id
        user_id = job_step_info_ptr.job_steps[i].user_id
        num_tasks = job_step_info_ptr.job_steps[i].num_tasks
        partition = job_step_info_ptr.job_steps[i].partition
        nodes = job_step_info_ptr.job_steps[i].nodes
        name = job_step_info_ptr.job_steps[i].name
        #network = job_step_info_ptr.job_steps[i].network

        Steps.append( [job_id, step_id, user_id, num_tasks, partition, nodes, name ] )

     c_slurm_free_job_step_info_response_msg(job_step_info_ptr)

   return Steps

def slurm_free_job_step_info_response_msg(ptr):

   cdef job_step_info_response_msg_t *old_job_step_info_ptr

   old_job_step_info_ptr = <job_step_info_response_msg_t*>ptr_unwrapper(ptr)

   c_slurm_free_job_step_info_response_msg(old_job_step_info_ptr)

   return

def slurm_job_step_layout_get(job_id, step_id):

    cdef slurm_step_layout_t *old_job_step_ptr

    cdef uint32_t JobID
    cdef uint32_t StepID

    cdef int i
    cdef int j

    JobID = job_id
    StepID = step_id

    Nodes = []
    Node_list = []

    old_job_step_ptr = c_slurm_job_step_layout_get(JobID, StepID)

    if old_job_step_ptr != NULL:
      nodes = old_job_step_ptr.node_cnt
      node_list = old_job_step_ptr.node_list
      Nodes = node_list.split(',')
      tasks = old_job_step_ptr.task_cnt

      i = 0
      for i in range(old_job_step_ptr.node_cnt):
        node_tasks = old_job_step_ptr.tasks[i]
        j = 0
        Tids_list = []
        while j < node_tasks:
           tids = old_job_step_ptr.tids[i][j]
           Tids_list.append(tids)
           j = j + 1

        Node_list.append( [Nodes[i], Tids_list] )
 
    c_slurm_job_step_layout_free(old_job_step_ptr)

    return Node_list

def slurm_job_step_layout_free(ptr):

   cdef slurm_step_layout_t *old_job_step_ptr

   old_job_step_ptr = <slurm_step_layout_t*>ptr_unwrapper(ptr)

   c_slurm_job_step_layout_free(old_job_step_ptr)

   return

def __get_part_state(inx, extended = 0):

     drain_flag   = (inx & 0x0200)
     comp_flag    = (inx & 0x0400)
     no_resp_flag = (inx & 0x0800)
     power_flag   = (inx & 0x1000)

     inx = (inx & 0x00ff)

     state = "?"
     if (drain_flag):
       if (comp_flag or (inx == 4) ):
          state = "DRAINING"
          if (no_resp_flag and extended):
            state = "DRAINING*"
       else:
          state = "DRAINED"
          if (no_resp_flag and extended):
            state = "DRAINED*"
       return state
 
     if (inx == 1):
        state = "DOWN"
        if (no_resp_flag and extended):
          state = "DOWN*"
     elif (inx == 3):
        state = "ALLOCATED"
        if (no_resp_flag and extended):
          state = "ALLOCATED*"
        elif (comp_flag and extended):
          state = "ALLOCATED+"
     elif (comp_flag):
        state = "COMPLETING"
        if (no_resp_flag and extended):
          state = "COMPLETING*"
     elif (inx == 2):
        state = "IDLE"
        if (no_resp_flag and extended):
          state = "IDLE*"
        elif (power_flag and extended):
          state = "IDLE~"
     elif (inx == 0):
        state = "UNKNOWN"
        if (no_resp_flag and extended):
          state = "UNKNOWN*"

     return state

def __get_job_state(inx):

     state = [ "Pending", "Running", "Suspended", "Complete",
               "Cancelled", "Timeout", "Failed", "Node Fail" ]
     try:
        job_state = state[inx]
     except:
        job_state = "Unknown"

     return job_state 

def __get_job_state_reason(inx):

     reason = [ "None", "higher priority jobs exist",
                "depedent job has not completed",
                "required resources not available",
                "request exceeds partition node limit",
                "request exceeds partition time limit",
                "requested partition is down",
                "job is held, priority==0",
                "job waiting for specific begin time",
                "TBD1",
                "TBD2",
                "partition for job is DOWN",
                "some node in the allocation failed",
                "constraints can not be satisfied",
                "slurm system failure",
                "unable to launch job",
                "exit code was non-zero",
                "reached end of time limit",
                "reached slurm InactiveLimit" ]

     try:
        job_state_reason = reason[inx]
     except:
        job_state_reason = "Unknown"

     return job_state_reason 

