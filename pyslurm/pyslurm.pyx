# cython: embedsignature=True
# cython: profile=False

import time
import os

from socket import gethostname
from collections import defaultdict

from libc.string cimport strlen, strcpy, memset, memcpy

from libc.stdint cimport uint8_t, uint16_t, uint32_t
from libc.stdint cimport int64_t, uint64_t

from libc.stdlib cimport malloc, free

from cpython cimport bool

cdef extern from 'stdlib.h':
	ctypedef long long size_t

cdef extern from 'stdio.h':
	ctypedef struct FILE
	cdef FILE *stdout

cdef extern from 'Python.h':
	cdef FILE *PyFile_AsFile(object file)

cdef extern from 'time.h' nogil:
	ctypedef long time_t

try:
	import __builtin__
except ImportError:
	## Python 3
	import builtins as __builtin__

#cdef object _unicode
#try:
	#_unicode = __builtin__.unicode
#except AttributeError:
	## Python 3
	#_unicode = __builtin__.str
    
#from cpython cimport PyErr_SetString, PyBytes_Check
#from cpython cimport PyUnicode_Check, PyBytes_FromStringAndSize

cimport slurm
include "bluegene.pxi"
include "slurm_defines.pxi"

#
# Slurm Macros as Cython inline functions
#

cdef inline SLURM_VERSION_NUMBER(): return slurm.SLURM_VERSION_NUMBER
cdef inline SLURM_VERSION_MAJOR(a): return ((a >> 16) & 0xff)
cdef inline SLURM_VERSION_MINOR(a): return ((a >>  8) & 0xff)
cdef inline SLURM_VERSION_MICRO(a): return (a & 0xff)
cdef inline SLURM_VERSION_NUM(a):   return (((SLURM_VERSION_MAJOR(a)) << 16) + ((SLURM_VERSION_MINOR(a)) << 8) + (SLURM_VERSION_MICRO(a)))

#
# SLURM_ID_HASH
# Description:
#  Creates a hash of a Slurm JOBID and STEPID
#  The JOB STEP ID is multiplied by 10,000,000,000
#  to move it out of the range of the JOB ID.
#  This allows viewers to easily read the JOB ID and JOB STEP ID
#  merely by looking at the numbers.  The JOB STEP ID should be
#  separated from the JOB ID by some number of zeros in most cases.
#  Example:
#   JOB ID = 123
#   JOB STEP ID = 456
#   ID_HASH = 4560000000123
#
# IN  _jobid -- SLURM's JOB ID (uint32_t)
# IN  _stepid -- SLURM's JOB STEP ID (uint32_t)
# RET id_hash -- (uint64_t)
#

cdef inline SLURM_ID_HASH(_jobid, _stepid): return <uint64_t>(<uint64_t>_stepid * SLURM_ID_HASH_NUM + _jobid)
cdef inline SLURM_ID_HASH_JOB_ID(hash_id): return <uint32_t>(hash_id % SLURM_ID_HASH_NUM)
cdef inline SLURM_ID_HASH_STEP_ID(hash_id): return <uint32_t>(hash_id / SLURM_ID_HASH_NUM)

#
# Misc helper inline functions
#

cdef inline IS_JOB_PENDING(int _X): return ((_X & JOB_STATE_BASE) == JOB_PENDING)
cdef inline IS_JOB_RUNNING(int _X): return ((_X & JOB_STATE_BASE) == JOB_RUNNING)
cdef inline IS_JOB_SUSPENDED(int _X): return ((_X & JOB_STATE_BASE) == JOB_SUSPENDED)
cdef inline IS_JOB_COMPLETE(int _X): return ((_X & JOB_STATE_BASE) == JOB_COMPLETE)
cdef inline IS_JOB_CANCELLED(int _X): return ((_X & JOB_STATE_BASE) == JOB_CANCELLED)
cdef inline IS_JOB_FAILED(int _X): return ((_X & JOB_STATE_BASE) == JOB_FAILED)
cdef inline IS_JOB_TIMEOUT(int _X): return ((_X & JOB_STATE_BASE) == JOB_TIMEOUT)
cdef inline IS_JOB_NODE_FAILED(int _X): return ((_X & JOB_STATE_BASE) == JOB_NODE_FAIL)

cdef inline IS_JOB_COMPLETING(int _X): return (_X & JOB_COMPLETING)
cdef inline IS_JOB_CONFIGURING(int _X): return (_X & JOB_CONFIGURING)
cdef inline IS_JOB_STARTED(int _X): return ((_X & JOB_STATE_BASE) >  JOB_PENDING)
cdef inline IS_JOB_FINISHED(int _X): return ((_X & JOB_STATE_BASE) >  JOB_SUSPENDED)
cdef inline IS_JOB_COMPLETED(int _X): return (IS_JOB_FINISHED(_X) and ((_X & JOB_COMPLETING) == 0))
cdef inline IS_JOB_RESIZING(int _X): return (_X & JOB_RESIZING)
cdef inline IS_JOB_REQUEUED(int _X): return (_X & JOB_REQUEUE)

cdef inline IS_NODE_UNKNOWN(int _X): return ((_X & NODE_STATE_BASE) == NODE_STATE_UNKNOWN)
cdef inline IS_NODE_DOWN(int _X): return ((_X & NODE_STATE_BASE) == NODE_STATE_DOWN)
cdef inline IS_NODE_IDLE(int _X): return ((_X & NODE_STATE_BASE) == NODE_STATE_IDLE)
cdef inline IS_NODE_ALLOCATED(int _X): return ((_X & NODE_STATE_BASE) == NODE_STATE_ALLOCATED)
cdef inline IS_NODE_ERROR(int _X): return ((_X & NODE_STATE_BASE) == NODE_STATE_ERROR)
cdef inline IS_NODE_MIXED(int _X): return ((_X & NODE_STATE_BASE) == NODE_STATE_MIXED)
cdef inline IS_NODE_FUTURE(int _X): return ((_X & NODE_STATE_BASE) == NODE_STATE_FUTURE)

cdef inline IS_NODE_CLOUD(int _X): return (_X & NODE_STATE_CLOUD)
cdef inline IS_NODE_DRAIN(int _X): return (_X & NODE_STATE_DRAIN)
cdef inline IS_NODE_DRAINING(int _X): return ((_X & NODE_STATE_DRAIN) or (IS_NODE_ALLOCATED(_X) or IS_NODE_ERROR(_X) or IS_NODE_MIXED(_X)))
cdef inline IS_NODE_DRAINED(int _X): return (IS_NODE_DRAIN(_X) and IS_NODE_DRAINING(_X) != 0)
cdef inline IS_NODE_COMPLETING(int _X): return (_X & NODE_STATE_COMPLETING)
cdef inline IS_NODE_NO_RESPOND(int _X): return (_X & NODE_STATE_NO_RESPOND)
cdef inline IS_NODE_POWER_SAVE(int _X): return (_X & NODE_STATE_POWER_SAVE)
cdef inline IS_NODE_POWER_UP(int _X): return (_X & NODE_STATE_POWER_UP)
cdef inline IS_NODE_FAIL(int _X): return (_X & NODE_STATE_FAIL)
cdef inline IS_NODE_MAINT(int _X): return (_X & NODE_STATE_MAINT)

ctypedef struct config_key_pair_t:
	char *name
	char *value

#
# Cython Wrapper Functions
#

cpdef tuple get_controllers():

	u"""Get information about slurm controllers.

	:return: Name of primary controller, Name of backup controller
	:rtype: `tuple`
	"""

	cdef:
		slurm.slurm_ctl_conf_t *slurm_ctl_conf_ptr = NULL
		slurm.time_t Time = <slurm.time_t>NULL
		int apiError = 0
		int errCode = slurm.slurm_load_ctl_conf(Time, &slurm_ctl_conf_ptr)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	primary = backup = None
	if slurm_ctl_conf_ptr is not NULL:

		if slurm_ctl_conf_ptr.control_machine is not NULL:
			primary = u"%s" % slurm_ctl_conf_ptr.control_machine
		if slurm_ctl_conf_ptr.backup_controller is not NULL:
			backup = u"%s" % slurm_ctl_conf_ptr.backup_controller

		slurm.slurm_free_ctl_conf(slurm_ctl_conf_ptr)

	return primary, backup

def is_controller(Host):

	u"""Return slurm controller status for host.
 
	:param string Host: Name of host to check

	:returns: None, primary or backup
	:rtype: `string`
	"""

	primary, backup = get_controllers()
	if not Host:
		Host = gethostname()

	if primary == Host:
		return u'primary'
	if backup  == Host:
		return u'backup'

	return None

def slurm_api_version():

	u"""Return the slurm API version number.

	:returns: version_major, version_minor, version_micro
	:rtype: `tuple`
	"""

	cdef long version = slurm.SLURM_VERSION_NUMBER

	return (SLURM_VERSION_MAJOR(version), SLURM_VERSION_MINOR(version), SLURM_VERSION_MICRO(version))

cpdef list slurm_load_slurmd_status():

	u"""Issue RPC to get and load the status of Slurmd daemon.

	:returns: Slurmd information
	:rtype: `dict`
	"""

	cdef:
		dict Status = {}, Status_dict = {}
		slurm.slurmd_status_t *slurmd_status = NULL
		char* hostname = NULL
		int errCode = slurm.slurm_load_slurmd_status(&slurmd_status)

	if errCode == 0:
		hostname = slurmd_status.hostname
		Status_dict[u'actual_boards'] = slurmd_status.actual_boards
		Status_dict[u'booted'] = slurmd_status.booted
		Status_dict[u'actual_cores'] = slurmd_status.actual_cores
		Status_dict[u'actual_cpus'] = slurmd_status.actual_cpus
		Status_dict[u'actual_real_mem'] = slurmd_status.actual_real_mem
		Status_dict[u'actual_sockets'] = slurmd_status.actual_sockets
		Status_dict[u'actual_threads'] = slurmd_status.actual_threads
		Status_dict[u'actual_tmp_disk'] = slurmd_status.actual_tmp_disk
		Status_dict[u'hostname'] = slurm.stringOrNone(slurmd_status.hostname, '')
		Status_dict[u'last_slurmctld_msg'] = slurmd_status.last_slurmctld_msg
		Status_dict[u'pid'] = slurmd_status.pid
		Status_dict[u'slurmd_debug'] = slurmd_status.slurmd_debug
		Status_dict[u'slurmd_logfile'] = slurm.stringOrNone(slurmd_status.slurmd_logfile, '')
		Status_dict[u'step_list'] = slurm.stringOrNone(slurmd_status.step_list, '')
		Status_dict[u'version'] = slurm.stringOrNone(slurmd_status.version, '')

		Status[hostname] = Status_dict

	slurm.slurm_free_slurmd_status(slurmd_status)

	return Status

#
# Slurm Config Class 
#

