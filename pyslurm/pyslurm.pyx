# cython: embedsignature=True

import string
import time
import pwd

from socket import gethostname
from collections import defaultdict

from libc.string cimport strlen

cdef extern from 'stdlib.h':
	ctypedef long size_t
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
	char* strcpy(char* dest, char* src)

cdef extern from 'stdio.h':
	ctypedef struct FILE
	cdef FILE *stdout

cdef extern from 'string.h':
	#ctypedef extern int strlen(char*)
	char *strcpy(char *dest, char *src)
	void* memset(void *s, int c, size_t n)
	void *memcpy(void *dest, void *src, size_t count)

cdef extern from 'Python.h':
	cdef FILE *PyFile_AsFile(object file)

cdef extern from 'time.h':
	ctypedef int time_t

cdef ptr_wrapper(void* ptr):
	return PyCObject_FromVoidPtr(ptr, NULL)

cdef void *ptr_unwrapper(object obj):
	return PyCObject_AsVoidPtr(obj)

cdef void *xmalloc(size_t size) except NULL:
	cdef void *mem = malloc(size)
	if mem == NULL:
		pass
		# raise MemoryError()
	return mem

cimport slurm

#
# SLURM enums
#

JOB_PENDING   = slurm.JOB_PENDING
JOB_RUNNING   = slurm.JOB_RUNNING
JOB_SUSPENDED = slurm.JOB_SUSPENDED
JOB_COMPLETE  = slurm.JOB_COMPLETE
JOB_CANCELLED = slurm.JOB_CANCELLED
JOB_FAILED    = slurm.JOB_FAILED
JOB_TIMEOUT   = slurm.JOB_TIMEOUT
JOB_NODE_FAIL = slurm.JOB_NODE_FAIL
JOB_END       = slurm.JOB_END

JOB_START      = slurm.JOB_START
JOB_STEP       = slurm.JOB_STEP
JOB_SUSPEND    = slurm.JOB_SUSPEND
JOB_TERMINATED = slurm.JOB_TERMINATED

NODE_STATE_UNKNOWN   = slurm.NODE_STATE_UNKNOWN
NODE_STATE_DOWN      = slurm.NODE_STATE_DOWN
NODE_STATE_IDLE      = slurm.NODE_STATE_IDLE
NODE_STATE_ALLOCATED = slurm.NODE_STATE_ALLOCATED
NODE_STATE_ERROR     = slurm.NODE_STATE_ERROR
NODE_STATE_MIXED     = slurm.NODE_STATE_MIXED
NODE_STATE_FUTURE    = slurm.NODE_STATE_FUTURE
NODE_STATE_END       = slurm.NODE_STATE_END

SELECT_JOBDATA_GEOMETRY      = slurm.SELECT_JOBDATA_GEOMETRY      # data-> uint16_t geometry[SYSTEM_DIMENSIONS]
SELECT_JOBDATA_ROTATE        = slurm.SELECT_JOBDATA_ROTATE        # data-> uint16_t rotate
SELECT_JOBDATA_CONN_TYPE     = slurm.SELECT_JOBDATA_CONN_TYPE     # data-> uint16_t connection_type
SELECT_JOBDATA_BLOCK_ID      = slurm.SELECT_JOBDATA_BLOCK_ID      # data-> char *bg_block_id
SELECT_JOBDATA_NODES         = slurm.SELECT_JOBDATA_NODES         # data-> char *nodes
SELECT_JOBDATA_IONODES       = slurm.SELECT_JOBDATA_IONODES       # data-> char *ionodes
SELECT_JOBDATA_NODE_CNT      = slurm.SELECT_JOBDATA_NODE_CNT      # data-> uint32_t node_cnt
SELECT_JOBDATA_ALTERED       = slurm.SELECT_JOBDATA_ALTERED       # data-> uint16_t altered
SELECT_JOBDATA_BLRTS_IMAGE   = slurm.SELECT_JOBDATA_BLRTS_IMAGE   # data-> char *blrtsimage
SELECT_JOBDATA_LINUX_IMAGE   = slurm.SELECT_JOBDATA_LINUX_IMAGE   # data-> char *linuximage
SELECT_JOBDATA_MLOADER_IMAGE = slurm.SELECT_JOBDATA_MLOADER_IMAGE # data-> char *mloaderimage
SELECT_JOBDATA_RAMDISK_IMAGE = slurm.SELECT_JOBDATA_RAMDISK_IMAGE # data-> char *ramdiskimage
SELECT_JOBDATA_REBOOT        = slurm.SELECT_JOBDATA_REBOOT        # data-> uint16_t reboot
SELECT_JOBDATA_RESV_ID       = slurm.SELECT_JOBDATA_RESV_ID       # data-> uint32_t reservation_id
SELECT_JOBDATA_PTR           = slurm.SELECT_JOBDATA_PTR           # data-> select_jobinfo_t *jobinfo

SELECT_NODEDATA_BITMAP_SIZE = slurm.SELECT_NODEDATA_BITMAP_SIZE
SELECT_NODEDATA_SUBGRP_SIZE = slurm.SELECT_NODEDATA_SUBGRP_SIZE
SELECT_NODEDATA_SUBCNT      = slurm.SELECT_NODEDATA_SUBCNT
SELECT_NODEDATA_BITMAP      = slurm.SELECT_NODEDATA_BITMAP
SELECT_NODEDATA_STR         = slurm.SELECT_NODEDATA_STR
SELECT_NODEDATA_PTR         = slurm.SELECT_NODEDATA_PTR

#
# SLURM defines
#

INFINITE = 0xffffffff
NOVAL    = 0xfffffffe

JOB_STATE_BASE  = 0x00ff
JOB_STATE_FLAGS = 0xff00
JOB_COMPLETING  = 0x8000
JOB_CONFIGURING = 0x4000
JOB_RESIZING    = 0x2000

READY_JOB_FATAL  = -2
READY_JOB_ERROR  = -1
READY_NODE_STATE = 0x01
READY_JOB_STATE  = 0x02

MAIL_JOB_BEGIN   = 0x0001
MAIL_JOB_END     = 0x0002
MAIL_JOB_FAIL    = 0x0004
MAIL_JOB_REQUEUE = 0x0008

NICE_OFFSET = 1000

NODE_STATE_BASE       = 0x00ff
NODE_STATE_FLAGS      = 0xff00
NODE_RESUME           = 0x0100
NODE_STATE_DRAIN      = 0x0200
NODE_STATE_COMPLETING = 0x0400
NODE_STATE_NO_RESPOND = 0x0800
NODE_STATE_POWER_SAVE = 0x1000
NODE_STATE_FAIL       = 0x2000
NODE_STATE_POWER_UP   = 0x4000
NODE_STATE_MAINT      = 0x8000

SLURM_SSL_SIGNATURE_LENGTH = 128

SHOW_ALL    = 0x0001
SHOW_DETAIL = 0x0002

RESERVE_FLAG_MAINT      = 0x0001
RESERVE_FLAG_NO_MAINT   = 0x0002
RESERVE_FLAG_DAILY      = 0x0004
RESERVE_FLAG_NO_DAILY   = 0x0008
RESERVE_FLAG_WEEKLY     = 0x0010
RESERVE_FLAG_NO_WEEKLY  = 0x0020
RESERVE_FLAG_IGN_JOBS   = 0x0040
RESERVE_FLAG_NO_IGN_JOB = 0x0080
RESERVE_FLAG_OVERLAP    = 0x4000
RESERVE_FLAG_SPEC_NODES = 0x8000

PARTITION_SUBMIT = 0x01
PARTITION_SCHED  = 0x02

PARTITION_DOWN     = (PARTITION_SUBMIT)
PARTITION_UP       = (PARTITION_SUBMIT | PARTITION_SCHED)
PARTITION_DRAIN    = (PARTITION_SCHED)
PARTITION_INACTIVE = 0x0000

PART_FLAG_DEFAULT       = 0x0001
PART_FLAG_HIDDEN        = 0x0002
PART_FLAG_NO_ROOT       = 0x0004
PART_FLAG_ROOT_ONLY     = 0x0008
PART_FLAG_DEFAULT_CLR   = 0x0100
PART_FLAG_HIDDEN_CLR    = 0x0200
PART_FLAG_NO_ROOT_CLR   = 0x0400
PART_FLAG_ROOT_ONLY_CLR = 0x0800

DEBUG_FLAG_SELECT_TYPE  = 0x00000001
DEBUG_FLAG_STEPS        = 0x00000002
DEBUG_FLAG_TRIGGERS     = 0x00000004
DEBUG_FLAG_CPU_BIND     = 0x00000008
DEBUG_FLAG_WIKI         = 0x00000010
DEBUG_FLAG_NO_CONF_HASH = 0x00000020
DEBUG_FLAG_GRES         = 0x00000040
DEBUG_FLAG_BG_PICK      = 0x00000080
DEBUG_FLAG_BG_WIRES     = 0x00000100
DEBUG_FLAG_BG_ALGO      = 0x00000200
DEBUG_FLAG_BG_ALGO_DEEP = 0x00000400
DEBUG_FLAG_PRIO         = 0x00000800
DEBUG_FLAG_BACKFILL     = 0x00001000
DEBUG_FLAG_GANG         = 0x00002000
DEBUG_FLAG_RESERVATION  = 0x00004000
GROUP_FORCE             = 0x8000
GROUP_CACHE             = 0x4000
GROUP_TIME_MASK         = 0x0fff

PREEMPT_MODE_OFF        = 0x0000
PREEMPT_MODE_SUSPEND    = 0x0001
PREEMPT_MODE_REQUEUE    = 0x0002
PREEMPT_MODE_CHECKPOINT = 0x0004
PREEMPT_MODE_CANCEL     = 0x0008
PREEMPT_MODE_GANG       = 0x8000

SYSTEM_DIMENSIONS  = 1
HIGHEST_DIMENSIONS = 4

#
# SLURM Macros as Cython inline functions
#

cdef inline SLURM_VERSION_NUMBER():	return 0x020207
cdef inline SLURM_VERSION_MAJOR(a):	return ((a >> 16) & 0xff)
cdef inline SLURM_VERSION_MINOR(a):	return ((a >>  8) & 0xff)
cdef inline SLURM_VERSION_MICRO(a):	return (a & 0xff)
cdef inline SLURM_VERSION_NUM(a):	return (((SLURM_VERSION_MAJOR(a)) << 16) + ((SLURM_VERSION_MINOR(a)) << 8) + (SLURM_VERSION_MICRO(a)))

#
# Cython Wrapper Functions
#

cpdef get_controllers():

	u'''Get information about the slurm controllers.

	:return: Name of primary controller, Name of backup controller
	:rtype: `tuple`
	'''

	cdef slurm.slurm_ctl_conf_t *slurm_ctl_conf_ptr = NULL
	cdef slurm.time_t Time = <slurm.time_t>NULL

	cdef char* primary = '', *backup = ''

	cdef int cRetval = slurm.slurm_load_ctl_conf(Time, &slurm_ctl_conf_ptr)

	if slurm_ctl_conf_ptr != NULL:

		if slurm_ctl_conf_ptr.control_machine != NULL:
			primary = slurm_ctl_conf_ptr.control_machine
		if slurm_ctl_conf_ptr.backup_controller != NULL:
			backup = slurm_ctl_conf_ptr.backup_controller

	slurm.slurm_free_ctl_conf(slurm_ctl_conf_ptr)

	return primary, backup

cpdef is_controller(Host=''):

	u'''Return slurm controller status for host.
 
	:param string Host: Name of host to check

	:returns: None, primary, backup
	:rtype: `string`
	'''

	primary, backup = get_controllers()
	if not Host:
		Host = gethostname()

	if primary == Host: return 'primary'
	if backup == Host:  return 'backup'

	return None

cpdef slurm_api_version():

	u'''Return the slurm API version number.

	:returns: version_major, version_minor, version_micro
	:rtype: `tuple`
	'''

	#cdef long version = slurm.slurm_api_version()
	cdef long version = 0x020207

	return (SLURM_VERSION_MAJOR(version), SLURM_VERSION_MINOR(version), SLURM_VERSION_MICRO(version))

cpdef slurm_load_ctl_conf():

	u'''Load the slurm control configuration information.

	:returns: slurm error code
	:rtype: `integer`
	:returns: Wrapped pointer of configuration data
	:rtype: `pointer`
	'''

	cdef slurm.slurm_ctl_conf_t *slurm_ctl_conf_ptr = NULL
	cdef slurm.time_t Time = <slurm.time_t>NULL

	cdef int cRetval = slurm.slurm_load_ctl_conf(Time, &slurm_ctl_conf_ptr)

	Conf_ptr = ptr_wrapper(slurm_ctl_conf_ptr)

	return cRetval, Conf_ptr

