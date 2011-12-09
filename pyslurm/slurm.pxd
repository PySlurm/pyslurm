# cython: embedsignature=True
# cython: profile=False

from libc.string cimport strlen 
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libc.stdint cimport int64_t

from cpython cimport bool

cdef extern from 'stdlib.h':
	ctypedef long size_t
	ctypedef long long size_t

	void free(void *__ptr)
	void* malloc(size_t size)

cdef extern from 'stdio.h':
	ctypedef struct FILE
	cdef FILE *stdout

cdef extern from 'string.h':
	void* memset(void *s, int c, size_t n)
	void *memcpy(void *dest, void *src, size_t count)

cdef extern from 'time.h':
	ctypedef int time_t

cdef extern from 'Python.h':
	cdef FILE *PyFile_AsFile(object file)
	cdef int __LINE__
	char *__FILE__
	char *__FUNCTION__
	
cdef extern from *:
	ctypedef char* const_char_ptr "const char*"

#
# PySLURM helper functions
#

cdef inline listOrNone(char* value, char* sep_char):
	if value is NULL:
		return []
	return value.split(sep_char)

cdef inline stringOrNone(char* value, value2):
	if value is NULL:
		if value2 is '':
			return None
		return value2
	return value

cdef inline boolToString(int value):
	if value == 0:
		return 'False'
	return 'True'

#
# SLURM declarations not in slurm.h
#

cdef inline xmalloc(size_t __sz):
	slurm_xmalloc(__sz, __FILE__, __LINE__, __FUNCTION__)

cdef inline xfree(void **__p):
	slurm_xfree(__p, __FILE__, __LINE__, __FUNCTION__)

cdef extern void *slurm_xmalloc(size_t, const_char_ptr, int, const_char_ptr)
cdef extern void slurm_xfree(void **, const_char_ptr, int, const_char_ptr)

cdef extern void slurm_api_set_conf_file(char *)
cdef extern void slurm_api_clear_config()

#
# SLURM spank API - Love the name !
#

cdef extern from 'slurm/spank.h' nogil:
	cdef extern void slurm_verbose (char *, ...)

#
# SLURM error API
#

cdef extern from 'slurm/slurm_errno.h' nogil:
	cdef extern char * slurm_strerror (int)
	cdef void slurm_seterrno (int)
	cdef int slurm_get_errno ()
	cdef void slurm_perror (char *)

#
# Main SLURM API
#