cdef class config:

	u"""Class to access slurm config Information."""

	cdef:
		slurm.slurm_ctl_conf_t *slurm_ctl_conf_ptr
		slurm.slurm_ctl_conf_t *__Config_ptr
		slurm.time_t Time
		slurm.time_t __lastUpdate
		dict __ConfigDict

	def __cinit__(self):
		self.__Config_ptr = NULL
		self.__lastUpdate = 0
		self.__ConfigDict = {}
		self.__load()

	def __dealloc__(self):
		self.__free()

	def lastUpdate(self):

		u"""Get the time (epoch seconds) the retrieved data was updated.

		:returns: epoch seconds
		:rtype: `integer`
		"""

		return self._lastUpdate

	def ids(self):

		u"""Return the config IDs from retrieved data.

		:returns: Dictionary of config key IDs
		:rtype: `dict`
		"""

		return self.__ConfigDict.keys()

	def find_id(self, char *keyID=''):

		u"""Retrieve config ID data.

		:param str keyID: Config key string to search
		:returns: Dictionary of values for given config key
		:rtype: `dict`
		"""

		return self.__JobDict.get(keyID, {})

	cdef void __free(self):

		u"""Free the slurm control configuration pointer returned from a previous slurm_load_ctl_conf call.
		"""

		if self.__Config_ptr is not NULL:
			slurm.slurm_free_ctl_conf(self.__Config_ptr)
			self.__Config_ptr = NULL
			self.__ConfigDict = {}
			self.__lastUpdate = 0

	def display_all(self):

		u"""Prints the contents of the data structure loaded by the slurm_load_ctl_conf function.
		"""

		slurm.slurm_print_ctl_conf(slurm.stdout, self.__Config_ptr)

	cdef int __load(self) except? -1:

		u"""Load the slurm control configuration information.

		:returns: slurm error code
		:rtype: `integer`
		"""

		cdef:
			slurm.slurm_ctl_conf_t *slurm_ctl_conf_ptr = NULL
			slurm.time_t Time = <slurm.time_t>NULL
			int apiError = 0
			int errCode = slurm.slurm_load_ctl_conf(Time, &slurm_ctl_conf_ptr)

		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		self.__Config_ptr = slurm_ctl_conf_ptr

		return errCode

	def key_pairs(self):

		u"""Return a dict of the slurm control data as key pairs.

		:returns: Dictionary of slurm key-pair values
		:rtype: `dict`
		"""

		cdef:
			void *ret_list = NULL
			slurm.List config_list = NULL
			slurm.ListIterator iters = NULL

			config_key_pair_t *keyPairs

			int listNum, i
			dict keyDict = {}

		if self.__Config_ptr is not NULL:

			config_list = <slurm.List>slurm.slurm_ctl_conf_2_key_pairs(self.__Config_ptr)

			listNum = slurm.slurm_list_count(config_list)
			iters = slurm.slurm_list_iterator_create(config_list)

			for i from 0 <= i < listNum:

				keyPairs = <config_key_pair_t *>slurm.slurm_list_next(iters)
				name = keyPairs.name

				if keyPairs.value is not NULL:
					value = keyPairs.value
				else:
					value = None

				keyDict[name] = value 

			slurm.slurm_list_iterator_destroy(iters)

		return keyDict

	def get(self):

		u"""Return the slurm control configuration information.

		:returns: Configuration data
		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return self.__ConfigDict

	cpdef dict __get(self):

		u"""Get the slurm control configuration information.

		:returns: Configuration data
		:rtype: `dict`
		"""

		cdef:
			void *ret_list = NULL
			slurm.List config_list = NULL
			slurm.ListIterator iters = NULL

			config_key_pair_t *keyPairs
			int i = 0
			int listNum
			dict Ctl_dict = {}
			dict key_pairs = {}

		if self.__Config_ptr is not NULL:

			self.__lastUpdate = self.__Config_ptr.last_update

			Ctl_dict[u'accounting_storage_tres'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_tres, '')
			Ctl_dict[u'accounting_storage_enforce'] = self.__Config_ptr.accounting_storage_enforce
			Ctl_dict[u'accounting_storage_backup_host'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_backup_host, '')
			Ctl_dict[u'accounting_storage_host'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_host, '')
			Ctl_dict[u'accounting_storage_loc'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_loc, '')
			Ctl_dict[u'accounting_storage_pass'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_pass, '')
			Ctl_dict[u'accounting_storage_port'] = self.__Config_ptr.accounting_storage_port
			Ctl_dict[u'accounting_storage_type'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_type, '')
			Ctl_dict[u'accounting_storage_user'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_user, '')
			Ctl_dict[u'acctng_store_job_comment'] = self.__Config_ptr.acctng_store_job_comment
			Ctl_dict[u'acct_gather_energy_type'] = slurm.stringOrNone(self.__Config_ptr.acct_gather_energy_type, '')
			Ctl_dict[u'acct_gather_profile_type'] = slurm.stringOrNone(self.__Config_ptr.acct_gather_profile_type, '')
			Ctl_dict[u'acct_gather_infiniband_type'] = slurm.stringOrNone(self.__Config_ptr.acct_gather_infiniband_type, '')
			Ctl_dict[u'acct_gather_filesystem_type'] = slurm.stringOrNone(self.__Config_ptr.acct_gather_filesystem_type, '')
			Ctl_dict[u'acct_gather_node_freq'] = self.__Config_ptr.acct_gather_node_freq
			Ctl_dict[u'authinfo'] = slurm.stringOrNone(self.__Config_ptr.authinfo, '')
			Ctl_dict[u'authtype'] = slurm.stringOrNone(self.__Config_ptr.authtype, '')
			Ctl_dict[u'backup_addr'] = slurm.stringOrNone(self.__Config_ptr.backup_addr, '')
			Ctl_dict[u'backup_controller'] = slurm.stringOrNone(self.__Config_ptr.backup_controller, '')
			Ctl_dict[u'batch_start_timeout'] = self.__Config_ptr.batch_start_timeout
			Ctl_dict[u'bb_type'] = slurm.stringOrNone(self.__Config_ptr.bb_type, '')
			Ctl_dict[u'boot_time'] = self.__Config_ptr.boot_time
			Ctl_dict[u'checkpoint_type'] = slurm.stringOrNone(self.__Config_ptr.checkpoint_type, '')
			Ctl_dict[u'chos_loc'] = slurm.stringOrNone(self.__Config_ptr.chos_loc, '')
			Ctl_dict[u'core_spec_plugin'] = slurm.stringOrNone(self.__Config_ptr.core_spec_plugin, '')
			Ctl_dict[u'cluster_name'] = slurm.stringOrNone(self.__Config_ptr.cluster_name, '')
			Ctl_dict[u'complete_wait'] = self.__Config_ptr.complete_wait
			Ctl_dict[u'control_addr'] = slurm.stringOrNone(self.__Config_ptr.control_addr, '')
			Ctl_dict[u'control_machine'] = slurm.stringOrNone(self.__Config_ptr.control_machine, '')
			Ctl_dict[u'cpu_freq_def'] = self.__Config_ptr.cpu_freq_def
			Ctl_dict[u'cpu_freq_govs'] = self.__Config_ptr.cpu_freq_govs
			Ctl_dict[u'crypto_type'] = slurm.stringOrNone(self.__Config_ptr.crypto_type, '')
			Ctl_dict[u'debug_flags'] = self.__Config_ptr.debug_flags
			Ctl_dict[u'def_mem_per_cpu'] = self.__Config_ptr.def_mem_per_cpu
			Ctl_dict[u'disable_root_jobs'] = bool(self.__Config_ptr.disable_root_jobs)
			Ctl_dict[u'eio_timeout'] = self.__Config_ptr.eio_timeout
			Ctl_dict[u'enforce_part_limits'] = bool(self.__Config_ptr.enforce_part_limits)
			Ctl_dict[u'epilog'] = slurm.stringOrNone(self.__Config_ptr.epilog, '')
			Ctl_dict[u'epilog_msg_time'] = self.__Config_ptr.epilog_msg_time
			Ctl_dict[u'epilog_slurmctld'] = slurm.stringOrNone(self.__Config_ptr.epilog_slurmctld, '')
			Ctl_dict[u'ext_sensors_type'] = slurm.stringOrNone(self.__Config_ptr.ext_sensors_type, '')
			Ctl_dict[u'fast_schedule'] = bool(self.__Config_ptr.fast_schedule)
			Ctl_dict[u'first_job_id'] = self.__Config_ptr.first_job_id
			Ctl_dict[u'fs_dampening_factor'] = self.__Config_ptr.fs_dampening_factor
			Ctl_dict[u'get_env_timeout'] = self.__Config_ptr.get_env_timeout
			Ctl_dict[u'gres_plugins'] = slurm.listOrNone(self.__Config_ptr.gres_plugins, ',')
			Ctl_dict[u'group_info'] = self.__Config_ptr.group_info
			Ctl_dict[u'hash_val'] = self.__Config_ptr.hash_val
			Ctl_dict[u'health_check_interval'] = self.__Config_ptr.health_check_interval
			Ctl_dict[u'health_check_node_state'] = self.__Config_ptr.health_check_node_state
			Ctl_dict[u'health_check_program'] = slurm.stringOrNone(self.__Config_ptr.health_check_program, '')
			Ctl_dict[u'inactive_limit'] = self.__Config_ptr.inactive_limit
			Ctl_dict[u'job_acct_gather_freq'] = self.__Config_ptr.job_acct_gather_freq
			Ctl_dict[u'job_acct_gather_type'] = slurm.stringOrNone(self.__Config_ptr.job_acct_gather_type, '')
			Ctl_dict[u'job_acct_gather_params'] = slurm.stringOrNone(self.__Config_ptr.job_acct_gather_params, '')
			Ctl_dict[u'job_ckpt_dir'] = slurm.stringOrNone(self.__Config_ptr.job_ckpt_dir, '')
			Ctl_dict[u'job_comp_host'] = slurm.stringOrNone(self.__Config_ptr.job_comp_host, '')
			Ctl_dict[u'job_comp_loc'] = slurm.stringOrNone(self.__Config_ptr.job_comp_loc, '')
			Ctl_dict[u'job_comp_pass'] = slurm.stringOrNone(self.__Config_ptr.job_comp_pass, '')
			Ctl_dict[u'job_comp_port'] = self.__Config_ptr.job_comp_port
			Ctl_dict[u'job_comp_type'] = slurm.stringOrNone(self.__Config_ptr.job_comp_type, '')
			Ctl_dict[u'job_comp_user'] = slurm.stringOrNone(self.__Config_ptr.job_comp_user, '')
			Ctl_dict[u'job_container_plugin'] = slurm.stringOrNone(self.__Config_ptr.job_container_plugin, '')
			Ctl_dict[u'job_credential_private_key'] = slurm.stringOrNone(self.__Config_ptr.job_credential_private_key, '')
			Ctl_dict[u'job_credential_public_certificate'] = slurm.stringOrNone(self.__Config_ptr.job_credential_public_certificate, '')
			Ctl_dict[u'job_file_append'] = bool(self.__Config_ptr.job_file_append)
			Ctl_dict[u'job_requeue'] = bool(self.__Config_ptr.job_requeue)
			Ctl_dict[u'job_submit_plugins'] = slurm.stringOrNone(self.__Config_ptr.job_submit_plugins, '')
			Ctl_dict[u'keep_alive_time'] = self.__Config_ptr.keep_alive_time
			Ctl_dict[u'kill_on_bad_exit'] = bool(self.__Config_ptr.kill_on_bad_exit)
			Ctl_dict[u'kill_wait'] = self.__Config_ptr.kill_wait
			Ctl_dict[u'launch_params'] = slurm.stringOrNone(self.__Config_ptr.launch_type, '')
			Ctl_dict[u'launch_type'] = slurm.stringOrNone(self.__Config_ptr.launch_type, '')
			Ctl_dict[u'licenses'] = __get_licenses(self.__Config_ptr.licenses)
			Ctl_dict[u'licenses_used'] = __get_licenses(self.__Config_ptr.licenses_used)
			Ctl_dict[u'log_fmt'] = self.__Config_ptr.log_fmt
			Ctl_dict[u'mail_prog'] = slurm.stringOrNone(self.__Config_ptr.mail_prog, '')
			Ctl_dict[u'max_array_sz'] = self.__Config_ptr.max_array_sz
			Ctl_dict[u'max_job_cnt'] = self.__Config_ptr.max_job_cnt
			Ctl_dict[u'max_job_id'] = self.__Config_ptr.max_job_id
			Ctl_dict[u'max_mem_per_cpu'] = self.__Config_ptr.max_mem_per_cpu
			Ctl_dict[u'max_step_cnt'] = self.__Config_ptr.max_step_cnt
			Ctl_dict[u'max_tasks_per_node'] = self.__Config_ptr.max_tasks_per_node
			Ctl_dict[u'mem_limit_enforce'] = self.__Config_ptr.mem_limit_enforce
			Ctl_dict[u'min_job_age'] = self.__Config_ptr.min_job_age
			Ctl_dict[u'mpi_default'] = slurm.stringOrNone(self.__Config_ptr.mpi_default, '')
			Ctl_dict[u'mpi_params'] = slurm.stringOrNone(self.__Config_ptr.mpi_params, '')
			Ctl_dict[u'msg_aggr_params'] = slurm.stringOrNone(self.__Config_ptr.msg_aggr_params, '')
			Ctl_dict[u'msg_timeout'] = self.__Config_ptr.msg_timeout
			Ctl_dict[u'next_job_id'] = self.__Config_ptr.next_job_id
			Ctl_dict[u'node_prefix']  = slurm.stringOrNone(self.__Config_ptr.node_prefix, '')
			Ctl_dict[u'over_time_limit'] = self.__Config_ptr.over_time_limit
			Ctl_dict[u'plugindir'] = slurm.stringOrNone(self.__Config_ptr.plugindir, '')
			Ctl_dict[u'plugstack'] = slurm.stringOrNone(self.__Config_ptr.plugstack, '')
			Ctl_dict[u'power_parameters'] = slurm.stringOrNone(self.__Config_ptr.power_parameters, '')
			Ctl_dict[u'power_plugin'] = slurm.stringOrNone(self.__Config_ptr.power_plugin, '')
			Ctl_dict[u'preempt_mode'] = get_preempt_mode(self.__Config_ptr.preempt_mode)
			Ctl_dict[u'preempt_type'] = slurm.stringOrNone(self.__Config_ptr.preempt_type, '')
			Ctl_dict[u'priority_decay_hl'] = self.__Config_ptr.priority_decay_hl
			Ctl_dict[u'priority_calc_period'] = self.__Config_ptr.priority_calc_period
			Ctl_dict[u'priority_favor_small'] = self.__Config_ptr.priority_favor_small
			Ctl_dict[u'priority_flags'] = self.__Config_ptr.priority_flags
			Ctl_dict[u'priority_max_age'] = self.__Config_ptr.priority_max_age
			Ctl_dict[u'priority_params'] = slurm.stringOrNone(self.__Config_ptr.priority_params, '')
			Ctl_dict[u'priority_reset_period'] = self.__Config_ptr.priority_reset_period
			Ctl_dict[u'priority_type'] = slurm.stringOrNone(self.__Config_ptr.priority_type, '')
			Ctl_dict[u'priority_weight_age'] = self.__Config_ptr.priority_weight_age
			Ctl_dict[u'priority_weight_fs'] = self.__Config_ptr.priority_weight_fs
			Ctl_dict[u'priority_weight_js'] = self.__Config_ptr.priority_weight_js
			Ctl_dict[u'priority_weight_part'] = self.__Config_ptr.priority_weight_part
			Ctl_dict[u'priority_weight_qos'] = self.__Config_ptr.priority_weight_qos
			Ctl_dict[u'proctrack_type'] = slurm.stringOrNone(self.__Config_ptr.proctrack_type, '')
			Ctl_dict[u'private_data'] = self.__Config_ptr.private_data
			Ctl_dict[u'priority_weight_tres'] = slurm.stringOrNone(self.__Config_ptr.priority_weight_tres, '')
			Ctl_dict[u'prolog'] = slurm.stringOrNone(self.__Config_ptr.prolog, '')
			Ctl_dict[u'prolog_epilog_timeout'] = self.__Config_ptr.prolog_epilog_timeout
			Ctl_dict[u'prolog_slurmctld'] = slurm.stringOrNone(self.__Config_ptr.prolog_slurmctld, '')
			Ctl_dict[u'propagate_prio_process'] = self.__Config_ptr.propagate_prio_process
			Ctl_dict[u'prolog_flags'] = self.__Config_ptr.prolog_flags
			Ctl_dict[u'propagate_rlimits'] = slurm.stringOrNone(self.__Config_ptr.propagate_rlimits, '')
			Ctl_dict[u'propagate_rlimits_except'] = slurm.stringOrNone(self.__Config_ptr.propagate_rlimits_except, '')
			Ctl_dict[u'reboot_program'] = slurm.stringOrNone(self.__Config_ptr.reboot_program, '')
			Ctl_dict[u'reconfig_flags'] = self.__Config_ptr.reconfig_flags
			Ctl_dict[u'resume_program'] = slurm.stringOrNone(self.__Config_ptr.resume_program, '')
			Ctl_dict[u'resume_rate'] = self.__Config_ptr.resume_rate
			Ctl_dict[u'resume_timeout'] = self.__Config_ptr.resume_timeout
			Ctl_dict[u'resv_epilog'] = slurm.stringOrNone(self.__Config_ptr.resv_epilog, '')
			Ctl_dict[u'resv_over_run'] = self.__Config_ptr.resv_over_run
			Ctl_dict[u'resv_prolog'] = slurm.stringOrNone(self.__Config_ptr.resv_prolog, '')
			Ctl_dict[u'ret2service'] = self.__Config_ptr.ret2service
			Ctl_dict[u'route_plugin'] = slurm.stringOrNone(self.__Config_ptr.route_plugin, '')
			Ctl_dict[u'salloc_default_command'] = slurm.stringOrNone(self.__Config_ptr.salloc_default_command, '')
			Ctl_dict[u'sched_logfile'] = slurm.stringOrNone(self.__Config_ptr.sched_logfile, '')
			Ctl_dict[u'sched_log_level'] = self.__Config_ptr.sched_log_level
			Ctl_dict[u'sched_params'] = slurm.stringOrNone(self.__Config_ptr.sched_params, '')
			Ctl_dict[u'sched_time_slice'] = self.__Config_ptr.sched_time_slice
			Ctl_dict[u'schedtype'] = slurm.stringOrNone(self.__Config_ptr.schedtype, '')
			Ctl_dict[u'schedport'] = self.__Config_ptr.schedport
			Ctl_dict[u'schedrootfltr'] = bool(self.__Config_ptr.schedrootfltr)
			Ctl_dict[u'select_type'] = slurm.stringOrNone(self.__Config_ptr.select_type, '')
			Ctl_dict[u'select_type_param'] = self.__Config_ptr.select_type_param
			Ctl_dict[u'slurm_conf'] = slurm.stringOrNone(self.__Config_ptr.slurm_conf, '')
			Ctl_dict[u'slurm_user_id'] = self.__Config_ptr.slurm_user_id
			Ctl_dict[u'slurm_user_name'] = slurm.stringOrNone(self.__Config_ptr.slurm_user_name, '')
			Ctl_dict[u'slurmd_user_id'] = self.__Config_ptr.slurmd_user_id
			Ctl_dict[u'slurmd_user_name'] = slurm.stringOrNone(self.__Config_ptr.slurmd_user_name, '')
			Ctl_dict[u'slurmctld_debug'] = self.__Config_ptr.slurmctld_debug
			Ctl_dict[u'slurmctld_logfile'] = slurm.stringOrNone(self.__Config_ptr.slurmctld_logfile, '')
			Ctl_dict[u'slurmctld_pidfile'] = slurm.stringOrNone(self.__Config_ptr.slurmctld_pidfile, '')
			Ctl_dict[u'slurmctld_port'] = self.__Config_ptr.slurmctld_port
			Ctl_dict[u'slurmctld_port_count'] = self.__Config_ptr.slurmctld_port_count
			Ctl_dict[u'slurmctld_timeout'] = self.__Config_ptr.slurmctld_timeout
			Ctl_dict[u'slurmd_debug'] = self.__Config_ptr.slurmd_debug
			Ctl_dict[u'slurmd_logfile'] = slurm.stringOrNone(self.__Config_ptr.slurmd_logfile, '')
			Ctl_dict[u'slurmd_pidfile'] = slurm.stringOrNone(self.__Config_ptr.slurmd_pidfile, '')
			Ctl_dict[u'slurmd_port'] = self.__Config_ptr.slurmd_port
			Ctl_dict[u'slurmd_spooldir'] = slurm.stringOrNone(self.__Config_ptr.slurmd_spooldir, '')
			Ctl_dict[u'slurmd_timeout'] = self.__Config_ptr.slurmd_timeout
			Ctl_dict[u'srun_epilog'] = slurm.stringOrNone(self.__Config_ptr.srun_epilog, '')

			#Ctl_dict[u'srun_port_range'] = self.__Config_ptr.srun_port_range

			Ctl_dict[u'srun_prolog'] = slurm.stringOrNone(self.__Config_ptr.srun_prolog, '')
			Ctl_dict[u'state_save_location'] = slurm.stringOrNone(self.__Config_ptr.state_save_location, '')
			Ctl_dict[u'suspend_exc_nodes'] = slurm.listOrNone(self.__Config_ptr.suspend_exc_nodes, ',')
			Ctl_dict[u'suspend_exc_parts'] = slurm.listOrNone(self.__Config_ptr.suspend_exc_parts, ',')
			Ctl_dict[u'suspend_program'] = slurm.stringOrNone(self.__Config_ptr.suspend_program, '')
			Ctl_dict[u'suspend_rate'] = self.__Config_ptr.suspend_rate
			Ctl_dict[u'suspend_time'] = self.__Config_ptr.suspend_time
			Ctl_dict[u'suspend_timeout'] = self.__Config_ptr.suspend_timeout
			Ctl_dict[u'switch_type'] = slurm.stringOrNone(self.__Config_ptr.switch_type, '')
			Ctl_dict[u'task_epilog'] = slurm.stringOrNone(self.__Config_ptr.task_epilog, '')
			Ctl_dict[u'task_plugin'] = slurm.stringOrNone(self.__Config_ptr.task_plugin, '')
			Ctl_dict[u'task_plugin_param'] = self.__Config_ptr.task_plugin_param
			Ctl_dict[u'task_prolog'] = slurm.stringOrNone(self.__Config_ptr.task_prolog, '')
			Ctl_dict[u'tmp_fs'] = slurm.stringOrNone(self.__Config_ptr.tmp_fs, '')
			Ctl_dict[u'topology_param'] = slurm.stringOrNone(self.__Config_ptr.topology_param, '')
			Ctl_dict[u'topology_plugin'] = slurm.stringOrNone(self.__Config_ptr.topology_plugin, '')
			Ctl_dict[u'track_wckey'] = self.__Config_ptr.track_wckey
			Ctl_dict[u'tree_width'] = self.__Config_ptr.tree_width
			Ctl_dict[u'unkillable_program'] = slurm.stringOrNone(self.__Config_ptr.unkillable_program, '')
			Ctl_dict[u'unkillable_timeout'] = self.__Config_ptr.unkillable_timeout
			Ctl_dict[u'use_pam'] = bool(self.__Config_ptr.use_pam)
			Ctl_dict[u'use_spec_resources'] = self.__Config_ptr.use_spec_resources
			Ctl_dict[u'version'] = slurm.stringOrNone(self.__Config_ptr.version, '')
			Ctl_dict[u'vsize_factor'] = self.__Config_ptr.vsize_factor
			Ctl_dict[u'wait_time'] = self.__Config_ptr.wait_time
			Ctl_dict[u'z_16'] = self.__Config_ptr.z_16
			Ctl_dict[u'z_32'] = self.__Config_ptr.z_32
			Ctl_dict[u'z_char'] = slurm.stringOrNone(self.__Config_ptr.z_char, '')

			#
			# Get key_pairs from Opaque data structure
			#

			#config_list = <slurm.List>self.__Config_ptr.select_conf_key_pairs

			#if config_list is not NULL:

				#listNum = slurm.slurm_list_count(config_list)
				#iters = slurm.slurm_list_iterator_create(config_list)
				#for i from 0 <= i < listNum:

					#keyPairs = <config_key_pair_t *>slurm.slurm_list_next(iters)
					#name = keyPairs.name
					#if keyPairs.value is not NULL:
						#value = keyPairs.value
					#else:
						#value = None

					#key_pairs[name] = value 

				#slurm.slurm_list_iterator_destroy(iters)

				#Ctl_dict[u'key_pairs'] = key_pairs

		self.__ConfigDict = Ctl_dict

#
# Partition Class
#

cdef class partition:

	u"""Class to access/modify Slurm Partition Information. 
	"""

	cdef:
		slurm.partition_info_msg_t *_Partition_ptr
		slurm.partition_info_t _record
		slurm.time_t _lastUpdate
		uint16_t _ShowFlags
		dict _PartDict

	def __cinit__(self):
		self._Partition_ptr = NULL
		self._lastUpdate = 0
		self._ShowFlags = 0
		self._PartDict = {}

	def __dealloc__(self):
		self.__destroy()

	cpdef __destroy(self):

		u"""Free the slurm partition memory allocated by load partition method. 
		"""

		if self._Partition_ptr is not NULL:
			slurm.slurm_free_partition_info_msg(self._Partition_ptr)

	def lastUpdate(self):

		u"""Get the time (epoch seconds) the retrieved data was updated.

		:returns: epoch seconds
		:rtype: `integer`
		"""
		return self._lastUpdate

	def ids(self):

		u"""Return the partition IDs from retrieved data.

		:returns: Dictionary of partition IDs
		:rtype: `dict`
		"""

		return self._PartDict.keys()

	def find_id(self, char *partID=''):

		u"""Retrieve partition ID data.

		:param str partID: Partition key to search
		:returns: Dictionary of values for given partition key
		:rtype: `dict`
		"""

		return self._PartDict.get(partID, {})

	def find(self, char *name='', val=''):

		u"""Search for a property and associated value in the retrieved partition data.

		:param str name: key string to search
		:param str value: value string to match
		:returns: List of IDs that match
		:rtype: `list`
		"""

		cdef list retList = []

		if val != '':
			for key, value in self._blockID.items():
				if self._blockID[key][name] == val:
					retList.append(key)
		return retList

	def load(self):

		u"""Load slurm partition information.
		"""

		self.__load()

	cpdef int __load(self) except? -1:

		u"""Load slurm partition information.

		:returns: slurm error Code
		:rtype: `integer`
		"""

		cdef:
			slurm.partition_info_msg_t *new_Partition_ptr = NULL
			slurm.time_t last_time = <slurm.time_t>NULL
			int apiError = 0, errCode = 0

		if self._Partition_ptr is not NULL:

			errCode = slurm.slurm_load_partitions(self._Partition_ptr.last_update, &new_Partition_ptr, self._ShowFlags)
			if errCode == 0: # SLURM_SUCCESS
				slurm.slurm_free_partition_info_msg(self._Partition_ptr)
			elif slurm.slurm_get_errno() == 1900: # SLURM_NO_CHANGE_IN_DATA
				errCode = 0
				new_Partition_ptr = self._Partition_ptr
		else:
			errCode = slurm.slurm_load_partitions(last_time, &new_Partition_ptr, self._ShowFlags)

		if errCode == 0:
			self._Partition_ptr = new_Partition_ptr
			self._lastUpdate = self._Partition_ptr.last_update
		else:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		return errCode

	cpdef print_info_msg(self, int oneLiner=False):

		u"""Display the partition information from previous load partition method.

		:param int oneLiner: Display on one line (default=0)
		"""

		if self._Partition_ptr is not NULL:
			slurm.slurm_print_partition_info_msg(slurm.stdout, self._Partition_ptr, oneLiner)

	cpdef int delete(self, char *PartID='') except? -1:

		u"""Delete a give slurm partition.

		:param string PartID: Name of slurm partition

		:returns: 0 for success else set the slurm error code as appropriately.
		:rtype: `int`
		"""

		cdef:
			slurm.delete_part_msg_t part_msg
			int apiError = 0, errCode = -1

		if PartID is not None:
			part_msg.name = PartID
			errCode = slurm.slurm_delete_partition(&part_msg)
			if errCode != 0:
				apiError = slurm.slurm_get_errno()
				raise ValueError(slurm.slurm_strerror(apiError), apiError)

		return errCode

	cpdef get(self):

		u"""Get the slurm partition data from a previous load partition method.

		:returns: Partition data, key is the partition ID
		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return  self._PartDict

	cpdef dict __get(self):

		u"""Get the slurm partition data from a previous load partition method.
		"""

		cdef:
			int i = 0
			unsigned int preempt_mode
			dict Partition = {}
			dict Part_dict = {}

		if self._Partition_ptr is not NULL:

			self._lastUpdate = self._Partition_ptr.last_update
			for i from 0 <= i < self._Partition_ptr.record_count:

				Part_dict = {}
				self._record = self._Partition_ptr.partition_array[i]
				name = self._record.name

				Part_dict[u'allow_accounts'] = slurm.listOrNone(self._record.allow_accounts, ',')
				Part_dict[u'allow_alloc_nodes'] = slurm.listOrNone(self._record.allow_alloc_nodes, ',')
				Part_dict[u'allow_groups'] = slurm.listOrNone(self._record.allow_groups, ',')
				Part_dict[u'allow_qos'] = slurm.listOrNone(self._record.allow_qos, ',')
				Part_dict[u'alternate'] = slurm.stringOrNone(self._record.alternate, '')
				Part_dict[u'billing_wights_str'] = slurm.stringOrNone(self._record.billing_weights_str, '')
				Part_dict[u'cr_type'] = self._record.cr_type
				Part_dict[u'def_mem_per_cpu'] = self._record.def_mem_per_cpu
				Part_dict[u'default_time'] = __convertDefaultTime(self._record.default_time)
				Part_dict[u'deny_accounts'] = slurm.listOrNone(self._record.deny_accounts, '')
				Part_dict[u'deny_qos'] = slurm.listOrNone(self._record.deny_qos, '')

				Part_dict[u'flags'] = get_partition_mode(self._record.flags)
				Part_dict[u'grace_time'] = self._record.grace_time
				Part_dict[u'max_cpus_per_node'] = self._record.max_cpus_per_node
				Part_dict[u'max_mem_per_cpu'] = self._record.max_mem_per_cpu
				Part_dict[u'max_nodes'] = self._record.max_nodes
				Part_dict[u'max_share'] = self._record.max_share
				Part_dict[u'max_time'] = self._record.max_time
				Part_dict[u'min_nodes'] = self._record.min_nodes
				Part_dict[u'name'] = slurm.stringOrNone(self._record.name, '')
				Part_dict[u'nodes'] = slurm.listOrNone(self._record.nodes, ',')

				#preempt_mode = self._record.preempt_mode
				#if ( preempt_mode == <unsigned int>NO_VAL ):
				#	preempt_mode = slurm.slurm_get_preempt_mode()	# use cluster param
				#preempt_mode = slurm.slurm_get_preempt_mode()
				#Part_dict[u'preempt_mode'] = get_preempt_mode(preempt_mode)

				Part_dict[u'preempt_mode'] = slurm.slurm_preempt_mode_string(self._record.preempt_mode)

				Part_dict[u'priority'] = self._record.priority
				Part_dict[u'qos_char'] = slurm.stringOrNone(self._record.qos_char, '')
				Part_dict[u'state_up'] = get_partition_state(self._record.state_up)
				Part_dict[u'total_cpus'] = self._record.total_cpus
				Part_dict[u'total_nodes'] = self._record.total_nodes
				Part_dict[u'tres_fmt_str'] = slurm.stringOrNone(self._record.tres_fmt_str, '')

				Partition[u"%s" % name] = Part_dict

		self._PartDict = Partition

	cpdef int update(self, dict Partition_dict = {}):

		u"""Update a slurm partition.

		:param dict partition_dict: A populated partition dictionary, an empty one is created by create_partition_dict

		:returns: 0 for success, -1 for error, and the slurm error code is set appropriately.
		:rtype: `int`
		"""

		cdef int errCode = slurm_update_partition(Partition_dict)

		return errCode

	cpdef int create(self, dict Partition_dict = {}):

		u"""Create a slurm partition.

		:param dict partition_dict: A populated partition dictionary, an empty one can be created by create_partition_dict

		:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
		:rtype: `int`
		"""

		cdef int errCode = slurm_create_partition(Partition_dict)

		return errCode