def get_ctl_data(Conf_ptr):

	u'''Return the slurm control configuration information.

	:param pointer Conf_ptr: Configuration pointer
	
	:returns: Wrapped pointer from the slurm_load_ctl_conf call
	:rtype: `pointer`
	:returns: Configuration data
	:rtype: `dict`
	'''

	cdef slurm.slurm_ctl_conf_t *slurm_ctl_conf_ptr = <slurm.slurm_ctl_conf_t *>ptr_unwrapper(Conf_ptr)

	cdef dict Ctl_dict

	Ctl_dict = {}
	if slurm_ctl_conf_ptr != NULL:

		Ctl_dict['last_update']                       = slurm_ctl_conf_ptr.last_update
		Ctl_dict['accounting_storage_enforce']        = slurm_ctl_conf_ptr.accounting_storage_enforce
		Ctl_dict['accounting_storage_backup_host']    = slurm.stringOrNone(slurm_ctl_conf_ptr.accounting_storage_backup_host, '')
		Ctl_dict['accounting_storage_host']           = slurm.stringOrNone(slurm_ctl_conf_ptr.accounting_storage_host, '')
		Ctl_dict['accounting_storage_loc']            = slurm.stringOrNone(slurm_ctl_conf_ptr.accounting_storage_loc, '')
		Ctl_dict['accounting_storage_pass']           = slurm.stringOrNone(slurm_ctl_conf_ptr.accounting_storage_pass, '')
		Ctl_dict['accounting_storage_port']           = slurm_ctl_conf_ptr.accounting_storage_port
		Ctl_dict['accounting_storage_type']           = slurm.stringOrNone(slurm_ctl_conf_ptr.accounting_storage_type, '')
		Ctl_dict['accounting_storage_user']           = slurm.stringOrNone(slurm_ctl_conf_ptr.accounting_storage_user, '')
		Ctl_dict['authtype']                          = slurm.stringOrNone(slurm_ctl_conf_ptr.authtype, '')
		Ctl_dict['backup_addr']                       = slurm.stringOrNone(slurm_ctl_conf_ptr.backup_addr, '')
		Ctl_dict['backup_controller']                 = slurm.stringOrNone(slurm_ctl_conf_ptr.backup_controller, '')
		Ctl_dict['batch_start_timeout']               = slurm_ctl_conf_ptr.batch_start_timeout
		Ctl_dict['boot_time']                         = slurm_ctl_conf_ptr.boot_time
		Ctl_dict['checkpoint_type']                   = slurm.stringOrNone(slurm_ctl_conf_ptr.checkpoint_type, '')
		Ctl_dict['cluster_name']                      = slurm.stringOrNone(slurm_ctl_conf_ptr.cluster_name, '')
		Ctl_dict['complete_wait']                     = slurm_ctl_conf_ptr.complete_wait
		Ctl_dict['control_addr']                      = slurm.stringOrNone(slurm_ctl_conf_ptr.control_addr, '')
		Ctl_dict['control_machine']                   = slurm.stringOrNone(slurm_ctl_conf_ptr.control_machine, '')
		Ctl_dict['crypto_type']                       = slurm.stringOrNone(slurm_ctl_conf_ptr.crypto_type, '')
		Ctl_dict['debug_flags']                       = get_debug_flags(slurm_ctl_conf_ptr.debug_flags)
		Ctl_dict['def_mem_per_cpu']                   = slurm_ctl_conf_ptr.def_mem_per_cpu
		Ctl_dict['disable_root_jobs']                 = slurm.boolToString(slurm_ctl_conf_ptr.disable_root_jobs)
		Ctl_dict['enforce_part_limits']               = slurm.boolToString(slurm_ctl_conf_ptr.enforce_part_limits)
		Ctl_dict['epilog']                            = slurm.stringOrNone(slurm_ctl_conf_ptr.epilog, '')
		Ctl_dict['epilog_msg_time']                   = slurm_ctl_conf_ptr.epilog_msg_time
		Ctl_dict['epilog_slurmctld']                  = slurm.stringOrNone(slurm_ctl_conf_ptr.epilog_slurmctld, '')
		Ctl_dict['fast_schedule']                     = slurm.boolToString(slurm_ctl_conf_ptr.fast_schedule)
		Ctl_dict['first_job_id']                      = slurm_ctl_conf_ptr.first_job_id
		Ctl_dict['get_env_timeout']                   = slurm_ctl_conf_ptr.get_env_timeout
		Ctl_dict['gres_plugins']                      = slurm.stringOrNone(slurm_ctl_conf_ptr.gres_plugins, '')
		Ctl_dict['group_info']                        = slurm_ctl_conf_ptr.group_info
		Ctl_dict['hash_val']                          = slurm_ctl_conf_ptr.hash_val
		Ctl_dict['health_check_interval']             = slurm_ctl_conf_ptr.health_check_interval
		Ctl_dict['health_check_program']              = slurm.stringOrNone(slurm_ctl_conf_ptr.health_check_program, '')
		Ctl_dict['inactive_limit']                    = slurm_ctl_conf_ptr.inactive_limit
		Ctl_dict['job_acct_gather_freq']              = slurm_ctl_conf_ptr.job_acct_gather_freq
		Ctl_dict['job_acct_gather_type']              = slurm.stringOrNone(slurm_ctl_conf_ptr.job_acct_gather_type, '')
		Ctl_dict['job_ckpt_dir']                      = slurm.stringOrNone(slurm_ctl_conf_ptr.job_ckpt_dir, '')
		Ctl_dict['job_comp_host']                     = slurm.stringOrNone(slurm_ctl_conf_ptr.job_comp_host, '')
		Ctl_dict['job_comp_loc']                      = slurm.stringOrNone(slurm_ctl_conf_ptr.job_comp_loc, '')
		Ctl_dict['job_comp_pass']                     = slurm.stringOrNone(slurm_ctl_conf_ptr.job_comp_pass, '')
		Ctl_dict['job_comp_port']                     = slurm_ctl_conf_ptr.job_comp_port
		Ctl_dict['job_comp_type']                     = slurm.stringOrNone(slurm_ctl_conf_ptr.job_comp_type, '')
		Ctl_dict['job_comp_user']                     = slurm.stringOrNone(slurm_ctl_conf_ptr.job_comp_user, '')
		Ctl_dict['job_credential_private_key']        = slurm.stringOrNone(slurm_ctl_conf_ptr.job_credential_private_key, '')
		Ctl_dict['job_credential_public_certificate'] = slurm.stringOrNone(slurm_ctl_conf_ptr.job_credential_public_certificate, '')
		Ctl_dict['job_file_append']                   = slurm.boolToString(slurm_ctl_conf_ptr.job_file_append)
		Ctl_dict['job_requeue']                       = slurm.boolToString(slurm_ctl_conf_ptr.job_requeue)
		Ctl_dict['job_submit_plugins']                = slurm.stringOrNone(slurm_ctl_conf_ptr.job_submit_plugins, '')
		Ctl_dict['kill_on_bad_exit']                  = slurm.boolToString(slurm_ctl_conf_ptr.kill_on_bad_exit)
		Ctl_dict['kill_wait']                         = slurm_ctl_conf_ptr.kill_wait
		Ctl_dict['licenses']                          = slurm.stringOrNone(slurm_ctl_conf_ptr.licenses, '')
		Ctl_dict['mail_prog']                         = slurm.stringOrNone(slurm_ctl_conf_ptr.mail_prog, '')
		Ctl_dict['max_job_cnt']                       = slurm_ctl_conf_ptr.max_job_cnt
		Ctl_dict['max_mem_per_cpu']                   = slurm_ctl_conf_ptr.max_mem_per_cpu
		Ctl_dict['max_tasks_per_node']                = slurm_ctl_conf_ptr.max_tasks_per_node
		Ctl_dict['min_job_age']                       = slurm_ctl_conf_ptr.min_job_age
		Ctl_dict['mpi_default']                       = slurm.stringOrNone(slurm_ctl_conf_ptr.mpi_default, '')
		Ctl_dict['mpi_params']                        = slurm.stringOrNone(slurm_ctl_conf_ptr.mpi_params, '')
		Ctl_dict['msg_timeout']                       = slurm_ctl_conf_ptr.msg_timeout
		Ctl_dict['next_job_id']                       = slurm_ctl_conf_ptr.next_job_id
		Ctl_dict['node_prefix']                       = slurm.stringOrNone(slurm_ctl_conf_ptr.node_prefix, '')
		Ctl_dict['over_time_limit']                   = slurm_ctl_conf_ptr.over_time_limit
		Ctl_dict['plugindir']                         = slurm.stringOrNone(slurm_ctl_conf_ptr.plugindir, '')
		Ctl_dict['plugstack']                         = slurm.stringOrNone(slurm_ctl_conf_ptr.plugstack, '')
		Ctl_dict['preempt_mode']                      = __get_preempt_mode(slurm_ctl_conf_ptr.preempt_mode)
		Ctl_dict['preempt_type']                      = slurm.stringOrNone(slurm_ctl_conf_ptr.preempt_type, '')
		Ctl_dict['priority_decay_hl']                 = slurm_ctl_conf_ptr.priority_decay_hl
		Ctl_dict['priority_calc_period']              = slurm_ctl_conf_ptr.priority_calc_period
		Ctl_dict['priority_favor_small']              = slurm_ctl_conf_ptr.priority_favor_small
		Ctl_dict['priority_max_age']                  = slurm_ctl_conf_ptr.priority_max_age
		Ctl_dict['priority_reset_period']             = slurm_ctl_conf_ptr.priority_reset_period
		Ctl_dict['priority_type']                     = slurm.stringOrNone(slurm_ctl_conf_ptr.priority_type, '')
		Ctl_dict['priority_weight_age']               = slurm_ctl_conf_ptr.priority_weight_age
		Ctl_dict['priority_weight_fs']                = slurm_ctl_conf_ptr.priority_weight_fs
		Ctl_dict['priority_weight_js']                = slurm_ctl_conf_ptr.priority_weight_js
		Ctl_dict['priority_weight_part']              = slurm_ctl_conf_ptr.priority_weight_part
		Ctl_dict['priority_weight_qos']               = slurm_ctl_conf_ptr.priority_weight_qos
		Ctl_dict['private_data']                      = slurm_ctl_conf_ptr.private_data
		Ctl_dict['proctrack_type']                    = slurm.stringOrNone(slurm_ctl_conf_ptr.proctrack_type, '')
		Ctl_dict['prolog']                            = slurm.stringOrNone(slurm_ctl_conf_ptr.prolog, '')
		Ctl_dict['prolog_slurmctld']                  = slurm.stringOrNone(slurm_ctl_conf_ptr.prolog_slurmctld, '')
		Ctl_dict['propagate_prio_process']            = slurm_ctl_conf_ptr.propagate_prio_process
		Ctl_dict['propagate_rlimits']                 = slurm.stringOrNone(slurm_ctl_conf_ptr.propagate_rlimits, '')
		Ctl_dict['propagate_rlimits_except']          = slurm.stringOrNone(slurm_ctl_conf_ptr.propagate_rlimits_except, '')
		Ctl_dict['resume_program']                    = slurm.stringOrNone(slurm_ctl_conf_ptr.resume_program, '')
		Ctl_dict['resume_rate']                       = slurm_ctl_conf_ptr.resume_rate
		Ctl_dict['resume_timeout']                    = slurm_ctl_conf_ptr.resume_timeout
		Ctl_dict['resv_over_run']                     = slurm_ctl_conf_ptr.resv_over_run
		Ctl_dict['ret2service']                       = slurm_ctl_conf_ptr.ret2service
		Ctl_dict['salloc_default_command']            = slurm.stringOrNone(slurm_ctl_conf_ptr.salloc_default_command, '')
		Ctl_dict['sched_logfile']                     = slurm.stringOrNone(slurm_ctl_conf_ptr.sched_logfile, '')
		Ctl_dict['sched_log_level']                   = slurm_ctl_conf_ptr.sched_log_level
		Ctl_dict['sched_params']                      = slurm.stringOrNone(slurm_ctl_conf_ptr.sched_params, '')
		Ctl_dict['sched_time_slice']                  = slurm_ctl_conf_ptr.sched_time_slice
		Ctl_dict['schedtype']                         = slurm.stringOrNone(slurm_ctl_conf_ptr.schedtype, '')
		Ctl_dict['schedport']                         = slurm_ctl_conf_ptr.schedport
		Ctl_dict['schedrootfltr']                     = slurm_ctl_conf_ptr.schedrootfltr
		Ctl_dict['select_type']                       = slurm.stringOrNone(slurm_ctl_conf_ptr.select_type, '')
		Ctl_dict['select_type_param']                 = slurm_ctl_conf_ptr.select_type_param
		Ctl_dict['slurm_conf']                        = slurm.stringOrNone(slurm_ctl_conf_ptr.slurm_conf, '')
		Ctl_dict['slurm_user_id']                     = slurm_ctl_conf_ptr.slurm_user_id
		Ctl_dict['slurm_user_name']                   = slurm.stringOrNone(slurm_ctl_conf_ptr.slurm_user_name, '')
		Ctl_dict['slurmd_user_id']                    = slurm_ctl_conf_ptr.slurmd_user_id
		Ctl_dict['slurmd_user_name']                  = slurm.stringOrNone(slurm_ctl_conf_ptr.slurmd_user_name, '')
		Ctl_dict['slurmctld_debug']                   = slurm_ctl_conf_ptr.slurmctld_debug
		Ctl_dict['slurmctld_logfile']                 = slurm.stringOrNone(slurm_ctl_conf_ptr.slurmctld_logfile, '')
		Ctl_dict['slurmctld_pidfile']                 = slurm.stringOrNone(slurm_ctl_conf_ptr.slurmctld_pidfile, '')
		Ctl_dict['slurmctld_port']                    = slurm_ctl_conf_ptr.slurmctld_port
		Ctl_dict['slurmctld_port_count']              = slurm_ctl_conf_ptr.slurmctld_port_count
		Ctl_dict['slurmctld_timeout']                 = slurm_ctl_conf_ptr.slurmctld_timeout
		Ctl_dict['slurmd_debug']                      = slurm_ctl_conf_ptr.slurmd_debug
		Ctl_dict['slurmd_logfile']                    = slurm.stringOrNone(slurm_ctl_conf_ptr.slurmd_logfile, '')
		Ctl_dict['slurmd_pidfile']                    = slurm.stringOrNone(slurm_ctl_conf_ptr.slurmd_pidfile, '')
		Ctl_dict['slurmd_port']                       = slurm_ctl_conf_ptr.slurmd_port
		Ctl_dict['slurmd_spooldir']                   = slurm.stringOrNone(slurm_ctl_conf_ptr.slurmd_spooldir, '')
		Ctl_dict['slurmd_timeout']                    = slurm_ctl_conf_ptr.slurmd_timeout
		Ctl_dict['srun_epilog']                       = slurm.stringOrNone(slurm_ctl_conf_ptr.srun_epilog, '')
		Ctl_dict['srun_prolog']                       = slurm.stringOrNone(slurm_ctl_conf_ptr.srun_prolog, '')
		Ctl_dict['state_save_location']               = slurm.stringOrNone(slurm_ctl_conf_ptr.state_save_location, '')
		Ctl_dict['suspend_exc_nodes']                 = slurm.stringOrNone(slurm_ctl_conf_ptr.suspend_exc_nodes, '')
		Ctl_dict['suspend_exc_parts']                 = slurm.stringOrNone(slurm_ctl_conf_ptr.suspend_exc_parts, '')
		Ctl_dict['suspend_program']                   = slurm.stringOrNone(slurm_ctl_conf_ptr.suspend_program, '')
		Ctl_dict['suspend_rate']                      = slurm_ctl_conf_ptr.suspend_rate
		Ctl_dict['suspend_time']                      = slurm_ctl_conf_ptr.suspend_time
		Ctl_dict['suspend_timeout']                   = slurm_ctl_conf_ptr.suspend_timeout
		Ctl_dict['switch_type']                       = slurm.stringOrNone(slurm_ctl_conf_ptr.switch_type, '')
		Ctl_dict['task_epilog']                       = slurm.stringOrNone(slurm_ctl_conf_ptr.task_epilog, '')
		Ctl_dict['task_plugin']                       = slurm.stringOrNone(slurm_ctl_conf_ptr.task_plugin, '')
		Ctl_dict['task_plugin_param']                 = slurm_ctl_conf_ptr.task_plugin_param
		Ctl_dict['task_prolog']                       = slurm.stringOrNone(slurm_ctl_conf_ptr.task_prolog, '')
		Ctl_dict['tmp_fs']                            = slurm.stringOrNone(slurm_ctl_conf_ptr.tmp_fs, '')
		Ctl_dict['topology_plugin']                   = slurm.stringOrNone(slurm_ctl_conf_ptr.topology_plugin, '')
		Ctl_dict['track_wckey']                       = slurm_ctl_conf_ptr.track_wckey
		Ctl_dict['tree_width']                        = slurm_ctl_conf_ptr.tree_width
		Ctl_dict['unkillable_program']                = slurm.stringOrNone(slurm_ctl_conf_ptr.unkillable_program, '')
		Ctl_dict['unkillable_timeout']                = slurm_ctl_conf_ptr.unkillable_timeout
		Ctl_dict['use_pam']                           = slurm.boolToString(slurm_ctl_conf_ptr.use_pam)
		Ctl_dict['version']                           = slurm.stringOrNone(slurm_ctl_conf_ptr.version, '')
		Ctl_dict['vsize_factor']                      = slurm_ctl_conf_ptr.vsize_factor
		Ctl_dict['wait_time']                         = slurm_ctl_conf_ptr.wait_time
		Ctl_dict['z_16']                              = slurm_ctl_conf_ptr.z_16
		Ctl_dict['z_32']                              = slurm_ctl_conf_ptr.z_32
		Ctl_dict['z_char']                            = slurm.stringOrNone(slurm_ctl_conf_ptr.z_char, '')

	return Ctl_dict

