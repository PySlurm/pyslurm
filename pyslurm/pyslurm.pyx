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

import time
from datetime import datetime, timedelta

from getopt import getopt, GetoptError

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
include "slurm_version.pxi"

#
# Slurm Macros as Cython inline functions
#

cdef inline SLURM_VERSION_MAJOR(a): return ((a >> 16) & 0xff)
cdef inline SLURM_VERSION_MINOR(a): return ((a >>  8) & 0xff)
cdef inline SLURM_VERSION_MICRO(a): return (a & 0xff)
cdef inline SLURM_VERSION_NUM(a,b,c):   return (((SLURM_VERSION_MAJOR(a)) << 16) + ((SLURM_VERSION_MINOR(a)) << 8) + (SLURM_VERSION_MICRO(a)))

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

sbatch_opts = "+ba:A:B:c:C:d:D:e:F:g:hHi:IJ:kL:m:M:n:N:o:Op:P:QRst:uU:vVw:x:"
sbatch_long_opts = [ "account", "array", "batch", "extra-node-info" "cpus-per-task", \
		"constraint", "dependency", "workdir", "error", "nodefile", "geometry", \
		"help", "hold", "input", "immediate", "job-name", "no-kill", "licenses", \
		"distribution", "cluster", "clusters", "tasks", "ntasks", "nodes", \
		"output", "overcommit", "partition", "quiet", "no-rotate", "share", \
		"time", "usage", "verbose", "version", "nodelist", "exclude", \
		"acctg-freq", "begin", "blrts-image", "checkpoint", "checkpoint-dir", \
		"cnload-image", "comment", "conn-type", "contiguous", "cores-per-socket", \
		"cpu_bind", "exclusive", "export", "export-file", "get-user-env", "gres", \
		"gid", "hint", "ioload-image", "jobid", "linux-image", "mail-type", \
		"mail-user", "mem", "mem-per-cpu", "mem_bind", "mincores", "mincpus", \
		"minsockets", "minthreads", "mloader-image", "network", "nice", \
		"no-requeue", "ntasks-per-core", "ntasks-per-node", "ntasks-per-socke", \
		"open-mode", "propagate", "profile", "qos", "ramdisk-image", "reboot", \
		"requeue", "reservation", "signal", "sockets-per-node", "tasks-per-node", \
		"time-min", "threads-per-core", "tmp", "uid", "wait-all-nodes", \
		"wckey", "wrap", "switches", "ignore-pbs"]
slurm_opt_dict = {
		"-a": "--array",
		"-A": "--account",
		"-B": "--extra-node-info",
		"-c": "--cpus-per-task",
		"-C": "--constraint",
		"-d": "--dependency",
		"-D": "--workdir",
		"-e": "--error",
		"-F": "--nodefile",
		"-g": "--geometry",
		"-h": "--help",
		"-H": "--hold",
		"-i": "--input",
		"-I": "--immediate",
		"-J": "--job-name",
		"-k": "--no-kill",
		"-L": "--licenses",
		"-m": "--distribution",
		"-M": "--clusters",
		"-n": "--ntasks",
		"-N": "--nodes",
		"-o": "--output",
		"-O": "--overcommit",
		"-p": "--partition",
		"-P": "--0",
		"-Q": "--quiet",
		"-R": "--no-rotate",
		"-s": "--share",
		"-t": "--time",
		"-u": "--usage",
		"-U": "--0",
		"-v": "--verbose",
		"-V": "--version",
		"-w": "--nodelist",
		"-x": "--exclude",
		}

pbs_opts = "+a:A:c:C:e:hIj:J:k:l:m:M:N:o:p:q:r:S:t:u:v:VW:z"

pbs_opts_long = [ "start_time", "account", "checkpoint", "working_dir", \
		"error", "hold", "interactive", "join", "job_array", "keep", \
		"resource_list", "mail_options", "mail_user_list", "job_name", \
		"out", "priority", "destination", "rerunable", "script_path", "array", \
		"running_user", "variable_list", "all_env", "attributes", "no_std" ]

pbs_opts_dict = {
	"-a": "--start_time",
	"-A": "--account",
	"-c": "--checkpoint",
	"-C": "--working_dir",
	"-e": "--error",
	"-h": "--hold",
	"-I": "--interactive",
	"-j": "--join",
	"-J": "--job_array",
	"-k": "--keep",
	"-l": "--resource_list",
	"-m": "--mail_options",
	"-M": "--mail_user_list",
	"-N": "--job_name",
	"-o": "--out",
	"-p": "--priority",
	"-q": "--destination",
	"-r": "--rerunable",
	"-S": "--script_path",
	"-t": "--array",
	"-u": "--running_user",
	"-v": "--variable_list",
	"-V": "--all_env",
	"-W": "--attributes",
	"-z": "--no_std",
}

pbs_slurm_opts_dict = {
	"start_time": "begin",
	"account": "account",
	"checkpoint": "checkpoint",
	"working_dir": "workdir",
	"error": "error",
	"hold": "hold",
	"interactive": "-1",
	"join": "-1",
	"job_array": "array",
	"array": "arrary",
	"keep": "-1",
	"resource_list": "-1",	# TODO:parse resource list
	"mail_options": "m",
	"mail_user_list": "mail-user",
	"job_name": "job-name",
	"out": "output",
	"priority": "nice",
	"destination": "partition",
	"rerunable": "-1",
	"script_path": "-1",
	"running_user": "-1",
	"variable_list": "variable_list",
	"all_env": "-1",
	"attributes": "attributes",
	"no_std": "-1",
}

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

def is_controller(Host=gethostname()):

	u"""Return slurm controller status for host.
 
	:param string Host: Name of host to check

	:returns: None, primary or backup
	:rtype: `string`
	"""

	primary, backup = get_controllers()

	if primary == Host:
		return u'primary'
	if backup  == Host:
		return u'backup'

	return None

def slurm_version():

	u"""Return the slurm version number.

	:returns: version_major, version_minor, version_micro
	:rtype: `tuple`
	"""

	cdef long version = SLURM_VERSION_NUMBER

	return (SLURM_VERSION_MAJOR(version), SLURM_VERSION_MINOR(version), SLURM_VERSION_MICRO(version))

def slurm_api_version():

	u"""Return the slurm API version number.

	:returns: version_major, version_minor, version_micro
	:rtype: `tuple`
	"""

	cdef long version = slurm.slurm_api_version()

	return (SLURM_VERSION_MAJOR(version), SLURM_VERSION_MINOR(version), SLURM_VERSION_MICRO(version))

#
# Slurmd Class
#

cdef class slurmd:

	u"""Class to access slurmd Information."""

	cdef:
		slurm.slurmd_status_t *slurmd_status
		slurm.slurmd_status_t *__slurmd_status
		dict __SlurmdDict

	def __cinit__(self):
		self.__slurmd_status = NULL
		self.__SlurmdDict = {}
		self.__load()
		self.__get()

	def __dealloc__(self):
		self.__free()

	cdef void __free(self):

		u"""Free the slurmd status pointer returned from a previous slurm_load_slurmd_status call.
		"""

		if self.__slurmd_status is not NULL:
			slurm.slurm_free_slurmd_status(self.__slurmd_status)
			self.__slurmd_status = NULL
			self.__SlurmdDict = {}

	cpdef int __load(self) except? -1:

		u"""Issue RPC to get and load the status of the slurmd daemon.

		:returns: slurmd information
		:rtype: `dict`
		"""

		cdef:
			slurm.slurmd_status_t *slurmd_status_ptr = NULL
			int apiError = 0
			int errCode = slurm.slurm_load_slurmd_status(&slurmd_status_ptr)

		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		self.__slurmd_status = slurmd_status_ptr

	def get(self):

		u"""Return the slurmd status information.

		:returns: Slurm status data
		:rtype: `dict`
		"""

		self.__free()
		self.__load()
		self.__get()

		return self.__SlurmdDict

	cpdef __get(self):

		u"""Issue RPC to get and load the status of the Slurmd daemon.

		:returns: Slurmd information
		:rtype: `dict`
		"""

		cdef:
			dict Status = {}, Status_dict = {}
			char* hostname = NULL

		if self.__slurmd_status is not NULL:

			hostname = self.__slurmd_status.hostname
			Status_dict[u'actual_boards'] = self.__slurmd_status.actual_boards
			Status_dict[u'booted'] = self.__slurmd_status.booted
			Status_dict[u'actual_cores'] = self.__slurmd_status.actual_cores
			Status_dict[u'actual_cpus'] = self.__slurmd_status.actual_cpus
			Status_dict[u'actual_real_mem'] = self.__slurmd_status.actual_real_mem
			Status_dict[u'actual_sockets'] = self.__slurmd_status.actual_sockets
			Status_dict[u'actual_threads'] = self.__slurmd_status.actual_threads
			Status_dict[u'actual_tmp_disk'] = self.__slurmd_status.actual_tmp_disk
			Status_dict[u'hostname'] = slurm.stringOrNone(self.__slurmd_status.hostname, '')
			Status_dict[u'last_slurmctld_msg'] = self.__slurmd_status.last_slurmctld_msg
			Status_dict[u'pid'] = self.__slurmd_status.pid
			Status_dict[u'slurmd_debug'] = self.__slurmd_status.slurmd_debug
			Status_dict[u'slurmd_logfile'] = slurm.stringOrNone(self.__slurmd_status.slurmd_logfile, '')
			Status_dict[u'step_list'] = slurm.stringOrNone(self.__slurmd_status.step_list, '')
			Status_dict[u'version'] = slurm.stringOrNone(self.__slurmd_status.version, '')

			Status[hostname] = Status_dict

		self.__SlurmdDict = Status