def create_partition_dict():

	u"""Returns a dictionary that can be populated by the user
	and used for the update_partition and create_partition calls.

	:returns: Empty reservation dictionary
	:rtype: `dict`
	"""

	return {
		u'Alternate': u'',
		u'Name': u'',
		u'MaxTime': -1,
		u'DefaultTime': -1,
		u'MaxNodes': -1,
		u'MinNodes': -1,
		u'Default': 0,
		u'Hidden': 0,
		u'RootOnly': 0,
		u'Shared': 0,
		u'Priority': -1,
		u'State': 0,
		u'Nodes': u'',
		u'AllowGroups': u'',
		u'AllocNodes': u''
		}

cpdef int slurm_create_partition(dict partition_dict={}):

	u"""Create a slurm partition.

	:param dict partition_dict: A populated partition dictionary, an empty one is created by create_partition_dict

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `int`
	"""

	cdef:
		slurm.update_part_msg_t part_msg_ptr
		int int_value = 0
		int errCode = 0
		unsigned int uint32_value
		unsigned int time_value

	slurm.slurm_init_part_desc_msg(&part_msg_ptr)

	if partition_dict[u'Name'] is not '':
		part_msg_ptr.name = partition_dict[u'Name']

	if  partition_dict[u'DefaultTime'] != -1:
		int_value = partition_dict[u'DefaultTime']
		part_msg_ptr.default_time = int_value

	if partition_dict[u'MaxNodes'] != -1:
		int_value = partition_dict[u'MaxNodes']
		part_msg_ptr.max_nodes = int_value

	if partition_dict[u'MinNodes'] != -1:
		int_value = partition_dict[u'MinNodes']
		part_msg_ptr.min_nodes = int_value

	errCode = slurm.slurm_create_partition(&part_msg_ptr)

	return errCode

cpdef int slurm_update_partition(dict partition_dict={}):

	u"""Update a slurm partition.

	:param dict partition_dict: A populated partition dictionary, an empty one is created by create_partition_dict

	:returns: 0 for success, -1 for error, and the slurm error code is set appropriately.
	:rtype: `integer`
	"""

	cdef:
		slurm.update_part_msg_t part_msg_ptr
		unsigned int uint32_value
		unsigned int time_value
		int int_value = 0
		int errCode = 0
		char* name

	slurm.slurm_init_part_desc_msg(&part_msg_ptr)

	if partition_dict[u'Name'] is not '':
		part_msg_ptr.name = partition_dict[u'Name']

	if partition_dict[u'Alternate'] is not '':
		part_msg_ptr.alternate = partition_dict[u'Alternate']

	int_value = partition_dict[u'MaxTime']
	part_msg_ptr.max_time = int_value

	int_value = partition_dict[u'DefaultTime']
	part_msg_ptr.default_time = int_value

	if partition_dict[u'MaxNodes'] != -1:
		int_value = partition_dict[u'MaxNodes']
		part_msg_ptr.max_nodes = int_value

	if partition_dict[u'MinNodes'] != -1:
		int_value = partition_dict[u'MinNodes']
		part_msg_ptr.min_nodes = int_value

	pystring = partition_dict['State']
	if pystring is not '':
		if pystring == u'DOWN':
			part_msg_ptr.state_up = 0x01      # PARTITION_DOWN (PARTITION_SUBMIT 0x01)
		elif pystring == u'UP':
			part_msg_ptr.state_up = 0x01|0x0  # PARTITION_UP (PARTITION_SUBMIT|PARTITION_SCHED)
		elif pystring == u'DRAIN':
			part_msg_ptr.state_up = 0x02      # PARTITION_DRAIN (PARTITION_SCHED=0x02)
		else:
			errCode = -1

	if partition_dict[u'Nodes'] is not '':
		part_msg_ptr.nodes = partition_dict[u'Nodes']

	if partition_dict[u'AllowGroups'] is not '':
		part_msg_ptr.allow_groups = partition_dict[u'AllowGroups']

	if partition_dict[u'AllocNodes'] is not '':
		part_msg_ptr.allow_alloc_nodes = partition_dict[u'AllocNodes']

	errCode = slurm.slurm_update_partition(&part_msg_ptr)

	return errCode

cpdef int slurm_delete_partition(char* PartID) except? -1:

	u"""Delete a slurm partition.

	:param string PartID: Name of slurm partition

	:returns: 0 for success else set the slurm error code as appropriately.
	:rtype: `integer`
	"""

	cdef:
		slurm.delete_part_msg_t part_msg
		int apiError = 0, errCode = -1

	if PartID is not None:
		part_msg.name = PartID
		errCode = slurm.slurm_delete_partition(&part_msg)
		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

#
# Slurm Ping/Reconfig/Shutdown functions
#

cpdef int slurm_ping(int Controller=1) except? -1:

	u"""Issue RPC to check if slurmctld is responsive.

	:param int Controller: 1 for primary (Default=1), 2 for backup

	:returns: 0 for success or slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_ping(Controller)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_reconfigure() except? -1:

	u"""Issue RPC to have slurmctld reload its configuration file.

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_reconfigure()

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_shutdown(uint16_t Options=0) except? -1:

	u"""Issue RPC to have slurmctld cease operations, both the primary and backup controller are shutdown.

	:param int Options:

		0 - All slurm daemons (default)
		1 - slurmctld generates a core file
		2 - slurmctld is shutdown (no core file)

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_shutdown(Options)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_takeover() except? -1:

	u"""Issue a RPC to have slurmctld backup controller take over the primary controller.

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_takeover()

	return errCode

cpdef int slurm_set_debug_level(uint32_t DebugLevel=0) except? -1:

	u"""Set the slurm controller debug level.

	:param int DebugLevel: 0 (default) to 6

	:returns: 0 for success, -1 for error and set slurm error number
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_set_debug_level(DebugLevel)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_set_debugflags(uint32_t debug_flags_plus=0, uint32_t debug_flags_minus=0) except? -1:

	u"""Set the slurm controller debug flags.

	:param int debug_flags_plus: debug flags to be added
	:param int debug_flags_minus: debug flags to be removed

	:returns: 0 for success, -1 for error and set slurm error number
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_set_debugflags(debug_flags_plus, debug_flags_minus)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_set_schedlog_level(uint32_t Enable=0) except? -1:

	u"""Set the slurm scheduler debug level.

	:param int Enable: True = 0, False = 1

	:returns: 0 for success, -1 for error and set the slurm error number
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_set_schedlog_level(Enable)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

#
# Slurm Job Suspend Functions
#

cpdef int slurm_suspend(uint32_t JobID=0) except? -1:

	u"""Suspend a running slurm job.

	:param int JobID: Job identifier

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_suspend(JobID)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_resume(uint32_t JobID=0) except? -1:

	u"""Resume a running slurm job step.

	:param int JobID: Job identifier

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_resume(JobID)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_requeue(uint32_t JobID=0, uint32_t State=0) except? -1:

	u"""Requeue a running slurm job step.

	:param int JobID: Job identifier

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_requeue(JobID, State)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef long slurm_get_rem_time(uint32_t JobID=0) except? -1:

	u"""Get the remaining time in seconds for a slurm job step.

	:param int JobID: Job identifier

	:returns: Remaining time in seconds or -1 on error
	:rtype: `long`
	"""

	cdef int apiError = 0
	cdef long errCode = slurm.slurm_get_rem_time(JobID)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef time_t slurm_get_end_time(uint32_t JobID=0) except? -1:

	u"""Get the end time in seconds for a slurm job step.

	:param int JobID: Job identifier

	:returns: Remaining time in seconds or -1 on error
	:rtype: `integer`
	"""

	cdef time_t EndTime = -1
	cdef int apiError = 0
	cdef int errCode = slurm.slurm_get_end_time(JobID, &EndTime)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return EndTime

cpdef int slurm_job_node_ready(uint32_t JobID=0) except? -1:

	u"""Return if a node could run a slurm job now if despatched.

	:param int JobID: Job identifier

	:returns: Node Ready code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_job_node_ready(JobID)

	return errCode

cpdef int slurm_signal_job(uint32_t JobID=0, uint16_t Signal=0) except? -1:

	u"""Send a signal to a slurm job step.

	:param int JobID: Job identifier
	:param int Signal: Signal to send (default=0)

	:returns: 0 for success or -1 for error and the set Slurm errno
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_signal_job(JobID, Signal)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

#
# Slurm Job/Step Signaling Functions
#

cpdef int slurm_signal_job_step(uint32_t JobID=0, uint32_t JobStep=0, uint16_t Signal=0) except? -1:

	u"""Send a signal to a slurm job step.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int Signal: Signal to send (default=0)

	:returns: Error code - 0 for success or -1 for error and set the slurm errno
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_signal_job_step(JobID, JobStep, Signal)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_kill_job(uint32_t JobID=0, uint16_t Signal=0, uint16_t BatchFlag=0) except? -1:

	u"""Terminate a running slurm job step.

	:param int JobID: Job identifier
	:param int Signal: Signal to send
	:param int BatchFlag: Job batch flag (default=0)

	:returns: 0 for success or -1 for error and set slurm errno
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_kill_job(JobID, Signal, BatchFlag)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_kill_job_step(uint32_t JobID=0, uint32_t JobStep=0, uint16_t Signal=0) except? -1:

	u"""Terminate a running slurm job step.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int Signal: Signal to send (default=0)

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_kill_job_step(JobID, JobStep, Signal)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_complete_job(uint32_t JobID=0, uint32_t JobCode=0) except? -1:

	u"""Complete a running slurm job step.

	:param int JobID: Job identifier
	:param int JobCode: Return code (default=0)

	:returns: 0 for success or -1 for error and set slurm errno
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_complete_job(JobID, JobCode)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_notify_job(uint32_t JobID=0, char* Msg='') except? -1:

	u"""Notify a message to a running slurm job step.

	:param string JobID: Job identifier (default=0)
	:param string Msg: Message string to send to job

	:returns: 0 for success or -1 on error
	:rtype: `integer`

	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_notify_job(JobID, Msg)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_terminate_job_step(uint32_t JobID=0, uint32_t JobStep=0) except? -1:

	u"""Terminate a running slurm job step.

	:param int JobID: Job identifier (default=0)
	:param int JobStep: Job step identifier (default=0)

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_terminate_job_step(JobID, JobStep)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

#
# Slurm Checkpoint functions
#

cpdef time_t slurm_checkpoint_able(uint32_t JobID=0, uint32_t JobStep=0) except? -1:

	u"""Report if checkpoint operations can presently be issued for the specified slurm job step.

	If yes, returns SLURM_SUCCESS and sets start_time if checkpoint operation is presently active. Returns ESLURM_DISABLED if checkpoint operation is disabled.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int StartTime: Checkpoint start time

	:returns: Time of checkpoint
	:rtype: `integer`
	"""

	cdef time_t Time = 0
	cdef int apiError = 0
	cdef int errCode = slurm.slurm_checkpoint_able(JobID, JobStep, &Time)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return Time

cpdef int slurm_checkpoint_enable(uint32_t JobID=0, uint32_t JobStep=0) except? -1:

	u"""Enable checkpoint requests for a given slurm job step.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_checkpoint_enable(JobID, JobStep)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_checkpoint_disable(uint32_t JobID=0, uint32_t JobStep=0) except? -1:

	u"""Disable checkpoint requests for a given slurm job step.

	This can be issued as needed to prevent checkpointing while a job step is in a critical section or for other reasons.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_checkpoint_disable(JobID, JobStep)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_checkpoint_create(uint32_t JobID=0, uint32_t JobStep=0, uint16_t MaxWait=60, char* ImageDir='') except? -1:

	u"""Request a checkpoint for the identified slurm job step and continue its execution upon completion of the checkpoint.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int MaxWait: Maximum time to wait
	:param string ImageDir: Directory to write checkpoint files

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_checkpoint_create(JobID, JobStep, MaxWait, ImageDir)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_checkpoint_requeue(uint32_t JobID=0, uint16_t MaxWait=60, char* ImageDir='') except? -1:

	u"""Initiate a checkpoint request for identified slurm job step, the job will be requeued after the checkpoint operation completes.

	:param int JobID: Job identifier
	:param int MaxWait: Maximum time in seconds to wait for operation to complete
	:param string ImageDir: Directory to write checkpoint files

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_checkpoint_requeue(JobID, MaxWait, ImageDir)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_checkpoint_vacate(uint32_t JobID=0, uint32_t JobStep=0, uint16_t MaxWait=60, char* ImageDir='') except? -1:

	u"""Request a checkpoint for the identified slurm Job Step. Terminate its execution upon completion of the checkpoint.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int MaxWait: Maximum time to wait
	:param string ImageDir: Directory to store checkpoint files

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm_checkpoint_vacate(JobID, JobStep, MaxWait, ImageDir)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_checkpoint_restart(uint32_t JobID=0, uint32_t JobStep=0, uint16_t Stick=0, char* ImageDir='') except? -1:

	u"""Request that a previously checkpointed slurm job resume execution.

	It may continue execution on different nodes than were originally used. Execution may be delayed if resources are not immediately available.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int Stick: Stick to nodes previously running om
	:param string ImageDir: Directory to find checkpoint image files

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_checkpoint_restart(JobID, JobStep, Stick, ImageDir)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_checkpoint_complete(uint32_t JobID=0, uint32_t JobStep=0, time_t BeginTime=0, uint32_t ErrorCode=0, char* ErrMsg='') except? -1:

	u"""Note that a requested checkpoint has been completed.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int BeginTime: Begin time of checkpoint
	:param int ErrorCode: Error code, highest value fore all complete calls is preserved 
	:param string ErrMsg: Error message, preserved for highest error code

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_checkpoint_complete(JobID, JobStep, BeginTime, ErrorCode, ErrMsg)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_checkpoint_task_complete(uint32_t JobID=0, uint32_t JobStep=0, uint32_t TaskID=0, time_t BeginTime=0, uint32_t ErrorCode=0, char* ErrMsg='') except? -1:

	u"""Note that a requested checkpoint has been completed.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int TaskID: Task identifier
	:param int BeginTime: Begin time of checkpoint
	:param int ErrorCode: Error code, highest value fore all complete calls is preserved 
	:param string ErrMsg: Error message, preserved for highest error code

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_checkpoint_task_complete(JobID, JobStep, TaskID, BeginTime, ErrorCode, ErrMsg)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

#
# Slurm Job Checkpoint Functions
#

def slurm_checkpoint_error(uint32_t JobID=0, uint32_t JobStep=0):

	u"""Get error information about the last checkpoint operation for a given slurm job step.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	:returns: Slurm error message and error string
	:rtype: `string`
	"""

	cdef:
		uint32_t ErrorCode = 0
		char* Msg = NULL
		int errCode = slurm.slurm_checkpoint_error(JobID, JobStep, &ErrorCode, &Msg)

	error_string = None
	if errCode != 0:
		error_string = u'%d:%s' % (ErrorCode, Msg)
		free(Msg)

	return errCode, error_string

cpdef int slurm_checkpoint_tasks(uint32_t JobID=0, uint16_t JobStep=0, uint16_t MaxWait=60, char* NodeList='') except? -1:

	u"""Send checkpoint request to tasks of specified slurm job step.

	:param int JobID: Job identifier
	:param int JobStep: Job step identifier
	:param int MaxWait: Seconds to wait for the operation to complete
	:param string NodeList: String of nodelist

	:returns: 0 for success, non zero on failure and with errno set
	:rtype: `integer`
	"""

	cdef:
		slurm.time_t BeginTime = <slurm.time_t>NULL
		char* ImageDir = NULL
		int apiError = 0
		int errCode = slurm.slurm_checkpoint_tasks(JobID, JobStep, BeginTime, ImageDir, MaxWait, NodeList)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

#
# Slurm Job Class to Control Configuration Read/Update
#