def slurm_free_ctl_conf(Conf_ptr):

	u'''Free the slurm control configuration pointer returned from a previous slurm_load_ctl_conf call.

	:param pointer Conf_ptr: Wrapped pointer from the slurm_load_ctl_conf call
	'''

	cdef slurm.slurm_ctl_conf_t *slurm_ctl_conf_ptr = <slurm.slurm_ctl_conf_t *>ptr_unwrapper(Conf_ptr)

	if slurm_ctl_conf_ptr != NULL:
		slurm.slurm_free_ctl_conf(slurm_ctl_conf_ptr)

def slurm_print_ctl_conf(Conf_ptr):

	u'''Prints the contents of the data structure loaded by the slurm_load_ctl_conf function.

	:param pointer Conf_ptr: Wrapped pointer from the slurm_load_ctl_conf call
	'''

	cdef slurm.slurm_ctl_conf_t *slurm_ctl_conf_ptr = <slurm.slurm_ctl_conf_t *>ptr_unwrapper(Conf_ptr)

	slurm.slurm_print_ctl_conf(slurm.stdout, slurm_ctl_conf_ptr)

def slurm_load_slurmd_status():

	u'''Issue RPC to get and load the status of Slurmd daemon.

	:returns: Slurmd information
	:rtype: `dict`
	'''

	cdef slurm.slurmd_status_t *slurmd_status = NULL
	cdef char* hostname = NULL
	cdef int cRetval = slurm.slurm_load_slurmd_status(&slurmd_status)

	cdef dict Status, Status_dict
	Status = {}

	if cRetval == 0:

		Status_dict = {}
		hostname = slurmd_status.hostname
		Status_dict['booted']             = slurmd_status.booted
		Status_dict['last_slurmctld_msg'] = slurmd_status.last_slurmctld_msg
		Status_dict['slurmd_debug']       = slurmd_status.slurmd_debug
		Status_dict['actual_cpus']        = slurmd_status.actual_cpus
		Status_dict['actual_sockets']     = slurmd_status.actual_sockets
		Status_dict['actual_cores']       = slurmd_status.actual_cores
		Status_dict['actual_threads']     = slurmd_status.actual_threads
		Status_dict['actual_real_mem']    = slurmd_status.actual_real_mem
		Status_dict['actual_tmp_disk']    = slurmd_status.actual_tmp_disk
		Status_dict['pid']                = slurmd_status.pid
		Status_dict['slurmd_logfile']     = slurm.stringOrNone(slurmd_status.slurmd_logfile, '')
		Status_dict['step_list']          = slurm.stringOrNone(slurmd_status.step_list, '')
		Status_dict['version']            = slurm.stringOrNone(slurmd_status.version, '')

		Status[hostname] = Status_dict

	slurm.slurm_free_slurmd_status(slurmd_status)

	return Status
      
cpdef slurm_load_partitions(Partition_ptr='', int ShowFlags=0):

	u'''Load the slurm partition information.

	:param pointer Partition_ptr: Wrapped partition record pointer returned a by previous call to slurm_load_partitions
	:param int ShowFlags: flags, default=0
	
	:returns: Error value
	:rtype: `int`
	:returns: Wrapped pointer that can be passed to the get_partition_data function
	:rtype: `pointer`
	'''

	cdef slurm.partition_info_msg_t *old_part_ptr = NULL
	cdef slurm.partition_info_msg_t *new_part_ptr = NULL

	cdef slurm.time_t Time = <slurm.time_t>NULL

	cdef int cRetval = 0

	if Partition_ptr:
		old_part_ptr = <slurm.partition_info_msg_t *>ptr_unwrapper(Partition_ptr)
		cRetval = slurm.slurm_load_partitions(old_part_ptr.last_update, &new_part_ptr, ShowFlags)
		if cRetval == 0:
			slurm.slurm_free_partition_info_msg(old_part_ptr)
		elif ( slurm.slurm_get_errno() == 1 ):
			cRetval = 0
			new_part_ptr = old_part_ptr
	else:
		old_part_ptr = NULL
		new_part_ptr = NULL

		last_time = <slurm.time_t>NULL

		cRetval = slurm.slurm_load_partitions(last_time, &new_part_ptr, ShowFlags)

	old_part_ptr = new_part_ptr
	Part_ptr = ptr_wrapper(new_part_ptr)

	return cRetval, Part_ptr

cpdef get_partition_data(Partition_ptr):

	u'''Get the slurm partition data.

	:param pointer Partition_ptr: Wrapped record pointer returned by a previous call to slurm_load_partitions

	:returns: Partition data, key is the partition ID
	:rtype: `dict`
	'''
	
	cdef slurm.partition_info_msg_t *old_part_ptr = <slurm.partition_info_msg_t *>ptr_unwrapper(Partition_ptr)
	cdef slurm.partition_info_t *partition_ptr

	cdef int i = 0

	cdef dict Partition, Part_dict 
	
	Partition = {}

	if old_part_ptr == NULL:
		return Partition

	for i from 0 <= i < old_part_ptr.record_count:

		Part_dict = {}
		name = old_part_ptr.partition_array[i].name
		Part_dict['max_time']          = old_part_ptr.partition_array[i].max_time
		Part_dict['max_share']         = old_part_ptr.partition_array[i].max_share
		Part_dict['max_nodes']         = old_part_ptr.partition_array[i].max_nodes
		Part_dict['min_nodes']         = old_part_ptr.partition_array[i].min_nodes
		Part_dict['total_nodes']       = old_part_ptr.partition_array[i].total_nodes
		Part_dict['total_cpus']        = old_part_ptr.partition_array[i].total_cpus
		Part_dict['priority']          = old_part_ptr.partition_array[i].priority
		Part_dict['preempt_mode']      = __get_preempt_mode(old_part_ptr.partition_array[i].preempt_mode)
		Part_dict['default_time']      = old_part_ptr.partition_array[i].default_time
		Part_dict['flags']             = __get_partition_mode(old_part_ptr.partition_array[i].flags)
		Part_dict['state_up']          = __get_partition_state(old_part_ptr.partition_array[i].state_up)
		Part_dict['alternate']         = slurm.stringOrNone(old_part_ptr.partition_array[i].alternate, '')
		Part_dict['nodes']             = slurm.stringOrNone(old_part_ptr.partition_array[i].nodes, '')
		Part_dict['allow_alloc_nodes'] = slurm.stringOrNone(old_part_ptr.partition_array[i].allow_alloc_nodes, 'ALL')
		Part_dict['allow_groups']      = slurm.stringOrNone(old_part_ptr.partition_array[i].allow_groups, 'ALL')

		Partition[name] = Part_dict

	return Partition

cpdef int slurm_create_partition(dict partition_dict={}):

	u'''Create a slurm partition.

	:param dict partition_dict: A populated partition dictionary, an empty one is created by create_partition_dict

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `int`
	'''

	cdef slurm.update_part_msg_t part_msg_ptr
	cdef char* name
	cdef int  int_value = 0, cRetval = 0

	cdef unsigned int uint32_value, time_value

	slurm.slurm_init_part_desc_msg(&part_msg_ptr)

	if partition_dict['PartitionName'] != '':
		name = partition_dict['PartitionName']
		part_msg_ptr.name = name

	if  partition_dict['DefaultTime'] != -1:
		int_value = partition_dict['DefaultTime']
		part_msg_ptr.default_time = int_value

	if partition_dict['MaxNodes'] != -1:
		int_value = partition_dict['MaxNodes']
		part_msg_ptr.max_nodes = int_value

	if partition_dict['MinNodes'] != -1:
		int_value = partition_dict['MinNodes']
		part_msg_ptr.min_nodes = int_value

	cRetval = slurm.slurm_create_partition(&part_msg_ptr)

	return cRetval

cpdef int slurm_update_partition(dict partition_dict={}):

	u'''Update a slurm partition.

	:param dict partition_dict: A populated partition dictionary, an empty one is created by create_partition_dict

	:returns: 0 for success, -1 for error, and the slurm error code is set appropriately.
	:rtype: `int`
	'''

	cdef slurm.update_part_msg_t part_msg_ptr
	cdef unsigned int uint32_value, time_value
	cdef int  int_value = 0, cRetval = 0
	cdef char* name

	slurm.slurm_init_part_desc_msg(&part_msg_ptr)

	name = partition_dict['alternate']
	part_msg_ptr.name = name

	int_value = partition_dict['MaxTime']
	part_msg_ptr.max_time = int_value

	int_value = partition_dict['DefaultTime']
	part_msg_ptr.default_time = int_value

	if partition_dict['MaxNodes'] != -1:
		int_value = partition_dict['MaxNodes']
		part_msg_ptr.max_nodes = int_value

	if partition_dict['MinNodes'] != -1:
		int_value = partition_dict['MinNodes']
		part_msg_ptr.min_nodes = int_value

	pystring = partition_dict['State']
	if pystring != '':
		if pystring == 'DOWN':
			part_msg_ptr.state_up = 1
		elif pystring == 'UP':
			part_msg_ptr.state_up = 0
		else:
			cRetval = -1

	if partition_dict['Nodes'] != '':
		part_msg_ptr.nodes = partition_dict['Nodes']

	if partition_dict['AllowGroups'] != '':
		part_msg_ptr.allow_groups = partition_dict['AllowGroups']

	if partition_dict['AllocNodes'] != '':
		part_msg_ptr.allow_alloc_nodes = partition_dict['AllocNodes']

	cRetval = slurm.slurm_update_partition(&part_msg_ptr)

	return cRetval

cpdef int slurm_delete_partition(char* PartID):

	u'''Delete a slurm partition.

	:param string PartID: Name of slurm partition

	:returns: 0 for success else set the slurm error code as appropriately.
	:rtype: `int`
	'''

	cdef slurm.delete_part_msg_t part_msg
	
	part_msg.name = PartID
	cdef int cRetval = slurm.slurm_delete_partition(&part_msg)

	return cRetval

def slurm_print_partition_info(Partition_ptr, int Flag=0):

	u'''Print the slurm partition information.

	:param pointer Partition_ptr: Wrapped partition pointer returned by a previous call to slurm_load_partitions
	:param int Flag: Partition flags (Default=0)
	'''

	cdef slurm.partition_info_t *part_ptr = <slurm.partition_info_t*>ptr_unwrapper(Partition_ptr)

	slurm.slurm_print_partition_info(slurm.stdout, part_ptr, Flag)

cpdef slurm_print_partition_info_msg(Partition_ptr, int Flag=0):

	u'''Print the partition information.

	:param pointer Partition_ptr: Wrapped partition pointer returned by a previous call to slurm_load_partitons
	:param int Flag: Partition flags (default=0)
	'''

	cdef slurm.partition_info_msg_t *part_ptr = <slurm.partition_info_msg_t *>ptr_unwrapper(Partition_ptr)

	slurm.slurm_print_partition_info_msg(stdout, part_ptr, Flag)

cpdef slurm_free_partition_info_msg(Partition_ptr):

	u'''Free partition pointer.

	:param pointer Partition_ptr: Wrapped partition pointer returned by a previous call to slurm_load_partitions
	'''

	cdef slurm.partition_info_msg_t *part_ptr =  <slurm.partition_info_msg_t *>ptr_unwrapper(Partition_ptr)

	slurm.slurm_free_partition_info_msg(part_ptr)

#
# SLURM Ping/Reconfig/Shutdown functions
#

cpdef int slurm_ping(int Controller=1):

	u'''Issue RPC to check if slurmctld is responsive.

	:param int Controller: 1 for primary (Default=1), 2 for backup

	:returns: 0 for success or slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_ping(Controller)

	return cRetval

cpdef int slurm_reconfigure():

	u'''Issue RPC to have slurmctld reload its configuration file.

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_reconfigure()

	return cRetval