cpdef dict slurm_load_slurmd_status():

	u"""Wrapper call for old slurm_load_slurmd_status calls

	:returns: Slurmd status information
	:rtype: `dict`
	"""

	a = slurmd()
	b = a.get()
	del a
	return b

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

	cpdef int __load(self) except ? -1:

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

		:returns: Controller configuration data
		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return self.__ConfigDict

	cpdef __get(self):

		u"""Get the slurm control configuration information.

		:returns: Controller configuration data
		:rtype: `dict`
		"""

		cdef:
			void *ret_list = NULL
			slurm.List config_list = NULL
			slurm.ListIterator iters = NULL
			config_key_pair_t *keyPairs
			int i, listNum
			dict Ctl_dict = {}, key_pairs = {}

		if self.__Config_ptr is not NULL:

			self.__lastUpdate = self.__Config_ptr.last_update

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
			Ctl_dict[u'authtype'] = slurm.stringOrNone(self.__Config_ptr.authtype, '')
			Ctl_dict[u'backup_addr'] = slurm.stringOrNone(self.__Config_ptr.backup_addr, '')
			Ctl_dict[u'backup_controller'] = slurm.stringOrNone(self.__Config_ptr.backup_controller, '')
			Ctl_dict[u'batch_start_timeout'] = self.__Config_ptr.batch_start_timeout
			Ctl_dict[u'boot_time'] = self.__Config_ptr.boot_time
			Ctl_dict[u'checkpoint_type'] = slurm.stringOrNone(self.__Config_ptr.checkpoint_type, '')
			Ctl_dict[u'cluster_name'] = slurm.stringOrNone(self.__Config_ptr.cluster_name, '')
			Ctl_dict[u'complete_wait'] = self.__Config_ptr.complete_wait
			Ctl_dict[u'control_addr'] = slurm.stringOrNone(self.__Config_ptr.control_addr, '')
			Ctl_dict[u'control_machine'] = slurm.stringOrNone(self.__Config_ptr.control_machine, '')
			Ctl_dict[u'crypto_type'] = slurm.stringOrNone(self.__Config_ptr.crypto_type, '')
			Ctl_dict[u'debug_flags'] = self.__Config_ptr.debug_flags
			Ctl_dict[u'def_mem_per_cpu'] = self.__Config_ptr.def_mem_per_cpu
			Ctl_dict[u'disable_root_jobs'] = bool(self.__Config_ptr.disable_root_jobs)
			Ctl_dict[u'dynalloc_port'] = self.__Config_ptr.dynalloc_port
			Ctl_dict[u'enforce_part_limits'] = bool(self.__Config_ptr.enforce_part_limits)
			Ctl_dict[u'epilog'] = slurm.stringOrNone(self.__Config_ptr.epilog, '')
			Ctl_dict[u'epilog_msg_time'] = self.__Config_ptr.epilog_msg_time
			Ctl_dict[u'epilog_slurmctld'] = slurm.stringOrNone(self.__Config_ptr.epilog_slurmctld, '')
			Ctl_dict[u'ext_sensors_type'] = slurm.stringOrNone(self.__Config_ptr.ext_sensors_type, '')
			Ctl_dict[u'ext_sensors_freq'] = self.__Config_ptr.ext_sensors_freq
			Ctl_dict[u'fast_schedule'] = bool(self.__Config_ptr.fast_schedule)
			Ctl_dict[u'first_job_id'] = self.__Config_ptr.first_job_id
			Ctl_dict[u'get_env_timeout'] = self.__Config_ptr.get_env_timeout
			Ctl_dict[u'gres_plugins'] = slurm.listOrNone(self.__Config_ptr.gres_plugins, ',')
			Ctl_dict[u'group_info'] = self.__Config_ptr.group_info
			Ctl_dict[u'hash_val'] = self.__Config_ptr.hash_val
			Ctl_dict[u'health_check_interval'] = self.__Config_ptr.health_check_interval
			Ctl_dict[u'health_check_node_state'] = self.__Config_ptr.health_check_node_state
			Ctl_dict[u'health_check_program'] = slurm.stringOrNone(self.__Config_ptr.health_check_program, '')
			Ctl_dict[u'inactive_limit'] = self.__Config_ptr.inactive_limit
			Ctl_dict[u'job_acct_gather_freq'] = slurm.stringOrNone(self.__Config_ptr.job_acct_gather_freq,'')
			Ctl_dict[u'job_acct_gather_type'] = slurm.stringOrNone(self.__Config_ptr.job_acct_gather_type, '')
			Ctl_dict[u'job_ckpt_dir'] = slurm.stringOrNone(self.__Config_ptr.job_ckpt_dir, '')
			Ctl_dict[u'job_comp_host'] = slurm.stringOrNone(self.__Config_ptr.job_comp_host, '')
			Ctl_dict[u'job_comp_loc'] = slurm.stringOrNone(self.__Config_ptr.job_comp_loc, '')
			Ctl_dict[u'job_comp_pass'] = slurm.stringOrNone(self.__Config_ptr.job_comp_pass, '')
			Ctl_dict[u'job_comp_port'] = self.__Config_ptr.job_comp_port
			Ctl_dict[u'job_comp_type'] = slurm.stringOrNone(self.__Config_ptr.job_comp_type, '')
			Ctl_dict[u'job_comp_user'] = slurm.stringOrNone(self.__Config_ptr.job_comp_user, '')
			Ctl_dict[u'job_credential_private_key'] = slurm.stringOrNone(self.__Config_ptr.job_credential_private_key, '')
			Ctl_dict[u'job_credential_public_certificate'] = slurm.stringOrNone(self.__Config_ptr.job_credential_public_certificate, '')
			Ctl_dict[u'job_file_append'] = bool(self.__Config_ptr.job_file_append)
			Ctl_dict[u'job_requeue'] = bool(self.__Config_ptr.job_requeue)
			Ctl_dict[u'job_submit_plugins'] = slurm.stringOrNone(self.__Config_ptr.job_submit_plugins, '')
			Ctl_dict[u'keep_alive_time'] = self.__Config_ptr.keep_alive_time
			Ctl_dict[u'kill_on_bad_exit'] = bool(self.__Config_ptr.kill_on_bad_exit)
			Ctl_dict[u'kill_wait'] = self.__Config_ptr.kill_wait
			Ctl_dict[u'launch_type'] = slurm.stringOrNone(self.__Config_ptr.launch_type, '')
			Ctl_dict[u'licenses'] = slurm.stringOrNone(self.__Config_ptr.licenses, '')
			Ctl_dict[u'licenses_used'] = slurm.stringOrNone(self.__Config_ptr.licenses_used, '')
			Ctl_dict[u'mail_prog'] = slurm.stringOrNone(self.__Config_ptr.mail_prog, '')
			Ctl_dict[u'max_array_sz'] = self.__Config_ptr.max_array_sz
			Ctl_dict[u'max_job_cnt'] = self.__Config_ptr.max_job_cnt
			Ctl_dict[u'max_job_id'] = self.__Config_ptr.max_job_id
			Ctl_dict[u'max_mem_per_cpu'] = self.__Config_ptr.max_mem_per_cpu
			Ctl_dict[u'max_step_cnt'] = self.__Config_ptr.max_step_cnt
			Ctl_dict[u'max_tasks_per_node'] = self.__Config_ptr.max_tasks_per_node
			Ctl_dict[u'min_job_age'] = self.__Config_ptr.min_job_age
			Ctl_dict[u'mpi_default'] = slurm.stringOrNone(self.__Config_ptr.mpi_default, '')
			Ctl_dict[u'mpi_params'] = slurm.stringOrNone(self.__Config_ptr.mpi_params, '')
			Ctl_dict[u'msg_timeout'] = self.__Config_ptr.msg_timeout
			Ctl_dict[u'next_job_id'] = self.__Config_ptr.next_job_id
			Ctl_dict[u'node_prefix']  = slurm.stringOrNone(self.__Config_ptr.node_prefix, '')
			Ctl_dict[u'over_time_limit'] = self.__Config_ptr.over_time_limit
			Ctl_dict[u'plugindir'] = slurm.stringOrNone(self.__Config_ptr.plugindir, '')
			Ctl_dict[u'plugstack'] = slurm.stringOrNone(self.__Config_ptr.plugstack, '')
			Ctl_dict[u'preempt_mode'] = get_preempt_mode(self.__Config_ptr.preempt_mode)
			Ctl_dict[u'preempt_type'] = slurm.stringOrNone(self.__Config_ptr.preempt_type, '')
			Ctl_dict[u'priority_decay_hl'] = self.__Config_ptr.priority_decay_hl
			Ctl_dict[u'priority_calc_period'] = self.__Config_ptr.priority_calc_period
			Ctl_dict[u'priority_favor_small'] = self.__Config_ptr.priority_favor_small
			Ctl_dict[u'priority_max_age'] = self.__Config_ptr.priority_max_age
			Ctl_dict[u'priority_reset_period'] = self.__Config_ptr.priority_reset_period
			Ctl_dict[u'priority_type'] = slurm.stringOrNone(self.__Config_ptr.priority_type, '')
			Ctl_dict[u'priority_weight_age'] = self.__Config_ptr.priority_weight_age
			Ctl_dict[u'priority_weight_fs'] = self.__Config_ptr.priority_weight_fs
			Ctl_dict[u'priority_weight_js'] = self.__Config_ptr.priority_weight_js
			Ctl_dict[u'priority_weight_part'] = self.__Config_ptr.priority_weight_part
			Ctl_dict[u'priority_weight_qos'] = self.__Config_ptr.priority_weight_qos
			Ctl_dict[u'private_data'] = self.__Config_ptr.private_data
			Ctl_dict[u'proctrack_type'] = slurm.stringOrNone(self.__Config_ptr.proctrack_type, '')
			Ctl_dict[u'prolog'] = slurm.stringOrNone(self.__Config_ptr.prolog, '')
			Ctl_dict[u'prolog_slurmctld'] = slurm.stringOrNone(self.__Config_ptr.prolog_slurmctld, '')
			Ctl_dict[u'propagate_prio_process'] = self.__Config_ptr.propagate_prio_process
			Ctl_dict[u'propagate_rlimits'] = slurm.stringOrNone(self.__Config_ptr.propagate_rlimits, '')
			Ctl_dict[u'propagate_rlimits_except'] = slurm.stringOrNone(self.__Config_ptr.propagate_rlimits_except, '')
			Ctl_dict[u'reboot_program'] = slurm.stringOrNone(self.__Config_ptr.reboot_program, '')
			Ctl_dict[u'reconfig_flags'] = self.__Config_ptr.reconfig_flags
			Ctl_dict[u'resume_program'] = slurm.stringOrNone(self.__Config_ptr.resume_program, '')
			Ctl_dict[u'resume_rate'] = self.__Config_ptr.resume_rate
			Ctl_dict[u'resume_timeout'] = self.__Config_ptr.resume_timeout
			Ctl_dict[u'resv_epilog'] = slurm.stringOrNone(self.__Config_ptr.resv_epilog,'')
			Ctl_dict[u'resv_over_run'] = self.__Config_ptr.resv_over_run
			Ctl_dict[u'resv_prolog'] = slurm.stringOrNone(self.__Config_ptr.resv_prolog,'')
			Ctl_dict[u'ret2service'] = self.__Config_ptr.ret2service
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
			Ctl_dict[u'slurmctld_plugstack'] = slurm.stringOrNone(self.__Config_ptr.slurmctld_plugstack, '')
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
			Ctl_dict[u'topology_plugin'] = slurm.stringOrNone(self.__Config_ptr.topology_plugin, '')
			Ctl_dict[u'track_wckey'] = self.__Config_ptr.track_wckey
			Ctl_dict[u'tree_width'] = self.__Config_ptr.tree_width
			Ctl_dict[u'unkillable_program'] = slurm.stringOrNone(self.__Config_ptr.unkillable_program, '')
			Ctl_dict[u'unkillable_timeout'] = self.__Config_ptr.unkillable_timeout
			Ctl_dict[u'use_pam'] = bool(self.__Config_ptr.use_pam)
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

		u"""Free the slurm partition memory allocated by the load partition method. 
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

		cdef:
			slurm.partition_info_msg_t *new_Partition_ptr = NULL
			slurm.time_t last_time = <slurm.time_t>NULL
			int apiError = 0, errCode = 0

		if self._Partition_ptr is not NULL:

			errCode = slurm.slurm_load_partitions(self._Partition_ptr.last_update, &new_Partition_ptr, self._ShowFlags)
			if errCode == 0:
				slurm.slurm_free_partition_info_msg(self._Partition_ptr)
			elif slurm.slurm_get_errno() == 1900:
				# SLURM_NO_CHANGE_IN_DATA
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

	cpdef __get(self):

		u"""Get the slurm partition data from a previous load partition method.
		"""

		cdef:
			int i = 0
			unsigned int preempt_mode
			dict Partition = {}, Part_dict  = {}

		if self._Partition_ptr is not NULL:

			self._lastUpdate = self._Partition_ptr.last_update
			for i from 0 <= i < self._Partition_ptr.record_count:

				self._record = self._Partition_ptr.partition_array[i]
				name = self._record.name

				Part_dict[u'allow_alloc_nodes'] = slurm.listOrNone(self._record.allow_alloc_nodes, ',')
				Part_dict[u'allow_groups'] = slurm.listOrNone(self._record.allow_groups, ',')
				Part_dict[u'alternate'] = slurm.stringOrNone(self._record.alternate, '')

				Part_dict[u'cr_type'] = self._record.cr_type
				Part_dict[u'def_mem_per_cpu'] = self._record.def_mem_per_cpu
				Part_dict[u'default_time'] = __convertDefaultTime(self._record.default_time)

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

				Part_dict[u'preempt_mode'] = slurm.slurm_preempt_mode_string(self._record.preempt_mode)

				Part_dict[u'priority'] = self._record.priority
				Part_dict[u'state_up'] = get_partition_state(self._record.state_up)
				Part_dict[u'total_cpus'] = self._record.total_cpus
				Part_dict[u'total_nodes'] = self._record.total_nodes

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

cpdef int slurm_update_partition(dict partition_dict={}) except? -1:

	u"""Update a slurm partition.

	:param dict partition_dict: A populated partition dictionary, an empty one is created by create_partition_dict

	:returns: 0 for success, -1 for error, and the slurm error code is set appropriately.
	:rtype: `integer`
	"""

	cdef:
		slurm.update_part_msg_t part_msg_ptr
		unsigned int uint32_value, time_value
		int  apiError = 0, errCode = 0, int_value = 0
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
			part_msg_ptr.state_up = 0x01		# PARTITION_DOWN (PARTITION_SUBMIT 0x01)
		elif pystring == u'UP':
			part_msg_ptr.state_up = 0x01|0x02	# PARTITION_UP (PARTITION_SUBMIT|PARTITION_SCHED)
		elif pystring == u'DRAIN':
			part_msg_ptr.state_up = 0x02		# PARTITION_DRAIN (PARTITION_SCHED=0x02)
		else:
			errCode = -1

	if partition_dict[u'Nodes'] is not '':
		part_msg_ptr.nodes = partition_dict[u'Nodes']

	if partition_dict[u'AllowGroups'] is not '':
		part_msg_ptr.allow_groups = partition_dict[u'AllowGroups']

	if partition_dict[u'AllocNodes'] is not '':
		part_msg_ptr.allow_alloc_nodes = partition_dict[u'AllocNodes']

	errCode = slurm.slurm_update_partition(&part_msg_ptr)
	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

	return errCode

cpdef int slurm_delete_partition(char* PartID) except? -1:

	u"""Delete a slurm partition.

	:param string PartID: Name of slurm partition

	:returns: 0 for success else set the slurm error code as appropriately.
	:rtype: `integer`
	"""

	cdef slurm.delete_part_msg_t part_msg
	cdef int apiError = 0, errCode = -1

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

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

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

cpdef int slurm_requeue(uint32_t JobID=0) except? -1:

	u"""Requeue a running slurm job step.

	:param int JobID: Job identifier

	:returns: 0 for success or a slurm error code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_requeue(JobID)

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
	:rtype: `time_t`
	"""

	cdef time_t EndTime = 0
	cdef int apiError = 0
	cdef int errCode = slurm.slurm_get_end_time(JobID, &EndTime)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)
	else:
		return EndTime

cpdef int slurm_job_node_ready(uint32_t JobID=0) except? -1:

	u"""Return if a node could run a slurm job now if despatched.

	:param int JobID: Job identifier

	:returns: Node Ready code
	:rtype: `integer`
	"""

	cdef int apiError = 0
	cdef int errCode = slurm.slurm_job_node_ready(JobID)

	if errCode != 0:
		apiError = slurm.slurm_get_errno()
		raise ValueError(slurm.slurm_strerror(apiError), apiError)

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

cdef slurm_env_array_merge_slurm(char ***dest_env, const char **c_environ):
	"""merge environments start with SLURM.
	"""
	cdef int i = 0
	while c_environ[i] != NULL:
		env = c_environ[i]
		if not env.startswith("SLURM"):
			continue
		env_split = env.split("=")
		if len(env_split) != 2:
			continue
		slurm.slurm_env_array_overwrite(dest_env, env_split[0], env_split[1])

def parse_time(time_str, int past):
	"""parse sbatch time_begin format

	Convert string to equivalent time_t value
	 input formats:
	   today or tomorrow
	   midnight, noon, teatime (4PM)
	   HH:MM[:SS] [AM|PM]
	   MMDD[YY] or MM/DD[/YY] or MM.DD[.YY]
	   MM/DD[/YY]-HH:MM[:SS]
	   YYYY-MM-DD[THH:MM[:SS]]

	   now + count [minutes | hours | days | weeks]

	 Invalid input results in message to stderr and return value of zero
	 NOTE: by default this will look into the future for the next time.
	 if you want to look in the past set the past flag.
	"""
	if time_str.startswith("uts"):
		uts = time_str[3:]
		if not uts.isdigit():
			return -1
		uts = int(uts)
		if uts < 1000000:
			return -1
		return uts

	time_dict = { "year":-1, "month":-1, "mday":-1, "hour":-1, "min":-1, "sec":0 }
	now = datetime.now()
	pos = 0
	while pos < len(time_str):
		curr_char = time_str[pos]
		substr = time_str[pos:]
		if curr_char.isspace() or curr_char == '-' or curr_char == 'T':
			continue
		if substr.startswith("today"):
			time_dict["year"] = now.year
			time_dict["month"] = now.month
			time_dict["mday"] = now.day
			pos += 5
			continue
		elif substr.startswith("tomorrow"):
			tomorrow = now + timedelta(days=1)
			time_dict["year"] = tomorrow.year
			time_dict["month"] = tomorrow.month
			time_dict["mday"] = tomorrow.day
			pos += 8
			continue
		elif substr.startswith("midnight"):
			time_dict["hour"] = 0
			time_dict["min"] = 0
			time_dict["sec"] = 0
			pos += 8
			continue
		elif substr.startswith("noon"):
			time_dict["hour"] = 12
			time_dict["min"] = 0
			time_dict["sec"] = 0
			pos += 4
			continue
		elif substr.startswith("teatime"):
			time_dict["hour"] = 16
			time_dict["min"] = 0
			time_dict["sec"] = 0
			pos += 7
			continue
		elif substr.startswith("now"):
			seconds = 0
			pos += 3
			if len(substr.strip()) > 4:
				if substr[3] != '+':
					return -1
				pos += 1
				now_sub = substr[4:]
				num = ''
				for c in now_sub:
					if c.isdigit():
						num += c
					else:
						break
				if len(num) == 0:
					return -1
				pos += len(num)
				unit_sub = now_sub[len(num)]
				num = int(num)
				if unit_sub.startswith("minute"):
					pos += 6
					seconds = num * 60
				elif unit_sub.startswith("minutes"):
					pos += 7
					seconds = num * 60
				elif unit_sub.startswith("hour"):
					pos += 4
					seconds = num * 60 * 60
				elif unit_sub.startswith("hours"):
					pos += 5
					seconds = num * 60 * 60
				elif unit_sub.startswith("day"):
					pos += 3
					seconds = num * 60 * 60 * 24
				elif unit_sub.startswith("days"):
					pos += 4
					seconds = num * 60 * 60 * 24
				elif unit_sub.startswith("week"):
					pos += 4
					seconds = num * 60 * 60 * 24 * 7
				elif unit_sub.startswith("weeks"):
					pos += 5
					seconds = num * 60 * 60 * 24 * 7
				else:
					return -1
			later = now + timedelta(seconds=seconds)
			time_dict["year"] = later.year
			time_dict["month"] = later.month
			time_dict["mday"] = later.day
			time_dict["hour"] = later.hour
			time_dict["min"] = later.minute
			time_dict["sec"] = later.second
			continue
		elif substr[0].isdigit():
			end = substr.find(' ')
			pos += end
			dt_str = substr[:end]
			try:
				later = None
				if 'T' in dt_str:
					if dt_str.count(':') == 1:
						later = datetime.strptime(substr, "%Y-%m-%dT%H:%M")
					if dt_str.count(':') == 2:
						later = datetime.strptime(substr, "%Y-%m-%dT%H:%M:%S")
				else:
					if dt_str.count(':') == 1:
						later = datetime.strptime(substr, "%H:%M")
					if dt_str.count(':') == 2:
						later = datetime.strptime(substr, "%H:%M:%S")
				time_dict["year"] = later.year
				time_dict["month"] = later.month
				time_dict["mday"] = later.day
				time_dict["hour"] = later.hour
				time_dict["min"] = later.minute
				time_dict["sec"] = later.second
			except:
				return -1
		else:
			return -1
	if time_dict["hour"] == -1 and time_dict["month"] == -1:
		return 0
	elif time_dict["hour"] == -1 and time_dict["month"] != -1:
		time_dict["hour"] = 0
		time_dict["minute"] = 0
	elif time_dict["hour"] != -1 and time_dict["month"] == -1:
		if past or time_dict["hour"] > now.hour or \
				(time_dict["hour"] == now.hour and time_dict["minute"] > now.minute):
			time_dict["year"] = now.year
			time_dict["month"] = now.month
			time_dict["mday"] = now.day
		else:
			tomorrow = now + timedelta(days=1)
			time_dict["year"] = tomorrow.year
			time_dict["month"] = tomorrow.month
			time_dict["mday"] = tomorrow.day
	if time_dict["year"] == -1:
		if past:
			if time_dict["month"] > now.month:
				time_dict["year"] = now.year - 1
			else:
				time_dict["year"] = now.year - 1
		else:
			time_str = now.year + '-' + time_dict["month"] + '-' + \
					time_dict["mday"] + ' ' + \
					time_dict["hour"] + ':' + time_dict["min"] + ':' + time_dict["sec"]
			tmp_date = datetime.strptime(time_str, "%Y-%m-%d %H:%M:%S")
			if tmp_date > now:
				time_dict["year"] = now.year
			else:
				time_dict["year"] = now.year + 1

	time_str = time_dict["year"] + '-' + time_dict["month"] + '-' + \
			time_dict["mday"] + ' ' + \
			time_dict["hour"] + ':' + time_dict["min"] + ':' + time_dict["sec"]
	try:
		time_array = time.strptime(time_str, "%Y-%m-%d %H:%M:%S")
	except:
		return -1
	return int(time.mktime(time_array))

def parse_script_options(script_body, job_desc):
	def __get_arguments(options):
		res = []
		quote_char = None
		escape_flag = False
		curr_arg = ''
		for c in options:
			if escape_flag:
				escape_flag = False
			elif c == '\\':
				escape_flag = True
			elif quote_char is not None and c == quote_char:
				quote_char = None
			elif c == '\"' or c == '\'':
				quote_char = c
			elif c == '#':
				break
			elif c.isspace() and curr_arg != '':
				res.append(curr_arg)
				curr_arg = ''
			curr_arg += c
		if quote_char is not None:
			return -1
		return res

	slurm_argv = []
	pbs_argv = []
	ignore_pbs = os.getenv('SBATCH_IGNORE_PBS')
	if ignore_pbs is not None:
		try:
			ignore_pbs = int(job_desc.get('ignore-pbs', 0))
		except ValueError:
			return -1, "ignore-pbs option invalid, must be 0/1 which specifies " \
					"ignore any \"#PBS\" options specified in the batch script."

	for line in script_body.splitlines():
		slurm_options = None
		if line.startswith("#SBATCH"):
			slurm_options = line[len("#SBATCH"):].strip()
		elif line.startswith("#SLURM"):
			slurm_options = line[len("#SLURM"):].strip()
		elif ignore_pbs == 0 and line.startswith("#PBS"):
			pbs_options = line[len("#PBS"):].strip()
			args = __get_arguments(pbs_options)
			if args != -1:
				pbs_argv.extend(args)

		if slurm_options is not None:
			args = __get_arguments(slurm_options)
			if args != -1:
				slurm_argv.extend(args)
	if len(slurm_argv) > 0:
		try:
			(opts, args) = getopt(slurm_argv, sbatch_opts, sbatch_long_opts)
		except GetoptError:
			return -1, "parse options in script file error."
		for o, a in opts:
			if not o.startswith("--"):
				if o not in slurm_opt_dict:
					return -1, "parse options in script file error."
				o = slurm_opt_dict(o)

			o = o[2:]
			if o == "--no-requeue":
				job_desc['requeue'] = 0
				continue
			if a == '' or a is None:
				a = 1
			job_desc[o] = a
	if len(pbs_argv) > 0:
		try:
			(opts, args) = getopt(pbs_argv, pbs_opts, pbs_opts_long)
		except GetoptError:
			return -1, "parse options in script file error."
		for o, a in opts:
			if not o.startswith("--"):
				if o not in pbs_opts_dict:
					return -1, "parse options in script file error."
				o = pbs_opts_dict(o)

			o = o[2:]
			o = pbs_slurm_opts_dict[o]
			if o == "variable_list" and a != '' and a is not None:
				if job_desc.get("export", '') != '':
					job_desc["export"] += ','
				job_desc["export"] += a
			elif o == "attributes":
				if a.startswith("umask="):
					job_desc["umask"] = a[len("umask="):]
				elif a.startswith("depend="):
					job_desc["dependency"] = a[len("depend="):]
			if a == '' or a is None:
				a = 1
			job_desc[o] = a


def slurm_submit_batch_job (dict job_options):
	u"""Submit a batch job.

	:param dict job_options: Job desc dict

	:returns: Error code/JobId - -1 for error others for job id
	:rtype: `integer`
	"""
	# submit_response_msg_t**
	cdef int job_id = 0
	cdef slurm.job_desc_msg_t msg_desc
	cdef slurm.submit_response_msg_t *resp

	job_desc = {k:job_options[k] for k in job_options}
	slurm.slurm_init_job_desc_msg(&msg_desc)

	wrap = job_desc.get("wrap", '')
	script = job_desc.get("script", '')
	cdef char *c_argv[100]
	if wrap != '':
			wrap_script = "#!/bin/sh\n"
			wrap_script += "# This script was created by pyslurm sbatch --wrap.\n\n"
			wrap_script += wrap + "\n"
			msg_desc.script = wrap_script
	elif script != '' and os.path.exists(script) and os.path.isfile(script):
		try:
			f = open(script)
		except:
			return -1, "script option invalid, script file read error."
		script_body = f.readall()
		f.close()
		if len(script_body.strip()) == 0:
			return -1, "script option invalid, script file has no content."
		elif not script_body.startswith("#!"):
			return -1, "script option invalid, batch script's first" + \
					"line must start with #! followed by the path" \
					" to an interpreter. For instance: #!/bin/sh"
		elif '\0' in script_body:
			return -1, "script option invalid, script does not allow contain a NULL character."
		elif "\r\n" in script_body:
			return -1, "script option invalid, script contains DOS line breaks (\\r\\n)" \
					"instead of expected UNIX line breaks (\\n)."

		parse_script_options(script_body, job_desc)

		msg_desc.script = script_body

		script_argv = job_desc.get("script-argv", [])
		msg_desc.argc = len(script_argv)
		if msg_desc.argc  > 99:
			return -1, "script has too many args"
		idx = 0
		for idx in range(len(script_argv)):
			c_argv[idx] = script_argv[idx]
		c_argv[idx+1] = NULL
		msg_desc.argv = c_argv
	else:
		return -1, "You must specify a script to excute, by wrap or script option."

	try:
		umask = int(job_desc.get("umask", -1))
	except ValueError:
		return -1, "umask option invalid, must be between 0 and 0777."
	if umask >= 0 and umask <= 0777:
		# TODO: set umask env
		pass

	try:
		job_id = int(job_desc.get("jobid", -1))
	except ValueError:
		return -1, "jobid option invalid, must be integer."
	if job_id != -1:
		msg_desc.job_id = job_id
	gres = job_desc.get("gres", '')
	if gres != '':
		msg_desc.gres = gres
	msg_desc.immediate = 0
	try:
		immediate = int(job_desc.get("immediate", 0))
	except ValueError:
		return -1, "immediate option invalid, must be 0/1"
	if immediate != 0:
		msg_desc.immediate = 1
	msg_desc.reboot = 0
	try:
		reboot = int(job_desc.get("reboot", 0))
	except ValueError:
		return -1, "reboot option invalid, must be 0/1 which " \
				"force the allocated nodes to reboot before starting the job."
	if reboot != 0:
		msg_desc.reboot = 1
	array_inx = job_desc.get("array", '')
	if array_inx != '':
		msg_desc.array_inx = array_inx
	account = job_desc.get("account", '')
	if account != '':
		msg_desc.account = account
	real_time = -1
	begin_time = job_desc.get("begin", '')
	if begin_time != '':
		real_time = parse_time(begin_time)
		if real_time == -1:
			return -1, "begin option invalid, " \
					"can be midnight/noon/teatime(4pm)/" \
					"YYYY-MM-DD[THH:MM[:SS]]/now+count(seconds/minutes/hours/days/weeks)."
		msg_desc.begin_time = real_time
	try:
		hold = int(job_desc.get("hold", 0))
	except ValueError:
		return -1, "hold option invalid, must be 0/1 which specify " \
				"the job is to be submitted in a held state (priority of zero)."
	if hold != 0:
		msg_desc.priority = 0
	try:
		no_kill = int(job_desc.get("no-kill", 0))
	except ValueError:
		return -1, "no-kill option invalid, must be 0/1 which set not automatically " \
				"terminate a job of one of the nodes it has been  allocated  fails."
	if no_kill != 0:
		msg_desc.kill_on_node_fail = 0
	comment = job_desc.get("comment", '')
	if comment != '':
		msg_desc.comment = comment
	dependency = job_desc.get("dependency", '')
	if dependency != '':
		msg_desc.dependency = dependency
	work_dir = job_desc.get("workdir", os.getcwd())
	msg_desc.work_dir = work_dir
	try:
		msg_desc.user_id = int(job_desc.get("uid", os.getuid()))
	except ValueError:
		return -1, "uid option invalid."
	try:
		msg_desc.group_id = int(job_desc.get("gid", os.getgid()))
	except ValueError:
		return -1, "gid option invalid."
	mail_type_str = job_desc.get("mail-type", '')
	mail_type = 0
	if mail_type_str == "BEGIN":
		mail_type = slurm.MAIL_JOB_BEGIN
	elif mail_type_str == "END":
		mail_type = slurm.MAIL_JOB_END
	elif mail_type_str == "FAIL":
		mail_type = slurm.MAIL_JOB_FAIL
	elif mail_type_str == "REQUEUE":
		mail_type = slurm.MAIL_JOB_REQUEUE
	elif mail_type_str == "ALL":
		mail_type = slurm.MAIL_JOB_BEGIN | slurm.MAIL_JOB_END | slurm.MAIL_JOB_FAIL | slurm.MAIL_JOB_REQUEUE
	if mail_type_str != '' and mail_type == 0:
		return -1, "mail-type option invalid, must be BEGIN|END|FAIL|REQUEUE|ALL"
	msg_desc.mail_type = mail_type
	mail_user = job_desc.get("mail-user", '')
	if mail_user != '':
		msg_desc.mail_user = mail_user
	try:
		nice = int(job_desc.get("nice", 0))
	except ValueError:
		return -1, "nice option invalid, must be integer for job priority."
	if nice != 0:
		msg_desc.nice = slurm.NICE_OFFSET + nice
	try:
		requeue = int(job_desc.get("requeue", -1))
	except ValueError:
		return -1, "requeue option invalid, must be 0/1 which specifies " \
				"that the batch job should be requeued after node failure."
	if requeue != -1:
		msg_desc.requeue = requeue
	partition = job_desc.get("partition", '')
	if partition != '':
		msg_desc.partition = partition
	try:
		ntasks = int(job_desc.get("ntasks", -1))
	except ValueError:
		return -1, "ntasks option invalid, must be integer."
	if ntasks > -1:
		msg_desc.num_tasks = ntasks
	try:
		ntasks_per_node = job_desc.get("ntasks-per-node", 0)
	except ValueError:
		return -1, "ntasks-per-node option invalid, must be integer."
	if ntasks_per_node != 0:
		msg_desc.ntasks_per_node = ntasks_per_node
	try:
		min_nodes = job_desc.get("min-nodes", -1)
		max_nodes = job_desc.get("max-nodes", -1)
	except ValueError:
		return -1, "min-nodes and max-nodes option invalid, must be integer."
	if min_nodes != -1:
		msg_desc.min_nodes = min_nodes
		if max_nodes != -1:
			msg_desc.max_nodes = max_nodes
	elif ntasks == 0:
		msg_desc.min_nodes = 0

	try:
		cpus_per_task = job_desc.get("cpus-per-task", -1)
	except ValueError:
		return -1, "cpus-per-task option invalid, must be interger."
	if cpus_per_task > -1:
		msg_desc.cpus_per_task = cpus_per_task

	try:
		overcommit = job_desc.get("overcommit", -1)
	except ValueError:
		return -1, "overcommit option invalid, must be integer for overcommit resources."
	if overcommit > -1:
		msg_desc.overcommit = overcommit
		msg_desc.min_cpus = max(min_nodes, 1)
	elif cpus_per_task > -1:
		msg_desc.min_cpus = ntasks * cpus_per_task
	elif ntasks > -1 and min_nodes == 0:
		msg_desc.min_cpus = 0
	else:
		msg_desc.min_cpus = msg_desc.num_tasks

	std_in = job_desc.get("input", "/dev/null")
	msg_desc.std_in = std_in
	std_outf = job_desc.get("output", '')
	if std_outf != '':
		msg_desc.std_out = std_outf
	std_errf = job_desc.get("error", '')
	if std_errf != '':
		msg_desc.std_err = std_errf
	wckey = job_desc.get("wckey", '')
	if wckey != '':
		msg_desc.wckey = wckey
	licenses = job_desc.get("licenses", '')
	if licenses != '':
		msg_desc.licenses = licenses
	msg_desc.shared = job_desc.get("share", 0)
	qos = job_desc.get("qos", '')
	if qos != '':
		msg_desc.qos = qos
	task_dist = slurm.SLURM_DIST_UNKNOWN
	task_dist_str = job_desc.get("distribution", '')
	lllp_dist = False
	plane_dist = False
	if ':' in task_dist_str:
		lllp_dist = True
	elif '=' in task_dist_str:
		ind = task_dist_str.index('=')
		msg_desc.plane_size = int(task_dist_str[ind+1])
		plane_dist = True
	if lllp_dist:
		if task_dist_str == "cyclic:cyclic":
			task_dist = slurm.SLURM_DIST_CYCLIC_CYCLIC
		elif task_dist_str == "cyclic:block":
			task_dist = slurm.SLURM_DIST_CYCLIC_BLOCK
		elif task_dist_str == "block:block":
			task_dist = slurm.SLURM_DIST_BLOCK_BLOCK
		elif task_dist_str == "block:cyclic":
			task_dist = slurm.SLURM_DIST_BLOCK_CYCLIC
	elif plane_dist:
		if task_dist_str.startswith("plane"):
			task_dist = slurm.SLURM_DIST_PLANE
	else:
		if task_dist_str.startswith("cyclic"):
			task_dist = slurm.SLURM_DIST_CYCLIC
		elif task_dist_str.startswith("block"):
			task_dist = slurm.SLURM_DIST_BLOCK
		elif task_dist_str.startswith("arbitrary") or \
				task_dist_str.startswith("hostfile"):
			task_dist = slurm.SLURM_DIST_ARBITRARY
	if task_dist_str != '' and task_dist == slurm.SLURM_DIST_UNKNOWN:
		return -1, "distribution option invalid, must " \
				"be block|cyclic|arbitrary|plane=<options>[:block|cyclic]"
	msg_desc.task_dist = task_dist
	# all|none|[energy[,|task[,|lustre[,|network]]]]
	msg_desc.profile = slurm.ACCT_GATHER_PROFILE_NOT_SET
	profile = job_desc.get("profile", '')
	if profile == "none":
		msg_desc.profile = slurm.ACCT_GATHER_PROFILE_NONE
	elif profile == "all":
		msg_desc.profile = slurm.ACCT_GATHER_PROFILE_ALL
	else:
		if "energy" in profile:
			msg_desc.profile |= slurm.ACCT_GATHER_PROFILE_ENERGY
		elif "task" in profile:
			msg_desc.profile |= slurm.ACCT_GATHER_PROFILE_TASk
		elif "lustre" in profile:
			msg_desc.profile |= slurm.ACCT_GATHER_PROFILE_LUSTRE
		elif "network" in profile:
			msg_desc.profile |= slurm.ACCT_GATHER_PROFILE_NETWORK

	try:
		time_limit = int(job_desc.get("time", -1))
	except:
		return -1, "time option invalid, must be integer which set a limit " \
				"on the total run time of the job allocation."
	try:
		time_min = int(job_desc.get("time-min", -1))
	except:
		return -1, "time-min option invalid, must be integer which " \
				"set a minimum time limit on the job allocation."
	if time_limit != -1:
		msg_desc.time_limit = time_limit
	if time_min != -1:
		msg_desc.time_min = time_min

	msg_desc.warn_signal = 0
	msg_desc.warn_time = 0
	warn_signal = job_desc.get("signal", '')
	if warn_signal != '':
		signal_sp = warn_signal.split('@')
		signal_str = signal_sp[0].strip()
		if len(signal_sp) > 1:
			time_str = signal_sp[1]
			if not time_str.isdigit():
				return -1, "signal option invalid, must be sig_num>[@<sig_time>], " \
						"sig_num can be signal number or name, sig_time 0~65535 seconds."
			else:
				msg_desc.warn_time = int(time_str)
		else:
			msg_desc.warn_time = 60

		if signal_str.isdigit():
			signal_num = int(signal_str)
			if signal_num < 1 or signal_num > 0x0ffff:
				return -1, "signal option invalid, must be sig_num>[@<sig_time>], " \
						"sig_num can be signal number or name, sig_time 0~65535 seconds."
			msg_desc.warn_signal = signal_num
		else:
			signal_dict = { "HUP": slurm.SIGHUP, "INT": slurm.SIGINT, "QUIT": slurm.SIGQUIT,
					"KILL": slurm.SIGKILL, "TERM": slurm.SIGTERM, "USR1": slurm.SIGUSR1,
					"USR2": slurm.SIGUSR2, "CONT": slurm.SIGCONT }
			if signal_str.startswith("SIG"):
				signal_str = signal_str[3:]
			if signal_str not in signal_dict:
				return -1, "signal option invalid, must be sig_num>[@<sig_time>], " \
						"sig_num can be signal number or name, sig_time 0~65535 seconds."
			else:
				msg_desc.warn_signal = signal_dict[signal_str]

	# Constraint options
	try:
		mincpus = int(job_desc.get("mincpus", -1))
	except ValueError:
		return -1, "mincpus option invalid, must be integer which specify " \
				"a minimum number of logical cpus/processors per node."
	if mincpus > -1:
		msg_desc.pn_min_cpus = mincpus;
	msg_desc.contiguous = 0
	try:
		contiguous = int(job_desc.get("contiguous", 0))
	except ValueError:
		return -1, "contiguous option invalid, must be 0/1 " \
				"for allocated nodes must or not form a contiguous set."
	if contiguous != 0:
		msg_desc.contiguous = 1
	try:
		tmpdisk = int(job_desc.get("tmp", -1))
	except ValueError:
		return -1, "tmp option invalid, must be integer which " \
				"specify a minimum amount of temporary disk space."
	if tmpdisk > -1:
		msg_desc.pn_min_tmp_disk = tmpdisk
	resv = job_desc.get("reservation", '')
	if resv != '':
		msg_desc.reservation = resv
	try:
		realmem = job_desc.get("mem", -1)
	except ValueError:
		return -1, "mem option invalid, must be integer which " \
				"specify the real memory required per node in MegaBytes."
	try:
		mempercpu = job_desc.get("mem-per-cpu", -1)
	except ValueError:
		return -1, "mem-per-cpu option invalid, must be integer which " \
				"specify mimimum memory required per allocated CPU in MegaBytes."
	if realmem > -1:
		msg_desc.pn_min_memory = realmem
	elif mempercpu > -1:
		msg_desc.pn_min_memory = mempercpu | MEM_PER_CPU

	# Affinity/Multi-core options
	try:
		sockets_per_node = job_desc.get("sockets-per-node", -1)
	except ValueError:
		return -1, "sockets-per-node optionin invalid, must be integer " \
				"which restrict node selection to nodes with "\
				"at least the specified number of sockets."
	try:
		cores_per_socket = job_desc.get("cores-per-socket", -1)
	except ValueError:
		return -1, "cores-per-socket option invalid, must be integer."
	try:
		threads_per_core = job_desc.get("threads-per-core", -1)
	except ValueError:
		return -1, "threads-per-core option invalid, must be integer " \
				"which restrict  node selection to nodes with at least " \
				"the specified number of threads per core."
	if sockets_per_node != -1:
		msg_desc.sockets_per_node = sockets_per_node
	if cores_per_socket != -1:
		msg_desc.cores_per_socket = cores_per_socket
	if threads_per_core != -1:
		msg_desc.threads_per_core = threads_per_core
	try:
		ntasks_per_socket = job_desc.get("ntasks-per-socket", -1)
	except ValueError:
		return -1, "ntasks-per-socket option invalid, must be integer which " \
				"request the maximum ntasks be invoked on each socket."
	try:
		ntasks_per_core = job_desc.get("ntasks-per-core", -1)
	except ValueError:
		return -1, "ntasks-per-core option invalid, must be integer which " \
				"request  the  maximum ntasks be invoked on each core."
	if ntasks_per_socket > -1:
		msg_desc.ntasks_per_socket = ntasks_per_socket
	if ntasks_per_core > -1:
		msg_desc.ntasks_per_core = ntasks_per_core
	req_nodes = job_desc.get("nodelist", '')
	if req_nodes != '':
		msg_desc.req_nodes = req_nodes
	exc_nodes = job_desc.get("exclude", '')
	if exc_nodes != '':
		msg_desc.exc_nodes = exc_nodes

	msg_desc.environment = NULL;
	export_env = job_desc.get("export", '')
	try:
		get_user_env = int(job_desc.get("get-user-env", 0))
	except ValueError:
		return -1, "get-user-env option invalid, must be 0/1."
	cdef const char **c_environ = slurm.environ
	cdef const char *merge_env[2]
	merge_env[1] = NULL
	if export_env == '' or export_env == "ALL":
		slurm.slurm_env_array_merge(&msg_desc.environment, c_environ)
	elif export_env == "NONE":
		msg_desc.environment = slurm.slurm_env_array_create()
		slurm_env_array_merge_slurm(&msg_desc.environment, c_environ)
		get_user_env = 0
	else:
		curr_env = export_env
		i = 0
		while i < len(curr_env) and curr_env != '':
			curr_char = curr_env[0]
			if curr_char == "\'" or curr_char == "\"":
				end = curr_env.find(curr_char, 1)
				if end == -1:
					return -1
				i = end + 1
			elif curr_char == ',':
				env = curr_env[:i-1]
				i = 0
				curr_env = curr_env[i:]
				if env.find('=') != -1:
					merge_env[0] = env
					slurm.slurm_env_array_merge(&msg_desc.environment, merge_env)
				else:
					iter_indx = 0
					while c_environ[iter_indx] != NULL:
						sys_env = c_environ[i]
						if sys_env.startswith(env) and sys_env[len(env)] == '=':
							merge_env[0] = sys_env
							slurm.slurm_env_array_merge(&msg_desc.environment, merge_env)
			else:
				i += 1
		slurm_env_array_merge_slurm(&msg_desc.environment, c_environ)
		get_user_env = 0

	if get_user_env >= 0:
		slurm.slurm_env_array_overwrite(&msg_desc.environment,
				"SLURM_GET_USER_ENV", "1")
	if task_dist == slurm.SLURM_DIST_ARBITRARY:
		slurm.slurm_env_array_overwrite(&msg_desc.environment,
				"SLURM_ARBITRARY_NODELIST", msg_desc.req_nodes)

	cdef int env_count = 0
	while msg_desc.environment[env_count] != NULL:
		env_count += 1
	msg_desc.env_size = env_count

	try:
		msg_desc.wait_all_nodes = int(job_desc.get("wait-all-nodes", 0))
	except ValueError:
		return -1, "wait-all-nodes option invalid, must be 0/1 which controls " \
				"when the execution of the command begins."
	switches = job_desc.get("switches", '')
	if switches != '':
		switches_sp = switches.split('@')
		if len(switches_sp) > 1:
			wait4switch = switches_sp[1]
			days = 0
			hours = 0
			minutes = 0
			seconds = 0
			try:
				if '-' in wait4switch:
					days = int(wait4switch.split('-')[0])
					wait4switch = wait4switch.split('-')[1]
				time_sp = wait4switch.split(':')
				if len(time_sp) >= 3:
					hours = int(time_sp[0])
					minutes = int(time_sp[1])
					seconds = int(time_sp[2])
				elif len(time_sp) >= 2:
					if days == 0:
						minutes = int(time_sp[0])
						seconds = int(time_sp[1])
					else:
						hours = int(time_sp[0])
						minutes = int(time_sp[1])
				else:
					if days == 0:
						minutes = int(time_sp[0])
					else:
						hours = int(time_sp[0])
			except:
				return -1, 'switches option invalid, must be count>[@<max-time>], ' \
						'which defines the maximum count of switches desired for ' \
						'the job allocation and optionally the maximum time to wait ' \
						'for that number of switches. max-time can be "minutes", ' \
						'"minutes:seconds", "hours:minutes:seconds",' \
						'"days-hours", "days-hours:minutes" and "days-hours:minutes:seconds"'
			msg_desc.wait4switch = ((days * 24 + hours) * 60 + minutes) * 60 + seconds
		else:
			msg_desc.wait4switch = -1
		req_switch = switches_sp[0].strip()
		if not req_switch.isdigit():
			return -1, 'switches option invalid, must be count>[@<max-time>], ' \
					'which defines the maximum count of switches desired for ' \
					'the job allocation and optionally the maximum time to wait ' \
					'for that number of switches. max-time can be "minutes", ' \
					'"minutes:seconds", "hours:minutes:seconds",' \
					'"days-hours", "days-hours:minutes" and "days-hours:minutes:seconds"'
		msg_desc.req_switch = int(req_switch)

	# TODO: set env, ref: sbatch-_opt_verify
	cpu_bind = int(job_desc.get("cpu_bind", 0))
	cpu_bind_type = int(job_desc.get("cpu_bind_type", 0))
	if cpu_bind != 0:
		msg_desc.cpu_bind = cpu_bind
	if cpu_bind_type != 0:
		msg_desc.cpu_bind_type = cpu_bind_type
	mem_bind = int(job_desc.get("mem_bind", 0))
	mem_bind_type = int(job_desc.get("mem_bind_type", 0))
	if mem_bind != 0:
		msg_desc.mem_bind = mem_bind
	if mem_bind_type != 0:
		msg_desc.mem_bind_type = mem_bind_type
	network = job_desc.get("network", '')
	if network != '':
		msg_desc.network = network

	blrtsimage = job_desc.get("blrtsimage", '')
	linuximage = job_desc.get("linuximage", '')
	mloaderimage = job_desc.get("mloaderimage", '')
	ramdiskimage = job_desc.get("ramdiskimage", '')
	if blrtsimage != '':
		msg_desc.blrtsimage = blrtsimage
	if linuximage != '':
		msg_desc.linuximage = linuximage
	if mloaderimage != '':
		msg_desc.mloaderimage = mloaderimage
	if ramdiskimage != '':
		msg_desc.ramdiskimage = ramdiskimage

	#if (opt.geometry[0] != (uint16_t) NO_VAL) {
	#	int dims = slurmdb_setup_cluster_dims();

	#	for (i=0; i<dims; i++)
	#		desc->geometry[i] = opt.geometry[i];
	#}
	#memcpy(desc->conn_type, opt.conn_type, sizeof(desc->conn_type));

	job_name = job_desc.get("job_name", '')
	if job_name != '':
		msg_desc.name = job_name
	elif script != '':
		msg_desc.name = script
	else:
		msg_desc.name = wrap

	open_mode = job_desc.get("open-mode", '')
	if open_mode != "append":
		msg_desc.open_mode = slurm.OPEN_MODE_APPEND
	elif open_mode != "truncate":
		msg_desc.open_mode = slurm.OPEN_MODE_TRUNCATE
	acctg_freq = job_desc.get("acctg-freq", '')
	if acctg_freq != '':
		msg_desc.acctg_freq = acctg_freq

	ckpt_dir = job_desc.get("ckpt-dir", os.getcwd())
	msg_desc.ckpt_dir = ckpt_dir
	msg_desc.ckpt_interval = job_desc.get("ckpt_interval", 0)

	#if (opt.spank_job_env_size) { /*char **/
	#	desc->spank_job_env      = opt.spank_job_env;
	#	desc->spank_job_env_size = opt.spank_job_env_size; /*u32*/
	#}

	# TODO: slusters support, set working_cluster_rec env
	clusters = job_desc.get("clusters", '')
	if clusters != '':
		clusters_list = slurm.slurmdb_get_info_cluster(clusters)

	retries = 0
	while slurm.slurm_submit_batch_job(&msg_desc, &resp) < 0:
		if slurm.errno == slurm.ESLURM_ERROR_ON_DESC_TO_RECORD_COPY:
			msg = "Slurm job queue full, sleeping and retrying."
		elif slurm.errno == slurm.ESLURM_NODES_BUSY:
			msg = "Job step creation temporarily disabled, retrying."
		elif slurm.errno == slurm.EAGAIN:
			msg = "Slurm temporarily unable to accept job, sleeping and retrying."
		else:
			msg = None

		if msg is None:
			return -1, "submit job error."
		if retries >= 15:
			return -1, msg
		retries += 1
		time.sleep(retries)

	job_id = resp.job_id
	slurm.slurm_free_submit_response_response_msg(resp)

	return job_id, "ok"


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
	:param string Msg: Message to send to job

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
	:rtype: `time_t`
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
	cdef int errCode = slurm.slurm_checkpoint_vacate(JobID, JobStep, MaxWait, ImageDir)

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
		self._ShowFlags = 0
		self._JobDict = {}

	def __dealloc__(self):
		self.__destroy()

	cpdef __destroy(self):

		u"""Free the slurm job memory allocated by load method. 
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

	def find_id(self, int jobID=0):

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
			elif errCode == 1900: # NO CHANGE IN DATA
				return 1900
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

		cdef:
			int i
			uint16_t retval16
			dict Jobs = {}, Job_dict = {}

		if self._job_ptr is not NULL:

			for i from 0 <= i < self._job_ptr.record_count:

				self._record = self._job_ptr.job_array[i]
				job_id = self._job_ptr.job_array[i].job_id

				Job_dict[u'account'] = slurm.stringOrNone(self._record.account, '')
				Job_dict[u'alloc_node'] = slurm.stringOrNone(self._record.alloc_node, '')
				Job_dict[u'alloc_sid'] = self._record.alloc_sid
				Job_dict[u'assoc_id'] = self._record.assoc_id
				Job_dict[u'array_job_id'] = self._record.array_job_id
				Job_dict[u'array_task_id'] = self._record.array_task_id
				Job_dict[u'batch_flag'] = self._record.batch_flag
				Job_dict[u'batch_host'] = slurm.stringOrNone(self._record.batch_host, '')
				Job_dict[u'batch_script'] = slurm.stringOrNone(self._record.batch_script, '')
				Job_dict[u'command'] = slurm.stringOrNone(self._record.command, '')
				Job_dict[u'comment'] = slurm.stringOrNone(self._record.comment, '')
				Job_dict[u'contiguous'] = bool(self._record.contiguous)
				Job_dict[u'cpus_per_task'] = self._record.cpus_per_task
				Job_dict[u'dependency'] = slurm.stringOrNone(self._record.dependency, '')
				Job_dict[u'derived_ec'] = self._record.derived_ec
				Job_dict[u'eligible_time'] = self._record.eligible_time
				Job_dict[u'end_time'] = self._record.end_time

				Job_dict[u'exc_nodes'] = slurm.listOrNone(self._record.exc_nodes, ',')

				Job_dict[u'exit_code'] = self._record.exit_code
				Job_dict[u'features'] = slurm.listOrNone(self._record.features, ',')
				Job_dict[u'gres'] = slurm.listOrNone(self._record.gres, ',')

				Job_dict[u'group_id'] = self._record.group_id
				Job_dict[u'job_state'] = slurm.slurm_job_state_string(self._record.job_state)
				Job_dict[u'licenses'] = __get_licenses(self._record.licenses)
				Job_dict[u'max_cpus'] = self._record.max_cpus
				Job_dict[u'max_nodes'] = self._record.max_nodes
				Job_dict[u'boards_per_node'] = self._record.boards_per_node
				Job_dict[u'sockets_per_board'] = self._record.sockets_per_board
				Job_dict[u'sockets_per_node'] = self._record.sockets_per_node
				Job_dict[u'cores_per_socket'] = self._record.cores_per_socket
				Job_dict[u'threads_per_core'] = self._record.threads_per_core
				Job_dict[u'name'] = slurm.stringOrNone(self._record.name, '')
				Job_dict[u'network'] = slurm.stringOrNone(self._record.network, '')
				Job_dict[u'nodes'] = slurm.stringOrNone(self._record.nodes, '')
				Job_dict[u'nice'] = self._record.nice

				#if self._record.node_inx[0] != -1:
				#	for x from 0 <= x < self._record.num_nodes

				Job_dict[u'ntasks_per_core'] = self._record.ntasks_per_core
				Job_dict[u'ntasks_per_node'] = self._record.ntasks_per_node
				Job_dict[u'ntasks_per_socket'] = self._record.ntasks_per_socket
				Job_dict[u'num_nodes'] = self._record.num_nodes
				Job_dict[u'num_cpus'] = self._record.num_cpus
				Job_dict[u'partition'] = self._record.partition
				Job_dict[u'pn_min_memory'] = self._record.pn_min_memory
				Job_dict[u'pn_min_cpus'] = self._record.pn_min_cpus
				Job_dict[u'pn_min_tmp_disk'] = self._record.pn_min_tmp_disk
				Job_dict[u'pre_sus_time'] = self._record.pre_sus_time
				Job_dict[u'priority'] = self._record.priority
				Job_dict[u'profile'] = self._record.profile
				Job_dict[u'qos'] = slurm.stringOrNone(self._record.qos, '')
				Job_dict[u'req_nodes'] = slurm.listOrNone(self._record.req_nodes, ',')
				Job_dict[u'req_switch'] = self._record.req_switch
				Job_dict[u'requeue'] = bool(self._record.requeue)
				Job_dict[u'resize_time'] = self._record.resize_time
				Job_dict[u'restart_cnt'] = self._record.restart_cnt
				Job_dict[u'resv_name'] = slurm.stringOrNone(self._record.resv_name, '')

				Job_dict[u'ionodes'] = self.__get_select_jobinfo(SELECT_JOBDATA_IONODES)
				Job_dict[u'block_id'] = self.__get_select_jobinfo(SELECT_JOBDATA_BLOCK_ID)
				Job_dict[u'blrts_image'] = self.__get_select_jobinfo(SELECT_JOBDATA_BLRTS_IMAGE)
				Job_dict[u'linux_image'] = self.__get_select_jobinfo(SELECT_JOBDATA_LINUX_IMAGE)
				Job_dict[u'mloader_image'] = self.__get_select_jobinfo(SELECT_JOBDATA_MLOADER_IMAGE)
				Job_dict[u'ramdisk_image'] = self.__get_select_jobinfo(SELECT_JOBDATA_RAMDISK_IMAGE)
				Job_dict[u'cnode_cnt'] = self.__get_select_jobinfo(SELECT_JOBDATA_NODE_CNT)
				Job_dict[u'resv_id'] = self.__get_select_jobinfo(SELECT_JOBDATA_RESV_ID)
				Job_dict[u'rotate'] = bool(self.__get_select_jobinfo(SELECT_JOBDATA_ROTATE))

				Job_dict[u'conn_type'] = slurm.slurm_conn_type_string(self.__get_select_jobinfo(SELECT_JOBDATA_CONN_TYPE))
				Job_dict[u'altered'] = self.__get_select_jobinfo(SELECT_JOBDATA_ALTERED)
				Job_dict[u'reboot'] = self.__get_select_jobinfo(SELECT_JOBDATA_REBOOT)

				Job_dict[u'cpus_allocated'] = {}
				if Job_dict[u'nodes']:
					for node_name in Job_dict[u'nodes'].split(","):
						Job_dict[u'cpus_allocated'][node_name] = self.__cpus_allocated_on_node(node_name)

				Job_dict[u'shared'] = self._record.shared
				Job_dict[u'show_flags'] = self._record.show_flags
				Job_dict[u'start_time'] = self._record.start_time
				Job_dict[u'state_desc'] = slurm.stringOrNone(self._record.state_desc, '')
				Job_dict[u'state_reason'] = slurm.slurm_job_reason_string(self._record.state_reason)
				Job_dict[u'submit_time'] = self._record.submit_time
				Job_dict[u'suspend_time'] = self._record.suspend_time
				Job_dict[u'time_limit'] = self._record.time_limit
				Job_dict[u'time_min'] = self._record.time_min
				Job_dict[u'user_id'] = self._record.user_id
				Job_dict[u'preempt_time'] = self._record.preempt_time
				Job_dict[u'wait4switch'] = self._record.wait4switch
				Job_dict[u'wckey'] = slurm.stringOrNone(self._record.wckey, '')
				Job_dict[u'work_dir'] = slurm.stringOrNone(self._record.work_dir, '')

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
			uint8_t retval8 = 0
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

		if dataType == SELECT_JOBDATA_CONFIRMED:
			retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &retval8)
			if retval == 0:
				return retval8

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
			return None

		if dataType == SELECT_JOBDATA_PTR: # data-> select_jobinfo_t *jobinfo
			retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &tmp_ptr)
			if retval == 0:
				# populate a dictonary ?
				pass

		return -1

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

		slurm.slurm_print_job_info_msg(slurm.stdout, self._job_ptr, oneLiner)