cdef class job:

	u"""Class to access/modify Slurm Job Information. 
	"""

	cdef:
		slurm.job_info_msg_t *_job_ptr
		slurm.slurm_job_info_t _record
		slurm.time_t _lastUpdate
	
		uint16_t _ShowFlags
		dict _JobDict

	def __cinit__(self):
		self._job_ptr = NULL
		self._lastUpdate = 0
		# SHOW_DETAIL flag notably make slurm allocate and fill
		# (job_resources_t *)job_resrcs structure member of
		# slurm_job_info_t, with all resources details of the job.
		self._ShowFlags = SHOW_DETAIL
		self._JobDict = {}

		self.get()


	def __dealloc__(self):
		self.__destroy()

	cpdef __destroy(self):

		u"""Free the slurm job memory allocated by load partition method. 
		"""

		if self._job_ptr is not NULL:
			slurm.slurm_free_job_info_msg(self._job_ptr)

	def lastUpdate(self):

		u"""Get the time (epoch seconds) the job data was updated.

		:returns: epoch seconds
		:rtype: `integer`
		"""

		return self._lastUpdate

	def ids(self):

		u"""Return the job IDs from retrieved data.

		:returns: Dictionary of job IDs
		:rtype: `dict`
		"""

		return self._JobDict.keys()

	def find_id(self, int jobID):

		u"""Retrieve job ID data.

		:param int jobID: Job id key string to search
		:returns: Dictionary of values for given job id
		:rtype: `dict`
		"""

		return self._JobDict.get(jobID, {})

	def find(self, char *name='', val=''):

		u"""Search for a property and associated value in the retrieved job data.

		:param str name: key string to search
		:param str value: value string to match
		:returns: List of IDs that match
		:rtype: `list`
		"""

		cdef list retList = []

		if val != '':

			for key, value in self._JobDict.items():

				if self._JobDict[key][name] == val:
					retList.append(key)

		return retList

	def load(self):

		u"""Load slurm job information.
		"""

		self.__load()

	cpdef int __load(self) except? -1:

		u"""Load slurm job information.

		:returns: error Code
		:rtype: `integer`
		"""

		cdef:
			slurm.job_info_msg_t *new_job_ptr = NULL
			slurm.time_t last_time = <slurm.time_t>NULL
			int apiError = 0
			int errCode = -1

		if self._job_ptr is not NULL:
			errCode = slurm.slurm_load_jobs(self._job_ptr.last_update, &new_job_ptr, self._ShowFlags)
			if errCode == 0:
				slurm.slurm_free_job_info_msg(self._job_ptr)
			elif slurm.slurm_get_errno() == 1900:
				errCode = 0
				new_job_ptr = self._job_ptr
		else:
			last_time = <time_t>NULL
			new_job_ptr = NULL
			errCode = slurm.slurm_load_jobs(last_time, &new_job_ptr, self._ShowFlags)

		if errCode == 0:
			self._job_ptr = new_job_ptr
			self._lastUpdate = self._job_ptr.last_update
		else:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

	def get(self):

		u"""Get the slurm job information.

		:returns: Data where key is the job name, each entry contains a dictionary of job attributes
		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return self._JobDict

	cpdef __get(self):

		u"""Get the slurm job information.

		:returns: Data where key is the job name, each entry contains a dictionary of job attributes
		:rtype: `dict`
		"""

		cdef:
			int i = 0
			int retval
			uint16_t retval16

			dict Jobs = {}
			dict Job_dict = {}

		if self._job_ptr is not NULL:

			for i from 0 <= i < self._job_ptr.record_count:

				self._record = self._job_ptr.job_array[i]
				job_id = self._job_ptr.job_array[i].job_id

				Job_dict = {}

				Job_dict[u'account'] = slurm.stringOrNone(self._job_ptr.job_array[i].account, '')
				Job_dict[u'alloc_node'] = slurm.stringOrNone(self._job_ptr.job_array[i].alloc_node, '')
				Job_dict[u'alloc_sid'] = self._job_ptr.job_array[i].alloc_sid
				Job_dict[u'array_job_id'] = self._job_ptr.job_array[i].array_job_id
				Job_dict[u'array_task_id'] = self._job_ptr.job_array[i].array_task_id
				Job_dict[u'array_max_tasks'] = self._job_ptr.job_array[i].array_max_tasks
				Job_dict[u'array_task_str'] = slurm.stringOrNone(self._job_ptr.job_array[i].array_task_str, '')
				Job_dict[u'assoc_id'] = self._job_ptr.job_array[i].assoc_id
				Job_dict[u'batch_flag'] = self._job_ptr.job_array[i].batch_flag
				Job_dict[u'batch_host'] = slurm.stringOrNone(self._job_ptr.job_array[i].batch_host, '')
				Job_dict[u'batch_script'] = slurm.stringOrNone(self._job_ptr.job_array[i].batch_script, '')
				Job_dict[u'bitflags'] = self._job_ptr.job_array[i].bitflags
				Job_dict[u'boards_per_node'] = self._job_ptr.job_array[i].boards_per_node
				Job_dict[u'burst_buffer'] = slurm.stringOrNone(self._job_ptr.job_array[i].burst_buffer, '')
				Job_dict[u'command'] = slurm.stringOrNone(self._job_ptr.job_array[i].command, '')
				Job_dict[u'comment'] = slurm.stringOrNone(self._job_ptr.job_array[i].comment, '')
				Job_dict[u'contiguous'] = bool(self._job_ptr.job_array[i].contiguous)
				Job_dict[u'core_spec'] = self._job_ptr.job_array[i].core_spec
				Job_dict[u'cores_per_socket'] = self._job_ptr.job_array[i].cores_per_socket
				Job_dict[u'billable_tres'] = self._job_ptr.job_array[i].billable_tres
				Job_dict[u'cpus_per_task'] = self._job_ptr.job_array[i].cpus_per_task
				Job_dict[u'cpu_freq_min'] = self._job_ptr.job_array[i].cpu_freq_min
				Job_dict[u'cpu_freq_max'] = self._job_ptr.job_array[i].cpu_freq_max
				Job_dict[u'cpu_freq_gov'] = self._job_ptr.job_array[i].cpu_freq_gov
				Job_dict[u'dependency'] = slurm.stringOrNone(self._job_ptr.job_array[i].dependency, '')
				Job_dict[u'derived_ec'] = self._job_ptr.job_array[i].derived_ec
				Job_dict[u'eligible_time'] = self._job_ptr.job_array[i].eligible_time
				Job_dict[u'end_time'] = self._job_ptr.job_array[i].end_time
				Job_dict[u'exc_nodes'] = slurm.listOrNone(self._job_ptr.job_array[i].exc_nodes, ',')
				Job_dict[u'exit_code'] = self._job_ptr.job_array[i].exit_code
				Job_dict[u'features'] = slurm.listOrNone(self._job_ptr.job_array[i].features, ',')
				Job_dict[u'gres'] = slurm.listOrNone(self._job_ptr.job_array[i].gres, ',')
				Job_dict[u'group_id'] = self._job_ptr.job_array[i].group_id

				# JOB RESOURCES HERE

				#Job_dict[u'job_state'] = get_job_state(self._job_ptr.job_array[i].job_state)
				Job_dict[u'job_state'] = slurm.slurm_job_state_string(self._job_ptr.job_array[i].job_state)
				Job_dict[u'licenses'] = __get_licenses(self._job_ptr.job_array[i].licenses)
				Job_dict[u'max_cpus'] = self._job_ptr.job_array[i].max_cpus
				Job_dict[u'max_nodes'] = self._job_ptr.job_array[i].max_nodes
				Job_dict[u'name'] = slurm.stringOrNone(self._job_ptr.job_array[i].name, '')
				Job_dict[u'network'] = slurm.stringOrNone(self._job_ptr.job_array[i].network, '')
				Job_dict[u'nodes'] = slurm.stringOrNone(self._job_ptr.job_array[i].nodes, '')
				Job_dict[u'nice'] = self._job_ptr.job_array[i].nice

				#if self._job_ptr.job_array[i].node_inx[0] != -1:
				#	for x from 0 <= x < self._job_ptr.job_array[i].num_nodes

				Job_dict[u'ntasks_per_core'] = self._job_ptr.job_array[i].ntasks_per_core
				Job_dict[u'ntasks_per_node'] = self._job_ptr.job_array[i].ntasks_per_node
				Job_dict[u'ntasks_per_socket'] = self._job_ptr.job_array[i].ntasks_per_socket
				Job_dict[u'ntasks_per_board'] = self._job_ptr.job_array[i].ntasks_per_board
				Job_dict[u'num_nodes'] = self._job_ptr.job_array[i].num_nodes
				Job_dict[u'num_cpus'] = self._job_ptr.job_array[i].num_cpus
				Job_dict[u'partition'] = self._job_ptr.job_array[i].partition
				Job_dict[u'pn_min_memory'] = self._job_ptr.job_array[i].pn_min_memory
				Job_dict[u'pn_min_cpus'] = self._job_ptr.job_array[i].pn_min_cpus
				Job_dict[u'pn_min_tmp_disk'] = self._job_ptr.job_array[i].pn_min_tmp_disk
				Job_dict[u'power_flags'] = self._job_ptr.job_array[i].power_flags
				Job_dict[u'preempt_time'] = self._job_ptr.job_array[i].preempt_time
				Job_dict[u'pre_sus_time'] = self._job_ptr.job_array[i].pre_sus_time
				Job_dict[u'priority'] = self._job_ptr.job_array[i].priority
				Job_dict[u'profile'] = self._job_ptr.job_array[i].profile
				Job_dict[u'qos'] = slurm.stringOrNone(self._job_ptr.job_array[i].qos, '')
				Job_dict[u'reboot'] = self.__get_select_jobinfo(SELECT_JOBDATA_REBOOT)
				Job_dict[u'req_nodes'] = slurm.listOrNone(self._job_ptr.job_array[i].req_nodes, ',')
				Job_dict[u'req_switch'] = self._job_ptr.job_array[i].req_switch
				Job_dict[u'requeue'] = bool(self._job_ptr.job_array[i].requeue)
				Job_dict[u'resize_time'] = self._job_ptr.job_array[i].resize_time
				Job_dict[u'restart_cnt'] = self._job_ptr.job_array[i].restart_cnt
				Job_dict[u'resv_name'] = slurm.stringOrNone(self._job_ptr.job_array[i].resv_name, '')

				Job_dict[u'sockets_per_board'] = self._job_ptr.job_array[i].sockets_per_board
				Job_dict[u'sockets_per_node'] = self._job_ptr.job_array[i].sockets_per_node
				Job_dict[u'shared'] = self._job_ptr.job_array[i].shared
				Job_dict[u'show_flags'] = self._job_ptr.job_array[i].show_flags
				Job_dict[u'sicp_mode'] = self._job_ptr.job_array[i].sicp_mode
				Job_dict[u'start_time'] = self._job_ptr.job_array[i].start_time
				Job_dict[u'state_desc'] = slurm.stringOrNone(self._job_ptr.job_array[i].state_desc, '')
				#Job_dict[u'state_reason'] = get_job_state_reason(self._job_ptr.job_array[i].state_reason)
				Job_dict[u'state_reason'] = slurm.slurm_job_reason_string(self._job_ptr.job_array[i].state_reason)
				Job_dict[u'std_err'] = slurm.stringOrNone(self._job_ptr.job_array[i].std_err, '')
				Job_dict[u'std_in'] = slurm.stringOrNone(self._job_ptr.job_array[i].std_in, '')
				Job_dict[u'std_out'] = slurm.stringOrNone(self._job_ptr.job_array[i].std_out, '')
				Job_dict[u'submit_time'] = self._job_ptr.job_array[i].submit_time
				Job_dict[u'suspend_time'] = self._job_ptr.job_array[i].suspend_time
				Job_dict[u'time_limit'] = self._job_ptr.job_array[i].time_limit
				Job_dict[u'time_min'] = self._job_ptr.job_array[i].time_min
				Job_dict[u'threads_per_core'] = self._job_ptr.job_array[i].threads_per_core
				Job_dict[u'tres_req_str'] = slurm.stringOrNone(self._job_ptr.job_array[i].tres_req_str, '')
				Job_dict[u'tres_alloc_str'] = slurm.stringOrNone(self._job_ptr.job_array[i].tres_alloc_str, '')
				Job_dict[u'user_id'] = self._job_ptr.job_array[i].user_id
				Job_dict[u'wait4switch'] = self._job_ptr.job_array[i].wait4switch
				Job_dict[u'wckey'] = slurm.stringOrNone(self._job_ptr.job_array[i].wckey, '')
				Job_dict[u'work_dir'] = slurm.stringOrNone(self._job_ptr.job_array[i].work_dir, '')

				Job_dict[u'ionodes'] = self.__get_select_jobinfo(SELECT_JOBDATA_IONODES)
				Job_dict[u'block_id'] = self.__get_select_jobinfo(SELECT_JOBDATA_BLOCK_ID)
				Job_dict[u'blrts_image'] = self.__get_select_jobinfo(SELECT_JOBDATA_BLRTS_IMAGE)
				Job_dict[u'linux_image'] = self.__get_select_jobinfo(SELECT_JOBDATA_LINUX_IMAGE)
				Job_dict[u'mloader_image'] = self.__get_select_jobinfo(SELECT_JOBDATA_MLOADER_IMAGE)
				Job_dict[u'ramdisk_image'] = self.__get_select_jobinfo(SELECT_JOBDATA_RAMDISK_IMAGE)
				Job_dict[u'cnode_cnt'] = self.__get_select_jobinfo(SELECT_JOBDATA_NODE_CNT)
				Job_dict[u'resv_id'] = self.__get_select_jobinfo(SELECT_JOBDATA_RESV_ID)
				Job_dict[u'rotate'] = bool(self.__get_select_jobinfo(SELECT_JOBDATA_ROTATE))
				#Job_dict[u'conn_type'] = get_conn_type_string(self.__get_select_jobinfo(SELECT_JOBDATA_CONN_TYPE))
				Job_dict[u'conn_type'] = slurm.slurm_conn_type_string(self.__get_select_jobinfo(SELECT_JOBDATA_CONN_TYPE))
				Job_dict[u'altered'] = self.__get_select_jobinfo(SELECT_JOBDATA_ALTERED)

				Job_dict[u'cpus_allocated'] = {}
				if self._record.nodes is not NULL:
					hl = hostlist()
					hl.create(self._record.nodes)
					for node_name in hl.get_list():
						Job_dict[u'cpus_allocated'][node_name] = self.__cpus_allocated_on_node(node_name)

				Jobs[job_id] = Job_dict

		self._JobDict = Jobs

	cpdef __get_select_jobinfo(self, uint32_t dataType):

		u"""Decode opaque data type jobinfo

		INCOMPLETE PORT 
		"""

		cdef:
			slurm.dynamic_plugin_data_t *jobinfo = <slurm.dynamic_plugin_data_t*>self._record.select_jobinfo
			slurm.select_jobinfo_t *tmp_ptr
			int retval = 0
			uint16_t retval16 = 0
			uint32_t retval32 = 0
			char *retvalStr = NULL
			char *str
			char *tmp_str

			dict Job_dict = {}

		if jobinfo is NULL:
			return None

		if dataType == SELECT_JOBDATA_GEOMETRY: # Int array[SYSTEM_DIMENSIONS]
			pass

		if dataType == SELECT_JOBDATA_ROTATE or dataType == SELECT_JOBDATA_CONN_TYPE or dataType == SELECT_JOBDATA_ALTERED \
			or dataType == SELECT_JOBDATA_REBOOT:

			retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &retval16)
			if retval == 0:
				return retval16

		if dataType == SELECT_JOBDATA_NODE_CNT or dataType == SELECT_JOBDATA_RESV_ID:
			
			retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &retval32)
			if retval == 0:
				return retval32

		if dataType == SELECT_JOBDATA_BLOCK_ID or dataType == SELECT_JOBDATA_NODES \
			or dataType == SELECT_JOBDATA_IONODES or dataType == SELECT_JOBDATA_BLRTS_IMAGE \
			or dataType == SELECT_JOBDATA_LINUX_IMAGE or dataType == SELECT_JOBDATA_MLOADER_IMAGE \
			or dataType == SELECT_JOBDATA_RAMDISK_IMAGE or dataType == SELECT_JOBDATA_USER_NAME:
		
			# data-> char* needs to be freed with xfree

			retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &tmp_str)
			if retval == 0:
				if tmp_str != NULL:
					retvalStr = strcpy(<char *>slurm.xmalloc(strlen(tmp_str)+1), tmp_str)
					slurm.xfree(tmp_str)
					return retvalStr
				else:
					return ''

		if dataType == SELECT_JOBDATA_PTR: # data-> select_jobinfo_t *jobinfo
			retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &tmp_ptr)
			if retval == 0:
				# populate a dictonary ?
				pass

		return None

	cpdef int __cpus_allocated_on_node_id(self, int nodeID=0):

		u"""Get the number of cpus allocated to a slurm job on a node by node name.

		:param int nodeID: Numerical node ID
		:returns: Num of CPUs allocated to job on this node or -1 on error
		:rtype: `integer`
		"""

		cdef:
			slurm.job_resources_t *job_resrcs_ptr = <slurm.job_resources_t *>self._record.job_resrcs
			int retval = slurm.slurm_job_cpus_allocated_on_node_id(job_resrcs_ptr, nodeID)

		return retval

	cpdef int __cpus_allocated_on_node(self, char* nodeName=''):

		u"""Get the number of cpus allocated to a slurm job on a node by node name.

		:param string nodeName: Name of node
		:returns: Num of CPUs allocated to job on this node or -1 on error
		:rtype: `integer`
		"""

		cdef:
			slurm.job_resources_t *job_resrcs_ptr = <slurm.job_resources_t *>self._record.job_resrcs
			int retval = slurm.slurm_job_cpus_allocated_on_node(job_resrcs_ptr, nodeName)

		return retval

	cpdef __free(self):

		u"""Release the storage generated by the slurm_get_job_steps function.
		"""

		if self._job_ptr is not NULL:
			slurm.slurm_free_job_info_msg(self._job_ptr)

	def print_job_info_msg(self, int oneLiner=0):

		u"""Prints the contents of the data structure describing all job step records loaded by the slurm_get_job_steps function.

		:param int Flag: Default=0
		"""

		if self._job_ptr is not NULL:
			slurm.slurm_print_job_info_msg(slurm.stdout, self._job_ptr, oneLiner)

def slurm_pid2jobid(uint32_t JobPID=0):

	u"""Get the slurm job id from a process id.

	:param int JobPID: Job process id

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	:returns: Job Identifier
	:rtype: `integer`
	"""

	cdef:
		uint32_t JobID = 0
		int apiError = 0
		int errCode = slurm.slurm_pid2jobid(JobPID, &JobID)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode, JobID

#
# Slurm Error Class
#

class SlurmError(Exception):

	def __init__(self, value):
		self.value = value

	def __str__(self):
		return repr(slurm.slurm_strerror(self.value))

#
# Slurm Error Functions
#

def slurm_get_errno():

	u"""Return the slurm error as set by a slurm API call.

	:returns: slurm error number
	:rtype: `integer`
	"""

	cdef int errNum = slurm.slurm_get_errno()

	return errNum

def slurm_strerror(int Errno=0):

	u"""Return slurm error message represented by a given slurm error number.

	:param int Errno: slurm error number.

	:returns: slurm error string
	:rtype: `string`
	"""

	cdef char* errMsg = slurm.slurm_strerror(Errno)

	return u"%s" % errMsg

def slurm_seterrno(int Errno=0):

	u"""Set the slurm error number.

	:param int Errno: slurm error number
	"""

	slurm.slurm_seterrno(Errno)

def slurm_perror(char* Msg=''):

	u"""Print to standard error the supplied header followed by a colon followed  by a text description of the last Slurm error code generated.

	:param string Msg: slurm program error String
	"""

	slurm.slurm_perror(Msg)

#
# Slurm Node Read/Print/Update Class 
#

cdef class node:

	u"""Class to access/modify/update Slurm Node Information.
	"""

	cdef:
		slurm.node_info_msg_t *_Node_ptr
		slurm.node_info_t _record
		slurm.time_t _lastUpdate
		uint16_t _ShowFlags
		dict _NodeDict

	def __cinit__(self):
		self._Node_ptr = NULL
		self._lastUpdate = 0
		self._ShowFlags = 0
		self._NodeDict = {}

	def __dealloc__(self):
		self.__destroy()

	cpdef __destroy(self):

		u"""Free the memory allocated by load node method. 
		"""

		if self._Node_ptr is not NULL:
			slurm.slurm_free_node_info_msg(self._Node_ptr)

	def lastUpdate(self):

		u"""Return last time (sepoch seconds) the node data was updated.

		:returns: epoch seconds
		:rtype: `integer`
		"""

		return self._lastUpdate

	def ids(self):

		u"""Return the node IDs from retrieved data.

		:returns: Dictionary of node IDs
		:rtype: `dict`
		"""

		return self._NodeDict.keys()

	def find_id(self, NodeID=''):

		u"""Retrieve node ID data.

		:param str nodeID: Node key string to search
		:returns: Dictionary of values for given node
		:rtype: `dict`
		"""

		cdef char *nodeID = NodeID
		return self._NodeDict.get(nodeID, {})

	def load(self):

		u"""Load slurm node data. 
		"""

		self.__load()

	cpdef int __load(self) except? -1:

		u"""Load node data method.

		:returns: Error value
		:rtype: `integer`
		"""

		cdef:
			slurm.node_info_msg_t *new_node_info_ptr = NULL
			slurm.time_t last_time = <slurm.time_t>NULL
			int apiError = 0, errCode = 0

		if self._Node_ptr is not NULL:

			errCode = slurm.slurm_load_node(self._Node_ptr.last_update, &new_node_info_ptr, self._ShowFlags)
			if errCode == 0:	# SLURM_SUCCESS
				slurm.slurm_free_node_info_msg(self._Node_ptr)
			elif slurm.slurm_get_errno() == 1900:	# SLURM_NO_CHANGE_IN_DATA
				errCode = 0
				new_node_info_ptr = self._Node_ptr
		else:
			last_time = <time_t>NULL
			errCode = slurm.slurm_load_node(last_time, &new_node_info_ptr, self._ShowFlags)

		if errCode == 0:
			self._Node_ptr = new_node_info_ptr
			self._lastUpdate = self._Node_ptr.last_update
		else:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		return errCode

	cpdef update(self, dict node_dict={}):

		u"""Update slurm node information.

		:param dict node_dict: A populated node dictionary, an empty one is created by create_node_dict

		:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
		:rtype: `integer`
		"""

		return slurm_update_node(node_dict)

	cpdef print_node_info_msg(self, int oneLiner=False):

		u"""Output information about all slurm nodes.

		:param int oneLiner: Print on one line - False (Default) or True
		"""

		if self._Node_ptr is not NULL:
			slurm.slurm_print_node_info_msg(slurm.stdout, self._Node_ptr, oneLiner)

	cpdef get(self):

		u"""Get slurm node information.

		:returns: Data whose key is the node name.
		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return self._NodeDict

	cpdef __get(self):

		cdef:
			slurm.node_info_t *node_ptr
			slurm.select_nodeinfo_t *select_node_ptr

			char *cloud_str = ""
			char *comp_str = ""
			char *drain_str = ""
			char *power_str = ""
			int i, total_used, cpus_per_node, rc
			uint16_t alloc_cpus, err_cpus
			uint32_t tmp_disk, node_state, node_scaling = 0
			uint32_t my_state
			#unit32_t cluster_flags = slurmdb_setup_cluster_flags()
			uint32_t currentWatts = 0
			time_t last_update

			dict Hosts = {}, Host_dict

		if self._Node_ptr is NULL:
			return Hosts

		node_scaling = self._Node_ptr.node_scaling
		last_update  = self._Node_ptr.last_update

		for i from 0 <= i < self._Node_ptr.record_count:

			self._record = self._Node_ptr.node_array[i]

			if self._record.name is NULL:
				break

			Host_dict = {}
			alloc_cpus = err_cpus = 0
			cpus_per_node = 1

			total_used = self._Node_ptr.node_array[i].cpus
			if (node_scaling):
				cpus_per_node = total_used / node_scaling

			name = self._Node_ptr.node_array[i].name

			Host_dict['arch'] = slurm.stringOrNone(self._Node_ptr.node_array[i].arch, '')
			Host_dict['boards'] = self._Node_ptr.node_array[i].boards
			Host_dict['boot_time'] = self._Node_ptr.node_array[i].boot_time
			Host_dict['cores'] = self._Node_ptr.node_array[i].cores
			Host_dict['core_spec_cnt'] = self._Node_ptr.node_array[i].core_spec_cnt
			Host_dict['cpus'] = self._Node_ptr.node_array[i].cpus
			Host_dict['cpu_load'] = self._Node_ptr.node_array[i].cpu_load
			Host_dict['cpu_spec_list'] = slurm.listOrNone(self._Node_ptr.node_array[i].features, '')
			Host_dict['features'] = slurm.listOrNone(self._Node_ptr.node_array[i].features, '')
			Host_dict['free_mem'] = self._Node_ptr.node_array[i].free_mem
			Host_dict['gres'] = slurm.listOrNone(self._Node_ptr.node_array[i].gres, '')
			Host_dict['gres_drain'] = slurm.listOrNone(self._Node_ptr.node_array[i].gres_drain, '')
			Host_dict['gres_used'] = slurm.listOrNone(self._Node_ptr.node_array[i].gres_used, '')
			Host_dict['mem_spec_limit'] = self._Node_ptr.node_array[i].mem_spec_limit
			Host_dict['name'] = slurm.stringOrNone(self._Node_ptr.node_array[i].name, '')
			Host_dict['node_addr'] = slurm.stringOrNone(self._Node_ptr.node_array[i].node_addr, '')
			Host_dict['node_hostname'] = slurm.stringOrNone(self._Node_ptr.node_array[i].node_hostname, '')
			Host_dict['os'] = slurm.stringOrNone(self._Node_ptr.node_array[i].os, '')
			Host_dict['owner'] = self._Node_ptr.node_array[i].owner
			Host_dict['real_memory'] = self._Node_ptr.node_array[i].real_memory
			Host_dict['reason'] = slurm.stringOrNone(self._Node_ptr.node_array[i].reason, '')
			Host_dict['reason_time'] = self._Node_ptr.node_array[i].reason_time
			Host_dict['reason_uid'] = self._Node_ptr.node_array[i].reason_uid
			Host_dict['slurmd_start_time'] = self._Node_ptr.node_array[i].slurmd_start_time
			Host_dict['sockets'] = self._Node_ptr.node_array[i].sockets
			Host_dict['threads'] = self._Node_ptr.node_array[i].threads
			Host_dict['tmp_disk'] = self._Node_ptr.node_array[i].tmp_disk
			Host_dict['weight'] = self._Node_ptr.node_array[i].weight
			Host_dict['tres_fmt_str'] = slurm.stringOrNone(self._Node_ptr.node_array[i].tres_fmt_str, '')
			Host_dict['version'] = slurm.stringOrNone(self._Node_ptr.node_array[i].version, '')

			# Energy statistics

			Host_dict['energy'] = {}
			Host_dict['energy']['base_watts'] = self._Node_ptr.node_array[i].energy.base_watts

			currentWatts = self._Node_ptr.node_array[i].energy.current_watts
			if currentWatts == NO_VAL:
				Host_dict['energy']['current_watts'] = 0
			else:
				Host_dict['energy']['current_watts'] = currentWatts

			Host_dict['energy']['consumed_energy'] = self._Node_ptr.node_array[i].energy.consumed_energy
			Host_dict['energy']['base_consumed_energy'] = self._Node_ptr.node_array[i].energy.base_consumed_energy
			Host_dict['energy']['previous_consumed_energy'] = self._Node_ptr.node_array[i].energy.previous_consumed_energy

			# Power Managment

			Host_dict['power_mgmt'] = {}

			# Enhanced node state - src/api/node_info.c

			node_state = self._Node_ptr.node_array[i].node_state
			my_state = node_state

			if (my_state & NODE_STATE_CLOUD):
				my_state &= (~NODE_STATE_CLOUD)
				cloud_str = "+CLOUD"

			if (my_state & NODE_STATE_COMPLETING):
				my_state &= (~NODE_STATE_COMPLETING)
				comp_str = "+COMPLETING"

			if (my_state & NODE_STATE_DRAIN):
				my_state &= (~NODE_STATE_DRAIN)
				drain_str = "+DRAIN"
			
			if (my_state & NODE_STATE_FAIL):
				my_state &= (~NODE_STATE_FAIL)
				drain_str = "+FAIL"

			if (my_state & NODE_STATE_POWER_SAVE):
				my_state &= (~NODE_STATE_POWER_SAVE)
				power_str = "+POWER"

			if self._Node_ptr.node_array[i].select_nodeinfo is not NULL:

				rc, alloc_cpus = self.__get_select_nodeinfo(SELECT_NODEDATA_SUBCNT, NODE_STATE_ALLOCATED)
				#if (cluster_flags & CLUSTER_FLAG_BG):
					#if not alloc_cpus and (IS_NODE_ALLOCATED(node_state) or IS_NODE_COMPLETING(node_state)):
					#	alloc_cpus = Host_dict['cpus']
					#else:
					#	alloc_cpus *= cpus_per_node
				total_used -= alloc_cpus

				rc, err_cpus = self.__get_select_nodeinfo(SELECT_NODEDATA_SUBCNT, NODE_STATE_ERROR)
				#if (cluster_flags & CLUSTER_FLAG_BG):
				#	err_cpus *= cpus_per_node
				total_used -= err_cpus

				if ((alloc_cpus and err_cpus) or (total_used and (total_used != self._Node_ptr.node_array[i].cpus))):
					my_state &= NODE_STATE_FLAGS
					my_state |= NODE_STATE_MIXED

			state_str = "%s%s%s%s%s" % (get_node_state(my_state), cloud_str, comp_str, drain_str, power_str)
			Host_dict['state'] = state_str
			Host_dict['err_cpus'] = err_cpus
			Host_dict['alloc_cpus'] = alloc_cpus
			Host_dict['total_cpus'] = total_used

			Hosts[u'%s' % name] = Host_dict

		self._NodeDict = Hosts

	#/*
	# * slurm_get_select_nodeinfo - get data from a select node credential
	# * IN nodeinfo  - updated select node credential
	# * IN data_type - type of data to enter into node credential
	# * IN state     - state of node query
	# * IN/OUT data  - the data to enter into node credential
	# * RET 0 or -1 on error
	# */
	#extern int slurm_get_select_nodeinfo PARAMS(
	#	(dynamic_plugin_data_t *nodeinfo, enum select_nodedata_type data_type,
	#	 enum node_states state, void *data));

	#	SELECT_NODEDATA_BITMAP_SIZE,	/* data-> uint16_t */
	#	SELECT_NODEDATA_SUBGRP_SIZE,	/* data-> uint16_t */
	#	SELECT_NODEDATA_SUBCNT,		/* data-> uint16_t */
	#	SELECT_NODEDATA_BITMAP,		/* data-> bitstr_t * needs to be
	#					* freed with FREE_NULL_BITMAP */
	#	SELECT_NODEDATA_STR,		/* data-> char *  needs to be
	#					* freed with xfree */
	#	SELECT_NODEDATA_PTR,		/* data-> select_nodeinfo_t *nodeinfo */
	#	SELECT_NODEDATA_EXTRA_INFO,	/* data-> char *  needs to be
	#					* freed with xfree */
	#	SELECT_NODEDATA_RACK_MP		/* data-> char * needs to be
	#					* freed with xfree */

	cpdef __get_select_nodeinfo(self, uint32_t dataType, uint32_t State):

		u"""
			A WORK IN PROGRESS
		"""

		cdef:
			slurm.dynamic_plugin_data_t *nodeinfo = <slurm.dynamic_plugin_data_t*>self._record.select_nodeinfo
			slurm.select_nodeinfo_t *tmp_ptr
			slurm.bitstr_t *tmp_bitmap = NULL

			int retval = 0, length = 0
			uint16_t retval16 = 0
			char *retvalStr
			char *tmp_str

			dict Host_dict = {}

		if dataType == SELECT_NODEDATA_SUBCNT or dataType == SELECT_NODEDATA_SUBGRP_SIZE or dataType == SELECT_NODEDATA_BITMAP_SIZE:

			retval = slurm.slurm_get_select_nodeinfo(nodeinfo, dataType, State, &retval16)
			if retval == 0:
				return retval, retval16

		if dataType == SELECT_NODEDATA_BITMAP:

			# data-> bitstr_t * needs to be freed with FREE_NULL_BITMAP

			#retval = slurm.slurm_get_select_nodeinfo(nodeinfo, dataType, State, &tmp_bitmap)
			#if retval == 0:
			#	Host_dict['bitstr'] = tmp_bitmap
			return retval, None

		elif dataType == SELECT_NODEDATA_STR:

			retval = slurm.slurm_get_select_nodeinfo(nodeinfo, dataType, State, &tmp_str)
			if retval == 0:
				retvalStr = strcpy(<char *>slurm.xmalloc(strlen(tmp_str)+1), tmp_str)
				slurm.xfree(tmp_str)
				return retval, retvalStr

		if dataType == SELECT_NODEDATA_PTR:
			retval = slurm.slurm_get_select_nodeinfo(nodeinfo, dataType, State, &tmp_ptr)
			if retval == 0:
				# opaque data as dict 
				pass

		return retval, None