cpdef int slurm_shutdown(uint16_t Options=0):

	u'''Issue RPC to have slurmctld cease operations, both the primary and backup controller are shutdown.

	:param int Options: 0 - All slurm daemons (default)
						1 - slurmctld generates a core file
						2 - slurmctld is shutdown (no core file)

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_shutdown(Options)

	return cRetval

cpdef int slurm_takeover():

	u'''Issue a RPC to have slurmctld backup controller take over the primary controller.

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_takeover()

	return cRetval

cpdef int slurm_set_debug_level(uint32_t DebugLevel=0):

	u'''Set the slurm controller debug level.

	:param int DebugLevel: 0 (default) to 6

	:returns: 0 for success, -1 for error and set slurm error number
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_set_debug_level(DebugLevel)

	return cRetval

cpdef int slurm_set_schedlog_level(uint32_t Enable=0):

	u'''Set the slurm scheduler debug level.

	:param int Enable: True = 0, False = 1

	:returns: 0 for success, -1 for error and set slurm error number
	:rtype: `int`
	'''

	cdef int cRetval = 0

	if ( Enable == 0 ) or ( Enable == 1 ):
		cRetval = slurm.slurm_set_schedlog_level(Enable)

	return cRetval

#
# SLURM Job Suspend Functions
#

cpdef int slurm_suspend(uint32_t JobID=0):

	u'''Suspend a running slurm job.

	:param int JobID: Job identifier

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_suspend(JobID)

	return cRetval

cpdef int slurm_resume(uint32_t JobID=0):

	u'''Resume a running slurm job step.

	:param int JobID: Job identifier

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_resume(JobID)

	return cRetval

cpdef int slurm_requeue(uint32_t JobID=0):

	u'''Requeue a running slurm job step.

	:param int JobID: Job identifier

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_requeue(JobID)

	return cRetval

cpdef int slurm_get_rem_time(uint32_t JobID=0):

	u'''Get the remaining time in seconds for a slurm job step.

	:param int JobID: Job identifier

	:returns: Remaining time in seconds or -1 on error
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_get_rem_time(JobID)

	return cRetval

cpdef int slurm_job_node_ready(uint32_t JobID=0):

	u'''Return if a node could run a slurm job now if despatched.

	:param int JobID: Job identifier

	:returns: Node Ready code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_job_node_ready(JobID)

	return cRetval

cpdef int slurm_signal_job(uint32_t JobID=0, uint16_t Signal=0):

	u'''Send a signal to a slurm job step.

	:param int JobID: Job identifier
	:param int Signal: Signal to send (default=0)

	:returns: 0 for success or -1 for error and the set Slurm errno
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_signal_job(JobID, Signal)

	return cRetval

#
# SLURM Job/Step Signaling Functions
#

cpdef int slurm_signal_job_step(uint32_t JobID=0, uint32_t JobStep=0, uint16_t Signal=0):

	u'''Send a signal to a slurm job step.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int Signal: Signal to send (default=0)

	:returns: Error code - 0 for success or -1 for error and set slurm errno
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_signal_job_step(JobID, JobStep, Signal)

	return cRetval

cpdef int slurm_kill_job(uint32_t JobID=0, uint16_t Signal=0, uint16_t BatchFlag=0):

	u'''Terminate a running slurm job step.

	:param int JobID: Job identifier
	:param int Signal: Signal to send
	:param int BatchFlag: Job batch flag (default=0)

	:returns: 0 for success or -1 for error and set slurm errno
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_kill_job(JobID, Signal, BatchFlag)

	return cRetval

cpdef int slurm_kill_job_step(uint32_t JobID=0, uint32_t JobStep=0, uint16_t Signal=0):

	u'''Terminate a running slurm job step.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int Signal: Signal to send (default=0)

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_kill_job_step(JobID, JobStep, Signal)

	return cRetval

cpdef int slurm_complete_job(uint32_t JobID=0, uint32_t JobCode=0):

	u'''Complete a running slurm job step.

	:param int JobID: Job identifier
	:param int JobCode: Return code (default=0)

	:returns: 0 for success or -1 for error and set slurm errno
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_complete_job(JobID, JobCode)

	return cRetval

cpdef int slurm_terminate_job(uint32_t JobID=0):

	u'''Terminate a running slurm job step.

	:param int JobID: Job identifier (default=0)

	:returns: 0 for success or -1 for error and set slurm errno
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_terminate_job(JobID)

	return cRetval

cpdef int slurm_notify_job(uint32_t JobID=0, char* Msg=''):

	u'''Notify a message to a running slurm job step.

	:param string JobID: Job identifier (default=0)
	:param string Msg: Message to send to job

	:returns: 0 for success or -1 on error
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_notify_job(JobID, Msg)

	return cRetval

cpdef int slurm_terminate_job_step(uint32_t JobID=0, uint32_t JobStep=0):

	u'''Terminate a running slurm job step.

	:param int JobID: Job identifier (default=0)
	:param int JobStep: Job step identifier (default=0)

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_terminate_job_step(JobID, JobStep)

	return cRetval

#
# SLURM Checkpoint functions
#

cpdef slurm_checkpoint_able(uint32_t JobID=0, uint32_t JobStep=0, time_t StartTime=0):

	u'''Report if checkpoint operations can presently be issued for the specified slurm job step.

	If yes, returns SLURM_SUCCESS and sets start_time if checkpoint operation is presently active. Returns ESLURM_DISABLED if checkpoint operation is disabled.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int StartTime: Checkpoint start time

	:returns: 0 can be checkpointed or a slurm error code
	:rtype: `int`
	'''

	cdef time_t Time = <slurm.time_t>NULL
	Time = StartTime
	cdef int cRetval = slurm.slurm_checkpoint_able(JobID, JobStep, &Time)
		
	return cRetval, Time

cpdef int slurm_checkpoint_enable(uint32_t JobID=0, uint32_t JobStep=0):

	u'''Enable checkpoint requests for a given slurm job step.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_checkpoint_enable(JobID, JobStep)

	return cRetval

cpdef int slurm_checkpoint_disable(uint32_t JobID=0, uint32_t JobStep=0):

	u'''Disable checkpoint requests for a given slurm job step.

	This can be issued as needed to prevent checkpointing while a job step is in a critical section or for other reasons.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_checkpoint_disable(JobID, JobStep)

	return cRetval

cpdef int slurm_checkpoint_create(uint32_t JobID=0, uint32_t JobStep=0, uint16_t MaxWait=60, char* ImageDir=''):

	u'''Request a checkpoint for the identified slurm job step and continue its execution upon completion of the checkpoint.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int MaxWait: Maximum time to wait
	:param string ImageDir: Directory to write checkpoint files

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_checkpoint_create(JobID, JobStep, MaxWait, ImageDir)

	return cRetval

cpdef int slurm_checkpoint_requeue(uint32_t JobID=0, uint16_t MaxWait=60, char* ImageDir=''):

	u'''Initiate a checkpoint request for identified slurm job step, the job will be requeued after the checkpoint operation completes.

	:param int JobID: Job identifier
	:param int MaxWait: Maximum time in seconds to wait for operation to complete
	:param string ImageDir: Directory to write checkpoint files

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_checkpoint_requeue(JobID, MaxWait, ImageDir)

	return cRetval

cpdef int slurm_checkpoint_vacate(uint32_t JobID=0, uint32_t JobStep=0, uint16_t MaxWait=60, char* ImageDir=''):

	u'''Request a checkpoint for the identified slurm Job Step. Terminate its execution upon completion of the checkpoint.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int MaxWait: Maximum time to wait
	:param string ImageDir: Directory to store checkpoint files

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm_checkpoint_vacate(JobID, JobStep, MaxWait, ImageDir)

	return cRetval

cpdef int slurm_checkpoint_restart(uint32_t JobID=0, uint32_t JobStep=0, uint16_t Stick=0, char* ImageDir=''):

	u'''Request that a previously checkpointed slurm job resume execution.

	It may continue execution on different nodes than were originally used. Execution may be delayed if resources are not immediately available.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int Stick: Stick to nodes previously running om
	:param string ImageDir: Directory to find checkpoint image files

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_checkpoint_restart(JobID, JobStep, Stick, ImageDir)

	return cRetval

cpdef int slurm_checkpoint_complete(uint32_t JobID=0, uint32_t JobStep=0, time_t BeginTime=0, uint32_t ErrorCode=0, char* ErrMsg=''):

	u'''Note that a requested checkpoint has been completed.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int BeginTime: Begin time of checkpoint
	:param int ErrorCode: Error code, highest value fore all complete calls is preserved 
	:param string ErrMsg: Error message, preserved for highest error code

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_checkpoint_complete(JobID, JobStep, BeginTime, ErrorCode, ErrMsg)

	return cRetval

cpdef int slurm_checkpoint_task_complete(uint32_t JobID=0, uint32_t JobStep=0, uint32_t TaskID=0, time_t BeginTime=0, uint32_t ErrorCode=0, char* ErrMsg=''):

	u'''Note that a requested checkpoint has been completed.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int TaskID: Task identifier
	:param int BeginTime: Begin time of checkpoint
	:param int ErrorCode: Error code, highest value fore all complete calls is preserved 
	:param string ErrMsg: Error message, preserved for highest error code

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef int cRetval = slurm.slurm_checkpoint_task_complete(JobID, JobStep, TaskID, BeginTime, ErrorCode, ErrMsg)

	return cRetval

#
# SLURM Job Checkpoint Functions
#

def slurm_checkpoint_error(uint32_t JobID=0, uint32_t JobStep=0):

	u'''Get error information about the last checkpoint operation for a given slurm job step.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier

	:returns: 0 for success or a slurm error code
	:rtype: tuple
	:returns: Slurm error message
	:rtype: `string`
	'''

	cdef uint32_t ErrorCode = 0

	cdef char* Msg = NULL

	cdef int cRetval = slurm.slurm_checkpoint_error(JobID, JobStep, &ErrorCode, &Msg)

	error_string = ''
	if cRetval == 0:
		error_string = '%d:%s' % (ErrorCode, Msg)
		free(Msg)

	return cRetval, error_string

cpdef int slurm_checkpoint_tasks(uint32_t JobID=0, uint16_t JobStep=0, uint16_t MaxWait=60, char* NodeList=''):

	u'''Send checkpoint request to tasks of specified slurm job step.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int MaxWait: Seconds to wait for the operation to complete
	:param string NodeList: String of nodelist

	:returns: 0 for success, non zero on failure and with errno set
	:rtype: tuple
	:returns: Error message
	:rtype: `string`
	'''

	cdef slurm.time_t BeginTime = <slurm.time_t>NULL
	cdef char* ImageDir = NULL

	cdef int cRetval = slurm.slurm_checkpoint_tasks(JobID, JobStep, BeginTime, ImageDir, MaxWait, NodeList)

	return cRetval

#
# SLURM Job Control Configuration Read/Print/Update Functions
#

def slurm_load_jobs(old_ptr='', uint16_t ShowFlags=0):

	u'''Load the slurm job information.

	:param pointer old_ptr: Wrapped record pointer returned a by previous slurm_load_jobs call
	:param int ShowFlags: Type of jobs to show, default is 0

	:returns: 0 for success or a slurm error code
	:rtype: int
	:returns: Wrapped job pointer
	:rtype: `int`
	'''

	cdef slurm.job_info_msg_t *old_job_ptr
	cdef slurm.job_info_msg_t *new_job_ptr

	cdef slurm.time_t Time = <slurm.time_t>NULL

	cdef int cRetval = 0

	ShowFlags = ShowFlags ^ 1

	new_job_ptr = NULL
	old_job_ptr = NULL

	if old_ptr:

		old_job_ptr = <slurm.job_info_msg_t*>ptr_unwrapper(old_ptr)
		if old_job_ptr == NULL:

			cRetval = slurm.slurm_load_jobs(old_job_ptr.last_update, &new_job_ptr, ShowFlags)
			if cRetval == 0:
				slurm.slurm_free_job_info_msg(old_job_ptr)
			elif ( slurm.slurm_get_errno() == 1 ):
				cRetval = 0
			new_job_ptr = old_job_ptr
		else:
			cRetval = -1
	else:
		last_time = <slurm.time_t>NULL
		cRetval = slurm.slurm_load_jobs(last_time, &new_job_ptr, ShowFlags)

	old_job_ptr = new_job_ptr

	Job_ptr = ptr_wrapper(new_job_ptr)

	return cRetval, Job_ptr