cdef extern from 'slurm/slurm.h' nogil:

	enum: SYSTEM_DIMENSIONS = 1
	enum: HIGHEST_DIMENSIONS = 4
	
	cdef enum job_states:
		JOB_PENDING
		JOB_RUNNING
		JOB_SUSPENDED
		JOB_COMPLETE
		JOB_CANCELLED
		JOB_FAILED
		JOB_TIMEOUT
		JOB_NODE_FAIL
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
		FAIL_QOS_THRES

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
		SELECT_JOBDATA_PTR

	cdef enum select_nodedata_type:
		SELECT_NODEDATA_BITMAP_SIZE
		SELECT_NODEDATA_SUBGRP_SIZE
		SELECT_NODEDATA_SUBCNT
		SELECT_NODEDATA_BITMAP
		SELECT_NODEDATA_STR
		SELECT_NODEDATA_PTR
		
	cdef enum select_node_cnt:
		SELECT_GET_NODE_SCALING
		SELECT_GET_NODE_CPU_CNT
		SELECT_GET_BP_CPU_CNT
		SELECT_APPLY_NODE_MIN_OFFSET
		SELECT_APPLY_NODE_MAX_OFFSET
		SELECT_SET_NODE_CNT
		SELECT_SET_BP_CNT

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

	ctypedef enum task_dist_states:
		SLURM_DIST_CYCLIC = 1
		SLURM_DIST_BLOCK
		SLURM_DIST_ARBITRARY
		SLURM_DIST_PLANE
		SLURM_DIST_CYCLIC_CYCLIC
		SLURM_DIST_CYCLIC_BLOCK
		SLURM_DIST_BLOCK_CYCLIC
		SLURM_DIST_BLOCK_BLOCK
		SLURM_NO_LLLP_DIST
		SLURM_DIST_UNKNOWN

	ctypedef task_dist_states task_dist_states_t

	ctypedef enum cpu_bind_type:
		CPU_BIND_VERBOSE = 0x01
		CPU_BIND_TO_THREADS = 0x02
		CPU_BIND_TO_CORES = 0x04
		CPU_BIND_TO_SOCKETS = 0x08
		CPU_BIND_TO_LDOMS = 0x10
		CPU_BIND_NONE = 0x20
		CPU_BIND_RANK = 0x40
		CPU_BIND_MAP = 0x80
		CPU_BIND_MASK = 0x100
		CPU_BIND_LDRANK = 0x200
		CPU_BIND_LDMAP = 0x400
		CPU_BIND_LDMASK = 0x800
		CPU_BIND_CPUSETS = 0x8000

	ctypedef cpu_bind_type cpu_bind_type_t

	ctypedef enum mem_bind_type:
		MEM_BIND_VERBOSE = 0x01
		MEM_BIND_NONE = 0x02
		MEM_BIND_RANK = 0x04
		MEM_BIND_MAP = 0x08
		MEM_BIND_MASK = 0x10
		MEM_BIND_LOCAL = 0x20

	ctypedef mem_bind_type mem_bind_type_t
	
	ctypedef enum connection_type:
		SELECT_MESH
		SELECT_TORUS
		SELECT_NAV
		SELECT_SMALL
		SELECT_HTC_S
		SELECT_HTC_D
		SELECT_HTC_V
		SELECT_HTC_L 

	ctypedef enum node_use_type:
		SELECT_COPROCESSOR_MODE
		SELECT_VIRTUAL_NODE_MODE
		SELECT_NAV_MODE

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

	ctypedef struct job_descriptor:
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
		uint16_t geometry[HIGHEST_DIMENSIONS] # HIGHEST_DIMENSIONS
		uint16_t conn_type
		uint16_t reboot
		uint16_t rotate
		char *blrtsimage
		char *linuximage
		char *mloaderimage
		char *ramdiskimage
		select_jobinfo_t select_jobinfo
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
		char *gres_plugins
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
		uint32_t max_tasks_per_node
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

	ctypedef struct job_info:
		char *account
		char *alloc_node
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
		dynamic_plugin_data_t *select_jobinfo
		job_resources_t  *job_resrcs
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

	ctypedef job_info job_info_t

	ctypedef struct job_info_msg:
		time_t last_update
		uint32_t record_count
		job_info_t *job_array

	ctypedef job_info_msg job_info_msg_t

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

	ctypedef struct delete_partition_msg:
		char *name

	ctypedef delete_partition_msg delete_part_msg_t

	ctypedef struct partition_info_msg_t:
		time_t last_update
		uint32_t record_count
		partition_info_t *partition_array

	ctypedef partition_info update_part_msg_t

	ctypedef struct resource_allocation_response_msg:
		uint32_t job_id
		char *node_list
		uint32_t num_cpu_groups
		uint16_t *cpus_per_node
		uint32_t *cpu_count_reps
		uint32_t node_cnt
		uint32_t error_code
		select_jobinfo_t *select_jobinfo

	ctypedef resource_allocation_response_msg resource_allocation_response_msg_t

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
		dynamic_plugin_data_t *select_nodeinfo

	ctypedef node_info node_info_t

	ctypedef struct node_info_msg:
		time_t last_update
		uint32_t node_scaling
		uint32_t record_count
		node_info_t *node_array

	ctypedef node_info_msg node_info_msg_t

	ctypedef struct slurm_update_node_msg:
		char *features
		char *gres
		char *node_names
		uint16_t node_state
		char *reason
		uint32_t reason_uid
		uint32_t weight

	ctypedef slurm_update_node_msg update_node_msg_t

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

	ctypedef struct reserve_info:
		char *accounts
		time_t end_time
		char *features
		uint16_t flags
		char *licenses
		char *name
		uint32_t node_cnt
		int *node_inx
		char *node_list
		char *partition
		time_t start_time
		char *users

	ctypedef reserve_info reserve_info_t

	ctypedef struct reserve_info_msg:
		time_t last_update
		uint32_t record_count
		reserve_info_t *reservation_array

	ctypedef reserve_info_msg reserve_info_msg_t

	ctypedef struct resv_desc_msg:
		char *accounts
		uint32_t duration
		time_t end_time
		char *features
		uint16_t flags
		char *licenses
		char *name
		uint32_t node_cnt
		char *node_list
		char *partition
		time_t   start_time
		char *users

	ctypedef resv_desc_msg resv_desc_msg_t

	ctypedef struct reserve_response_msg:
		char *name

	ctypedef reserve_response_msg reserve_response_msg_t

	ctypedef struct trigger_info:
		uint32_t trig_id
		uint16_t res_type
		char *res_id
		uint16_t trig_type
		uint16_t offset
		uint32_t user_id
		char *program

	ctypedef trigger_info trigger_info_t

	ctypedef struct trigger_info_msg:
		uint32_t record_count
		trigger_info_t *trigger_array

	ctypedef trigger_info_msg trigger_info_msg_t

	ctypedef struct reservation_name_msg:
		char *name

	ctypedef reservation_name_msg reservation_name_msg_t

	ctypedef struct dynamic_plugin_data:
		void *data
		uint32_t plugin_id

	ctypedef dynamic_plugin_data dynamic_plugin_data_t

	ctypedef int64_t bitstr_t
	ctypedef bitstr_t bitoff_t

	ctypedef struct block_info_t:
		char *bg_block_id
		char *blrtsimage
		int *bp_inx
		uint16_t conn_type
		char *ionodes
		int *ionode_inx
		uint32_t job_running
		char *linuximage
		char *mloaderimage
		char *nodes
		uint32_t node_cnt
		uint16_t node_use
		char *owner_name
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

	#
	# List
	#
	
	cdef extern void * slurm_list_append (List l, void *x)
	cdef extern int slurm_list_count (List l)
	cdef extern List slurm_list_create (ListDelF f)
	cdef extern void slurm_list_destroy (List l)
	cdef extern void * slurm_list_find (ListIterator i, ListFindF f, void *key)
	cdef extern int slurm_list_is_empty (List l)
	cdef extern ListIterator slurm_list_iterator_create (List l)
	cdef extern void slurm_list_iterator_reset (ListIterator i)
	cdef extern void slurm_list_iterator_destroy (ListIterator i)
	cdef extern void * slurm_list_next (ListIterator i)
	cdef extern void slurm_list_sort (List l, ListCmpF f)

	#
	# Control Config Read/Print/Update
	#

	cdef extern long slurm_api_version ()
	cdef extern int slurm_load_ctl_conf (time_t, slurm_ctl_conf **)
	cdef extern void slurm_free_ctl_conf (slurm_ctl_conf_t *)
	cdef extern void slurm_print_ctl_conf (FILE *, slurm_ctl_conf_t *)
	cdef extern void *slurm_ctl_conf_2_key_pairs (slurm_ctl_conf_t*)
	cdef extern void slurm_print_ctl_2_key_pairs (slurm_ctl_conf_t *)
	cdef extern int slurm_load_slurmd_status (slurmd_status_t **)
	cdef extern void slurm_free_slurmd_status (slurmd_status_t *)
	cdef extern int slurm_print_slurmd_status (FILE *, slurmd_status_t **)
	cdef extern void slurm_print_key_pairs (FILE *, void* key_pairs, char *)

	#
	# Partitions
	#

	cdef extern void slurm_init_part_desc_msg (update_part_msg_t *)
	cdef extern int slurm_load_partitions (time_t, partition_info_msg_t **, uint16_t)
	cdef extern void slurm_free_partition_info_msg (partition_info_msg_t *)
	cdef extern void slurm_print_partition_info_msg (FILE *, partition_info_msg_t *,int)
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
	cdef extern int slurm_get_select_nodeinfo (dynamic_plugin_data_t *, uint32_t, uint32_t , void *)

	#
	# Job Resource Read/Print
	#

	cdef extern int slurm_job_cpus_allocated_on_node_id (job_resources_t *, int)
	cdef extern int slurm_job_cpus_allocated_on_node (job_resources_t *, char *)

	#
	# Job Control Config
	#

	cdef extern void slurm_free_job_info_msg (job_info_msg_t *)
	cdef extern int slurm_get_end_time (uint32_t, time_t *)
	cdef extern long slurm_get_rem_time (uint32_t)
	cdef extern int slurm_job_node_ready (uint32_t)
	cdef extern int slurm_load_job (job_info_msg_t **, uint32_t, uint16_t)
	cdef extern int slurm_load_jobs (time_t, job_info_msg_t **, uint16_t)
	cdef extern int slurm_notify_job (uint32_t, char *)
	cdef extern int slurm_pid2jobid (uint32_t, uint32_t *)
	cdef extern void slurm_print_job_info (FILE *, job_info_t *, int)
	cdef extern void slurm_print_job_info_msg (FILE *, job_info_msg_t *, int)
	cdef extern char *slurm_sprint_job_info (job_info_t *, int)
	cdef extern int slurm_update_job (job_desc_msg_t *)

	#
	# Ping/Reconfigure/Shutdown
	#

	cdef extern int slurm_ping (int)
	cdef extern int slurm_reconfigure ()
	cdef extern int slurm_shutdown (uint16_t)
	cdef extern int slurm_takeover ()
	cdef extern int slurm_set_debug_level (uint32_t)
	cdef extern int slurm_set_schedlog_level (uint32_t)

	#
	# Job/Job Step Signaling
	#

	cdef extern int slurm_kill_job (uint32_t, uint16_t, uint16_t)
	cdef extern int slurm_kill_job_step (uint32_t, uint32_t, uint16_t)
	cdef extern int slurm_signal_job (uint32_t , uint16_t)
	cdef extern int slurm_signal_job_step (uint32_t, uint32_t, uint16_t)

	#
	# Job Completion/Terminate
	#

	cdef extern int slurm_complete_job (uint32_t, uint32_t)
	cdef extern int slurm_terminate_job (uint32_t)
	cdef extern int slurm_terminate_job_step (uint32_t, uint32_t)

	#
	# Job Suspend/Resume/Requeue
	#

	cdef extern int slurm_suspend (uint32_t)
	cdef extern int slurm_resume (uint32_t)
	cdef extern int slurm_requeue (uint32_t)

	#
	# Checkpoint
	#

	cdef extern int slurm_checkpoint_able (uint32_t, uint32_t, time_t *)
	cdef extern int slurm_checkpoint_disable (uint32_t, uint32_t)
	cdef extern int slurm_checkpoint_enable (uint32_t, uint32_t)
	cdef extern int slurm_checkpoint_create (uint32_t, uint32_t, uint16_t, char*)
	cdef extern int slurm_checkpoint_vacate (uint32_t, uint32_t, uint16_t, char *)
	cdef extern int slurm_checkpoint_restart (uint32_t, uint32_t, uint16_t, char *)
	cdef extern int slurm_checkpoint_complete (uint32_t, uint32_t, time_t, uint32_t, char *)
	cdef extern int slurm_checkpoint_task_complete (uint32_t, uint32_t, uint32_t, time_t, uint32_t, char *)
	cdef extern int slurm_checkpoint_error (uint32_t, uint32_t, uint32_t *, char **)
	cdef extern int slurm_checkpoint_tasks (uint32_t, uint16_t, time_t, char *, uint16_t, char *)

	#
	# Node Configuration Read/Print/Update
	#

	cdef extern int slurm_load_node (time_t, node_info_msg_t **, uint16_t)
	cdef extern void slurm_free_node_info_msg (node_info_msg_t *)
	cdef extern void slurm_print_node_info_msg (FILE *, node_info_msg_t *, int)
	#cdef extern void slurm_print_node_table (FILE *, node_info_t *, int)
	#cdef extern char *slurm_sprint_node_table (node_info_t *, int)
	cdef extern void slurm_init_update_node_msg (update_node_msg_t *)
	cdef extern int slurm_update_node (update_node_msg_t *)

	#
	# SlurmD
	#

	cdef extern void slurm_free_slurmd_status (slurmd_status_t *)
	cdef extern int slurm_get_job_steps (time_t, uint32_t, uint32_t, job_step_info_response_msg_t **, uint16_t)
	cdef extern void slurm_free_job_step_info_response_msg (job_step_info_response_msg_t *)
	cdef extern slurm_step_layout_t *slurm_job_step_layout_get (uint32_t, uint32_t)
	cdef void slurm_job_step_layout_free (slurm_step_layout *)

	#
	# Triggers
	#

	cdef extern int slurm_set_trigger (trigger_info_t *)
	cdef extern int slurm_clear_trigger (trigger_info_t *)
	cdef extern int slurm_get_triggers (trigger_info_msg_t **)
	cdef extern int slurm_pull_trigger (trigger_info_t *)
	cdef extern void slurm_free_trigger_msg (trigger_info_msg_t *)

	#
	# Hostlists
	#

	cdef extern hostlist_t slurm_hostlist_create (char *)
	cdef extern void slurm_hostlist_destroy (hostlist_t hl)
	cdef extern int slurm_hostlist_count (hostlist_t hl)
	cdef extern int slurm_hostlist_find (hostlist_t hl, char *)
	cdef extern int slurm_hostlist_push (hostlist_t hl, char *)
	cdef extern int slurm_hostlist_push_host (hostlist_t hl, char *)
	cdef extern ssize_t slurm_hostlist_ranged_string (hostlist_t hl, size_t, char *)
	cdef extern char *slurm_hostlist_ranged_string_malloc (hostlist_t hl)
	cdef extern char *slurm_hostlist_ranged_string_xmalloc (hostlist_t hl)
	cdef extern char *slurm_hostlist_shift (hostlist_t hl)
	cdef extern void slurm_hostlist_uniq (hostlist_t hl)

	#
	# Topologly
	#

	cdef extern int slurm_load_topo (topo_info_response_msg_t **)
	cdef extern void slurm_free_topo_info_msg (topo_info_response_msg_t *)
	cdef extern void slurm_print_topo_info_msg (FILE *, topo_info_response_msg_t *, int)
	cdef extern void slurm_print_topo_record (FILE * out, topo_info_t *, int one_liner)

	#
	# Blue Gene
	#

	cdef extern void slurm_print_block_info_msg (FILE *out, block_info_msg_t *info_ptr, int)
	cdef extern void slurm_print_block_info (FILE *out, block_info_t *bg_info_ptr, int)
	cdef extern char *slurm_sprint_block_info (block_info_t * bg_info_ptr, int)
	cdef extern int slurm_load_block_info (time_t update_time, block_info_msg_t **block_info_msg_pptr, uint16_t)
	cdef extern void slurm_free_block_info_msg (block_info_msg_t *block_info_msg)
	cdef extern int slurm_update_block (update_block_msg_t *block_msg)
	cdef extern void slurm_init_update_block_msg (update_block_msg_t *update_block_msg)