def slurm_update_node(dict node_dict={}):

	u"""Update slurm node information.

	:param dict node_dict: A populated node dictionary, an empty one is created by create_node_dict

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `integer`
	"""

	cdef:
		slurm.update_node_msg_t node_msg
		int apiError = 0
		int errCode = 0

	if node_dict is {}:
		return -1

	slurm.slurm_init_update_node_msg(&node_msg)

	if 'node_state' in node_dict:
		node_msg.node_state = <uint16_t>node_dict['node_state']

	if 'features' in node_dict:
		node_msg.features = node_dict['features']

	if 'gres' in node_dict:
		node_msg.gres = node_dict['gres']

	if 'node_names' in node_dict:
		node_msg.node_names = node_dict['node_names']

	if 'reason' in node_dict:
		node_msg.reason = node_dict['reason']
		node_msg.reason_uid = <uint32_t>os.getuid()

	if 'weight' in node_dict:
		node_msg.weight = <uint32_t>node_dict['weight']

	errCode = slurm.slurm_update_node(&node_msg)
	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

def create_node_dict():

	u"""Returns a dictionary that can be populated by the user
	and used for the update_node call.

	:returns: Empty node dictionary
	:rtype: `dict`
	"""

	return {
		'node_names': '',
		'gres': '',
		'reason': '',
		'node_state': -1,
		'weight': -1,
		'features': ''
		}

#
# Jobstep Class
#

cdef class jobstep:

	u"""Class to access/modify Slurm Jobstep Information.
	"""

	cdef:
		slurm.time_t _lastUpdate
		uint32_t JobID, StepID
		uint16_t _ShowFlags
		dict _JobStepDict

	def __cinit__(self):
		self._ShowFlags = 0
		self._lastUpdate = 0
		self.JobID = 4294967294    # 0xfffffffe - NOVAL
		self.StepID = 4294967294   # 0xfffffffe - NOVAL
		self._JobStepDict = {}

	def __dealloc__(self):
		self.__destroy()

	cpdef __destroy(self):

		u"""Free the slurm job memory allocated by load jobstep method. 
		"""

		self._lastUpdate = 0
		self._ShowFlags = 0
		self._JobStepDict = {}

	def lastUpdate(self):

		u"""Get the time (epoch seconds) the jobstep data was updated.

		:returns: epoch seconds
		:rtype: `integer`
		"""

		return self._lastUpdate

	def ids(self):

		cdef dict jobsteps = {}

		for key, value in self._JobStepDict.items():
			for new_key in value.keys():
				jobsteps.setdefault(key, []).append(new_key)

		return jobsteps

	def find(self, jobID=-1, stepID=-1):

		cdef dict retDict = {}

		#retlist = [ key for key, value in self.blockID.items() if self.blockID[key][name] == value ]

		for key, value in self._JobStepDict.items():
			if self._JobStepDict[key][u'name'] == value:
				retDict.append(key)

		return retDict

	cpdef get(self):

		u"""Get slurm jobstep information.

		:returns: Data whose key is the jobstep ID.
		:rtype: `dict`
		"""

		self.__get()

		return self._JobStepDict

	cpdef __get(self):

		u"""Loads into details about job steps that satisfy the job_id 
		and/or step_id specifications provided if the data has been 
		updated since the update_time specified.

		:param int JobID: Job Identifier
		:param int StepID: Jobstep Identifier
		:param int ShowFlags: Display flags (Default=0)

		:returns: Data whose key is the job and step ID
		:rtype: `dict`
		"""

		cdef:
			slurm.job_step_info_response_msg_t *job_step_info_ptr = NULL

			slurm.time_t last_time = 0
			dict Steps = {}
			dict StepDict = {}
			uint16_t ShowFlags = self._ShowFlags ^ SHOW_ALL
			int i = 0
			int errCode = slurm.slurm_get_job_steps(last_time, self.JobID, self.StepID, &job_step_info_ptr, ShowFlags)

		if errCode != 0:
			self._JobStepDict = {}
			return

		if job_step_info_ptr is not NULL:

			for i from 0 <= i < job_step_info_ptr.job_step_count:

				job_id = job_step_info_ptr.job_steps[i].job_id
				step_id = job_step_info_ptr.job_steps[i].step_id

				Steps[job_id] = {}
				Step_dict = {}
				Step_dict[u'array_job_id'] = job_step_info_ptr.job_steps[i].array_job_id
				Step_dict[u'array_task_id'] = job_step_info_ptr.job_steps[i].array_task_id
				Step_dict[u'ckpt_dir'] = job_step_info_ptr.job_steps[i].ckpt_dir
				Step_dict[u'ckpt_interval'] = job_step_info_ptr.job_steps[i].ckpt_interval
				Step_dict[u'gres'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].gres, '')
				Step_dict[u'name'] = job_step_info_ptr.job_steps[i].name
				Step_dict[u'network'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].network, '')
				Step_dict[u'nodes'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].nodes, '')
				Step_dict[u'num_cpus'] = job_step_info_ptr.job_steps[i].num_cpus
				Step_dict[u'num_tasks'] = job_step_info_ptr.job_steps[i].num_tasks
				Step_dict[u'partition'] = job_step_info_ptr.job_steps[i].partition
				Step_dict[u'resv_ports'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].resv_ports, '')
				Step_dict[u'run_time'] = job_step_info_ptr.job_steps[i].run_time
				Step_dict[u'start_time'] = job_step_info_ptr.job_steps[i].start_time
				Step_dict[u'state'] = slurm.slurm_job_state_string(job_step_info_ptr.job_steps[i].state)
				Step_dict[u'time_limit'] = job_step_info_ptr.job_steps[i].time_limit
				Step_dict[u'user_id'] = job_step_info_ptr.job_steps[i].user_id

				Steps[job_id][step_id] = Step_dict

			slurm.slurm_free_job_step_info_response_msg(job_step_info_ptr)

		self._JobStepDict = Steps

	cpdef layout(self, uint32_t JobID=0, uint32_t StepID=0):

		u"""Get the slurm job step layout from a given job and step id.

		:param int JobID: slurm job id (Default=0)
		:param int StepID: slurm step id (Default=0)

		:returns: List of job step layout.
		:rtype: `list`
		"""

		return self.__layout(JobID, StepID)

	cpdef __layout(self, uint32_t JobID, uint32_t StepID):

		cdef:
			slurm.slurm_step_layout_t *old_job_step_ptr 
			int i = 0, j = 0, Node_cnt = 0

			dict Layout = {}
			list Nodes = [], Node_list = [], Tids_list = []

		old_job_step_ptr = slurm.slurm_job_step_layout_get(JobID, StepID)

		if old_job_step_ptr is not NULL:

			Node_cnt  = old_job_step_ptr.node_cnt

			Layout[u'front_end'] = slurm.stringOrNone(old_job_step_ptr.front_end, '')
			Layout[u'node_cnt'] = Node_cnt
			Layout[u'node_list'] = old_job_step_ptr.node_list
			Layout[u'plane_size'] = old_job_step_ptr.plane_size
			Layout[u'task_cnt'] = old_job_step_ptr.task_cnt
			Layout[u'task_dist'] = old_job_step_ptr.task_dist

			Nodes = Layout[u'node_list'].split(',')
			for i from 0 <= i < Node_cnt:

				Tids_list = []
				for j from 0 <= j < old_job_step_ptr.tasks[i]:

					Tids_list.append(old_job_step_ptr.tids[i][j])

				Node_list.append( [Nodes[i], Tids_list] )
			
			Layout[u'tasks'] = Node_list

			slurm.slurm_job_step_layout_free(old_job_step_ptr)

		return Layout

#
# Hostlist Class
#

cdef class hostlist:

	u"""Wrapper class for Slurm hostlist functions.
	"""

	cdef slurm.hostlist_t hl

	def __cinit__(self):
		self.hl = NULL

	def __dealloc__(self):
		self.destroy()

	def destroy(self):

		if self.hl is not NULL:
			slurm.slurm_hostlist_destroy(self.hl)
			self.hl = NULL

	cpdef int count(self):

		cdef int errCode = -1
		if self.hl is not NULL:
			errCode = slurm.slurm_hostlist_count(self.hl)
		return errCode

	cpdef int create(self, char* HostList=''):

		# convert python byte string to C char
		if self.hl is not NULL:
			self.destroy()

		if HostList is not NULL:
			self.hl = slurm.slurm_hostlist_create(HostList)
			if self.hl is not NULL:
				return True
		return False

	cpdef get(self):
		return self.__get()

	cpdef get_list(self):
		u"""Get the list of hostnames composing the hostlist. For example
		with a hostlist created with "tux[1-3]" -> [ 'tux1', tux2', 'tux3' ].

		:returns: the list of hostnames in case of success or None on error.
		:rtype: list
		"""

		cdef:
			char *hostlist_s = NULL

		host_list = None

		if self.hl is not NULL:
			# make a copy of self.hl since slurm.slurm_hostlist_shift() is
			# destructive.
			hostlist_s = slurm.slurm_hostlist_ranged_string_xmalloc(self.hl)
			if hostlist_s is not NULL:
				hl = slurm.slurm_hostlist_create(hostlist_s)
				host_list = []
				nb_hosts = slurm.slurm_hostlist_count(hl)
				for host_id in range(nb_hosts):
					host_list.append(slurm.slurm_hostlist_shift(hl))
				slurm.xfree(hostlist_s)
				slurm.slurm_hostlist_destroy(hl)

		return host_list


	cpdef __get(self):

		cdef:
			char *hostlist = NULL
			char *tmp_str = NULL

		range_str = None
		if self.hl is not NULL:
			tmp_str = slurm.slurm_hostlist_ranged_string_xmalloc(self.hl)
			if tmp_str is not NULL:
				hostlist = <char *>malloc(strlen(tmp_str) + 1)
				strcpy(hostlist, tmp_str)
				slurm.xfree(tmp_str)
				range_str = hostlist
				hostlist = NULL

		return range_str

	cpdef int find(self, char* Host):

		# convert python byte string to C char
		cdef int errCode = -1
		if self.hl is not NULL:
			if Host is not NULL:
				errCode = slurm.slurm_hostlist_find(self.hl, Host)
		return errCode

	cpdef pop(self):

		# convert C char to python byte string
		cdef char *host = ''
		if self.hl is not NULL:
			host = slurm.slurm_hostlist_shift(self.hl)
		return host

	cpdef int push(self, char *Hosts):

		# convert python byte string to C char
		cdef int errCode = -1
		if self.hl is not NULL:
			if Hosts is not NULL:
				errCode = slurm.slurm_hostlist_push_host(self.hl, Hosts)
		return errCode

	cpdef uniq(self):

		if self.hl is not NULL:
			slurm.slurm_hostlist_uniq(self.hl)

#
# Trigger Get/Set/Update Class
#