cpdef get_job_data(Job_ptr):

	u'''Get the slurm job information.

	:param pointer Job_ptr: Wrapped record pointer returned a by previous slurm_load_jobs call

	:returns: Data where key is the job name, each entry contains a dictionary of job attributes
	:rtype: `dict`
	'''

	cdef slurm.job_info_msg_t *old_job_ptr = <slurm.job_info_msg_t*>ptr_unwrapper(Job_ptr)

	cdef char *name = NULL
	cdef int i = 0, x = 0, y = 0
	cdef uint16_t retval16

	cdef dict Jobs, Job_dict

	Jobs = {}
	if old_job_ptr == NULL:	return Jobs

	for i from 0 <=i < old_job_ptr.record_count:

		job_id = old_job_ptr.job_array[i].job_id

		Job_dict = {}

		Job_dict['account']           = slurm.stringOrNone(old_job_ptr.job_array[i].account, '')
		Job_dict['alloc_node']        = slurm.stringOrNone(old_job_ptr.job_array[i].alloc_node, '')
		Job_dict['alloc_sid']         = old_job_ptr.job_array[i].alloc_sid
		Job_dict['assoc_id']          = old_job_ptr.job_array[i].assoc_id
		Job_dict['batch_flag']        = old_job_ptr.job_array[i].batch_flag
		Job_dict['command']           = slurm.stringOrNone(old_job_ptr.job_array[i].command, '')
		Job_dict['comment']           = slurm.stringOrNone(old_job_ptr.job_array[i].comment, '')
		Job_dict['contiguous']        = slurm.boolToString(old_job_ptr.job_array[i].contiguous)
		Job_dict['cpus_per_task']     = old_job_ptr.job_array[i].cpus_per_task
		Job_dict['dependency']        = slurm.stringOrNone(old_job_ptr.job_array[i].dependency, '')
		Job_dict['derived_ec']        = old_job_ptr.job_array[i].derived_ec
		Job_dict['eligible_time']     = old_job_ptr.job_array[i].eligible_time
		Job_dict['end_time']          = old_job_ptr.job_array[i].end_time
		Job_dict['exc_nodes']         = slurm.listOrNone(old_job_ptr.job_array[i].exc_nodes, ',')

		Job_dict['exit_code']         = old_job_ptr.job_array[i].exit_code
		Job_dict['features']          = slurm.listOrNone(old_job_ptr.job_array[i].features, ',')
		Job_dict['gres']              = slurm.listOrNone(old_job_ptr.job_array[i].gres, ',')
		Job_dict['group_id']          = old_job_ptr.job_array[i].group_id

		Job_dict['job_state']         = __get_job_state(old_job_ptr.job_array[i].job_state)
		Job_dict['licenses']          = slurm.stringOrNone(old_job_ptr.job_array[i].licenses, '')
		Job_dict['max_cpus']          = old_job_ptr.job_array[i].max_cpus
		Job_dict['max_nodes']         = old_job_ptr.job_array[i].max_nodes
		Job_dict['sockets_per_node']  = old_job_ptr.job_array[i].sockets_per_node
		Job_dict['cores_per_socket']  = old_job_ptr.job_array[i].cores_per_socket
		Job_dict['threads_per_core']  = old_job_ptr.job_array[i].threads_per_core
		Job_dict['name']              = slurm.stringOrNone(old_job_ptr.job_array[i].name, '')
		Job_dict['network']           = slurm.stringOrNone(old_job_ptr.job_array[i].network, '')
		Job_dict['nodes']             = slurm.listOrNone(old_job_ptr.job_array[i].nodes, ',')
		Job_dict['nice']              = old_job_ptr.job_array[i].nice

		#if old_job_ptr.job_array[i].node_inx[0] != -1:
		#	for x from 0 <= x < old_job_ptr.job_array[i].num_nodes

		Job_dict['ntasks_per_core']   = old_job_ptr.job_array[i].ntasks_per_core
		Job_dict['ntasks_per_node']   = old_job_ptr.job_array[i].ntasks_per_node
		Job_dict['ntasks_per_socket'] = old_job_ptr.job_array[i].ntasks_per_socket
		Job_dict['num_nodes']         = old_job_ptr.job_array[i].num_nodes
		Job_dict['num_cpus']          = old_job_ptr.job_array[i].num_cpus
		Job_dict['partition']         = old_job_ptr.job_array[i].partition
		Job_dict['pn_min_memory']     = old_job_ptr.job_array[i].pn_min_memory
		Job_dict['pn_min_cpus']       = old_job_ptr.job_array[i].pn_min_cpus
		Job_dict['pn_min_tmp_disk']   = old_job_ptr.job_array[i].pn_min_tmp_disk
		Job_dict['pre_sus_time']      = old_job_ptr.job_array[i].pre_sus_time
		Job_dict['priority']          = old_job_ptr.job_array[i].priority
		Job_dict['qos']               = slurm.stringOrNone(old_job_ptr.job_array[i].qos, '')
		Job_dict['req_nodes']         = slurm.listOrNone(old_job_ptr.job_array[i].req_nodes, ',')

		Job_dict['requeue']           = old_job_ptr.job_array[i].requeue
		Job_dict['resize_time']       = old_job_ptr.job_array[i].resize_time
		Job_dict['restart_cnt']       = old_job_ptr.job_array[i].restart_cnt
		Job_dict['resv_name']         = slurm.stringOrNone(old_job_ptr.job_array[i].resv_name, '')

		# dynamic_plugin_data_t *select_jobinfo - opaque data type
		# process using slurm_get_select_jobinfo()

		res_ptr                        = ptr_wrapper(old_job_ptr.job_array[i].select_jobinfo)
		#Job_dict['nodes']              = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_NODES)

		Job_dict['ionodes']            = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_IONODES)
		Job_dict['block_id']           = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_BLOCK_ID)
		Job_dict['blrts_image']        = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_BLRTS_IMAGE)
		Job_dict['linux_image']        = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_LINUX_IMAGE)
		Job_dict['mloader_image']      = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_MLOADER_IMAGE)
		Job_dict['ramdisk_image']      = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_RAMDISK_IMAGE)
		#Job_dict['node_cnt']           = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_NODE_CNT)
		Job_dict['resv_id']            = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_RESV_ID)
		Job_dict['rotate']             = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_ROTATE)
		Job_dict['conn_type']          = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_CONN_TYPE)
		Job_dict['altered']            = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_ALTERED)
		Job_dict['reboot']             = slurm_get_select_jobinfo(res_ptr, SELECT_JOBDATA_REBOOT)

		# Opaque data type - job resources

		res_ptr = ptr_wrapper(old_job_ptr.job_array[i].job_resrcs)

		Job_dict['cpus_allocated'] = {}
		for node_name in Job_dict['nodes']:
			Job_dict['cpus_allocated'][node_name] = slurm_job_cpus_allocated_on_node(res_ptr, node_name)

		Job_dict['shared']            = old_job_ptr.job_array[i].shared
		Job_dict['show_flags']        = old_job_ptr.job_array[i].show_flags
		Job_dict['start_time']        = old_job_ptr.job_array[i].start_time
		Job_dict['state_desc']        = slurm.stringOrNone(old_job_ptr.job_array[i].state_desc, '')
		Job_dict['state_reason']      = __get_job_state_reason(old_job_ptr.job_array[i].state_reason)
		Job_dict['submit_time']       = old_job_ptr.job_array[i].submit_time
		Job_dict['suspend_time']      = old_job_ptr.job_array[i].suspend_time
		Job_dict['time_limit']        = old_job_ptr.job_array[i].time_limit
		Job_dict['time_min']          = old_job_ptr.job_array[i].time_min
		Job_dict['user_id']           = old_job_ptr.job_array[i].user_id
		Job_dict['wckey']             = slurm.stringOrNone(old_job_ptr.job_array[i].wckey, '')
		Job_dict['work_dir']          = slurm.stringOrNone(old_job_ptr.job_array[i].work_dir, '')

		Jobs[job_id] = Job_dict

	return Jobs

cpdef slurm_get_select_jobinfo(Job_Ptr, uint32_t dataType):

	u''' Decode opaque data type *jobinfo

		*** INCOMPLETE ***
	'''

	cdef slurm.dynamic_plugin_data_t *jobinfo = <slurm.dynamic_plugin_data_t*> ptr_unwrapper(Job_Ptr)
	cdef slurm.select_jobinfo_t *tmp_ptr

	cdef int retval = 0, len = 0
	cdef uint16_t retval16 = 0
	cdef uint32_t retval32 = 0
	cdef char *retvalStr, *str, *tmp_str

	cdef dict Job_dict

	Job_dict = {}
	
	if jobinfo == NULL:
		return None

	if dataType == SELECT_JOBDATA_GEOMETRY: # Int array[SYSTEM_DIMENSIONS]
		pass

	if dataType == SELECT_JOBDATA_ROTATE or dataType == SELECT_JOBDATA_CONN_TYPE or dataType == SELECT_JOBDATA_ALTERED \
		or dataType == SELECT_JOBDATA_REBOOT:

		retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &retval16)
		if retval == 0:
			return retval16

	elif dataType == SELECT_JOBDATA_NODE_CNT or dataType == SELECT_JOBDATA_RESV_ID:
		
		retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &retval32)
		if retval == 0:
			return retval32

	elif dataType == SELECT_JOBDATA_BLOCK_ID or dataType == SELECT_JOBDATA_NODES \
		or dataType == SELECT_JOBDATA_IONODES or dataType == SELECT_JOBDATA_BLRTS_IMAGE \
		or dataType == SELECT_JOBDATA_LINUX_IMAGE or dataType == SELECT_JOBDATA_MLOADER_IMAGE \
		or dataType == SELECT_JOBDATA_RAMDISK_IMAGE:
	
		# data-> char *  needs to be freed with xfree

		retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &tmp_str)
		if retval == 0:
			len = strlen(tmp_str)+1
			str = <char*>malloc(len)
			memcpy(tmp_str, str, len)
			slurm.xfree(<void**>tmp_str)
			return str

	elif dataType == SELECT_JOBDATA_PTR: # data-> select_jobinfo_t *jobinfo
		retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &tmp_ptr)
		if retval == 0:
			#sv_setref_pv(data, "Slurm::select_jobinfo_t", (void*)tmp_ptr);
			pass

	return None

#
# SLURM Job Resources Functions
#

cpdef slurm_job_cpus_allocated_on_node_id(Ptr, int nodeID=0):

	u'''Get the number of cpus allocated to a slurm job on a node by node name.

	:param pointer Ptr: Wrapped pointer to job_resources structure
	:param int nodeID: Numerical node ID
	:returns: Num of CPUs allocated to job on this node or -1 on error
	:rtype: `int`
	'''

	cdef slurm.job_resources_t *job_resrcs_ptr = <slurm.job_resources_t *>ptr_unwrapper(Ptr)
	cdef int retval = slurm.slurm_job_cpus_allocated_on_node_id(job_resrcs_ptr, nodeID)

	return retval

cpdef slurm_job_cpus_allocated_on_node(Ptr, char* nodeName=''):

	u'''Get the number of cpus allocated to a slurm job on a node by node name.

	:param pointer Ptr: Wrapped pointer to job_resources structure
	:param string nodeName: Name of node
	:returns: Num of CPUs allocated to job on this node or -1 on error
	:rtype: `int`
	'''

	cdef slurm.job_resources_t *job_resrcs_ptr = <slurm.job_resources_t *>ptr_unwrapper(Ptr)
	cdef int retval = slurm.slurm_job_cpus_allocated_on_node(job_resrcs_ptr, nodeName)

	return retval

cpdef slurm_free_job_info_msg(Ptr):

	u'''Release the storage generated by the slurm_get_job_steps function.

	:param pointer Job_ptr: Record pointer returned a by previous slurm_load_jobs call
	'''

	cdef slurm.job_info_msg_t *jobPtr = <slurm.job_info_msg_t *>ptr_unwrapper(Ptr)

	slurm.slurm_free_job_info_msg(jobPtr)

def slurm_print_job_info_msg(Job_ptr, int Flag=0):

	u'''Prints the contents of the data structure describing all job step records loaded by the slurm_get_job_steps function.

	:param pointer Job_ptr: Wrapped job pointer returned by a previous call to slurm_load_jobs
	:param int Flag: Default=0
	'''

	cdef slurm.job_info_msg_t *job_ptr = <slurm.job_info_msg_t *>ptr_unwrapper(Job_ptr)

	slurm.slurm_print_job_info_msg(slurm.stdout, job_ptr, Flag)

cpdef slurm_print_job_info(Job_ptr, int Flag=0):

	u'''Prints the contents of the data structure describing all job step records loaded by the slurm_load_job function.

	:param pointer Job_ptr: Wrapped job pointer returned by a previous call to slurm_load_jobs
	:param int Flag: Output to single line if True (Default=0)
	'''

	cdef slurm.job_info_t *job_ptr = <slurm.job_info_t *>ptr_unwrapper(Job_ptr)

	slurm.slurm_print_job_info(slurm.stdout, job_ptr, Flag)

cpdef slurm_sprint_job_info(Job_ptr):

	u'''Print the job information.

	:param pointer Job_ptr: Wrapped job pointer returned by a previous call to slurm_load_jobs
	'''

	cdef slurm.job_info_t *job_ptr = <slurm.job_info_t *>ptr_unwrapper(Job_ptr)

	slurm.slurm_sprint_job_info(job_ptr, 0)

cpdef slurm_pid2jobid(uint32_t JobPID=0):

	u'''Get the slurm job id from a process id.

	:param int JobPID: Job process id

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	:returns: Job Identifier
	:rtype: `int`
	'''

	cdef uint32_t JobID = 0
	cdef int cRetval = slurm.slurm_pid2jobid(JobPID, &JobID)

	return cRetval, JobID

#
# SLURM Error Functions
#

cpdef int slurm_get_errno():

	u'''Return the slurm error as set by a slurm API call.

	:returns: slurm error number
	:rtype: `int`
	'''

	cdef int errNum = slurm.slurm_get_errno()

	return errNum

cpdef slurm_strerror(int Errno=0):

	u'''Return slurm error message represented by slurm error number

	:param int Errno: slurm error number.

	:returns: slurm error string
	:rtype: `string`
	'''

	cdef char* errMsg = slurm.slurm_strerror(Errno)

	return errMsg

cpdef slurm_seterrno(int Errno=0):

	u'''Set the slurm error number.

	:param int Errno: slurm error number
	'''

	slurm.slurm_seterrno(Errno)

cpdef slurm_perror(char* Msg=''):

	u'''Print to standard error the supplied header followed by a colon followed  by a text description of the last Slurm error code generated.

	:param string Msg: slurm program error String
	'''

	slurm.slurm_perror(Msg)

#
# SLURM Node Read/Print/Update Functions 
#

cpdef slurm_load_node(old_ptr='', uint16_t ShowFlags=0):

	u'''Load slurm node information.

	:param pointer old_ptr: Wrapped record pointer returned a by previous slurm_load_node call
	:param int ShowFlags: Default is 0

	:returns: Error value
	:rtype: `int`
	:returns: Wrapped pointer that can be passed to get_node_data
	:rtype: `int`
	'''

	cdef slurm.node_info_msg_t *old_node_ptr = NULL
	cdef slurm.node_info_msg_t *new_node_ptr = NULL

	cdef slurm.time_t last_time = <slurm.time_t>NULL

	cdef int cRetval = 0

	if old_ptr:
		old_node_ptr = <slurm.node_info_msg_t*>ptr_unwrapper(old_ptr)
		cRetval = slurm.slurm_load_node(old_node_ptr.last_update, &new_node_ptr, ShowFlags)
		if cRetval == 0:
			slurm.slurm_free_node_info_msg(old_node_ptr)
		elif ( slurm.slurm_get_errno() == 1 ):
			cRetval = 0
		new_node_ptr = old_node_ptr
	else:
		new_node_ptr = NULL
		old_node_ptr = NULL

		last_time = <slurm.time_t>NULL

		cRetval = slurm.slurm_load_node(last_time, &new_node_ptr, ShowFlags)

	old_node_ptr = new_node_ptr

	Node_ptr = ptr_wrapper(new_node_ptr)

	return cRetval, Node_ptr