def slurm_pid2jobid(uint32_t JobPID=0):

	u"""Get the slurm job id from a process id.

	:param int JobPID: Job process id

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

	return JobID

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
			int errCode = 0, apiError = 0

		if self._Node_ptr is not NULL:

			errCode = slurm.slurm_load_node(self._Node_ptr.last_update, &new_node_info_ptr, self._ShowFlags)
			if errCode == 0:	# SLURM_SUCCESS
				slurm.slurm_free_node_info_msg(self._Node_ptr)
			elif slurm.slurm_get_errno() == 1900:	# SLURM_NO_CHANGE_IN_DATA (1900)
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
			int i, total_used, cpus_per_node, cpus
			uint16_t alloc_cpus, err_cpus
			uint32_t tmp_disk, node_scaling
			time_t last_update
			char* test
			dict Hosts = {}, Host_dict

		if self._Node_ptr is NULL:
			return Hosts

		node_scaling = self._Node_ptr.node_scaling
		last_update  = self._Node_ptr.last_update

		for i from 0 <= i < self._Node_ptr.record_count:

			self._record = self._Node_ptr.node_array[i]

			Host_dict = {}
			alloc_cpus = err_cpus = total_used = 0
			cpus_per_node = 1

			name = self._record.name
			node_state = self._record.node_state
			
			Host_dict['arch'] = slurm.stringOrNone(self._record.arch, '')
			Host_dict['boards'] = self._record.boards
			Host_dict['boot_time'] = self._record.boot_time
			Host_dict['cores'] = self._record.cores
			cpus = self._record.cpus
			Host_dict['cpus'] = cpus
			Host_dict['features'] = slurm.listOrNone(self._record.features, '')
			Host_dict['gres'] = slurm.listOrNone(self._record.gres, '')
			Host_dict['cpu_load'] = self._record.cpu_load
			Host_dict['name'] = slurm.stringOrNone(self._record.name, '')
			Host_dict['node_addr'] = slurm.stringOrNone(self._record.node_addr, '')
			Host_dict['node_hostname'] = slurm.stringOrNone(self._record.node_hostname, '')
			Host_dict['node_state'] = get_node_state(node_state)
			Host_dict['os'] = slurm.stringOrNone(self._record.os, '')
			Host_dict['real_memory'] = self._record.real_memory
			Host_dict['reason'] = slurm.stringOrNone(self._record.reason, '')
			Host_dict['reason_time'] = self._record.reason_time
			Host_dict['reason_uid'] = self._record.reason_uid
			Host_dict['slurmd_start_time'] = self._record.slurmd_start_time
			Host_dict['sockets'] = self._record.sockets
			Host_dict['threads'] = self._record.threads
			Host_dict['tmp_disk'] = self._record.tmp_disk
			Host_dict['weight'] = self._record.weight

			#
			# Energy statistics
			#

			Host_dict['energy'] = {}
			Host_dict['energy']['base_watts'] = self._record.energy.base_watts
			Host_dict['energy']['current_watts'] = self._record.energy.current_watts
			Host_dict['energy']['consumed_energy'] = self._record.energy.consumed_energy
			Host_dict['energy']['base_consumed_energy'] = self._record.energy.base_consumed_energy
			Host_dict['energy']['previous_consumed_energy'] = self._record.energy.previous_consumed_energy

			#
			# External Sensors
			#

			Host_dict['sensors'] = {}
			Host_dict['sensors']['consumed_energy'] = self._record.ext_sensors.consumed_energy
			Host_dict['sensors']['temperature'] = self._record.ext_sensors.temperature
			Host_dict['sensors']['energy_update_time'] = self._record.ext_sensors.energy_update_time
			Host_dict['sensors']['current_watts'] = self._record.ext_sensors.current_watts

			#
			# NEED TO DO MORE WORK HERE ! SUCH AS NODE STATES AND CLUSTER/BG DETECTION
			#

			if self._Node_ptr.node_array[i].select_nodeinfo is not NULL:

				alloc_cpus = self.__get_select_nodeinfo(SELECT_NODEDATA_SUBCNT, NODE_STATE_ALLOCATED)

				#if (cluster_flags & CLUSTER_FLAG_BG)
				#if not alloc_cpus and (IS_NODE_ALLOCATED(node_state) or IS_NODE_COMPLETING(node_state)):
				#	alloc_cpus = Host_dict['cpus']
				#else:
				#	alloc_cpus *= cpus_per_node
				cpus -= alloc_cpus

				err_cpus = self.__get_select_nodeinfo(SELECT_NODEDATA_SUBCNT, node_state)

				#if (cluster_flags & CLUSTER_FLAG_BG):
				#if 1:
				#	err_cpus *= cpus_per_node
				total_used -= err_cpus

				#test = self.__get_select_nodeinfo(SELECT_NODEDATA_STR, node_state)
				#if rc:
				#	print "%s" % test

			Host_dict['err_cpus'] = err_cpus
			Host_dict['idle_cpus'] = cpus
			Host_dict['alloc_cpus'] = alloc_cpus

			Hosts[u'%s' % name] = Host_dict

		self._NodeDict = Hosts

	cpdef __get_select_nodeinfo(self, uint32_t dataType, uint32_t State):

		u"""
			WORK IN PROGRESS
		"""

		cdef:
			slurm.dynamic_plugin_data_t *nodeinfo = <slurm.dynamic_plugin_data_t*>self._record.select_nodeinfo
			slurm.select_nodeinfo_t *tmp_ptr
			slurm.bitstr_t *tmp_bitmap = NULL
			int retval = 0, length = 0
			uint16_t retval16 = 0
			char *retvalStr
			char *str
			char *tmp_str = ''
			dict Host_dict = {}

		if nodeinfo == NULL:
			return

		if dataType == SELECT_NODEDATA_SUBCNT or dataType == SELECT_NODEDATA_SUBGRP_SIZE or dataType == SELECT_NODEDATA_BITMAP_SIZE:

			retval = slurm.slurm_get_select_nodeinfo(nodeinfo, dataType, State, &retval16)
			if retval == 0:
				return retval16
			return retval

		if dataType == SELECT_NODEDATA_BITMAP:

			# data-> bitstr_t * needs to be freed with FREE_NULL_BITMAP

			#retval = slurm.slurm_get_select_nodeinfo(nodeinfo, dataType, State, &tmp_bitmap)
			#if retval == 0:
			#	Host_dict['bitstr'] = tmp_bitmap
			return None

		elif dataType == SELECT_NODEDATA_STR:

			# data-> char *  needs to be freed with xfree

			retval = slurm.slurm_get_select_nodeinfo(nodeinfo, dataType, State, &tmp_str)
			if retval == 0:
				length = strlen(tmp_str)+1
				retvalStr = <char*>malloc(length)
				memcpy(tmp_str, retvalStr, length)
				slurm.xfree(tmp_str)
				return retvalStr
			return None

		# data-> select_jobinfo_t *jobinfo

		if dataType == SELECT_NODEDATA_PTR:
			retval = slurm.slurm_get_select_nodeinfo(nodeinfo, dataType, State, &tmp_ptr)
			if retval == 0:
				# opaque data as dict 
				pass

		return

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
		self.JobID = 4294967294		# 0xfffffffe
		self.StepID = 4294967294	# 0xfffffffe
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
			dict Steps = {}, StepDict
			int i
			uint16_t ShowFlags = self._ShowFlags ^ SHOW_ALL
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
				Step_dict[u'user_id'] = job_step_info_ptr.job_steps[i].user_id
				Step_dict[u'num_cpus'] = job_step_info_ptr.job_steps[i].num_cpus
				Step_dict[u'num_tasks'] = job_step_info_ptr.job_steps[i].num_tasks
				Step_dict[u'partition'] = job_step_info_ptr.job_steps[i].partition
				Step_dict[u'start_time'] = job_step_info_ptr.job_steps[i].start_time
				Step_dict[u'run_time'] = job_step_info_ptr.job_steps[i].run_time
				Step_dict[u'resv_ports'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].resv_ports, '')
				Step_dict[u'nodes'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].nodes, '')
				Step_dict[u'name'] = job_step_info_ptr.job_steps[i].name
				Step_dict[u'network'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].network, '')
				Step_dict[u'ckpt_dir'] = job_step_info_ptr.job_steps[i].ckpt_dir
				Step_dict[u'ckpt_interval'] = job_step_info_ptr.job_steps[i].ckpt_interval
				Step_dict[u'gres'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].gres, '')
				Step_dict[u'time_limit'] = job_step_info_ptr.job_steps[i].time_limit

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
			
			Layout[u'node_cnt'] = Node_cnt
			Layout[u'front_end'] = slurm.stringOrNone(old_job_step_ptr.front_end, '')
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

	u"""Wrapper around slurm hostlist functions.
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

	cpdef uniq(self):

		if self.hl is not NULL:
			slurm.slurm_hostlist_uniq(self.hl)

	cpdef int find(self, char* Host=''):

		# convert python byte string to C char
		cdef int errCode = -1
		if self.hl is not NULL:
			if Host is not NULL:
				errCode = slurm.slurm_hostlist_find(self.hl, Host)
		return errCode

	cpdef int push(self, char *Hosts):

		# convert python byte string to C char
		cdef int errCode = -1
		if self.hl is not NULL:
			if Hosts is not NULL:
				errCode = slurm.slurm_hostlist_push_host(self.hl, Hosts)
		return errCode

	cpdef pop(self):

		# convert C char to python byte string
		cdef char *host = ''

		if self.hl is not NULL:
			host = slurm.slurm_hostlist_shift(self.hl)
		return host

	cpdef get(self):
		return self.__get()

	cpdef __get(self):

		cdef:
			char *hostlist = NULL
			char *newlist  = ''

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
			char* JobId
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

	cpdef dict get(self):

		u"""Get the information on slurm triggers.

		:returns: Where key is the trigger ID
		:rtype: `dict`
		"""

		cdef:
			slurm.trigger_info_msg_t *trigger_get = NULL
			int i = 0, apiError = 0
			dict Triggers = {}, Trigger_dict
			int errCode = slurm.slurm_get_triggers(&trigger_get)

		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

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
			int apiError = 0, errCode = 0

		memset(&trigger_clear, 0, sizeof(slurm.trigger_info_t))

		if TriggerID != -1:
			trigger_clear.trig_id = TriggerID
		if UserID != -1:
			trigger_clear.user_id = UserID

		if len(ID) != 0:
			trigger_clear.res_type = TRIGGER_RES_TYPE_JOB  #1 
			memcpy(tmp_c, ID, 128)
			trigger_clear.res_id = tmp_c

		errCode = slurm.slurm_clear_trigger(&trigger_clear)
		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

		return errCode

	cpdef int pull(self, uint32_t TriggerID=0, uint32_t UserID=0, char* ID='') except? -1:

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
			int apiError = 0, errCode = 0

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

	u"""Class to access/update slurm reservation Information. 
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

		u"""Load slurm reservation data. 
		"""

		self.__load()

	cpdef int __load(self) except? -1:

		u"""Load slurm reservation information.
		"""

		cdef:
			slurm.reserve_info_msg_t *new_reserve_info_ptr = NULL
			slurm.time_t last_time = <slurm.time_t>NULL
			int apiError = 0, errCode = -1

		if self._Res_ptr is not NULL:
			errCode = slurm.slurm_load_reservations(self._Res_ptr.last_update, &new_reserve_info_ptr)
			if errCode == 0:	# SLURM_SUCCESS
				slurm.slurm_free_reservation_info_msg(self._Res_ptr)
			elif errCode == 1900:	# SLURM_NO_CHANGE_IN_DATA (1900)
				return 1900
		else:
			last_time = <time_t>NULL
			new_reserve_info_ptr = NULL
			errCode = slurm.slurm_load_reservations(last_time, &new_reserve_info_ptr)

		if errCode == 0:
			self._Res_ptr = new_reserve_info_ptr
			self._lastUpdate = self._Res_ptr.last_update
		else:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

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

		self.__load()
		self.__get()

		return self._ResDict

	cpdef __get(self):

		cdef:
			int i
			dict Reservations = {}, Res_dict

		if self._Res_ptr is not NULL:

			for i from 0 <= i < self._Res_ptr.record_count:

				Res_dict = {}

				name = self._Res_ptr.reservation_array[i].name
				Res_dict[u'accounts'] = slurm.listOrNone(self._Res_ptr.reservation_array[i].accounts, ',')
				Res_dict[u'end_time'] = self._Res_ptr.reservation_array[i].end_time
				Res_dict[u'features'] = slurm.listOrNone(self._Res_ptr.reservation_array[i].features, ',')
				Res_dict[u'flags'] = slurm.slurm_reservation_flags_string(self._Res_ptr.reservation_array[i].flags)
				Res_dict[u'licenses'] = __get_licenses(self._Res_ptr.reservation_array[i].licenses)
				Res_dict[u'node_cnt'] = self._Res_ptr.reservation_array[i].node_cnt
				Res_dict[u'core_cnt'] = self._Res_ptr.reservation_array[i].core_cnt
				Res_dict[u'node_list'] = slurm.stringOrNone(self._Res_ptr.reservation_array[i].node_list, ',')
				Res_dict[u'partition'] = slurm.stringOrNone(self._Res_ptr.reservation_array[i].partition, '')
				Res_dict[u'start_time'] = self._Res_ptr.reservation_array[i].start_time
				Res_dict[u'users'] = slurm.listOrNone(self._Res_ptr.reservation_array[i].users, ',')

				Reservations[name] = Res_dict

		self._ResDict = Reservations

	def create(self, dict reservation_dict={}):

		u"""Create slurm reservation.
		"""

		a = slurm_create_reservation(reservation_dict)

		return a

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
		int int_value = 0, free_users = 0, free_accounts = 0
		unsigned int uint32_value, time_value

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

	resid = slurm.slurm_create_reservation(&resv_msg)

	resID = ''
	if resid is not NULL:
		resID = resid
		free(resid)

	if free_users == 1:
		slurm.xfree(resv_msg.users)
	if free_accounts == 1:
		slurm.xfree(resv_msg.accounts)

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

	cpdef int __load(self):

		cdef:
			slurm.block_info_msg_t *new_block_info_ptr = NULL
			time_t last_time = <time_t>NULL
			int errCode = 0

		if self._block_ptr is not NULL:

			errCode = slurm.slurm_load_block_info(self._block_ptr.last_update, &new_block_info_ptr, self._ShowFlags)
			if errCode == 0:	# SLURM_SUCCESS
				slurm.slurm_free_block_info_msg(self._block_ptr)
			elif slurm.slurm_get_errno() == 1900:	# SLURM_NO_CHANGE_IN_DATA = 1900
				errCode = 0
				new_block_info_ptr = self._block_ptr
		else:
			last_time = <time_t>NULL
			errCode = slurm.slurm_load_block_info(last_time, &new_block_info_ptr, self._ShowFlags)

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
				Block_dict[u'cnode_cnt'] = self._block_ptr.block_array[i].cnode_cnt
				Block_dict[u'cnode_err_cnt'] = self._block_ptr.block_array[i].cnode_err_cnt
				Block_dict[u'conn_type'] = get_conn_type_string(self._block_ptr.block_array[i].conn_type[HIGHEST_DIMENSIONS])
				Block_dict[u'ionode_str'] = slurm.listOrNone(self._block_ptr.block_array[i].ionode_str, ',')
				Block_dict[u'linuximage'] = slurm.stringOrNone(self._block_ptr.block_array[i].linuximage, '')
				Block_dict[u'mloaderimage'] = slurm.stringOrNone(self._block_ptr.block_array[i].mloaderimage, '')
				Block_dict[u'mp_str'] = slurm.stringOrNone(self._block_ptr.block_array[i].mp_str, '')
				Block_dict[u'node_use'] = get_node_use(self._block_ptr.block_array[i].node_use)
				Block_dict[u'ramdiskimage'] = slurm.stringOrNone(self._block_ptr.block_array[i].ramdiskimage, '')
				Block_dict[u'reason'] = slurm.stringOrNone(self._block_ptr.block_array[i].reason, '')
				Block_dict[u'state'] = get_bg_block_state_string(self._block_ptr.block_array[i].state)

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

		cdef int i, dictlen
		cdef slurm.update_block_msg_t block_msg

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

	cpdef int __load(self) except ? -1:
		
		u"""Load slurm topology.
		"""

		cdef int errCode = 0, apiError

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
# Statistics 
#

cdef class statistics:

	cdef:
		slurm.stats_info_request_msg_t _req
		slurm.stats_info_response_msg_t *_buf
		dict _StatsDict

	def __cinit__(self):
		self._req.command_id = 1
		self._buf = NULL 
		self._StatsDict = {}

	def __dealloc__(self):
		self.__free()

	cpdef __free(self):
		pass

	def load(self):
		return self.__load()

	cpdef int __load(self) except ? -1:

		u"""
		#extern int  slurm_get_statistics (stats_info_response_msg_t **buf, stats_info_request_msg_t *req)
		"""

		cdef int errCode = slurm.slurm_get_statistics(&self._buf, <slurm.stats_info_request_msg_t*>&self._req)
		if errCode != 0:
			apiError = slurm.slurm_get_errno()
			raise ValueError(slurm.slurm_strerror(apiError), apiError)

	def get(self):

		u"""Get slurm statistics information.

		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return self._StatsDict

	cpdef __get(self):

		cdef:
			dict Stats_dict = {}, tmp = {}
			int i = 0

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

		self._StatsDict = Stats_dict

	def reset(self):
		return self.__reset()

	cpdef int __reset(self) except ? -1:

		"""
		#extern int slurm_reset_statistics (stats_info_request_msg_t *req)
		"""

		self._req.command_id = 0	# STAT_COMMAND_RESET

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
		#cdef slurm.front_end_info_t _record
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

		#cdef slurm.front_end_info_msg_t *new_FrontEndNode_ptr = NULL
		cdef:
			time_t last_time = <time_t>NULL
			int apiError = 0, errCode = 0

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

		u"""Get slurm front end node information.

		:returns: Dictionary whose key is the Topology ID
		:rtype: `dict`
		"""

		self.__load()
		self.__get()

		return self._FrontEndDict

	cpdef __get(self):

		cdef:
			int i
			dict FENode = {}, FE_dict

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

				FENode[name] = FE_dict

		self._FrontEndDict = FENode

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