cdef class trigger:

	cpdef int set(self, dict trigger_dict={}):

		u"""Set or create a slurm trigger.

		:param dict trigger_dict: A populated dictionary of trigger information

		:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
		:rtype: `integer`
		"""

		cdef:
			slurm.trigger_info_t trigger_set
			char tmp_c[128]
			char *JobId
			int  errCode = -1

		memset(&trigger_set, 0, sizeof(slurm.trigger_info_t))

		trigger_set.user_id = 0

		if 'jobid' in trigger_dict:

			JobId = trigger_dict[u'jobid']
			trigger_set.res_type = TRIGGER_RES_TYPE_JOB #1
			memcpy(tmp_c, JobId, 128)
			trigger_set.res_id = tmp_c

			if 'fini' in trigger_dict:
				trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_FINI #0x0010
			if 'offset' in trigger_dict:
				trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_TIME #0x0008

		elif 'node' in trigger_dict:

			trigger_set.res_type = TRIGGER_RES_TYPE_NODE #TRIGGER_RES_TYPE_NODE
			if trigger_dict[u'node'] == '':
				trigger_set.res_id = '*'
			else:
				trigger_set.res_id = trigger_dict[u'node']
			
		trigger_set.offset = 32768
		if 'offset' in trigger_dict:
			trigger_set.offset = trigger_set.offset + trigger_dict[u'offset']

		trigger_set.program = trigger_dict[u'program']

		event = trigger_dict[u'event']
		if event == 'block_err':
			trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_BLOCK_ERR #0x0040

		if event == 'drained':
			trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_DRAINED   #0x0100

		if event == 'down':
			trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_DOWN      #0x0002

		if event == 'fail':
			trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_FAIL      #0x0004

		if event == 'up':
			trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_UP        #0x0001

		if event == 'idle':
			trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_IDLE      #0x0080

		if event == 'reconfig':
			trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_RECONFIG  #0x0020
		
		while slurm.slurm_set_trigger(&trigger_set):

			slurm.slurm_perror('slurm_set_trigger')
			# EAGAIN
			if slurm.slurm_get_errno() != 11:
				errCode = slurm.slurm_get_errno()
				return errCode

			time.sleep(5)

		return 0

	cpdef get(self):

		u"""Get the information on slurm triggers.

		:returns: Where key is the trigger ID
		:rtype: `dict`
		"""

		cdef:
			slurm.trigger_info_msg_t *trigger_get = NULL
			int i = 0
			int errCode = slurm.slurm_get_triggers(&trigger_get)

			dict Triggers = {}, Trigger_dict

		if errCode == 0:

			for i from 0 <= i < trigger_get.record_count:

				trigger_id = trigger_get.trigger_array[i].trig_id

				Trigger_dict = {}
				Trigger_dict[u'flags'] = trigger_get.trigger_array[i].flags
				Trigger_dict[u'trig_id'] = trigger_get.trigger_array[i].trig_id
				Trigger_dict[u'res_type'] = trigger_get.trigger_array[i].res_type
				Trigger_dict[u'res_id'] = slurm.stringOrNone(trigger_get.trigger_array[i].res_id, '')
				Trigger_dict[u'trig_type'] = trigger_get.trigger_array[i].trig_type
				Trigger_dict[u'offset'] = trigger_get.trigger_array[i].offset-0x8000
				Trigger_dict[u'user_id'] = trigger_get.trigger_array[i].user_id
				Trigger_dict[u'program'] = slurm.stringOrNone(trigger_get.trigger_array[i].program, '')

				Triggers[trigger_id] = Trigger_dict

			slurm.slurm_free_trigger_msg(trigger_get)

		return Triggers

	cpdef int clear(self, uint32_t TriggerID=-1, uint32_t UserID=-1, char* ID='') except? -1:

		u"""Clear or remove a slurm trigger.

		:param string TriggerID: Trigger Identifier
		:param string UserID: User Identifier
		:param string ID: Job Identifier

		:returns: 0 for success or a slurm error code
		:rtype: `integer`
		"""

		cdef:
			slurm.trigger_info_t trigger_clear
			char tmp_c[128]
			int apiError = 0
			int errCode = 0

		memset(&trigger_clear, 0, sizeof(slurm.trigger_info_t))

		if TriggerID != -1:
			trigger_clear.trig_id = TriggerID
		if UserID != -1:
			trigger_clear.user_id = UserID

		if ID:
			trigger_clear.res_type = TRIGGER_RES_TYPE_JOB  #1 
			memcpy(tmp_c, ID, 128)
			trigger_clear.res_id = tmp_c

		errCode = slurm.slurm_clear_trigger(&trigger_clear)
		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		return errCode

	cpdef int pull(self, uint32_t TriggerID, uint32_t UserID, char* ID) except? -1:

		u"""Pull a slurm trigger.

		:param int TriggerID: Trigger Identifier
		:param int UserID: User Identifier
		:param string ID: Job Identifier

		:returns: 0 for success or a slurm error code
		:rtype: `integer`
		"""

		cdef:
			slurm.trigger_info_t trigger_pull
			char tmp_c[128]
			int apiError = 0
			int errCode = 0

		memset(&trigger_pull, 0, sizeof(slurm.trigger_info_t))

		trigger_pull.trig_id = TriggerID 
		trigger_pull.user_id = UserID

		if ID:
			trigger_pull.res_type = TRIGGER_RES_TYPE_JOB #1
			memcpy(tmp_c, ID, 128)
			trigger_pull.res_id = tmp_c

		errCode = slurm.slurm_pull_trigger(&trigger_pull)
		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		return errCode

#
# Reservation Class
#

cdef class reservation:

	u"""Class to access/update/delete slurm reservation Information. 
	"""

	cdef:
		slurm.reserve_info_msg_t *_Res_ptr
		slurm.time_t _lastUpdate
		uint16_t _ShowFlags
		dict _ResDict

	def __cinit__(self):
		self._Res_ptr = NULL
		self._lastUpdate = 0
		self._ShowFlags = 0
		self._ResDict = {}

	def __dealloc__(self):
		self.__free()

	def lastUpdate(self):

		u"""Get the time (epoch seconds) the reservation data was updated.

		:returns: epoch seconds
		:rtype: `integer`
		"""

		return self._lastUpdate

	def ids(self):

		u"""Return a list of reservation IDs from retrieved data.

		:returns: Dictionary of reservation IDs
		:rtype: `dict`
		"""

		return self._ResDict.keys()

	def find_id(self, char *resID=''):

		u"""Retrieve reservation ID data.

		:param str resID: Reservation key string to search
		:returns: Dictionary of values for given reservation key
		:rtype: `dict`
		"""

		return self._ResDict.get(resID, {})

	def find(self, char *name='', val=''):

		u"""Search for a property and associated value in the retrieved reservation data

		:param str name: key string to search
		:param str value: value string to match
		:returns: List of IDs that match
		:rtype: `list`
		"""

		# [ key for key, value in self._ResDict.items() if self._ResDict[key]['state'] == 'error']
		cdef list retList = []

		if val != '':
			for key, value in self._ResDict.items():
				if self._ResDict[key][name] == val:
					retList.append(key)
		return retList

	def load(self):
		self.__load()

	cpdef int __load(self) except? -1:

		u"""Load slurm reservation information.
		"""

		cdef:
			slurm.reserve_info_msg_t *new_reserve_info_ptr = NULL
			slurm.time_t last_time = <slurm.time_t>NULL
			int apiError = 0, errCode = 0

		if self._Res_ptr is not NULL:

			errCode = slurm.slurm_load_reservations(self._Res_ptr.last_update, &new_reserve_info_ptr)
			if errCode == 0: # SLURM_SUCCESS
				slurm.slurm_free_reservation_info_msg(self._Res_ptr)
			elif slurm.slurm_get_errno() == 1900:	# SLURM_NO_CHANGE_IN_DATA
				errCode = 0
				new_reserve_info_ptr = self._Res_ptr
		else:
			last_time = <time_t>NULL
			errCode = slurm.slurm_load_reservations(last_time, &new_reserve_info_ptr)

		if errCode == 0:
			self._Res_ptr = new_reserve_info_ptr
			self._lastUpdate = self._Res_ptr.last_update
		else:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		return errCode

	cpdef __free(self):

		u"""Free slurm reservation pointer.
		"""

		if self._Res_ptr is not NULL:
			slurm.slurm_free_reservation_info_msg(self._Res_ptr)

	def get(self):

		u"""Get slurm reservation information.

		:returns: Data whose key is the Reservation ID
		:rtype: `dict`
		"""

		self.load()
		self.__get()

		return self._ResDict

	cpdef __get(self):

		cdef:
			int i
			dict Reservations = {}
			dict Res_dict

		if self._Res_ptr is not NULL:

			for i from 0 <= i < self._Res_ptr.record_count:

				Res_dict = {}

				name = self._Res_ptr.reservation_array[i].name
				Res_dict[u'accounts'] = slurm.listOrNone(self._Res_ptr.reservation_array[i].accounts, ',')
				Res_dict[u'burst_buffer'] = slurm.listOrNone(self._Res_ptr.reservation_array[i].burst_buffer, ',')
				Res_dict[u'core_cnt'] = self._Res_ptr.reservation_array[i].core_cnt
				Res_dict[u'end_time'] = self._Res_ptr.reservation_array[i].end_time
				Res_dict[u'features'] = slurm.listOrNone(self._Res_ptr.reservation_array[i].features, ',')
				Res_dict[u'flags'] = slurm.slurm_reservation_flags_string(self._Res_ptr.reservation_array[i].flags)
				Res_dict[u'licenses'] = __get_licenses(self._Res_ptr.reservation_array[i].licenses)
				Res_dict[u'node_cnt'] = self._Res_ptr.reservation_array[i].node_cnt
				Res_dict[u'node_list'] = slurm.stringOrNone(self._Res_ptr.reservation_array[i].node_list, ',')
				Res_dict[u'partition'] = slurm.stringOrNone(self._Res_ptr.reservation_array[i].partition, '')
				Res_dict[u'start_time'] = self._Res_ptr.reservation_array[i].start_time
				Res_dict[u'resv_watts'] = self._Res_ptr.reservation_array[i].resv_watts
				Res_dict[u'tres_str'] = slurm.stringOrNone(self._Res_ptr.reservation_array[i].tres_str, '')
				Res_dict[u'users'] = slurm.listOrNone(self._Res_ptr.reservation_array[i].users, ',')

				Reservations[name] = Res_dict

		self._ResDict = Reservations

	def create(self, dict reservation_dict={}):

		u"""Create slurm reservation.
		"""

		return slurm_create_reservation(reservation_dict)


	def delete(self, char *ResID=''):

		u"""Delete slurm reservation.

		:returns: 0 for success or a slurm error code
		:rtype: `integer`
		"""

		return slurm_delete_reservation(ResID)

	def update(self, dict reservation_dict={}):

		u"""Update a slurm reservation attributes.

		:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
		:rtype: `integer`
		"""

		return slurm_update_reservation(reservation_dict)

	def print_reservation_info_msg(self, int oneLiner=False):

		u"""Output information about all slurm reservations.

		:param int Flags: Print on one line - False (Default) or True
		"""

		if self._Res_ptr is not NULL:
			slurm.slurm_print_reservation_info_msg(slurm.stdout, self._Res_ptr, oneLiner)

#
# Reservation Helper Functions
#

def slurm_create_reservation(dict reservation_dict={}):

	u"""Create a slurm reservation.

	:param dict reservation_dict: A populated reservation dictionary, an empty one is created by create_reservation_dict

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `int`
	"""

	cdef:
		slurm.resv_desc_msg_t resv_msg
		char *resid = NULL
		char *name = NULL
		int int_value = 0
		int free_users = 0
		int free_accounts = 0
		unsigned int uint32_value
		unsigned int time_value

	slurm.slurm_init_resv_desc_msg(&resv_msg)

	time_value = reservation_dict[u'start_time']
	resv_msg.start_time = time_value

	uint32_value = reservation_dict[u'duration']
	resv_msg.duration = uint32_value

	if reservation_dict[u'node_cnt'] != -1:
		int_value = reservation_dict[u'node_cnt']
		resv_msg.node_cnt = <uint32_t*>slurm.xmalloc(sizeof(uint32_t) * 2)
		resv_msg.node_cnt[0] = int_value
		resv_msg.node_cnt[1] = 0

	if reservation_dict[u'users'] is not '':
		name = reservation_dict[u'users']
		resv_msg.users = strcpy(<char*>slurm.xmalloc(strlen(name)+1), name)
		free_users = 1

	if reservation_dict[u'accounts'] is not '':
		name = reservation_dict[u'accounts']
		resv_msg.accounts = strcpy(<char*>slurm.xmalloc(strlen(name)+1), name)
		free_accounts = 1

	if reservation_dict[u'licenses'] is not '':
		name = reservation_dict[u'licenses']
		resv_msg.licenses = name

	if reservation_dict[u'flags'] is not '':
		int_value = reservation_dict[u'flags']
		resv_msg.flags = int_value

	if reservation_dict[u'name'] is not '':
		name = reservation_dict[u'name']
		resv_msg.name = name

	resid = slurm.slurm_create_reservation(&resv_msg)

	if free_users == 1:
		slurm.xfree(resv_msg.users)
	if free_accounts == 1:
		slurm.xfree(resv_msg.accounts)

	resID = ''
	if resid is not NULL:
		resID = resid
		free(resid)
	else:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return u"%s" % resID

def slurm_update_reservation(dict reservation_dict={}):

	u"""Update a slurm reservation.

	:param dict reservation_dict: A populated reservation dictionary, an empty one is created by create_reservation_dict

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `integer`
	"""

	cdef:
		slurm.resv_desc_msg_t resv_msg
		char* name = NULL
		int free_users = 0, free_accounts = 0, errCode = 0
		uint32_t uint32_value
		slurm.time_t time_value

	slurm.slurm_init_resv_desc_msg(&resv_msg)

	time_value = reservation_dict[u'start_time']
	if time_value != -1:
		resv_msg.start_time = time_value

	uint32_value = reservation_dict[u'duration']
	if uint32_value != -1:
		resv_msg.duration = uint32_value

	if reservation_dict[u'name'] is not '':
		resv_msg.name = reservation_dict[u'name']

	#if reservation_dict[u'node_cnt'] != -1:
		#uint32_value = reservation_dict[u'node_cnt']
		#resv_msg.node_cnt = uint32_value

	if reservation_dict[u'users'] is not '':
		name = reservation_dict[u'users']
		resv_msg.users = <char*>slurm.xmalloc((len(name)+1)*sizeof(char))
		strcpy(resv_msg.users, name)
		free_users = 1

	if reservation_dict[u'accounts'] is not '':
		name = reservation_dict[u'accounts']
		resv_msg.accounts = <char*>slurm.xmalloc((len(name)+1)*sizeof(char))
		strcpy(resv_msg.accounts, name)
		free_accounts = 1

	if reservation_dict[u'licenses'] is not '':
		name = reservation_dict[u'licenses']
		resv_msg.licenses = name

	errCode = slurm.slurm_update_reservation(&resv_msg)

	if free_users == 1:
		slurm.xfree(resv_msg.users)
	if free_accounts == 1:
		slurm.xfree(resv_msg.accounts)

	return errCode

def slurm_delete_reservation(char* ResID=''):

	u"""Delete a slurm reservation.

	:param string ResID: Reservation Identifier

	:returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
	:rtype: `integer`
	"""


	cdef slurm.reservation_name_msg_t resv_msg

	if not ResID: 
		return -1

	resv_msg.name = ResID

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_delete_reservation(&resv_msg)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

def create_reservation_dict():

	u"""Create and empty dict for use with create_reservation method.

	Returns a dictionary that can be populated by the user an used for 
	the update_reservation and create_reservation calls.

	:returns: Empty Reservation dictionary
	:rtype: `dict`
	"""

	return {u'start_time': -1,
		u'end_time': -1,
		u'duration': -1,
		u'node_cnt': -1,
		u'name': '',
		u'node_list': '',
		u'flags': '',
		u'partition': '',
		u'licenses': '',
		u'users': '',
		u'accounts': ''}

#
# Block Class
#

cdef class block:

	u"""Class to access/update slurm block Information. 
	"""

	cdef:
		slurm.block_info_msg_t *_block_ptr
		slurm.time_t _lastUpdate
		uint16_t _ShowFlags
		dict _BlockDict

	def __cinit__(self):
		self._block_ptr = NULL
		self._lastUpdate = 0
		self._ShowFlags = 0
		self._BlockDict = {}

	def __dealloc__(self):
		self.__free()

	def lastUpdate(self):

		u"""Get the time (epoch seconds) the retrieved data was updated.

		:returns: epoch seconds
		:rtype: `integer`
		"""

		return self._lastUpdate

	def ids(self):

		u"""Return the block IDs from retrieved data.

		:returns: Dictionary of block IDs
		:rtype: `dict`
		"""

		return self._BlockDict.keys()

	def find_id(self, char *blockID=''):

		u"""Retrieve block ID data.

		:param str blockID: Block key string to search
		:returns: Dictionary of values for given block key
		:rtype: `dict`
		"""

		return self._BlockDict.get(blockID, {})

	def find(self, char *name='', val=''):

		u"""Search for a property and associated value in the retrieved block data.

		:param str name: key string to search
		:param value: value to match
		:returns: List of IDs that match
		:rtype: `list`
		"""

		# [ key for key, value in blockID.items() if blockID[key]['state'] == 'error']
		cdef list retList = []

		if val != '':
			for key, value in self._BlockDict.items():
				if self._BlockDict[key][name] == val:
					retList.append(key)
		return retList

	def load(self):

		u"""Load slurm block information.
		"""

		self.__load()

	cpdef int __load(self) except? -1:

		cdef:
			slurm.block_info_msg_t *new_block_info_ptr = NULL
			time_t last_time = <time_t>NULL
			int apiError = 0
			int errCode = 0

		if self._block_ptr is not NULL:

			errCode = slurm.slurm_load_block_info(self._block_ptr.last_update, &new_block_info_ptr, self._ShowFlags)
			if errCode == 0:  # SLURM_SUCCESS
				slurm.slurm_free_block_info_msg(self._block_ptr)
			elif slurm.slurm_get_errno() == 1900:   # SLURM_NO_CHANGE_IN_DATA
				errCode = 0
				new_block_info_ptr = self._block_ptr
		else:
			last_time = <time_t>NULL
			errCode = slurm.slurm_load_block_info(last_time, &new_block_info_ptr, self._ShowFlags)

		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)
		else:
			self._block_ptr = new_block_info_ptr

		return errCode

	def get(self):

		u"""Get slurm block information.

		:returns: Dictionary whose key is the Block ID
		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return self._BlockDict

	cpdef __get(self):

		cdef:
			int i
			dict Block = {}, Block_dict

		if self._block_ptr is not NULL:

			self._lastUpdate = self._block_ptr.last_update

			for i from 0 <= i < self._block_ptr.record_count:

				Block_dict = {}

				name = self._block_ptr.block_array[i].bg_block_id
				Block_dict[u'bg_block_id'] = name
				Block_dict[u'blrtsimage'] = slurm.stringOrNone(self._block_ptr.block_array[i].blrtsimage, '')
				#Block_dict[u'conn_type'] = self._block_ptr.block_array[i].conn_type[HIGHEST_DIMENSIONS]
				Block_dict[u'conn_type'] = get_conn_type_string(self._block_ptr.block_array[i].conn_type[HIGHEST_DIMENSIONS])
				Block_dict[u'ionode_str'] = slurm.listOrNone(self._block_ptr.block_array[i].ionode_str, ',')
				Block_dict[u'linuximage'] = slurm.stringOrNone(self._block_ptr.block_array[i].linuximage, '')
				Block_dict[u'mloaderimage'] = slurm.stringOrNone(self._block_ptr.block_array[i].mloaderimage, '')
				Block_dict[u'cnode_cnt'] = self._block_ptr.block_array[i].cnode_cnt
				Block_dict[u'cnode_err_cnt'] = self._block_ptr.block_array[i].cnode_err_cnt
				Block_dict[u'mp_str'] = slurm.stringOrNone(self._block_ptr.block_array[i].mp_str, '')
				Block_dict[u'node_use'] = get_node_use(self._block_ptr.block_array[i].node_use)
				Block_dict[u'ramdiskimage'] = slurm.stringOrNone(self._block_ptr.block_array[i].ramdiskimage, '')
				Block_dict[u'reason'] = slurm.stringOrNone(self._block_ptr.block_array[i].reason, '')
				#Block_dict[u'state'] = self._block_ptr.block_array[i].state
				Block_dict[u'state'] = get_bg_block_state_string(self._block_ptr.block_array[i].state)

				# Implement List job_list

				Block[name] = Block_dict

		self._BlockDict = Block

	cpdef print_info_msg(self, int oneLiner=False):

		u"""Output information about all slurm blocks

		This is based upon data returned by the slurm_load_block.

		:param int oneLiner: Print information on one line - False (Default), True
		"""

		if self._block_ptr is not NULL:
			slurm.slurm_print_block_info_msg(slurm.stdout, self._block_ptr, oneLiner)

	cpdef __free(self):

		u"""Free the memory returned by load method.
		"""

		if self._block_ptr is not NULL:
			slurm.slurm_free_block_info_msg(self._block_ptr)

	cpdef update_error(self, char *blockID=''):

		u"""Set slurm block to ERROR state.

		:param string blockID: The ID string of the block
		"""

		return self.update(blockID, BLOCK_ERROR)

	cpdef update_free(self, char *blockID=''):

		u"""Set slurm block to FREE state.

		:param string blockID: The ID string of the block
		"""

		return self.update(blockID, BLOCK_FREE)

	cpdef update_recreate(self, char *blockID=''):

		u"""Set slurm block to RECREATE state.

		:param string blockID: The ID string of the block
		"""

		return self.update(blockID, BLOCK_RECREATE)

	cpdef update_remove(self, char *blockID=''):

		u"""Set slurm block to REMOVE state.

		:param string blockID: The ID string of the block
		"""

		return self.update(blockID, BLOCK_REMOVE)

	cpdef update_resume(self, char *blockID=''):

		u"""Set slurm block to RESUME state.

		:param string blockID: The ID string of the block
		"""

		return self.update(blockID, BLOCK_RESUME)

	cpdef update(self, char *blockID='', int blockOP=0):

		cdef:
			int i, dictlen
			slurm.update_block_msg_t block_msg

		if not blockID:
			return

		slurm.slurm_init_update_block_msg(&block_msg)
		block_msg.bg_block_id = blockID
		block_msg.state = blockOP

		if slurm.slurm_update_block(&block_msg):
			return slurm.slurm_get_errno()

		return 0

#
# Topology Class
#

cdef class topology:

	u"""Class to access/update slurm topology information. 
	"""

	cdef:
		slurm.topo_info_response_msg_t *_topo_info_ptr
		dict _TopoDict

	def __cinit__(self):
		self._topo_info_ptr = NULL
		self._TopoDict = {}

	def __dealloc__(self):
		self.__free()

	def lastUpdate(self):

		u"""Get the time (epoch seconds) the retrieved data was updated.

		:returns: epoch seconds
		:rtype: `integer`
		"""

		return self._lastUpdate

	cpdef __free(self):

		u"""Free the memory returned by load method.
		"""

		if self._topo_info_ptr is not NULL:
			slurm.slurm_free_topo_info_msg(self._topo_info_ptr)

	def load(self):

		u"""Load slurm topology information.
		"""

		self.__load()

	cpdef int __load(self) except? -1:
		
		u"""Load slurm topology.
		"""

		cdef int apiError = 0
		cdef int errCode = 0

		if self._topo_info_ptr is not NULL:
			# free previous pointer
			slurm.slurm_free_topo_info_msg(self._topo_info_ptr)

		errCode = slurm.slurm_load_topo(&self._topo_info_ptr)
		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		return errCode

	def get(self):

		u"""Get slurm topology information.

		:returns: Dictionary whose key is the Topology ID
		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return self._TopoDict

	cpdef __get(self):

		cdef:
			int i
			dict Topo = {}, Topo_dict

		if self._topo_info_ptr is not NULL:

			for i from 0 <= i < self._topo_info_ptr.record_count:

				Topo_dict = {}

				name = u"%s" % self._topo_info_ptr.topo_array[i].name
				Topo_dict[u'name'] = name
				Topo_dict[u'nodes'] = slurm.listOrNone(self._topo_info_ptr.topo_array[i].nodes, ',')
				Topo_dict[u'level'] = self._topo_info_ptr.topo_array[i].level
				Topo_dict[u'link_speed'] = self._topo_info_ptr.topo_array[i].link_speed
				Topo_dict[u'switches'] = slurm.listOrNone(self._topo_info_ptr.topo_array[i].switches, ',')

				Topo[name] = Topo_dict

		self._TopoDict = Topo

	def display(self):

		u"""Display topology information to standard output
		"""

		self._print_topo_info_msg()

	cpdef _print_topo_info_msg(self):

		u"""Output information about toplogy based upon message as loaded using slurm_load_topo.
		:param int Flags: Print on one line - False (Default), True
		"""

		if self._topo_info_ptr is not NULL:
			slurm.slurm_print_topo_info_msg(slurm.stdout, self._topo_info_ptr, self._ShowFlags)