cpdef int slurm_update_node(dict node_dict={}):

	u'''Update slurm node information.

	:param dict node_dict: A populated node dictionary, an empty one is created by create_node_dict

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `int`
	'''

	cdef slurm.update_node_msg_t node_msg

	cdef int cRetval = 0

	slurm.slurm_init_update_node_msg(&node_msg)

	if node_dict.has_key('reason'):
		node_msg.reason = node_dict['reason']

	if node_dict.has_key('state'):
		node_msg.node_state = <uint16_t>node_dict['state']

	if node_dict.has_key('features'):
		node_msg.features = node_dict['features']

	if node_dict.has_key('gres'):
		node_msg.gres = node_dict['gres']

	if node_dict.has_key('node_names'):
		node_msg.node_names = node_dict['node_names']

	if node_dict.has_key('reason'):
		node_msg.reason = node_dict['reason']

	if node_dict.has_key('weight'):
		node_msg.weight = <uint32_t>node_dict['weight']

	cRetval = slurm.slurm_update_node(&node_msg)

	return cRetval

cpdef slurm_free_node_info_msg(Node_ptr):

	u'''Free slurm node information message.

	:param pointer Node_ptr: Wrapped node info record pointer
	'''

	cdef slurm.node_info_msg_t *old_node_ptr

	old_node_ptr = <slurm.node_info_msg_t*>ptr_unwrapper(Node_ptr)

	slurm.slurm_free_node_info_msg(old_node_ptr)

cpdef get_node_data(Node_ptr):

	u'''Get slurm node information.

	:param pointer Node_ptr: Wrapped record pointer returned by slurm_load_node call

	:returns: Data whose key is the node name.
	:rtype: `dict`
	'''


	cdef slurm.node_info_msg_t *old_node_ptr = <slurm.node_info_msg_t*>ptr_unwrapper(Node_ptr)
	cdef slurm.node_info_t *node_ptr
	cdef slurm.select_nodeinfo_t *select_node_ptr

	cdef int i = 0, retval = 0
	cdef uint16_t y = 0, alloc_cpus = 0

	cdef dict Hosts, Host_dict

	Hosts = {}
	if old_node_ptr == NULL:
		return Hosts

	for i from 0 <= i < old_node_ptr.record_count:

		Host_dict = {}

		name = old_node_ptr.node_array[i].name

		Host_dict['arch']              = slurm.stringOrNone(old_node_ptr.node_array[i].arch, '')
		Host_dict['boot_time']         = old_node_ptr.node_array[i].boot_time
		Host_dict['cores']             = old_node_ptr.node_array[i].cores
		Host_dict['cpus']              = old_node_ptr.node_array[i].cpus
		Host_dict['features']          = slurm.stringOrNone(old_node_ptr.node_array[i].features, '')
		Host_dict['gres']              = slurm.stringOrNone(old_node_ptr.node_array[i].gres, '')
		Host_dict['name']              = slurm.stringOrNone(old_node_ptr.node_array[i].name, '')
		Host_dict['node_state']        = __get_node_state(old_node_ptr.node_array[i].node_state)
		Host_dict['os']                = slurm.stringOrNone(old_node_ptr.node_array[i].os, '')
		Host_dict['real_memory']       = old_node_ptr.node_array[i].real_memory
		Host_dict['reason']            = slurm.stringOrNone(old_node_ptr.node_array[i].reason, '')
		Host_dict['reason_uid']        = old_node_ptr.node_array[i].reason_uid
		Host_dict['slurmd_start_time'] = old_node_ptr.node_array[i].slurmd_start_time
		Host_dict['sockets']           = old_node_ptr.node_array[i].sockets
		Host_dict['threads']           = old_node_ptr.node_array[i].threads
		Host_dict['tmp_disk']          = old_node_ptr.node_array[i].tmp_disk
		Host_dict['weight']            = old_node_ptr.node_array[i].weight

		if old_node_ptr.node_array[i].select_nodeinfo != NULL:

			Ptr = ptr_wrapper(old_node_ptr.node_array[i].select_nodeinfo)

			alloc_cpus = slurm_get_select_nodeinfo(Ptr, SELECT_NODEDATA_SUBCNT, old_node_ptr.node_array[i].node_state)

		Hosts[name] = Host_dict

	return Hosts

cpdef slurm_get_select_nodeinfo(Node_Ptr, uint32_t dataType, uint32_t State):

	cdef slurm.dynamic_plugin_data_t *nodeinfo = <slurm.dynamic_plugin_data_t*>ptr_unwrapper(Node_Ptr)
	cdef slurm.select_nodeinfo_t *tmp_ptr
	cdef slurm.bitstr_t *tmp_bitmap = NULL

	cdef int retval = 0, len = 0
	cdef uint16_t retval16 = 0
	cdef char *retvalStr, *str, *tmp_str = ''

	cdef dict Host_dict

	Host_dict = {}

	if dataType == SELECT_NODEDATA_SUBCNT or dataType == SELECT_NODEDATA_SUBGRP_SIZE or dataType == SELECT_NODEDATA_BITMAP_SIZE:

		retval = slurm.slurm_get_select_nodeinfo(nodeinfo, dataType, State, &retval16)
		if retval == 0:
			return retval16

	elif dataType == SELECT_NODEDATA_BITMAP:

		# data-> bitstr_t * needs to be freed with FREE_NULL_BITMAP

		#retval = slurm.slurm_get_select_nodeinfo(nodeinfo, dataType, State, &tmp_bitmap)
		#if retval == 0:
		#	Host_dict['bitstr'] = tmp_bitmap
		return None

	elif dataType == SELECT_NODEDATA_STR:

		# data-> char *  needs to be freed with xfree

		retval = slurm.slurm_get_select_nodeinfo(nodeinfo, dataType, State, &tmp_str)
		if retval == 0:
			len = strlen(tmp_str)+1
			str = <char*>malloc(len)
			memcpy(tmp_str, str, len)
			slurm.xfree(<void**>tmp_str)
			return str

	elif dataType == SELECT_NODEDATA_PTR: # data-> select_jobinfo_t *jobinfo
		retval = slurm.slurm_get_select_nodeinfo(nodeinfo, dataType, State, &tmp_ptr)
		if retval == 0:
			#"Slurm::select_nodeinfo_t", (void*)tmp_ptr)
			pass

	return None

cpdef slurm_get_job_steps(uint32_t JobID=0, uint32_t StepID=0, uint16_t ShowFlags=0):

	u'''Loads into details about job steps that satisfy the job_id 
	    and/or step_id specifications provided if the data has been 
	    updated since the update_time specified.

	:param int JobID: Job Identifier
	:param int StepID: Jobstep Identifier
	:param int ShowFlags: Display flags (Default=0)

	:returns: Data whose key is the job and step ID
	:rtype: `dict`
	'''

	cdef slurm.job_step_info_response_msg_t *job_step_info_ptr = NULL

	cdef slurm.time_t last_time = 0

	cdef int i = 0, cRetval = 0

	ShowFlags = ShowFlags ^ 1

	cRetval = slurm.slurm_get_job_steps(last_time, JobID, StepID, &job_step_info_ptr, ShowFlags)

	cdef dict Steps, Step_dict

	Steps = {}
	if cRetval != 0:	return Steps

	if job_step_info_ptr != NULL:

		for i from 0 <= i < job_step_info_ptr.job_step_count:

			job_id  = job_step_info_ptr.job_steps[i].job_id
			step_id = job_step_info_ptr.job_steps[i].step_id

			Steps[job_id] = {}
			Step_dict = {}
			Step_dict['user_id']    = job_step_info_ptr.job_steps[i].user_id
			Step_dict['num_tasks']  = job_step_info_ptr.job_steps[i].num_tasks
			Step_dict['partition']  = job_step_info_ptr.job_steps[i].partition
			Step_dict['start_time'] = job_step_info_ptr.job_steps[i].start_time
			Step_dict['run_time']   = job_step_info_ptr.job_steps[i].run_time
			Step_dict['resv_ports'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].resv_ports, '')
			Step_dict['nodes']      = slurm.stringOrNone(job_step_info_ptr.job_steps[i].nodes, '')
			Step_dict['name']       = job_step_info_ptr.job_steps[i].name
			Step_dict['network']    = slurm.stringOrNone(job_step_info_ptr.job_steps[i].network, '')
			Step_dict['ckpt_dir']   = job_step_info_ptr.job_steps[i].ckpt_dir
			Step_dict['ckpt_int']   = job_step_info_ptr.job_steps[i].ckpt_interval

			Steps[job_id][step_id] = Step_dict

		slurm.slurm_free_job_step_info_response_msg(job_step_info_ptr)

	return Steps

cpdef slurm_free_job_step_info_response_msg(ptr):

	u'''Free the slurm job step info pointer.

	:param pointer Ptr: A wrapped job step info pointer
	'''

	cdef slurm.job_step_info_response_msg_t *old_job_step_info_ptr = <slurm.job_step_info_response_msg_t*>ptr_unwrapper(ptr)

	slurm.slurm_free_job_step_info_response_msg(old_job_step_info_ptr)

cpdef slurm_job_step_layout_get(uint32_t JobID=0, uint32_t StepID=0):

	u'''Get the slurm job step layout from a given job and step id.

	:param int JobID: slurm job id (Default=0)
	:param int StepID: slurm step id (Default=0)

	:returns: List of job step layout.
	:rtype: `list`
	'''

	cdef slurm.slurm_step_layout_t *old_job_step_ptr 
	cdef int i = 0, j = 0, Node_cnt = 0

	cdef dict Layout = {}
	cdef list Nodes = [], Node_list = [], Tids_list = []

	old_job_step_ptr = slurm.slurm_job_step_layout_get(JobID, StepID)

	if old_job_step_ptr != NULL:

		Node_cnt  = old_job_step_ptr.node_cnt

		Layout['node_cnt']   = Node_cnt
		Layout['node_list']  = old_job_step_ptr.node_list
		Layout['plane_size'] = old_job_step_ptr.plane_size
		Layout['task_cnt']   = old_job_step_ptr.task_cnt
		Layout['task_dist']  = old_job_step_ptr.task_dist

		Nodes = Layout['node_list'].split(',')
		for i from 0 <= i < Node_cnt:

			Tids_list = []
			for j from 0 <= j < old_job_step_ptr.tasks[i]:

				Tids_list.append(old_job_step_ptr.tids[i][j])

			Node_list.append( [Nodes[i], Tids_list] )
		
		Layout['tasks'] = Node_list

		slurm.slurm_job_step_layout_free(old_job_step_ptr)

	return Layout

cpdef slurm_job_step_layout_free(Ptr):

	u'''Free the slurm job step layout pointer.

	:param pointer Ptr: A wrapped job step layout pointer
	'''

	cdef slurm.slurm_step_layout_t *old_job_step_ptr = <slurm.slurm_step_layout_t*>ptr_unwrapper(Ptr)

	slurm.slurm_job_step_layout_free(old_job_step_ptr)

#
# SLURM HostList Functions
#

cpdef slurm_hostlist_create(char* HostList=''):

	u'''Create a slurm hostlist.

	:param string HostList: A string of hosts
	'''

	cdef slurm.hostlist_t hl = slurm.slurm_hostlist_create(HostList)

	print slurm.slurm_hostlist_count(hl)

	return

cpdef int slurm_hostlist_find(Ptr, char* HostString=''):

	u'''Find host in slurm hostlist.

	:param pointer Ptr: Wrapped slurm hostlist pointer

	:returns: 0 for success or -1 for failure
	:rtype: `int`
	'''

	cdef slurm.hostlist_t hl = <slurm.hostlist_t>ptr_unwrapper(Ptr)
	cdef int cRetval = slurm.slurm_hostlist_find(hl, HostString)

	return cRetval

cpdef slurm_hostlist_destroy(Ptr):

	u'''Destroy a slurm hostlist.

	:param pointer Ptr: A wrapped hostlist pointer
	'''

	cdef slurm.hostlist_t hl = <slurm.hostlist_t>ptr_unwrapper(Ptr)

	slurm.slurm_hostlist_destroy(hl)

cpdef int slurm_hostlist_count(Ptr):

	u'''Count the number of hosts in slurm hostlist.

	:param pointer Ptr: A wrapped hostlist pointer

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `int`
	'''

	cdef slurm.hostlist_t hl = <slurm.hostlist_t>ptr_unwrapper(Ptr)
	cdef int cRetval = slurm.slurm_hostlist_count(hl)

	return cRetval

#
# SLURM Trigger Get/Set/Update Functions
#