cdef inline dict __get_licenses(char *licenses=''):

	u"""Returns a dict of licenses from the slurm license string.

	:param string licenses: String containing license information

	:returns: Dictionary of licenses and associated value.
	:rtype: `dict`
	"""

	if (licenses is NULL):
		return {}

	cdef:
		int i = 0
		char *split_char = ':'
		dict licDict = {}
		list alist = slurm.listOrNone(licenses, ',')
		int listLen = len(alist)

	if alist:
		if '*' in licenses:
			split_char = '*'
		for i in range(listLen):
			key, value = alist[i].split(split_char)
			licDict[u"%s" % key] = value

	return licDict

def get_connection_type(int inx=0):

	u"""Returns a tuple that represents the slurm block connection type.

	:param int ResType: Slurm block connection type

		- SELECT_MESH                 1
		- SELECT_TORUS                2
		- SELECT_NAV                  3
		- SELECT_SMALL                4
		- SELECT_HTC_S                5
		- SELECT_HTC_D                6
		- SELECT_HTC_V                7
		- SELECT_HTC_L                8

	:returns: Block connection value
	:rtype: `integer`
	:returns: Block connection string
	:rtype: `string`
	"""

	return slurm.slurm_conn_type_string(inx)

def get_node_use(int inx=0):

	u"""Returns a tuple that represents the block node mode.

	:param int ResType: Slurm block node usage

		- SELECT_COPROCESSOR_MODE         1
		- SELECT_VIRTUAL_NODE_MODE        2
		- SELECT_NAV_MODE                 3

	:returns: Block node usage value
	:rtype: `integer`
	:returns: Block node usage string
	:rtype: `string`
	"""

	return __get_node_use(inx)