#
# PowerCapping
#

cdef class powercap:

	u"""Class to access powercap information. 
	"""

	cdef:
		slurm.powercap_info_msg_t *_msg
		dict _pwrDict

	def __cinit__(self):
		self._msg = NULL
		self._pwrDict = {}

	def __dealloc__(self):
		self.__destroy()

	cpdef __destroy(self):

		u"""Free the memory allocated by __load method. 
		"""

		if self._msg is not NULL:
			slurm.slurm_free_powercap_info_msg(self._msg)

	def load(self):

		u"""Load powercap information.
		"""

		self.__load()

	cpdef int __load(self) except? -1:
		
		u"""Load powercap information.
		"""

		cdef:
			int apiError = 0
			int errCode = 0

		if self._msg is not NULL:
			slurm.slurm_free_powercap_info_msg(self._msg)

		errCode = slurm.slurm_load_powercap(&self._msg)
		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		return errCode

	def get(self):

		u"""Get powercap information.

		:returns: Dictionary of powercap information
		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return self._pwrDict

	cpdef __get(self):

		cdef:
			dict pwrDict = {}

		if self._msg is not NULL:

			pwrDict[u'power_cap'] = self._msg.power_cap
			pwrDict[u'power_floor'] = self._msg.power_floor
			pwrDict[u'power_change'] = self._msg.power_change
			pwrDict[u'min_watts'] = self._msg.min_watts
			pwrDict[u'cur_max_watts'] = self._msg.cur_max_watts
			pwrDict[u'adj_max_watts'] = self._msg.adj_max_watts
			pwrDict[u'max_watts'] = self._msg.max_watts

		self._pwrDict = pwrDict

	#
	# slurm_update_powercap - issue RPC to update powercapping cap 
	# IN powercap_msg - description of powercapping updates
	# RET 0 on success, otherwise return -1 and set errno to indicate the error
	#
	#extern int slurm_update_powercap (update_powercap_msg_t * powercap_msg)

#
# Statistics 
#

cdef class statistics:

	cdef:
		slurm.stats_info_request_msg_t _req
		slurm.stats_info_response_msg_t *_buf

		dict _StatsDict

	def __cinit__(self):
		self._req.command_id = 0 # STAT_COMMAND_RESET
		self._buf = NULL 
		self._StatsDict = {}

		self.__reset()

	def __dealloc__(self):
		self.__free()

	cpdef __free(self):
		pass

	def load(self):
		return self.__load()

	cpdef int __load(self) except? -1:

		u"""
		#extern int  slurm_get_statistics (stats_info_response_msg_t **buf, stats_info_request_msg_t *req)
		"""

		cdef int apiError = 0
		cdef int errCode = slurm.slurm_get_statistics(&self._buf, <slurm.stats_info_request_msg_t*>&self._req)

		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		return errCode

	def get(self):

		u"""Get slurm statistics information.

		:rtype: `dict`
		"""

		self.__get()
		return self._StatsDict

	cpdef __get(self):

		cdef:
			dict Stats_dict = {}
			dict tmp = {}
			int i = 0
			int errCode = slurm.slurm_get_statistics(&self._buf, <slurm.stats_info_request_msg_t*>&self._req)

		if self._buf is not NULL:

			Stats_dict[u'parts_packed'] = self._buf.parts_packed
			Stats_dict[u'req_time'] = self._buf.req_time
			Stats_dict[u'req_time_start'] = self._buf.req_time_start
			Stats_dict[u'server_thread_count'] = self._buf.server_thread_count
			Stats_dict[u'agent_queue_size'] = self._buf.agent_queue_size
			Stats_dict[u'schedule_cycle_last'] = self._buf.schedule_cycle_last
			Stats_dict[u'schedule_cycle_max'] = self._buf.schedule_cycle_max
			Stats_dict[u'schedule_cycle_counter'] = self._buf.schedule_cycle_counter
			Stats_dict[u'schedule_cycle_sum'] = self._buf.schedule_cycle_sum
			Stats_dict[u'schedule_cycle_depth'] = self._buf.schedule_cycle_depth
			Stats_dict[u'schedule_queue_len'] = self._buf.schedule_queue_len
			Stats_dict[u'jobs_submitted'] = self._buf.jobs_submitted
			Stats_dict[u'jobs_started'] = self._buf.jobs_started + self._buf.bf_last_backfilled_jobs
			Stats_dict[u'jobs_completed'] = self._buf.jobs_completed
			Stats_dict[u'jobs_canceled'] = self._buf.jobs_canceled
			Stats_dict[u'jobs_failed'] = self._buf.jobs_failed
			Stats_dict[u'bf_active'] = self._buf.bf_active
			Stats_dict[u'bf_backfilled_jobs'] = self._buf.bf_backfilled_jobs
			Stats_dict[u'bf_last_backfilled_jobs'] = self._buf.bf_last_backfilled_jobs
			Stats_dict[u'bf_cycle_counter'] = self._buf.bf_cycle_counter
			Stats_dict[u'bf_cycle_sum'] = self._buf.bf_cycle_sum
			Stats_dict[u'bf_cycle_last'] = self._buf.bf_cycle_last
			Stats_dict[u'bf_cycle_max'] = self._buf.bf_cycle_max
			Stats_dict[u'bf_last_depth'] = self._buf.bf_last_depth
			Stats_dict[u'bf_last_depth_try'] = self._buf.bf_last_depth_try
			Stats_dict[u'bf_depth_sum'] = self._buf.bf_depth_sum
			Stats_dict[u'bf_depth_try_sum'] = self._buf.bf_depth_try_sum
			Stats_dict[u'bf_queue_len'] = self._buf.bf_queue_len
			Stats_dict[u'bf_queue_len_sum'] = self._buf.bf_queue_len_sum
			Stats_dict[u'bf_when_last_cycle'] = self._buf.bf_when_last_cycle
			Stats_dict[u'bf_active'] = self._buf.bf_active

			Stats_dict[u'rpc_type_size'] = self._buf.rpc_type_size
			tmp = {}
			for i from 0 <= i < self._buf.rpc_type_size:
				tmp[self._buf.rpc_type_id[i]] = {}
				tmp[self._buf.rpc_type_id[i]][u'rpc_type_cnt'] = self._buf.rpc_type_cnt[i]
				tmp[self._buf.rpc_type_id[i]][u'rpc_type_time'] = self._buf.rpc_type_time[i]
			Stats_dict[u'rpc_type_stats'] = tmp

			Stats_dict[u'rpc_user_size'] = self._buf.rpc_user_size
			tmp = {}
			for i from 0 <= i < self._buf.rpc_user_size:
				tmp[self._buf.rpc_user_id[i]] = {}
				tmp[self._buf.rpc_user_id[i]][u'rpc_user_cnt'] = self._buf.rpc_user_cnt[i]
				tmp[self._buf.rpc_user_id[i]][u'rpc_user_time'] = self._buf.rpc_user_time[i]
			Stats_dict[u'rpc_user_stats'] = tmp

		self._StatsDict = Stats_dict

	def reset(self):
		return self.__reset()

	cpdef int __reset(self) except? -1:

		"""
		#extern int slurm_reset_statistics (stats_info_request_msg_t *req)
		"""

		self._req.command_id = 1 # STAT_COMMAND_RESET

		cdef int apiError = 0
		cdef int errCode = slurm.slurm_reset_statistics(<slurm.stats_info_request_msg_t*>&self._req)

		if errCode == 0:
			self._StatsDict = {}
		else:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		return errCode

#
# Front End Node Class
#

cdef class front_end:

	u"""Class to access/update slurm front end node information. 
	"""

	cdef:
		slurm.time_t Time
		slurm.time_t _lastUpdate
		slurm.front_end_info_msg_t *_FrontEndNode_ptr
		#slurm.front_end_info_t _record
		uint16_t _ShowFlags
		dict _FrontEndDict

	def __cinit__(self):
		self._FrontEndNode_ptr = NULL
		self._lastUpdate = 0
		self._ShowFlags = 0
		self._FrontEndDict = {}

	def __dealloc__(self):
		self.__destroy()

	cpdef __destroy(self):

		u"""Free the memory allocated by load front end node method. 
		"""

		if self._FrontEndNode_ptr is not NULL:
			slurm.slurm_free_front_end_info_msg(self._FrontEndNode_ptr)

	def load(self):

		u"""Load slurm front end node information.
		"""

		self.__load()

	cpdef int __load(self) except? -1:
		
		u"""Load slurm front end node.
		"""
 
		cdef:
			#slurm.front_end_info_msg_t *new_FrontEndNode_ptr = NULL
			time_t last_time = <time_t>NULL
			int apiError = 0
			int errCode = 0

		if self._FrontEndNode_ptr is not NULL:
			# free previous pointer
			slurm.slurm_free_front_end_info_msg(self._FrontEndNode_ptr)
		else:
			last_time = <time_t>NULL
			errCode = slurm.slurm_load_front_end(last_time, &self._FrontEndNode_ptr)

		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		return errCode

	def lastUpdate(self):

		u"""Return last time (sepoch seconds) the node data was updated.

		:returns: epoch seconds
		:rtype: `integer`
		"""

		return self._lastUpdate

	def ids(self):

		u"""Return the node IDs from retrieved data.

		:returns: Dictionary of node IDs
		:rtype: `dict`
		"""

		return self._FrontEndDict.keys()

	def get(self):

		u"""Get front end node information.

		:returns: Dictionary whose key is the Topology ID
		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return self._FrontEndDict

	cpdef __get(self):

		cdef:
			int i = 0
			dict FENode = {}
			dict FE_dict = {}

		if self._FrontEndNode_ptr is not NULL:

			for i from 0 <= i < self._FrontEndNode_ptr.record_count:

				FE_dict = {}

				name = u"%s" % self._FrontEndNode_ptr.front_end_array[i].name
				FE_dict[u'boot_time'] = self._FrontEndNode_ptr.front_end_array[i].boot_time
				FE_dict[u'allow_groups'] = slurm.stringOrNone(self._FrontEndNode_ptr.front_end_array[i].allow_groups, '')
				FE_dict[u'allow_users'] = slurm.stringOrNone(self._FrontEndNode_ptr.front_end_array[i].allow_users, '')
				FE_dict[u'deny_groups'] = slurm.stringOrNone(self._FrontEndNode_ptr.front_end_array[i].deny_groups, '')
				FE_dict[u'deny_users'] = slurm.stringOrNone(self._FrontEndNode_ptr.front_end_array[i].deny_users, '')
				FE_dict[u'node_state'] = get_node_state(self._FrontEndNode_ptr.front_end_array[i].node_state)
				FE_dict[u'reason'] = slurm.stringOrNone(self._FrontEndNode_ptr.front_end_array[i].reason, '')
				FE_dict[u'reason_time'] = self._FrontEndNode_ptr.front_end_array[i].reason_time
				FE_dict[u'reason_uid'] = self._FrontEndNode_ptr.front_end_array[i].reason_uid
				FE_dict[u'slurmd_start_time'] = self._FrontEndNode_ptr.front_end_array[i].slurmd_start_time
				FE_dict[u'version'] = slurm.stringOrNone(self._FrontEndNode_ptr.front_end_array[i].version, '')

				FENode[name] = FE_dict

		self._FrontEndDict = FENode

#
# QOS Class
#