cpdef int slurm_set_trigger(dict trigger_dict={}):

	u'''Set or create a slurm trigger.

	:param dict trigger_dict: A populated dictionary of trigger information

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `int`
	'''

	cdef slurm.trigger_info_t trigger_set
	cdef char tmp_c[128]
	cdef char* JobId
	cdef int  cRetval = -1

	if (trigger_dict.has_key('node') or trigger_dict.has_key('jobid')):
		if (trigger_dict.has_key('node') and trigger_dict.has_key('jobid')):
			return cRetval
	else:
		return cRetval

	memset(&trigger_set, 0, sizeof(slurm.trigger_info_t))

	trigger_set.user_id = 0

	if trigger_dict.has_key('jobid'):

		JobId = trigger_dict['jobid']
		trigger_set.res_type = 1	#TRIGGER_RES_TYPE_JOB
		memcpy(tmp_c, JobId, 128)
		trigger_set.res_id = tmp_c

		if trigger_dict.has_key('fini'):
			trigger_set.trig_type = trigger_set.trig_type | 0x0010 #TRIGGER_TYPE_FINI
		if trigger_dict.has_key('offset'):
			trigger_set.trig_type = trigger_set.trig_type | 0x0008 #TRIGGER_TYPE_TIME

	elif trigger_dict.has_key('node'):

		trigger_set.res_type = 2	#TRIGGER_RES_TYPE_NODE
		if trigger_dict['node'] == '':
			trigger_set.res_id = '*'
		else:
			trigger_set.res_id = trigger_dict['node']
		
	trigger_set.offset = 32768
	if trigger_dict.has_key('offset'):
		trigger_set.offset = trigger_set.offset + trigger_dict['offset']

	trigger_set.program = trigger_dict['program']

	event = trigger_dict['event']
	if event == 'block_err':
		trigger_set.trig_type = trigger_set.trig_type | 0x0040 #TRIGGER_BLOCK_ERR

	if event == 'drained':
		trigger_set.trig_type = trigger_set.trig_type | 0x0100 #TRIGGER_TYPE_DRAINED

	if event == 'down':
		trigger_set.trig_type = trigger_set.trig_type | 0x0002 #TRIGGER_TYPE_DOWN

	if event == 'fail':
		trigger_set.trig_type = trigger_set.trig_type | 0x0004 #TRIGGER_TYPE_FAIL

	if event == 'up':
		trigger_set.trig_type = trigger_set.trig_type | 0x0001 #TRIGGER_TYPE_UP

	if event == 'idle':
		trigger_set.trig_type = trigger_set.trig_type | 0x0080 #TRIGGER_TYPE_IDLE

	if event == 'reconfig':
		trigger_set.trig_type = trigger_set.trig_type | 0x0020 #TRIGGER_TYPE_RECONFIG
	
	while slurm.slurm_set_trigger(&trigger_set):

		slurm.slurm_perror('slurm_set_trigger')
		if slurm.slurm_get_errno() != 11: #EAGAIN

			cRetval = slurm.slurm_get_errno()
			return cRetval

		time.sleep(5)

	return 0

cpdef slurm_get_triggers():

	u'''Get the information on slurm triggers.

	:returns: Where key is the trigger ID
	:rtype: `dict`
	'''

	cdef slurm.trigger_info_msg_t *trigger_get = NULL
	cdef slurm.trigger_info_t *trigger_array = NULL

	cdef int i = 0
	cdef int cRetval = slurm.slurm_get_triggers(&trigger_get)

	cdef dict Triggers, Trigger_dict

	Triggers = {}
	if cRetval == 0:

		for i from 0 <= i < trigger_get.record_count:

			trigger_id = trigger_get.trigger_array[i].trig_id

			Trigger_dict = {}
			Trigger_dict['res_type']  = __get_trigger_res_type(trigger_get.trigger_array[i].res_type)
			Trigger_dict['res_id']    = trigger_get.trigger_array[i].res_id
			Trigger_dict['trig_type'] = __get_trigger_type(trigger_get.trigger_array[i].trig_type)
			Trigger_dict['offset']    = trigger_get.trigger_array[i].offset-0x8000
			Trigger_dict['user_id']   = trigger_get.trigger_array[i].user_id
			Trigger_dict['program']   = trigger_get.trigger_array[i].program

			Triggers[trigger_id] = Trigger_dict

		slurm.slurm_free_trigger_msg(trigger_get)

	return Triggers