cdef inline object __get_node_use(uint16_t NodeType=0):

	return slurm.slurm_node_state_string(NodeType)

def get_trigger_res_type(uint16_t inx=0):

	u"""Returns a tuple that represents the slurm trigger res type.

	:param int ResType: Slurm trigger res state

		- TRIGGER_RES_TYPE_JOB            1
		- TRIGGER_RES_TYPE_NODE           2
		- TRIGGER_RES_TYPE_SLURMCTLD      3
		- TRIGGER_RES_TYPE_SLURMDBD       4
		- TRIGGER_RES_TYPE_DATABASE       5
		- TRIGGER_RES_TYPE_FRONT_END      6

	:returns: Trigger reservation state value
	:rtype: `integer`
	:returns:  Trigger reservation state string
	:rtype: `string`
	"""

	return __get_trigger_res_type(inx)

cdef inline object __get_trigger_res_type(uint16_t ResType=0):

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

def get_trigger_type(uint32_t inx=0):

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

	:returns: Trigger state value
	:rtype: `integer`
	:returns: Trigger state string
	:rtype: `string`
	"""

	return __get_trigger_type(inx)

cdef inline object __get_trigger_type(uint32_t TriggerType=0):

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

def get_res_state(uint16_t inx=0):

	u"""Returns a tuple that represents the state of the slurm reservation.

	:param int flags: Slurm reservation flags

		- RESERVE_FLAG_MAINT              0x0001
		- RESERVE_FLAG_NO_MAINT           0x0002
		- RESERVE_FLAG_DAILY              0x0004
		- RESERVE_FLAG_NO_DAILY           0x0008
		- RESERVE_FLAG_WEEKLY             0x0010
		- RESERVE_FLAG_NO_WEEKLY          0x0020
		- RESERVE_FLAG_IGN_JOBS           0x0040
		- RESERVE_FLAG_NO_IGN_JOB         0x0080
		- RESERVE_FLAG_LIC_ONLY           0x0100
		- RESERVE_FLAG_NO_LIC_ONLY        0x0200
		- RESERVE_FLAG_OVERLAP            0x4000
		- RESERVE_FLAG_SPEC_NODES         0x8000

	:returns: Reservation state value
	:rtype: `integer`
	:returns: Reservation state string
	:rtype: `string`
	"""

	try:
		return slurm.slurm_reservation_flags_string(inx)
	except:
		pass

def get_debug_flags(uint32_t inx=0):

	u"""
	Returns a tuple that represents the slurm debug flags.

	:param int flags: Slurm debug flags

		- DEBUG_FLAG_SELECT_TYPE    0x00000001
		- DEBUG_FLAG_STEPS          0x00000002
		- DEBUG_FLAG_TRIGGERS       0x00000004
		- DEBUG_FLAG_CPU_BIND       0x00000008
		- DEBUG_FLAG_WIKI           0x00000010
		- DEBUG_FLAG_NO_CONF_HASH   0x00000020
		- DEBUG_FLAG_GRES           0x00000040
		- DEBUG_FLAG_BG_PICK        0x00000080
		- DEBUG_FLAG_BG_WIRES       0x00000100
		- DEBUG_FLAG_BG_ALGO        0x00000200
		- DEBUG_FLAG_BG_ALGO_DEEP   0x00000400
		- DEBUG_FLAG_PRIO           0x00000800
		- DEBUG_FLAG_BACKFILL       0x00001000
		- DEBUG_FLAG_GANG           0x00002000
		- DEBUG_FLAG_RESERVATION    0x00004000
		- DEBUG_FLAG_FRONT_END      0x00008000
		- DEBUG_FLAG_NO_REALTIME    0x00010000

	:returns: Debug flag value
	:rtype: `integer`
	:returns: Debug flag string
	:rtype: `string`
	"""

	return __get_debug_flags(inx)

cdef inline list __get_debug_flags(uint32_t flags=0):

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

def get_node_state(uint16_t inx=0):

	u"""Returns a string that represents the state of the slurm node.

	:param int inx: Slurm node state

	:returns: Node state value
	:rtype: `integer`
	:returns: Node state string
	:rtype: `string`
	"""

	return slurm.slurm_node_state_string(inx)

def get_rm_partition_state(int inx=0):

	u"""Returns a string that represents the partition state.

	:param int inx: Slurm partition state

	:returns: Partition state value
	:rtype: `integer`
	:returns: Partition state string
	:rtype: `string`
	"""

	return __get_rm_partition_state(inx)

cdef inline object __get_rm_partition_state(int inx=0):

	rm_part_state = 'Unknown'
	cdef list state = [
			'Free',
			'Configuring',
			'Ready',
			'Busy',
			'Deallocating',
			'Error',
			'Nav'
			]

	try:
		rm_part_state = state[inx]
	except:
		pass

	return u"%s" % rm_part_state

def get_preempt_mode(uint16_t inx=0):

	u"""Returns a string that represents the preempt mode.

	:param int inx: Slurm preempt mode

		- PREEMPT_MODE_OFF          0x0000
		- PREEMPT_MODE_SUSPEND      0x0001
		- PREEMPT_MODE_REQUEUE      0x0002
		- PREEMPT_MODE_CHECKPOINT   0x0004
		- PREEMPT_MODE_CANCEL       0x0008
		- PREEMPT_MODE_GANG         0x8000

	:returns: Preempt mode value
	:rtype: `integer`
	:returns: Preempt mode string
	:rtype: `string`
	"""

	return slurm.slurm_preempt_mode_string(inx)

def get_preempt_mode_num(char* preempt_mode):

	u"""Returns a value that represents the preempt mode.

	:param char: Slurm preempt mode string

	:returns: Preempt mode value
	:rtype: `integer`
	"""

	return slurm.slurm_preempt_mode_num(preempt_mode)

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

	u"""Returns a string that represents the state of the slurm partition.

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

	u"""Returns a string that represents the the partition mode

	:param int inx: Slurm partition mode

	:returns: Partition mode flag
	:rtype: `integer`
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

	return mode

def get_conn_type_string(inx=0):

	u"""Returns a string that represents the state of the slurm bluegene connection type.

	:param int inx: Slurm BG connection state

	:returns: Block connection value
	:rtype: `integer`
	:returns: Block connection string
	:rtype: `string`
	"""

	return slurm.slurm_conn_type_string(inx)

def get_bg_block_state_string(uint16_t inx=0):

	u"""Returns a string that represents the state of the slurm bluegene block state.

	:param int inx: Slurm BG block state

	:returns: Block state value
	:rtype: `integer`
	:returns: Block state string
	:rtype: `string`
	"""

	return slurm.slurm_bg_block_state_string(inx)

def get_job_state(int inx=0):

	u"""Returns a string that represents the state of the slurm job state.

	:param int inx: Slurm job state

		- JOB_PENDING		0
		- JOB_RUNNING		1
		- JOB_SUSPENDED		2
		- JOB_COMPLETE		3
		- JOB_CANCELLED		4
		- JOB_FAILED		5
		- JOB_TIMEOUT		6
		- JOB_NODE_FAIL		7
		- JOB_PREEMPTED		8
		- JOB_END		9

	:returns: Job state value
	:rtype: `integer`
	:returns: Job state string
	:rtype: `string`
	"""

	try:
		return slurm.slurm_job_state_string(inx)
	except:
		pass

def get_job_state_reason(uint16_t inx=0):

	u"""Returns a reason why the slurm job is in a state.

	:param int inx: Slurm job state reason

	:returns: Reason value
	:rtype: `integer`
	:returns: Reason string
	:rtype: `string`
	"""

	return slurm.slurm_job_reason_string(inx)

def epoch2date(epochSecs=0):

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