cdef class qos:

	u"""Class to access/update slurm QOS information.
	"""

	cdef:
		void *dbconn
		dict _QOSDict
		slurm.List _QOSList

	def __cinit__(self):
		self.dbconn = <void *>NULL
		self._QOSDict = {}

	def __dealloc__(self):
		self.__destroy()

	cpdef __destroy(self):

		u"""QOS Destructor method.
		"""

		self._QOSDict = {}

	def load(self):

		u"""Load slurm QOS information.
		"""

		self.__load()

	cpdef int __load(self) except? -1:

		u"""Load slurm QOS list.
		"""

		cdef slurm.slurmdb_qos_cond_t *new_qos_cond = NULL
		cdef int apiError = 0
		cdef void* dbconn = slurm.slurmdb_connection_get()
		cdef slurm.List QOSList = slurm.slurmdb_qos_get(dbconn, new_qos_cond)

		if QOSList is NULL:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)
		else:
			self._QOSList = QOSList

		slurm.slurmdb_connection_close(&dbconn)

		return 0

	def lastUpdate(self):

		u"""Return last time (sepoch seconds) the QOS data was updated.

		:returns: epoch seconds
		:rtype: `integer`
		"""

		return self._lastUpdate

	def ids(self):

		u"""Return the QOS IDs from retrieved data.

		:returns: Dictionary of QOS IDs
		:rtype: `dict`
		"""

		return self._QOSDict.keys()

	def get(self):

		u"""Get slurm QOS information.

		:returns: Dictionary whose key is the QOS ID
		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return self._QOSDict

	cpdef __get(self):

		cdef:
			slurm.List qos_list = NULL
			slurm.ListIterator iters = NULL
			int i = 0
			int listNum = 0
			dict Q_dict = {}

		if self._QOSList is not NULL:

			listNum = slurm.slurm_list_count(self._QOSList)
			iters = slurm.slurm_list_iterator_create(self._QOSList)

			for i from 0 <= i < listNum:
				qos = <slurm.slurmdb_qos_rec_t *>slurm.slurm_list_next(iters)
				name = qos.name

				# QOS infos
				QOS_info = {}

				if name is not NULL:
					QOS_info[u'description'] = slurm.stringOrNone(qos.description, '')
					QOS_info[u'flags'] = qos.flags
					QOS_info[u'grace_time'] = qos.grace_time
					QOS_info[u'grp_jobs'] = qos.grp_jobs
					QOS_info[u'grp_submit_jobs'] = qos.grp_submit_jobs
					QOS_info[u'grp_tres'] = slurm.stringOrNone(qos.grp_tres, '')
					#QOS_info[u'grp_tres_ctld']
					QOS_info[u'grp_tres_mins'] = slurm.stringOrNone(qos.grp_tres_mins, '')
					#QOS_info[u'grp_tres_mins_ctld']
					QOS_info[u'grp_tres_run_mins'] = slurm.stringOrNone(qos.grp_tres_run_mins, '')
					#QOS_info[u'grp_tres_run_mins_ctld']
					QOS_info[u'grp_wall'] = qos.grp_wall
					QOS_info[u'max_jobs_pu'] = qos.max_jobs_pu
					QOS_info[u'max_submit_jobs_pu'] = qos.max_submit_jobs_pu
					QOS_info[u'max_tres_mins_pj'] = slurm.stringOrNone(qos.max_tres_mins_pj, '')
					#QOS_info[u'max_tres_min_pj_ctld']
					QOS_info[u'max_tres_pj'] = slurm.stringOrNone(qos.max_tres_pj, '')
					#QOS_info[u'max_tres_min_pj_ctld']
					QOS_info[u'max_tres_pn'] = slurm.stringOrNone(qos.max_tres_pn, '')
					#QOS_info[u'max_tres_min_pn_ctld']
					QOS_info[u'max_tres_pu'] = slurm.stringOrNone(qos.max_tres_pu, '')
					#QOS_info[u'max_tres_min_pu_ctld']
					QOS_info[u'max_tres_run_mins_pu'] = slurm.stringOrNone(qos.max_tres_run_mins_pu, '')
					QOS_info[u'max_wall_pj'] = qos.max_wall_pj
					QOS_info[u'min_tres_pj'] = slurm.stringOrNone(qos.min_tres_pj, '')
					#QOS_info[u'min_tres_pj_ctld']
					QOS_info[u'name'] = slurm.stringOrNone(name, '')
					#QOS_info[u'*preempt_bitstr'] =
					#QOS_info[u'preempt_list'] = qos.preempt_list
					QOS_info[u'preempt_mode'] = get_preempt_mode(qos.preempt_mode)
					QOS_info[u'priority'] = qos.priority
					QOS_info[u'usage_factor'] = qos.usage_factor
					QOS_info[u'usage_thres'] = qos.usage_thres

					# NB - Need to add code to decode types of grp_tres_ctld (uint64t list) etc

				if name is not NULL:
					Q_dict[name] = QOS_info

			slurm.slurm_list_iterator_destroy(iters)
			slurm.slurm_list_destroy(self._QOSList)

		self._QOSDict = Q_dict

#
# Helper functions to convert numerical States
#

def get_last_slurm_error():

	u"""Get and return the last error from a slurm API call

	:returns: Slurm error number and the associated error string
	:rtype: `integer`
	:returns: Slurm error string
	:rtype: `string`
	"""

	rc =  slurm.slurm_get_errno()

	if rc == 0:
		return (rc, 'Success')
	else:
		return (rc, slurm.slurm_strerror(rc))

cdef inline dict __get_licenses(char *licenses):

	u"""Returns a dict of licenses from the slurm license string.

	:param string licenses: String containing license information

	:returns: Dictionary of licenses and associated value.
	:rtype: `dict`
	"""

	if (licenses is NULL):
		return {}

	cdef:
		dict licDict = {}
		int i = 0
		list alist = slurm.listOrNone(licenses, ',')
		int listLen = len(alist)

	if alist:
		for i in range(listLen):
			key, value = alist[i].split(':')
			licDict[u"%s" % key] = value

	return licDict

def get_connection_type(int inx):

	u"""Returns a string that represents the slurm block connection type.

	:param int ResType: Slurm block connection type

		- SELECT_MESH    1
		- SELECT_TORUS   2
		- SELECT_NAV     3
		- SELECT_SMALL   4
		- SELECT_HTC_S   5
		- SELECT_HTC_D   6
		- SELECT_HTC_V   7
		- SELECT_HTC_L   8

	:returns: Block connection string
	:rtype: `string`
	"""

	return slurm.slurm_conn_type_string(inx)

def get_node_use(int inx):

	u"""Returns a string that represents the block node mode.

	:param int ResType: Slurm block node usage

		- SELECT_COPROCESSOR_MODE   1
		- SELECT_VIRTUAL_NODE_MODE  2
		- SELECT_NAV_MODE           3

	:returns: Block node usage string
	:rtype: `string`
	"""

	return __get_node_use(inx)

cdef inline object __get_node_use(uint32_t NodeType):

	return slurm.slurm_node_state_string(NodeType)

def get_trigger_res_type(uint16_t inx):

	u"""Returns a tuple that represents the slurm trigger res type.

	:param int ResType: Slurm trigger res state

		- TRIGGER_RES_TYPE_JOB        1
		- TRIGGER_RES_TYPE_NODE       2
		- TRIGGER_RES_TYPE_SLURMCTLD  3
		- TRIGGER_RES_TYPE_SLURMDBD   4
		- TRIGGER_RES_TYPE_DATABASE   5
		- TRIGGER_RES_TYPE_FRONT_END  6

	:returns:  Trigger reservation state string
	:rtype: `string`
	"""

	return __get_trigger_res_type(inx)

cdef inline object __get_trigger_res_type(uint16_t ResType):

	rtype = 'unknown'

	if ResType == TRIGGER_RES_TYPE_JOB:
		rtype = 'job'
	elif ResType == TRIGGER_RES_TYPE_NODE:
		rtype = 'node'
	elif ResType == TRIGGER_RES_TYPE_SLURMCTLD:
		rtype = 'slurmctld'
	elif ResType == TRIGGER_RES_TYPE_SLURMDBD:
		rtype = 'slurmbdb'
	elif ResType == TRIGGER_RES_TYPE_DATABASE:
		rtype = 'database'
	elif ResType == TRIGGER_RES_TYPE_FRONT_END:
		rtype = 'front_end'

	return u"%s" % rtype

def get_trigger_type(uint32_t inx):

	u"""Returns a tuple that represents the state of the slurm trigger.

	:param int TriggerType: Slurm trigger type

		- TRIGGER_TYPE_UP                 0x00000001
		- TRIGGER_TYPE_DOWN               0x00000002
		- TRIGGER_TYPE_FAIL               0x00000004
		- TRIGGER_TYPE_TIME               0x00000008
		- TRIGGER_TYPE_FINI               0x00000010
		- TRIGGER_TYPE_RECONFIG           0x00000020
		- TRIGGER_TYPE_BLOCK_ERR          0x00000040
		- TRIGGER_TYPE_IDLE               0x00000080
		- TRIGGER_TYPE_DRAINED            0x00000100
		- TRIGGER_TYPE_PRI_CTLD_FAIL      0x00000200
		- TRIGGER_TYPE_PRI_CTLD_RES_OP    0x00000400
		- TRIGGER_TYPE_PRI_CTLD_RES_CTRL  0x00000800
		- TRIGGER_TYPE_PRI_CTLD_ACCT_FULL 0x00001000
		- TRIGGER_TYPE_BU_CTLD_FAIL       0x00002000
		- TRIGGER_TYPE_BU_CTLD_RES_OP     0x00004000
		- TRIGGER_TYPE_BU_CTLD_AS_CTRL    0x00008000
		- TRIGGER_TYPE_PRI_DBD_FAIL       0x00010000
		- TRIGGER_TYPE_PRI_DBD_RES_OP     0x00020000
		- TRIGGER_TYPE_PRI_DB_FAIL        0x00040000
		- TRIGGER_TYPE_PRI_DB_RES_OP      0x00080000

	:returns: Trigger state string
	:rtype: `string`
	"""

	return __get_trigger_type(inx)

cdef inline object __get_trigger_type(uint32_t TriggerType):

	rtype = 'unknown'

	if TriggerType == TRIGGER_TYPE_UP:
		rtype = 'up'
	elif TriggerType == TRIGGER_TYPE_DOWN:
		rtype = 'down'
	elif TriggerType == TRIGGER_TYPE_FAIL:
		rtype = 'fail'
	elif TriggerType == TRIGGER_TYPE_TIME:
		rtype = 'time'
	elif TriggerType == TRIGGER_TYPE_FINI:
		rtype = 'fini'
	elif TriggerType == TRIGGER_TYPE_RECONFIG:
		rtype = 'reconfig'
	elif TriggerType == TRIGGER_TYPE_BLOCK_ERR:
		rtype = 'block_err'
	elif TriggerType == TRIGGER_TYPE_IDLE:
		rtype = 'idle'
	elif TriggerType == TRIGGER_TYPE_DRAINED:
		rtype = 'drained'
	elif TriggerType == TRIGGER_TYPE_PRI_CTLD_FAIL:
		rtype = 'primary_slurmctld_failure'
	elif TriggerType == TRIGGER_TYPE_PRI_CTLD_RES_OP:
		rtype = 'primary_slurmctld_resumed_operation'
	elif TriggerType == TRIGGER_TYPE_PRI_CTLD_RES_CTRL:
		rtype = 'primary_slurmctld_resumed_control'
	elif TriggerType == TRIGGER_TYPE_PRI_CTLD_ACCT_FULL:
		rtype = 'primary_slurmctld_acct_buffer_full'
	elif TriggerType == TRIGGER_TYPE_BU_CTLD_FAIL:
		rtype = 'backup_ctld_failure'
	elif TriggerType == TRIGGER_TYPE_BU_CTLD_RES_OP:
		rtype = 'backup_ctld_resumed_operation'
	elif TriggerType == TRIGGER_TYPE_BU_CTLD_AS_CTRL:
		rtype = 'backup_ctld_assumed_control'
	elif TriggerType == TRIGGER_TYPE_PRI_DBD_FAIL:
		rtype = 'primary_slurmdbd_failure'
	elif TriggerType == TRIGGER_TYPE_PRI_DBD_RES_OP:
		rtype = 'primary_slurmdbd_resumed_operation'
	elif TriggerType == TRIGGER_TYPE_PRI_DB_FAIL:
		return 'primary_database_failure'
	elif TriggerType == TRIGGER_TYPE_PRI_DB_RES_OP:
		rtype = 'primary_database_resumed_operation'

	return u"%s" % rtype

def get_res_state(uint16_t inx):

	u"""Returns a string that represents the state of the slurm reservation.

	:param int flags: Slurm reservation flags

		- RESERVE_FLAG_MAINT            0x00000001
		- RESERVE_FLAG_NO_MAINT         0x00000002
		- RESERVE_FLAG_DAILY            0x00000004
		- RESERVE_FLAG_NO_DAILY         0x00000008
		- RESERVE_FLAG_WEEKLY           0x00000010
		- RESERVE_FLAG_NO_WEEKLY        0x00000020
		- RESERVE_FLAG_IGN_JOBS         0x00000040
		- RESERVE_FLAG_NO_IGN_JOB       0x00000080
		- RESERVE_FLAG_ANY_NODES        0x00000100
		- RESERVE_FLAG_NO_ANY_NODES     0x00000200
		- RESERVE_FLAG_STATIC           0x00000400
		- RESERVE_FLAG_NO_STATIC        0x00000800
		- RESERVE_FLAG_PART_NODES       0x00001000
		- RESERVE_FLAG_NO_PART_NODES    0x00002000
		- RESERVE_FLAG_OVERLAP          0x00004000
		- RESERVE_FLAG_SPEC_NODES       0x00008000
		- RESERVE_FLAG_FIRST_CORES      0x00010000
		- RESERVE_FLAG_TIME_FLOAT       0x00020000
		- RESERVE_FLAG_REPLACE          0x00040000

	:returns: Reservation state string
	:rtype: `string`
	"""

	try:
		return slurm.slurm_reservation_flags_string(inx)
	except:
		pass

def get_debug_flags(uint32_t inx):

	u"""
	Returns a string that represents the slurm debug flags.

	:param int flags: Slurm debug flags

		- DEBUG_FLAG_SELECT_TYPE   0x0000000000000001
		- DEBUG_FLAG_STEPS         0x0000000000000002
		- DEBUG_FLAG_TRIGGERS      0x0000000000000004
		- DEBUG_FLAG_CPU_BIND      0x0000000000000008
		- DEBUG_FLAG_WIKI          0x0000000000000010
		- DEBUG_FLAG_NO_CONF_HASH  0x0000000000000020
		- DEBUG_FLAG_GRES          0x0000000000000040
		- DEBUG_FLAG_BG_PICK       0x0000000000000080
		- DEBUG_FLAG_BG_WIRES      0x0000000000000100
		- DEBUG_FLAG_BG_ALGO       0x0000000000000200
		- DEBUG_FLAG_BG_ALGO_DEEP  0x0000000000000400
		- DEBUG_FLAG_PRIO          0x0000000000000800
		- DEBUG_FLAG_BACKFILL      0x0000000000001000
		- DEBUG_FLAG_GANG          0x0000000000002000
		- DEBUG_FLAG_RESERVATION   0x0000000000004000
		- DEBUG_FLAG_FRONT_END     0x0000000000008000
		- DEBUG_FLAG_NO_REALTIME   0x0000000000010000
		- DEBUG_FLAG_SWITCH        0x0000000000020000
		- DEBUG_FLAG_ENERGY        0x0000000000040000
		- DEBUG_FLAG_EXT_SENSORS   0x0000000000080000
		- DEBUG_FLAG_LICENSE       0x0000000000100000
		- DEBUG_FLAG_PROFILE       0x0000000000200000
		- DEBUG_FLAG_INFINIBAND    0x0000000000400000
		- DEBUG_FLAG_FILESYSTEM    0x0000000000800000
		- DEBUG_FLAG_JOB_CONT      0x0000000001000000
		- DEBUG_FLAG_TASK          0x0000000002000000
		- DEBUG_FLAG_PROTOCOL      0x0000000004000000
		- DEBUG_FLAG_BACKFILL_MAP  0x0000000008000000
		- DEBUG_FLAG_TRACE_JOBS    0x0000000010000000
		- DEBUG_FLAG_ROUTE         0x0000000020000000
		- DEBUG_FLAG_DB_ASSOC      0x0000000040000000
		- DEBUG_FLAG_DB_EVENT      0x0000000080000000
		- DEBUG_FLAG_DB_JOB        0x0000000100000000
		- DEBUG_FLAG_DB_QOS        0x0000000200000000
		- DEBUG_FLAG_DB_QUERY      0x0000000400000000
		- DEBUG_FLAG_DB_RESV       0x0000000800000000
		- DEBUG_FLAG_DB_RES        0x0000001000000000
		- DEBUG_FLAG_DB_STEP       0x0000002000000000
		- DEBUG_FLAG_DB_USAGE      0x0000004000000000
		- DEBUG_FLAG_DB_WCKEY      0x0000008000000000
		- DEBUG_FLAG_BURST_BUF     0x0000010000000000
		- DEBUG_FLAG_CPU_FREQ      0x0000020000000000
		- DEBUG_FLAG_POWER         0x0000040000000000
		- DEBUG_FLAG_SICP          0x0000080000000000
		- DEBUG_FLAG_DB_ARCHIVE    0x0000100000000000
		- DEBUG_FLAG_DB_TRES       0x0000200000000000

	:returns: Debug flag string
	:rtype: `string`
	"""

	return __get_debug_flags(inx)

cdef inline list __get_debug_flags(uint32_t flags):

	cdef list debugFlags = []

	if (flags & DEBUG_FLAG_BG_ALGO):
		debugFlags.append(u'BGBlockAlgo')

	if (flags & DEBUG_FLAG_BG_ALGO_DEEP):
		debugFlags.append(u'BGBlockAlgoDeep')

	if (flags & DEBUG_FLAG_BACKFILL):
		debugFlags.append(u'Backfill')

	if (flags & DEBUG_FLAG_BG_PICK):
		debugFlags.append(u'BGBlockPick')

	if (flags & DEBUG_FLAG_BG_WIRES):
		debugFlags.append(u'BGBlockWires')

	if (flags & DEBUG_FLAG_CPU_BIND):
		debugFlags.append(u'CPU_Bind')

	if (flags & DEBUG_FLAG_GANG):
		debugFlags.append(u'Gang')

	if (flags & DEBUG_FLAG_GRES):
		debugFlags.append(u'Gres')

	if (flags & DEBUG_FLAG_NO_CONF_HASH):
		debugFlags.append(u'NO_CONF_HASH')

	if (flags & DEBUG_FLAG_PRIO ):
		debugFlags.append(u'Priority')
               
	if (flags & DEBUG_FLAG_RESERVATION):
		debugFlags.append(u'Reservation')

	if (flags & DEBUG_FLAG_SELECT_TYPE):
		debugFlags.append(u'SelectType')

	if (flags & DEBUG_FLAG_STEPS):
		debugFlags.append(u'Steps')

	if (flags & DEBUG_FLAG_TRIGGERS):
		debugFlags.append(u'Triggers')

	if (flags & DEBUG_FLAG_WIKI):
		debugFlags.append(u'Wiki')

	if (flags & DEBUG_FLAG_FRONT_END):
		debugFlags.append(u'Front_End')

	return debugFlags

def get_node_state(uint32_t inx):

	u"""Returns a string that represents the state of the slurm node.

	:param int inx: Slurm node state

	:returns: Node state string
	:rtype: `string`
	"""

	return slurm.slurm_node_state_string(inx)

def get_rm_partition_state(int inx):

	u"""Returns a string that represents the partition state.

	:param int inx: Slurm partition state

	:returns: Partition state string
	:rtype: `string`
	"""

	return __get_rm_partition_state(inx)

cdef inline object __get_rm_partition_state(int inx):

	cdef list state = [
			'Free',
			'Configuring',
			'Ready',
			'Busy',
			'Deallocating',
			'Error',
			'Nav'
			]

	rm_part_state = 'Unknown'
	try:
		rm_part_state = state[inx]
	except:
		pass

	return u"%s" % rm_part_state

def get_preempt_mode(uint16_t inx):

	u"""Returns a string that represents the preempt mode.

	:param int inx: Slurm preempt mode

		- PREEMPT_MODE_OFF        0x0000
		- PREEMPT_MODE_SUSPEND    0x0001
		- PREEMPT_MODE_REQUEUE    0x0002
		- PREEMPT_MODE_CHECKPOINT 0x0004
		- PREEMPT_MODE_CANCEL     0x0008
		- PREEMPT_MODE_GANG       0x8000

	:returns: Preempt mode string
	:rtype: `string`
	"""

	return slurm.slurm_preempt_mode_string(inx)

def get_partition_state(uint16_t inx):

	u"""Returns a string that represents the state of the slurm partition.

	:param int inx: Slurm partition state

		- PARTITION_DOWN      0x01
		- PARTITION_UP        0x01 | 0x02
		- PARTITION_DRAIN     0x02
		- PARTITION_INACTIVE  0x00

	:returns: Partition state string
	:rtype: `string`
	"""

	state = ""
	if inx:
		if inx == PARTITION_UP:
			state = "up"
		elif inx == PARTITION_DOWN:
			state = "down"
		elif inx == PARTITION_INACTIVE:
			stats = "inactive"
		elif inx == PARTITION_DRAIN:
			state = "drain"
		else:
			state = "unknown"

	return state

cdef inline object __get_partition_state(int inx, int extended=0):

	u"""Returns a string that represents the state of the partition.

	:param int inx: Slurm partition type
	:param int extended:

	:returns: Partition state
	:rtype: `string`
	"""

	cdef:
		int drain_flag   = (inx & 0x0200)
		int comp_flag    = (inx & 0x0400)
		int no_resp_flag = (inx & 0x0800)
		int power_flag   = (inx & 0x1000)

	inx = (inx & 0x00ff)

	state = '?'

	if (drain_flag):
		if (comp_flag or (inx == 4)):
			state = 'Draining'
			if (no_resp_flag and extended):
				state = 'Draining*'
		else:
			state = 'Drained'
			if (no_resp_flag and extended):
				state = 'Drained*'
		return state

	if (inx == 1):
		state = 'Down'
		if (no_resp_flag and extended):
			state = 'Down*'
	elif (inx == 3):
		state = 'Allocated'
		if (no_resp_flag and extended):
			state = 'Allocated*'
		elif (comp_flag and extended):
			state = 'Allocated+'
		elif (comp_flag):
			state = 'Completing'
			if (no_resp_flag and extended):
				state = 'Completing*'
	elif (inx == 2):
		state = 'Idle'
		if (no_resp_flag and extended):
			state = 'Idle*'
		elif (power_flag and extended):
			state = 'Idle~'
	elif (inx == 0):
		state = 'Unknown'
		if (no_resp_flag and extended):
			state = 'Unknown*'

	return u"%s" % state

def get_partition_mode(uint16_t flags=0, uint16_t max_share=0):

	u"""Returns a string represents the state of the partition mode.

	:param int inx: Slurm partition mode

	:returns: Partition mode string
	:rtype: `string`
	"""

	return __get_partition_mode(flags, max_share)

cdef inline dict __get_partition_mode(uint16_t flags=0, uint16_t max_share=0):

	cdef:
		dict mode = {}
		int force = max_share & SHARED_FORCE
		int val = max_share & (~SHARED_FORCE)

	if (flags & PART_FLAG_DEFAULT):
		mode[u'Default'] = 1
	else:
		mode[u'Default'] = 0

	if (flags & PART_FLAG_HIDDEN):
		mode[u'Hidden'] = 1
	else:
		mode[u'Hidden'] = 0

	if (flags & PART_FLAG_NO_ROOT):
		mode[u'DisableRootJobs'] = 1
	else:
		mode[u'DisableRootJobs'] = 0

	if (flags & PART_FLAG_ROOT_ONLY):
		mode[u'RootOnly'] = 1
	else:
		mode[u'RootOnly'] = 0

	if val == 0:
		mode[u'Shared'] = u"EXCLUSIVE"
	elif force:
		mode[u'Shared'] = u"FORCED"
	elif val == 1:
		mode[u'Shared'] = 0
	else:
		mode[u'Shared'] = 1

	if (flags & PART_FLAG_LLN):
		mode[u'LLN'] = 1
	else:
		mode[u'LLN'] = 0

	if (flags & PART_FLAG_EXCLUSIVE_USER):
		mode[u'ExclusiveUser'] = 1
	else:
		mode[u'ExclusiveUser'] = 0

	return mode

def get_conn_type_string(uint16_t inx):

	u"""Returns a string that represents the state of the slurm bluegene connection type.

	:param int inx: Slurm BG connection state

	:returns: Block connection string
	:rtype: `string`
	"""

	return slurm.slurm_conn_type_string(inx)

def get_bg_block_state_string(uint16_t inx):

	u"""Returns a string that represents the state of the slurm bluegene block state.

	:param int inx: Slurm BG block state

	:returns: Block state string
	:rtype: `string`
	"""

	return slurm.slurm_bg_block_state_string(inx)

def get_job_state(uint16_t inx):

	u"""Returns a string that represents the state of the slurm job state.

	:param int inx: Slurm job state

		- JOB_PENDING     0
		- JOB_RUNNING     1
		- JOB_SUSPENDED   2
		- JOB_COMPLETE    3
		- JOB_CANCELLED   4
		- JOB_FAILED      5
		- JOB_TIMEOUT     6
		- JOB_NODE_FAIL   7
		- JOB_PREEMPTED   8
		- JOB_BOOT_FAIL   10
		- JOB_END         11

	:returns: Job state string
	:rtype: `string`
	"""

	try:
		return slurm.slurm_job_state_string(inx)
	except:
		pass

def get_job_state_reason(uint16_t inx):

	u"""Returns a reason why the slurm job is in a provided state.

	:param int inx: Slurm job state reason

	:returns: Reason string
	:rtype: `string`
	"""

	return slurm.slurm_job_reason_string(inx)

def epoch2date(epochSecs):

	u"""Convert epoch secs to a python time string.

	:param int epochSecs: Seconds since epoch

	:returns: Date
	:rtype: `string`
	"""

	try:
		dateTime = time.gmtime(epochSecs)
		return u"%s" % time.strftime("%a %b %d %H:%M:%S %Y", dateTime)
	except:
		pass

def __convertDefaultTime(uint32_t inx):

	try:
		if inx == 0xffffffff:
			return 'infinite'
		elif inx ==  0xfffffffe:
			return 'no_value'
		else:
			return '%s' % inx
	except:
		pass

class Dict(defaultdict):

	def __init__(self):
		defaultdict.__init__(self, Dict)

	def __repr__(self):
		return dict.__repr__(self)

#
# Slurm Controller License Class
#

cdef class licenses:

	u"""Class to access slurm controller license information. 
	"""

	cdef:
		slurm.license_info_msg_t *_msg
		slurm.time_t _lastUpdate
		uint16_t _ShowFlags
		dict _licDict

	def __cinit__(self):
		self._msg = NULL
		self._lastUpdate = 0
		self._ShowFlags = 0
		self._licDict = {}

	def __dealloc__(self):
		self.__destroy()

	cpdef __destroy(self):

		u"""Free the memory allocated by load licenses method. 
		"""

		if self._msg is not NULL:
			slurm.slurm_free_license_info_msg(self._msg)

	def load(self):

		u"""Load slurm controller licenses information.
		"""

		self.__load()

	cpdef int __load(self) except? -1:

		u"""Load slurm controller licenses information.
		"""

		cdef:
			slurm.license_info_msg_t *_new_msg = NULL
			time_t last_time = <time_t>NULL
			int apiError = 0
			int errCode = 0

		if self._msg is not NULL:
			errCode = slurm.slurm_load_licenses(self._lastUpdate, &_new_msg, self._ShowFlags)
			if errCode == 0:
				slurm.slurm_free_license_info_msg(self._msg)
			elif slurm.slurm_get_errno() == 1900:
				errCode = 0
				_new_msg = self._msg
		else:
			last_time = <time_t>NULL
			_new_msg = NULL
			errCode = slurm.slurm_load_licenses(last_time, &_new_msg, self._ShowFlags)

		if errCode == 0:
			if _new_msg.last_update > self._lastUpdate :
				self._msg = _new_msg
				self._lastUpdate = self._msg.last_update
		else:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

	def lastUpdate(self):

		u"""Return last time (epoch seconds) license data was updated.

		:returns: epoch seconds
		:rtype: `integer`
		"""

		return self._lastUpdate

	def ids(self):

		u"""Return the current license names from retrieved license data.

		:returns: Dictionary of licenses
		:rtype: `dict`
		"""

		return self._licDict.keys()

	def get(self):

		u"""Get slurm controller licenses information.

		:returns: Dictionary whose key is the license name
		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return self._licDict

	cpdef __get(self):

		cdef:
			int i
			dict licenses = {}
			dict lic

		if self._msg is not NULL:

			if self._msg.num_lic:

				for i from 0 <= i < self._msg.num_lic:

					lic = {}
					name = u"%s" % self._msg.lic_array[i].name
					lic[u'available'] = self._msg.lic_array[i].available
					lic[u'in_use'] = self._msg.lic_array[i].in_use
					lic[u'remote'] = self._msg.lic_array[i].remote
					lic[u'total'] = self._msg.lic_array[i].total

					licenses[name] = lic

		self._licDict = licenses