cpdef int slurm_clear_trigger(uint32_t TriggerID=-1, uint32_t UserID=-1, char* ID=''):

	u'''Clear or remove a slurm trigger.

	:param string TriggerID: Trigger Identifier
	:param string UserID: User Identifier
	:param string ID: Job Identifier

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef slurm.trigger_info_t trigger_clear
	cdef char tmp_c[128]
	cdef int  cRetval = 0

	memset(&trigger_clear, 0, sizeof(slurm.trigger_info_t))

	if TriggerID != -1:
		trigger_clear.trig_id = TriggerID
	if UserID != -1:
		trigger_clear.user_id = UserID

	if ID:
		trigger_clear.res_type = 1  #TRIGGER_RES_TYPE_JOB 
		memcpy(tmp_c, ID, 128)
		trigger_clear.res_id = tmp_c

	cRetval = slurm.slurm_clear_trigger(&trigger_clear)

	return cRetval

cpdef int slurm_pull_trigger(uint32_t TriggerID=0, uint32_t UserID=0, char* ID=''):

	u'''Pull a slurm trigger.

	:param int TriggerID: Trigger Identifier
	:param int UserID: User Identifier
	:param string ID: Job Identifier

	:returns: 0 for success or a slurm error code
	:rtype: `int`
	'''

	cdef slurm.trigger_info_t trigger_pull
	cdef char tmp_c[128]
	cdef int  cRetval = 0

	memset(&trigger_pull, 0, sizeof(slurm.trigger_info_t))

	trigger_pull.trig_id = TriggerID 
	trigger_pull.user_id = UserID

	if ID:
		trigger_pull.res_type = 1  #TRIGGER_RES_TYPE_JOB 
		memcpy(tmp_c, ID, 128)
		trigger_pull.res_id = tmp_c

	cRetval = slurm.slurm_pull_trigger(&trigger_pull)

	return cRetval

#
# SLURM Reservation Functions
#

cpdef slurm_load_reservations(Reservation_ptr='', int Flags=0):

	u'''Load slurm reservation information.

	:param	pointer Reservation_ptr: Wrapped record pointer returned a by previous slurm_load_reservatione call
	:param int Flags: Reservation Flag, default is 0

	:returns: Error value
	:rtype: `int`
	:returns: Wrapped pointer that can be passed to get_reservation_data
	:rtype: `int`
	'''

	cdef slurm.reserve_info_msg_t *old_res_info_ptr = NULL
	cdef slurm.reserve_info_msg_t *res_info_ptr = NULL

	cdef slurm.time_t last_time = <slurm.time_t>NULL
	cdef int cRetval = 0

	if Reservation_ptr != '':
		old_res_info_ptr = <slurm.reserve_info_msg_t *>ptr_unwrapper(Reservation_ptr)
		cRetval = slurm.slurm_load_reservations(old_res_info_ptr.last_update, &res_info_ptr)
		if cRetval == 0:
			slurm.slurm_free_reservation_info_msg(old_res_info_ptr)
		elif ( slurm.slurm_get_errno() == 1 ):
			cRetval = 0
			res_info_ptr = old_res_info_ptr
	else:
		old_res_info_ptr = NULL
		res_info_ptr = NULL

		last_time = <time_t>NULL

		cRetval = slurm.slurm_load_reservations(last_time, &res_info_ptr)

	old_res_info_ptr = res_info_ptr

	Res_ptr = ptr_wrapper(res_info_ptr)

	return cRetval, Res_ptr

def get_reservation_data(Reservation_ptr):

	u'''Get slurm reservation information.

	:param pointer Reservation_ptr: Wrapped record pointer returned by slurm_load_reservation call

	:returns: Data whose key is the Reservation ID
	:rtype: `dict`
	'''

	cdef slurm.reserve_info_msg_t *old_res_ptr = <slurm.reserve_info_msg_t*>ptr_unwrapper(Reservation_ptr)
	cdef slurm.reserve_info_t *res_ptr

	cdef int i = 0

	cdef dict Reservations, Res_dict

	Reservations = {}
	if old_res_ptr == NULL:	return Reservations

	for i from 0 <= i < old_res_ptr.record_count:

		Res_dict = {}

		name = old_res_ptr.reservation_array[i].name
		Res_dict['name']       = name
		Res_dict['accounts']   = slurm.stringOrNone(old_res_ptr.reservation_array[i].accounts, '')
		Res_dict['features']   = slurm.stringOrNone(old_res_ptr.reservation_array[i].features, '')
		Res_dict['licenses']   = slurm.stringOrNone(old_res_ptr.reservation_array[i].licenses, '')
		Res_dict['partition']  = slurm.stringOrNone(old_res_ptr.reservation_array[i].partition, '')
		Res_dict['node_list']  = slurm.stringOrNone(old_res_ptr.reservation_array[i].node_list, '')
		Res_dict['node_cnt']   = old_res_ptr.reservation_array[i].node_cnt
		Res_dict['users']      = slurm.stringOrNone(old_res_ptr.reservation_array[i].users, '')
		Res_dict['start_time'] = old_res_ptr.reservation_array[i].start_time
		Res_dict['end_time']   = old_res_ptr.reservation_array[i].end_time
		Res_dict['flags']      = get_res_state(old_res_ptr.reservation_array[i].flags)

		Reservations[name] = Res_dict

	return Reservations

cpdef slurm_print_reservation_info_msg(Reservation_ptr, int Flags=0):

	u'''Output information about all slurm reservations.

	:param pointer Reservation_ptr: Wrapped record pointer returned by slurm_load_reservation call
	:param int Flags: Reservation flags, 1 - print to a single line, 0 - multi lines (default)
	'''

	cdef slurm.reserve_info_msg_t *res_ptr = <slurm.reserve_info_msg_t *>ptr_unwrapper(Reservation_ptr)

	slurm.slurm_print_reservation_info_msg(slurm.stdout, res_ptr, Flags)

cpdef slurm_print_reservation_info(Reservation_ptr, int Flags=0):

	u'''Output information about slurm reservations.

	:param pointer Reservation_ptr: Wrapped record pointer returned by slurm_load_reservation call
	:param int Flags: Reservation flags (default=0)
	'''

	cdef slurm.reserve_info_t *res_ptr = <slurm.reserve_info_t*>ptr_unwrapper(Reservation_ptr)

	slurm.slurm_print_reservation_info(stdout, res_ptr, Flags)

cpdef slurm_sprint_reservation_info(Reservation_ptr):

	u'''Output information about all slurm reservations.

	:param pointer Reservation_ptr: Wrapped record pointer returned by slurm_load_reservation call

	:returns: Reservation information string
	:rtype: `char`
	'''

	cdef slurm.reserve_info_t *res_ptr = <slurm.reserve_info_t *>ptr_unwrapper(Reservation_ptr)

	cdef char* resinfo = slurm.slurm_sprint_reservation_info(res_ptr, 0)

	return resinfo

cpdef slurm_create_reservation(dict reservation_dict={}):

	u'''Create a slurm reservation.

	:param dict reservation_dict: A populated reservation dictionary, an empty one is created by create_reservation_dict

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `int`
	'''

	cdef slurm.resv_desc_msg_t resv_msg
	cdef char* resid = NULL, *name = NULL
	cdef int  int_value = 0, free_users = 0, free_accounts = 0

	cdef unsigned int uint32_value, time_value

	slurm.slurm_init_resv_desc_msg(&resv_msg)

	time_value = reservation_dict['start_time']
	resv_msg.start_time = time_value

	uint32_value = reservation_dict['duration']
	resv_msg.duration = uint32_value

	if reservation_dict['node_cnt'] != -1:
		int_value = reservation_dict['node_cnt']
		resv_msg.node_cnt = int_value

	if reservation_dict['users'] != '':
		name = reservation_dict['users']
		resv_msg.users = <char*>xmalloc((len(name)+1)*sizeof(char))
		strcpy(resv_msg.users, name)
		free_users = 1

	if reservation_dict['accounts'] != '':
		name = reservation_dict['accounts']
		resv_msg.accounts = <char*>xmalloc((len(name)+1)*sizeof(char))
		strcpy(resv_msg.accounts, name)
		free_accounts = 1

	if reservation_dict['licenses'] != '':
		name = reservation_dict['licenses']
		resv_msg.licenses = name

	resid = slurm.slurm_create_reservation(&resv_msg)

	if free_users == 1:
		free(resv_msg.users)
	if free_accounts == 1:
		free(resv_msg.accounts)

	return resid

cpdef int slurm_update_reservation(dict reservation_dict={}):

	u'''Update a slurm reservation.

	:param dict reservation_dict: A populated reservation dictionary, an empty one is created by create_reservation_dict

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `int`
	'''

	cdef slurm.resv_desc_msg_t resv_msg
	cdef char* name
	cdef int  int_value = 0, free_users = 0, free_accounts = 0, cRetval = 0

	cdef uint32_t uint32_value
	cdef slurm.time_t time_value

	slurm.slurm_init_resv_desc_msg(&resv_msg)

	time_value = reservation_dict['start_time']
	if time_value != -1:
		resv_msg.start_time = time_value

	uint32_value = reservation_dict['duration']
	if uint32_value != -1:
		resv_msg.duration = uint32_value

	if reservation_dict['name'] != '':
		resv_msg.name = reservation_dict['name']

	if reservation_dict['node_cnt'] != -1:
		uint32_value = reservation_dict['node_cnt']
		resv_msg.node_cnt = uint32_value

	if reservation_dict['users'] != '':
		name = reservation_dict['users']
		resv_msg.users = <char*>xmalloc((len(name)+1)*sizeof(char))
		strcpy(resv_msg.users, name)
		free_users = 1

	if reservation_dict['accounts'] != '':
		name = reservation_dict['accounts']
		resv_msg.accounts = <char*>xmalloc((len(name)+1)*sizeof(char))
		strcpy(resv_msg.accounts, name)
		free_accounts = 1

	if reservation_dict['licenses'] != '':
		name = reservation_dict['licenses']
		resv_msg.licenses = name

	cRetval = slurm.slurm_update_reservation(&resv_msg)

	if free_users == 1:
		free(resv_msg.users)
	if free_accounts == 1:
		free(resv_msg.accounts)

	return cRetval

cpdef int slurm_delete_reservation(char* ResID=''):

	u'''Delete a slurm reservation.

	:param int ResID: Reservation Identifier

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `int`
	'''

	cdef slurm.reservation_name_msg_t resv_msg 

	if not ResID: 
		return -1

	resv_msg.name = ResID
	cdef int cRetval = slurm.slurm_delete_reservation(&resv_msg)

	return cRetval
   
cpdef slurm_free_reservation_info_msg(Reservation_ptr):

	u'''Free slurm reservation pointer.

	:param pointer Reservation_ptr: Wrapped reservation pointer returned by a previous call to slurm_load_reservations
	'''

	cdef slurm.reserve_info_msg_t *old_resv_ptr = <slurm.reserve_info_msg_t*>ptr_unwrapper(Reservation_ptr)

	slurm.slurm_free_reservation_info_msg(old_resv_ptr)

#
# Block Functions
#

cpdef slurm_print_block_info_msg (Block_ptr, int Flags=0):
	#void slurm_print_block_info_msg (FILE *out, block_info_msg_t *info_ptr, int)
	pass

cpdef slurm_print_block_info (BG_ptr, int Flags=0):
	#cpdef void slurm_print_block_info (FILE *out, block_info_t *bg_info_ptr, int)
	pass

cpdef slurm_sprint_block_info (Block_ptr, int Flags=0):
	#cpdef char *slurm_sprint_block_info (block_info_t * bg_info_ptr, int)
	pass

cpdef slurm_load_block_info (time_t, Block_ptr, uint16_t Flags=0):
	#int slurm_load_block_info (time_t, block_info_msg_t **block_info_msg_pptr, uint16_t)
	pass

cpdef slurm_free_block_info_msg (Block_ptr):
	#void slurm_free_block_info_msg (block_info_msg_t *block_info_msg):
	pass

cpdef slurm_update_block (Block_ptr):
	#int slurm_update_block (update_block_msg_t *block_msg):
	pass

cpdef slurm_init_update_block_msg (Block_ptr):
	#void slurm_init_update_block_msg (update_block_msg_t *update_block_msg):
	pass

def create_reservation_dict():

	u'''Returns a dictionary that can be populated by the user an used for 
	the update_reservation and create_reservation calls.

	:returns: Empty Reservation dictionary
	:rtype: `dict`
	'''

	return  {
		'start_time': -1,
		'end_time': -1,
		'duration': -1,
		'node_cnt': -1,
		'name': '',
		'node_list': '',
		'flags': '',
		'partition': '',
		'licenses': '',
		'users': '',
		'accounts': ''
		}
 
def create_partition_dict():

	u'''Returns a dictionary that can be populated by the user
	and used for the update_partition and create_partition calls.

	:returns: Empty reservation dictionary
	:rtype: `dict`
	'''

	return {
		'PartitonName': '',
		'MaxTime': -1,
		'DefaultTime': -1,
		'MaxNodes': -1,
		'MinNodes': -1,
		'Default': False,
		'Hidden': False,
		'RootOnly': False,
		'Shared': False,
		'Priority': -1,
		'State': False,
		'Nodes': '',
		'AllowGroups': '',
		'AllocNodes': ''
		}

cpdef __get_user(int UserID):

	try:
		user = pwd.getpwuid(UserID).pw_name
	except:
		user = 'unknown(%s)' % UserID

	return user

cpdef __get_trigger_res_type(int ResType=0):

	u'''Returns a string that represents the state of the slurm trigger res type

	:returns: Trigger reservation state
	:rtype: `string`
	'''

	cdef char* type = 'unknown'

	if ResType == 1:	# TRIGGER_RES_TYPE_JOB
		type = 'job'
	elif ResType == 2:	# TRIGGER_RES_TYPE_NODE
		type = 'node'
	elif ResType == 3:	# TRIGGER_RES_TYPE_SLURMCTLD
		type='slurmctld'
	elif ResType == 4:	# TRIGGER_RES_TYPE_SLURMDBD
		type='slurmbdb'
	elif ResType == 5:	# TRIGGER_RES_TYPE_DATABASE
		type='database'

	return type

cpdef __get_trigger_type(int TriggerType=0):

	u'''Returns a string that represents the state of the slurm trigger

	:returns: Trigger state
	:rtype: `string`
	'''

	cdef char* type = 'unknown'

	if TriggerType == 0x0001:	# TRIGGER_TYPE_UP
		type = 'up'
	elif TriggerType == 0x0002:	# TRIGGER_TYPE_DOWN
		type = 'down'
	elif TriggerType == 0x0004:	# TRIGGER_TYPE_FAIL
		type = 'fail'
	elif TriggerType == 0x0008:	# TRIGGER_TYPE_TIME
		type = 'time'
	elif TriggerType == 0x0010:	# TRIGGER_TYPE_FINI
		type = 'fini'
	elif TriggerType == 0x0020:	# TRIGGER_TYPE_RECONFIG
		type = 'reconfig'
	elif TriggerType == 0x0040:	# TRIGGER_TYPE_BLOCK_ERR
		type = 'block_err'
	elif TriggerType == 0x0080:	# TRIGGER_TYPE_IDLE
		type = 'idle'
	elif TriggerType == 0x0100:	# TRIGGER_TYPE_DRAINED
		type = 'drained'

	return type

cpdef __get_partition_state2(int inx, int extended=0):

	u'''Returns a string that represents the state of the slurm partition

	:returns: Partition state
	:rtype: `string`
	'''

	cdef int drain_flag   = (inx & 0x0200)
	cdef int comp_flag    = (inx & 0x0400)
	cdef int no_resp_flag = (inx & 0x0800)
	cdef int power_flag   = (inx & 0x1000)

	inx = (inx & 0x00ff)

	cdef char* state = '?'

	if (drain_flag):
		if (comp_flag or (inx == 4) ):
			state = 'DRAINING'
			if (no_resp_flag and extended):
				state = 'DRAINING*'
		else:
			state = 'DRAINED'
			if (no_resp_flag and extended):
				state = 'DRAINED*'
		return state

	if (inx == 1):
		state = 'DOWN'
		if (no_resp_flag and extended):
			state = 'DOWN*'
	elif (inx == 3):
		state = 'ALLOCATED'
		if (no_resp_flag and extended):
			state = 'ALLOCATED*'
		elif (comp_flag and extended):
			state = 'ALLOCATED+'
		elif (comp_flag):
			state = 'COMPLETING'
			if (no_resp_flag and extended):
				state = 'COMPLETING*'
	elif (inx == 2):
		state = 'IDLE'
		if (no_resp_flag and extended):
			state = 'IDLE*'
		elif (power_flag and extended):
			state = 'IDLE~'
	elif (inx == 0):
		state = 'UNKNOWN'
		if (no_resp_flag and extended):
			state = 'UNKNOWN*'

	return state

cpdef get_res_state(int flags=0):

	u'''Returns a string that represents the state of the slurm reservation

	:returns: Reservation state
	:rtype: `list`
	'''

	cdef list resFlags

	resFlags = []
	if (flags & RESERVE_FLAG_MAINT):
		resFlags.append('MAINT')

	if (flags & RESERVE_FLAG_NO_MAINT):
		resFlags.append('NO_MAINT')
   
	if (flags & RESERVE_FLAG_DAILY):
		resFlags.append('DAILY')

	if (flags & RESERVE_FLAG_NO_DAILY):
		resFlags.append('NO_DAILY')
     
	if (flags & RESERVE_FLAG_WEEKLY): 
		resFlags.append('WEEKLY')
       
	if (flags & RESERVE_FLAG_NO_WEEKLY):
		resFlags.append('NO_WEEKLY')

	if (flags & RESERVE_FLAG_IGN_JOBS): 
		resFlags.append('IGNORE_JOBS')

	if (flags & RESERVE_FLAG_NO_IGN_JOB): 
		resFlags.append('NO_IGNORE_JOBS')

	if (flags & RESERVE_FLAG_OVERLAP):
		resFlags.append('OVERLAP')

	if (flags & RESERVE_FLAG_SPEC_NODES): 
		resFlags.append('SPEC_NODES')

	return resFlags

cpdef get_debug_flags(int flags=0):

	u'''Returns a string that represents the slurm debug flags

	:returns: Debug flags
	:rtype: `string`
	'''

	cdef list debugFlags
	
	debugFlags = []
	
	if ( flags & DEBUG_FLAG_BG_ALGO ):
		debugFlags.append('BGBlockAlgo')

	if ( flags & DEBUG_FLAG_BG_ALGO_DEEP ):
		debugFlags.append('BGBlockAlgoDeep')

	if ( flags & DEBUG_FLAG_BACKFILL ):
		debugFlags.append('Backfill')

	if ( flags & DEBUG_FLAG_BG_PICK ):
		debugFlags.append('BGBlockPick')

	if ( flags & DEBUG_FLAG_BG_WIRES ):
		debugFlags.append('BGBlockWires')

	if ( flags & DEBUG_FLAG_CPU_BIND ):
		debugFlags.append('CPU_Bind')

	if ( flags & DEBUG_FLAG_GANG ):
		debugFlags.append('Gang')

	if ( flags & DEBUG_FLAG_GRES ):
		debugFlags.append('Gres')

	if ( flags & DEBUG_FLAG_NO_CONF_HASH ):
		debugFlags.append('NO_CONF_HASH')

	if ( flags & DEBUG_FLAG_PRIO ):
		debugFlags.append('Priority')
               
	if ( flags & DEBUG_FLAG_RESERVATION ):
		debugFlags.append('Reservation')

	if ( flags & DEBUG_FLAG_SELECT_TYPE ):
		debugFlags.append('SelectType')

	if ( flags & DEBUG_FLAG_STEPS ):
			debugFlags.append('Steps')

	if ( flags & DEBUG_FLAG_TRIGGERS ):
		debugFlags.append('Triggers')

	if ( flags & DEBUG_FLAG_WIKI ):
		debugFlags.append('Wiki')

	return debugFlags

cpdef __get_node_state(int inx=0):

	u'''Returns a string that represents the state of the slurm node

	:returns: Node state
	:rtype: `string`
	'''

	cdef char* node_state = 'Unknown'

	state = [
			'Unknown',
			'Down',
			'Idle',
			'Allocated',
			'Error',
			'Mixed',
			'Future'
			]

	try:
		node_state = state[inx]
	except:
		pass

	return node_state 

cpdef __get_job_state(int inx):

	u'''Returns a string that represents the state of the slurm job state

	:returns: Job state
	:rtype: `string`
	'''

	cdef char* job_state = 'Unknown'

	cdef list state = [
					'Pending',
					'Running',
					'Suspended',
					'Complete',
					'Cancelled',
					'Failed',
					'Timeout',
					'Node Fail',
					'End'
					]

	try:
		job_state = state[inx]
	except:
		pass

	return job_state 

cpdef __get_preempt_mode(uint16_t inx):

	u'''Returns a list that represents the preempt mode

	:returns: Preempt mode
	:rtype: `list`
	'''

	cdef list modeFlags

	inx = 65534 - inx 
	if inx == PREEMPT_MODE_OFF:	return ['OFF']
	if inx == PREEMPT_MODE_GANG:	return ['GANG']

	modeFlags = []
	mode_str = ''
	if inx & PREEMPT_MODE_GANG :
		modeFlags.append('GANG')
		inx &= (~ PREEMPT_MODE_GANG)

	if ( inx == PREEMPT_MODE_CANCEL ):
		modeFlags.append('CANCEL')
	elif ( inx == PREEMPT_MODE_CHECKPOINT ):
		modeFlags.append('CHECKPOINT')
	elif ( inx == PREEMPT_MODE_REQUEUE ):
		modeFlags.append('REQUEUE')
	elif ( inx == PREEMPT_MODE_SUSPEND ):
		modeFlags.append('SUSPEND')
	else:
		modeFlags.append('UNKNOWN')

	return modeFlags

cpdef __get_partition_state(uint16_t inx=0):

	u'''Return a string that represents the state of the slurm partition

	:returns: Partition state
	:rtype: `string`
	'''

	cdef char* part_state = 'Unknown'

	if inx == (0x01|0x02):	
		part_state = 'Up'
	elif inx == (0x001):
		part_state = 'Down'
	elif inx == (0x00):
		part_state = 'Inactive'
	elif inx == (0x02):
		part_state = 'Drain'
	else:
		part_state = 'Unknown'

	return part_state

cpdef __get_partition_mode(uint16_t inx=0):

	u'''Returns a dictionary that represents the mode of the slurm partition

	:returns: Partition mode
	:rtype: `dict`
	'''

	cdef dict mode

	mode = {}
	if (inx & PART_FLAG_DEFAULT):
		mode['Default'] = True
	else:
		mode['Default'] = False

	if (inx & PART_FLAG_HIDDEN):
		mode['Hidden'] = True
	else:
		mode['Hidden'] = False

	if (inx & PART_FLAG_NO_ROOT):
		mode['DisableRootJobs'] = True
	else:
		mode['DisableRootJobs'] = False

	if (inx & PART_FLAG_ROOT_ONLY):
		mode['RootOnly'] = True
	else:
		mode['RootOnly'] = False

	return mode

cpdef __get_job_state_reason(int inx=0):

	u'''Returns a string that represents the state of the slurm job

	:returns: Reason state
	:rtype: `string`
	'''

	cdef char* job_state_reason = 'Unknown'

	cdef list reason = [
		'None',
		'higher priority jobs exist',
		'dependent job has not completed',
		'required resources not available',
		'request exceeds partition node limit',
		'request exceeds partition time limit',
		'requested partition is down',
		'requested partition is inactive',
		'job is held by administrator',
		'job is waiting for specific begin time',
		'job is waiting for licenses',
		'user/bank job limit reached',
		'user/bank resource limit reached',
		'user/bank time limit reached',
		'reservation not available',
		'required node is DOWN or DRAINED',
		'job is held by user',
		'TBD2',
		'partition for job is DOWN',
		'some node in the allocation failed',
		'constraints can not be satisfied',
		'slurm system failure',
		'unable to launch job',
		'exit code was non-zero',
		'reached end of time limit',
		'reached slurm InactiveLimit',
		'invalid account',
		'invalid QOS',
		'required QOS threshold has been breached'
		]

	try:
		job_state_reason = reason[inx]
	except:
		pass

	return job_state_reason 

def epoch2date(int epochSecs=0):

	u'''Convert epoch secs to a python time string

	:returns: Date
	:rtype: `string`
	'''

	dateTime = time.gmtime(epochSecs)
	dateStr = time.strftime("%a %b %d %H:%M:%S %Y", dateTime)

	return dateStr

class SlurmError(Exception):

	def __init__(self, value):
		self.value = value

	def __str__(self):
		return repr(slurm.slurm_strerror(self.value))

class Dict(defaultdict):

	def __init__(self):
		defaultdict.__init__(self, Dict)

	def __repr__(self):
		return dict.__repr__(self)
