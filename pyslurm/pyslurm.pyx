# cython: embedsignature=True
# cython: profile=False

import time as p_time
import os

from socket import gethostname
from collections import defaultdict
from pwd import getpwnam, getpwuid

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
    double difftime(time_t time1, time_t time2)
    time_t time(time_t *t)

cdef extern from "sys/wait.h" nogil:
    int WIFSIGNALED (int status)
    int WTERMSIG (int status)
    int WEXITSTATUS (int status)

try:
    import __builtin__
except ImportError:
    # Python 3
    import builtins as __builtin__

# cdef object _unicode
# try:
#     _unicode = __builtin__.unicode
# except AttributeError:
#     Python 3
#     _unicode = __builtin__.str
#
# from cpython cimport PyErr_SetString, PyBytes_Check
# from cpython cimport PyUnicode_Check, PyBytes_FromStringAndSize

cimport slurm
include "bluegene.pxi"
include "slurm_defines.pxi"

#
# Slurm Macros as Cython inline functions
#

cdef inline SLURM_VERSION_NUMBER():
    return slurm.SLURM_VERSION_NUMBER

cdef inline SLURM_VERSION_MAJOR(a):
    return ((a >> 16) & 0xff)

cdef inline SLURM_VERSION_MINOR(a):
    return ((a >> 8) & 0xff)

cdef inline SLURM_VERSION_MICRO(a):
    return (a & 0xff)

cdef inline SLURM_VERSION_NUM(a):
    return (((SLURM_VERSION_MAJOR(a)) << 16) +
            ((SLURM_VERSION_MINOR(a)) << 8) +
            (SLURM_VERSION_MICRO(a)))

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

cdef inline SLURM_ID_HASH(_jobid, _stepid):
    return <uint64_t>(<uint64_t>_stepid * SLURM_ID_HASH_NUM + _jobid)

cdef inline SLURM_ID_HASH_JOB_ID(hash_id):
    return <uint32_t>(hash_id % SLURM_ID_HASH_NUM)

cdef inline SLURM_ID_HASH_STEP_ID(hash_id):
    return <uint32_t>(hash_id / SLURM_ID_HASH_NUM)

#
# Defined job states
#

cdef inline IS_JOB_PENDING(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_PENDING

cdef inline IS_JOB_RUNNING(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_RUNNING

cdef inline IS_JOB_SUSPENDED(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_SUSPENDED

cdef inline IS_JOB_COMPLETE(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_COMPLETE

cdef inline IS_JOB_CANCELLED(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_CANCELLED

cdef inline IS_JOB_FAILED(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_FAILED

cdef inline IS_JOB_TIMEOUT(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_TIMEOUT

cdef inline IS_JOB_NODE_FAILED(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_NODE_FAIL

#
# Derived job states
#

cdef inline IS_JOB_COMPLETING(slurm.slurm_job_info_t _X):
    return _X.job_state & JOB_COMPLETING

cdef inline IS_JOB_CONFIGURING(slurm.slurm_job_info_t _X):
    return _X.job_state & JOB_CONFIGURING

cdef inline IS_JOB_STARTED(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_STATE_BASE) > JOB_PENDING

cdef inline IS_JOB_FINISHED(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_STATE_BASE) > JOB_SUSPENDED

cdef inline IS_JOB_COMPLETED(slurm.slurm_job_info_t _X):
    return (IS_JOB_FINISHED(_X) and (_X.job_state & JOB_COMPLETING) == 0)

cdef inline IS_JOB_RESIZING(slurm.slurm_job_info_t _X):
    return _X.job_state & JOB_RESIZING

cdef inline IS_JOB_REQUEUED(slurm.slurm_job_info_t _X):
    return _X.job_state & JOB_REQUEUE

cdef inline IS_JOB_UPDATE_DB(slurm.slurm_job_info_t _X):
    return _X.job_state & JOB_UPDATE_DB

#
# Defined node states
#

cdef inline IS_NODE_UNKNOWN(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_UNKNOWN

cdef inline IS_NODE_DOWN(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_DOWN

cdef inline IS_NODE_IDLE(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_IDLE

cdef inline IS_NODE_ALLOCATED(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_ALLOCATED

cdef inline IS_NODE_ERROR(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_ERROR

cdef inline IS_NODE_MIXED(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_MIXED

cdef inline IS_NODE_FUTURE(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_FUTURE

#
# Derived node states
#

cdef inline IS_NODE_CLOUD(slurm.node_info_t _X):
    return _X.node_state & NODE_STATE_CLOUD

cdef inline IS_NODE_DRAIN(slurm.node_info_t _X):
    return _X.node_state & NODE_STATE_DRAIN

cdef inline IS_NODE_DRAINING(slurm.node_info_t _X):
    return ((_X.node_state & NODE_STATE_DRAIN) and
            (IS_NODE_ALLOCATED(_X) or IS_NODE_ERROR(_X) or IS_NODE_MIXED(_X)))

cdef inline IS_NODE_DRAINED(slurm.node_info_t _X):
    return IS_NODE_DRAIN(_X) and not IS_NODE_DRAINING(_X)

cdef inline IS_NODE_COMPLETING(slurm.node_info_t _X):
    return _X.node_state & NODE_STATE_COMPLETING

cdef inline IS_NODE_NO_RESPOND(slurm.node_info_t _X):
    return _X.node_state & NODE_STATE_NO_RESPOND

cdef inline IS_NODE_POWER_SAVE(slurm.node_info_t _X):
    return _X.node_state & NODE_STATE_POWER_SAVE

cdef inline IS_NODE_FAIL(slurm.node_info_t _X):
    return _X.node_state & NODE_STATE_FAIL

cdef inline IS_NODE_POWER_UP(slurm.node_info_t _X):
    return _X.node_state & NODE_STATE_POWER_UP

cdef inline IS_NODE_MAINT(slurm.node_info_t _X):
    return _X.node_state & NODE_STATE_MAINT

ctypedef struct config_key_pair_t:
    char *name
    char *value


#
# Cython Wrapper Functions
#


def get_controllers():
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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    primary = backup = None
    if slurm_ctl_conf_ptr is not NULL:

        if slurm_ctl_conf_ptr.control_machine is not NULL:
            primary = slurm.stringOrNone(slurm_ctl_conf_ptr.control_machine, '')
        if slurm_ctl_conf_ptr.backup_controller is not NULL:
            backup = slurm.stringOrNone(slurm_ctl_conf_ptr.backup_controller, '')

        slurm.slurm_free_ctl_conf(slurm_ctl_conf_ptr)

    return primary, backup


def is_controller(Host=None):
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
    if backup == Host:
        return u'backup'


def slurm_api_version():
    u"""Return the slurm API version number.

    :returns: version_major, version_minor, version_micro
    :rtype: `tuple`
    """
    cdef long version = slurm.SLURM_VERSION_NUMBER

    return (SLURM_VERSION_MAJOR(version),
            SLURM_VERSION_MINOR(version),
            SLURM_VERSION_MICRO(version))


def slurm_load_slurmd_status():
    u"""Issue RPC to get and load the status of Slurmd daemon.

    :returns: Slurmd information
    :rtype: `dict`
    """
    cdef:
        dict Status = {}, Status_dict = {}
        slurm.slurmd_status_t *slurmd_status = NULL
        int errCode = slurm.slurm_load_slurmd_status(&slurmd_status)

    if errCode == slurm.SLURM_SUCCESS:
        hostname = slurm.stringOrNone(slurmd_status.hostname, '')
        Status_dict[u'actual_boards'] = slurmd_status.actual_boards
        Status_dict[u'booted'] = slurmd_status.booted
        Status_dict[u'actual_cores'] = slurmd_status.actual_cores
        Status_dict[u'actual_cpus'] = slurmd_status.actual_cpus
        Status_dict[u'actual_real_mem'] = slurmd_status.actual_real_mem
        Status_dict[u'actual_sockets'] = slurmd_status.actual_sockets
        Status_dict[u'actual_threads'] = slurmd_status.actual_threads
        Status_dict[u'actual_tmp_disk'] = slurmd_status.actual_tmp_disk
        Status_dict[u'hostname'] = hostname
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

def get_private_data_list(data):
    u"""Return the list of enciphered Private Data configuration."""

    result = []
    exponent = 7
    types = ['jobs', 'node', 'partitions', 'usage', 'users', 'accounts', 'reservations', 'cloud_nodes']
    preview = data
    rest = data
    while rest != 0:
        rest = data % pow(2, exponent)
        if rest != preview:
            result.append(types[exponent])
        exponent = exponent - 1
        preview = rest
    return result

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
        u"""Free memory allocated by slurm_load_ctl_conf."""
        if self.__Config_ptr is not NULL:
            slurm.slurm_free_ctl_conf(self.__Config_ptr)
            self.__Config_ptr = NULL
            self.__ConfigDict = {}
            self.__lastUpdate = 0

    def display_all(self):
        u"""Print slurm control configuration information."""
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
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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

            for i in range(listNum):

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
            Ctl_dict[u'job_credential_private_key'] = slurm.stringOrNone(
                self.__Config_ptr.job_credential_private_key, ''
            )
            Ctl_dict[u'job_credential_public_certificate'] = slurm.stringOrNone(
                self.__Config_ptr.job_credential_public_certificate, ''
            )
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
            Ctl_dict[u'mail_domain'] = slurm.stringOrNone(self.__Config_ptr.mail_domain, '')
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
            Ctl_dict[u'node_prefix'] = slurm.stringOrNone(self.__Config_ptr.node_prefix, '')
            Ctl_dict[u'over_time_limit'] = self.__Config_ptr.over_time_limit
            Ctl_dict[u'plugindir'] = slurm.stringOrNone(self.__Config_ptr.plugindir, '')
            Ctl_dict[u'plugstack'] = slurm.stringOrNone(self.__Config_ptr.plugstack, '')
            Ctl_dict[u'power_parameters'] = slurm.stringOrNone(self.__Config_ptr.power_parameters, '')
            Ctl_dict[u'power_plugin'] = slurm.stringOrNone(self.__Config_ptr.power_plugin, '')

            config_get_preempt_mode = get_preempt_mode(self.__Config_ptr.preempt_mode)
            Ctl_dict[u'preempt_mode'] = slurm.stringOrNone(config_get_preempt_mode, '')

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
            Ctl_dict[u'private_data_list'] = get_private_data_list(self.__Config_ptr.private_data)
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
            Ctl_dict[u'sbcast_parameters'] = slurm.stringOrNone(self.__Config_ptr.sbcast_parameters, '')
            Ctl_dict[u'sched_logfile'] = slurm.stringOrNone(self.__Config_ptr.sched_logfile, '')
            Ctl_dict[u'sched_log_level'] = self.__Config_ptr.sched_log_level
            Ctl_dict[u'sched_params'] = slurm.stringOrNone(self.__Config_ptr.sched_params, '')
            Ctl_dict[u'sched_time_slice'] = self.__Config_ptr.sched_time_slice
            Ctl_dict[u'schedtype'] = slurm.stringOrNone(self.__Config_ptr.schedtype, '')
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

            # Ctl_dict[u'srun_port_range'] = self.__Config_ptr.srun_port_range

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

#            config_list = <slurm.List>self.__Config_ptr.select_conf_key_pairs
#            if config_list is not NULL:
#                listNum = slurm.slurm_list_count(config_list)
#                iters = slurm.slurm_list_iterator_create(config_list)
#                for i in range(listNum):
#                    keyPairs = <config_key_pair_t *>slurm.slurm_list_next(iters)
#                    name = keyPairs.name
#                    if keyPairs.value is not NULL:
#                        value = keyPairs.value
#                    else:
#                        value = None
#                    key_pairs[name] = value
#                slurm.slurm_list_iterator_destroy(iters)
#                Ctl_dict[u'key_pairs'] = key_pairs

        self.__ConfigDict = Ctl_dict


#
# Partition Class
#


cdef class partition:
    u"""Class to access/modify Slurm Partition Information."""

    cdef:
        slurm.partition_info_msg_t *_Partition_ptr
        slurm.time_t _lastUpdate
        uint16_t _ShowFlags
        dict _PartDict

    def __cinit__(self):
        self._Partition_ptr = NULL
        self._ShowFlags = slurm.SHOW_ALL
        self._lastUpdate = <time_t> NULL

    def __dealloc__(self):
        pass

    def lastUpdate(self):
        u"""Return time (epoch seconds) the partition data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    def ids(self):
        u"""Return the partition IDs from retrieved data.

        :returns: Dictionary of partition IDs
        :rtype: `dict`
        """
        cdef:
            int rc
            int apiError
            uint32_t i

        rc = slurm.slurm_load_partitions(<time_t> NULL, &self._Partition_ptr,
                                         slurm.SHOW_ALL)

        if rc == slurm.SLURM_SUCCESS:
            self._lastUpdate = self._Partition_ptr.last_update
            all_partitions = []

            for record in self._Partition_ptr.partition_array[:self._Partition_ptr.record_count]:
                all_partitions.append(slurm.stringOrNone(record.name, ''))

            slurm.slurm_free_partition_info_msg(self._Partition_ptr)
            self._Partition_ptr = NULL
            return all_partitions
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    def find_id(self, partID):
        u"""Get partition information for a given partition.

        :param str partID: Partition key string to search
        :returns: Dictionary of values for given partition
        :rtype: `dict`
        """
        return self.get().get(partID)

    def find(self, name='', val=''):
        u"""Search for a property and associated value in the retrieved partition data.

        :param str name: key string to search
        :param str value: value string to match
        :returns: List of IDs that match
        :rtype: `list`
        """
        cdef:
            list retList = []
            dict _partition_dict = {}

        _partition_dict = self.get()

        if val != '':
            for key, value in self._partition_dict.items():
                if _partition_dict[key][name] == val:
                    retList.append(key)
        return retList

    def print_info_msg(self, int oneLiner=0):
        u"""Display the partition information from previous load partition method.

        :param int oneLiner: Display on one line (default=0)
        """
        cdef:
            int rc
            int apiError

        rc = slurm.slurm_load_partitions(<time_t> NULL, &self._Partition_ptr,
                                         slurm.SHOW_ALL)

        if rc == slurm.SLURM_SUCCESS:
            slurm.slurm_print_partition_info_msg(slurm.stdout,
                                                 self._Partition_ptr,
                                                 oneLiner)
            self._lastUpdate = self._Partition_ptr.last_update
            slurm.slurm_free_partition_info_msg(self._Partition_ptr)
            self._Partition_ptr = NULL
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    def delete(self, PartID):
        u"""Delete a give slurm partition.

        :param string PartID: Name of slurm partition

        :returns: 0 for success else set the slurm error code as appropriately.
        :rtype: `integer`
        """
        cdef:
            slurm.delete_part_msg_t part_msg
            int apiError
            int errCode

        b_partid = PartID.encode("UTF-8", "replace")
        part_msg.name = b_partid

        errCode = slurm.slurm_delete_partition(&part_msg)

        if errCode != slurm.SLURM_SUCCESS:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

        return errCode

    def get(self):
        u"""Get all slurm partition information

        :returns: Dictionary of dictionaries whose key is the partition name.
        :rtype: `dict`
        """
        cdef:
            int rc
            int apiError
            uint16_t preempt_mode
            uint32_t i
            slurm.partition_info_t *record

        rc = slurm.slurm_load_partitions(<time_t> NULL, &self._Partition_ptr,
                                         slurm.SHOW_ALL)

        if rc == slurm.SLURM_SUCCESS:
            self._PartDict = {}
            self._lastUpdate = self._Partition_ptr.last_update

            for record in self._Partition_ptr.partition_array[:self._Partition_ptr.record_count]:
                Part_dict = {}
                name = slurm.stringOrNone(record.name, '')

                if record.allow_accounts or not record.deny_accounts:
                    if record.allow_accounts == NULL or \
                       record.allow_accounts[0] == "\0":
                        Part_dict[u'allow_accounts'] = u"ALL"
                    else:
                        Part_dict[u'allow_accounts'] = slurm.listOrNone(
                            record.allow_accounts, ',')

                    Part_dict[u'deny_accounts'] = None
                else:
                    Part_dict[u'allow_accounts'] = None
                    Part_dict[u'deny_accounts'] = slurm.listOrNone(
                        record.deny_accounts, ',')

                if record.allow_alloc_nodes == NULL:
                    Part_dict[u'allow_alloc_nodes'] = u"ALL"
                else:
                    Part_dict[u'allow_alloc_nodes'] = slurm.listOrNone(
                        record.allow_alloc_nodes, ',')

                if record.allow_groups == NULL or \
                   record.allow_groups[0] == "\0":
                    Part_dict[u'allow_groups'] = u"ALL"
                else:
                    Part_dict[u'allow_groups'] = slurm.listOrNone(
                        record.allow_groups, ',')

                if record.allow_qos or not record.deny_qos:
                    if record.allow_qos == NULL or \
                       record.allow_qos[0] == "\0":
                        Part_dict[u'allow_qos'] = u"ALL"
                    else:
                        Part_dict[u'allow_qos'] = slurm.listOrNone(
                            record.allow_qos, ',')
                    Part_dict[u'deny_qos'] = None
                else:
                    Part_dict[u'allow_qos'] = None
                    Part_dict[u'deny_qos'] = slurm.listOrNone(record.allow_qos, ',')

                if record.alternate != NULL:
                    Part_dict[u'alternate'] = slurm.stringOrNone(record.alternate, '')
                else:
                    Part_dict[u'alternate'] = None

                Part_dict[u'billing_weights_str'] = slurm.stringOrNone(
                    record.billing_weights_str, '')
                Part_dict[u'cr_type'] = record.cr_type

                if record.def_mem_per_cpu & slurm.MEM_PER_CPU:
                    if record.def_mem_per_cpu == slurm.MEM_PER_CPU:
                        Part_dict[u'def_mem_per_cpu'] = u"UNLIMITED"
                        Part_dict[u'def_mem_per_node'] = None
                    else:
                        Part_dict[u'def_mem_per_cpu'] = record.def_mem_per_cpu & (~slurm.MEM_PER_CPU)
                        Part_dict[u'def_mem_per_node'] = None
                elif record.def_mem_per_cpu == 0:
                    Part_dict[u'def_mem_per_cpu'] = None
                    Part_dict[u'def_mem_per_node'] = u"UNLIMITED"
                else:
                    Part_dict[u'def_mem_per_cpu'] = None
                    Part_dict[u'def_mem_per_node'] = record.def_mem_per_cpu

                if record.default_time == slurm.INFINITE:
                    Part_dict[u'default_time'] = u"UNLIMITED"
                    Part_dict[u'default_time_str'] = u"UNLIMITED"
                elif record.default_time == slurm.NO_VAL:
                    Part_dict[u'default_time'] = u"NONE"
                    Part_dict[u'default_time_str'] = u"NONE"
                else:
                    Part_dict[u'default_time'] = record.default_time * 60
                    Part_dict[u'default_time_str'] = secs2time_str(
                        record.default_time * 60)

                Part_dict[u'flags'] = get_partition_mode(record.flags,
                                                         record.max_share)
                Part_dict[u'grace_time'] = record.grace_time

                if record.max_cpus_per_node == slurm.INFINITE:
                    Part_dict[u'max_cpus_per_node'] = u"UNLIMITED"
                else:
                    Part_dict[u'max_cpus_per_node'] = record.max_cpus_per_node

                if record.max_mem_per_cpu & slurm.MEM_PER_CPU:
                    if record.max_mem_per_cpu == slurm.MEM_PER_CPU:
                        Part_dict[u'max_mem_per_cpu'] = u"UNLIMITED"
                        Part_dict[u'max_mem_per_node'] = None
                    else:
                        Part_dict[u'max_mem_per_cpu'] = record.max_mem_per_cpu & (~slurm.MEM_PER_CPU)
                        Part_dict[u'max_mem_per_node'] = None
                elif record.max_mem_per_cpu == 0:
                    Part_dict[u'max_mem_per_cpu'] = None
                    Part_dict[u'max_mem_per_node'] = u"UNLIMITED"
                else:
                    Part_dict[u'max_mem_per_cpu'] = None
                    Part_dict[u'max_mem_per_node'] = record.max_mem_per_cpu

                if record.max_nodes == slurm.INFINITE:
                    Part_dict[u'max_nodes'] = u"UNLIMITED"
                else:
                    Part_dict[u'max_nodes'] = record.max_nodes

                Part_dict[u'max_share'] = record.max_share

                if record.max_time == slurm.INFINITE:
                    Part_dict[u'max_time'] = u"UNLIMITED"
                    Part_dict[u'max_time_str'] = u"UNLIMITED"
                else:
                    Part_dict[u'max_time'] = record.max_time * 60
                    Part_dict[u'max_time_str'] = secs2time_str(record.max_time * 60)

                Part_dict[u'min_nodes'] = record.min_nodes
                Part_dict[u'name'] = slurm.stringOrNone(record.name, '')
                Part_dict[u'nodes'] = slurm.stringOrNone(record.nodes, '')

                if record.over_time_limit == slurm.NO_VAL16:
                    Part_dict[u'over_time_limit'] = "NONE"
                elif record.over_time_limit == <uint16_t>slurm.INFINITE:
                    Part_dict[u'over_time_limit'] = "UNLIMITED"
                else:
                    Part_dict[u'over_time_limit'] = record.over_time_limit

                preempt_mode = record.preempt_mode
                if preempt_mode == slurm.NO_VAL16:
                    preempt_mode = slurm.slurm_get_preempt_mode()
                Part_dict[u'preempt_mode'] = slurm.stringOrNone(
                    slurm.slurm_preempt_mode_string(preempt_mode), ''
                )

                Part_dict[u'priority_job_factor'] = record.priority_job_factor
                Part_dict[u'priority_tier'] = record.priority_tier
                Part_dict[u'qos_char'] = slurm.stringOrNone(record.qos_char, '')
                Part_dict[u'state'] = get_partition_state(record.state_up)
                Part_dict[u'total_cpus'] = record.total_cpus
                Part_dict[u'total_nodes'] = record.total_nodes
                Part_dict[u'tres_fmt_str'] = slurm.stringOrNone(record.tres_fmt_str, '')

                self._PartDict[u"%s" % name] = Part_dict
            slurm.slurm_free_partition_info_msg(self._Partition_ptr)
            self._Partition_ptr = NULL
            return self._PartDict
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)


    def update(self, dict Partition_dict):
        u"""Update a slurm partition.

        :param dict partition_dict: A populated partition dictionary,
            an empty one is created by create_partition_dict
        :returns: 0 for success, -1 for error, and the slurm error code
            is set appropriately.
        :rtype: `integer`
        """
        cdef int errCode = slurm_update_partition(Partition_dict)
        return errCode

    def create(self, dict Partition_dict):
        u"""Create a slurm partition.

        :param dict partition_dict: A populated partition dictionary,
            an empty one can be created by create_partition_dict
        :returns: 0 for success or -1 for error, and the slurm error
            code is set appropriately.
        :rtype: `integer`
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
        u'Alternate': None,
        u'Name': None,
        u'MaxTime': 0,
        u'DefaultTime': 0,
        u'MaxNodes': 0,
        u'MinNodes': 0,
        u'Default': 0,
        u'Hidden': 0,
        u'RootOnly': 0,
        u'Shared': 0,
        u'Priority': 0,
        u'State': 0,
        u'Nodes': None,
        u'AllowGroups': None,
        u'AllocNodes': None
    }


def slurm_create_partition(dict partition_dict):
    u"""Create a slurm partition.

    :param dict partition_dict: A populated partition dictionary,
        an empty one is created by create_partition_dict
    :returns: 0 for success or -1 for error, and the slurm error
        code is set appropriately.
    :rtype: `integer`
    """
    cdef:
        slurm.update_part_msg_t part_msg_ptr
        int errCode

    slurm.slurm_init_part_desc_msg(&part_msg_ptr)

    b_name = partition_dict['Name'].encode("UTF-8", "replace")
    part_msg_ptr.name = b_name

    if partition_dict.get('DefaultTime'):
        part_msg_ptr.default_time = partition_dict[u'DefaultTime']

    if partition_dict.get('MaxNodes'):
        part_msg_ptr.max_nodes = partition_dict[u'MaxNodes']

    if partition_dict.get('MinNodes'):
        part_msg_ptr.min_nodes = partition_dict[u'MinNodes']

    errCode = slurm.slurm_create_partition(&part_msg_ptr)
    return errCode


def slurm_update_partition(dict partition_dict):
    u"""Update a slurm partition.

    :param dict partition_dict: A populated partition dictionary,
        an empty one is created by create_partition_dict
    :returns: 0 for success, -1 for error, and the slurm error
        code is set appropriately.
    :rtype: `integer`
    """
    cdef:
        slurm.update_part_msg_t part_msg_ptr
        unsigned int uint32_value
        unsigned int time_value
        int int_value = 0
        int errCode = 0

    slurm.slurm_init_part_desc_msg(&part_msg_ptr)

    if partition_dict.get(u'Name'):
        b_name = partition_dict[u'Name'].encode("UTF-8", "replace")
        part_msg_ptr.name = b_name

    if partition_dict.get(u'Alternate'):
        b_alternate = partition_dict[u'Alternate'].encode("UTF-8", "replace")
        part_msg_ptr.alternate = b_alternate

    if partition_dict.get(u'MaxTime'):
        part_msg_ptr.max_time = partition_dict[u'MaxTime']

    if partition_dict.get(u'DefaultTime'):
        part_msg_ptr.default_time = partition_dict[u'DefaultTime']

    if partition_dict.get(u'MaxNodes'):
        part_msg_ptr.max_nodes = partition_dict[u'MaxNodes']

    if partition_dict.get(u'MinNodes'):
        part_msg_ptr.min_nodes = partition_dict[u'MinNodes']

    state = partition_dict.get('State')
    if state:
        if state == u'DOWN':
            part_msg_ptr.state_up = PARTITION_DOWN
        elif state == u'UP':
            part_msg_ptr.state_up = PARTITION_UP
        elif state == u'DRAIN':
            part_msg_ptr.state_up = PARTITION_DRAIN
        else:
            errCode = -1

    if partition_dict.get('Nodes'):
        b_nodes = partition_dict[u'Nodes'].encode("UTF-8")
        part_msg_ptr.nodes = b_nodes

    if partition_dict.get('AllowGroups'):
        b_allow_groups = partition_dict[u'AllowGroups'].encode("UTF-8")
        part_msg_ptr.allow_groups = b_allow_groups

    if partition_dict.get('AllocNodes'):
        b_allow_alloc_nodes = partition_dict[u'AllocNodes'].encode("UTF-8")
        part_msg_ptr.allow_alloc_nodes = b_allow_alloc_nodes

    errCode = slurm.slurm_update_partition(&part_msg_ptr)
    return errCode


def slurm_delete_partition(PartID):
    u"""Delete a slurm partition.

    :param string PartID: Name of slurm partition
    :returns: 0 for success else set the slurm error code as appropriately.
    :rtype: `integer`
    """
    cdef:
        slurm.delete_part_msg_t part_msg
        int apiError
        int errCode

    b_partid = PartID.encode("UTF-8", "replace")
    part_msg.name = b_partid
    errCode = slurm.slurm_delete_partition(&part_msg)

    if errCode != slurm.SLURM_SUCCESS:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_shutdown(uint16_t Options=0) except? -1:
    u"""Issue RPC to have slurmctld cease operations.

    Both the primary and backup controller are shutdown.

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_takeover() except? -1:
    u"""Issue a RPC to have slurmctld backup controller take over.

    The backup controller takes over the primary controller.

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_set_debugflags(uint32_t debug_flags_plus=0,
                               uint32_t debug_flags_minus=0) except? -1:
    u"""Set the slurm controller debug flags.

    :param int debug_flags_plus: debug flags to be added
    :param int debug_flags_minus: debug flags to be removed
    :returns: 0 for success, -1 for error and set slurm error number
    :rtype: `integer`
    """
    cdef int apiError = 0
    cdef int errCode = slurm.slurm_set_debugflags(debug_flags_plus,
                                                  debug_flags_minus)

    if errCode != 0:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return EndTime


cpdef int slurm_job_node_ready(uint32_t JobID=0) except? -1:
    u"""Return if a node could run a slurm job now if dispatched.

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


#
# Slurm Job/Step Signaling Functions
#


cpdef int slurm_signal_job_step(uint32_t JobID=0, uint32_t JobStep=0,
                                uint16_t Signal=0) except? -1:
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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_kill_job(uint32_t JobID=0, uint16_t Signal=0,
                         uint16_t BatchFlag=0) except? -1:
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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_kill_job_step(uint32_t JobID=0, uint32_t JobStep=0,
                              uint16_t Signal=0) except? -1:
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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_terminate_job_step(uint32_t JobID=0, uint32_t JobStep=0) except? -1:
    u"""Terminate a running slurm job step.

    :param int JobID: Job identifier (default=0)
    :param int JobStep: Job step identifier (default=0)
    :returns: 0 for success or -1 for error, and the slurm error code
        is set appropriately.
    :rtype: `integer`
    """
    cdef int apiError = 0
    cdef int errCode = slurm.slurm_terminate_job_step(JobID, JobStep)

    if errCode != 0:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


#
# Slurm Checkpoint functions
#


cpdef time_t slurm_checkpoint_able(uint32_t JobID=0, uint32_t JobStep=0) except? -1:
    u"""Report if checkpoint operations can be issued for the job step.

    If yes, returns SLURM_SUCCESS and sets start_time if checkpoint operation
    is presently active. Returns ESLURM_DISABLED if checkpoint operation is
    disabled.

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_checkpoint_disable(uint32_t JobID=0, uint32_t JobStep=0) except? -1:
    u"""Disable checkpoint requests for a given slurm job step.

    This can be issued as needed to prevent checkpointing while a job step is
    in a critical section or for other reasons.

    :param int JobID: Job identifier
    :param int JobStep: Job step identifier
    :returns: 0 for success or a slurm error code
    :rtype: `integer`
    """
    cdef int apiError = 0
    cdef int errCode = slurm.slurm_checkpoint_disable(JobID, JobStep)

    if errCode != 0:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_checkpoint_create(uint32_t JobID=0, uint32_t JobStep=0,
                                  uint16_t MaxWait=60, char* ImageDir='') except? -1:
    u"""Request a checkpoint for the identified slurm job step.

    Continue its execution upon completion of the checkpoint.

    :param int JobID: Job identifier
    :param int JobStep: Job step identifier
    :param int MaxWait: Maximum time to wait
    :param string ImageDir: Directory to write checkpoint files
    :returns: 0 for success or a slurm error code
    :rtype: `integer`
    """
    cdef int apiError = 0
    cdef int errCode = slurm.slurm_checkpoint_create(JobID, JobStep,
                                                     MaxWait, ImageDir)

    if errCode != 0:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_checkpoint_requeue(uint32_t JobID=0, uint16_t MaxWait=60,
                                   char* ImageDir='') except? -1:
    u"""Initiate a checkpoint request for identified slurm job step.

    The job will be requeued after the checkpoint operation completes.

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_checkpoint_vacate(uint32_t JobID=0, uint32_t JobStep=0,
                                  uint16_t MaxWait=60, char* ImageDir='') except? -1:
    u"""Request a checkpoint for the identified slurm Job Step.

    Terminate its execution upon completion of the checkpoint.

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_checkpoint_restart(uint32_t JobID=0, uint32_t JobStep=0,
                                   uint16_t Stick=0, char* ImageDir='') except? -1:
    u"""Request that a previously checkpointed slurm job resume execution.

    It may continue execution on different nodes than were originally used.
    Execution may be delayed if resources are not immediately available.

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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_checkpoint_complete(uint32_t JobID=0, uint32_t JobStep=0,
                                    time_t BeginTime=0, uint32_t ErrorCode=0,
                                    char* ErrMsg='') except? -1:
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
    cdef int errCode = slurm.slurm_checkpoint_complete(JobID, JobStep,
                                                       BeginTime, ErrorCode,
                                                       ErrMsg)

    if errCode != 0:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_checkpoint_task_complete(uint32_t JobID=0, uint32_t JobStep=0,
                                         uint32_t TaskID=0, time_t BeginTime=0,
                                         uint32_t ErrorCode=0, char* ErrMsg='') except? -1:
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
    cdef int errCode = slurm.slurm_checkpoint_task_complete(JobID, JobStep,
                                                            TaskID, BeginTime,
                                                            ErrorCode, ErrMsg)

    if errCode != 0:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


#
# Slurm Job Checkpoint Functions
#


def slurm_checkpoint_error(uint32_t JobID=0, uint32_t JobStep=0):
    u"""Get error information about the last checkpoint operation for job step.

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


cpdef int slurm_checkpoint_tasks(uint32_t JobID=0, uint16_t JobStep=0,
                                 uint16_t MaxWait=60, char* NodeList='') except? -1:
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
        int errCode = slurm.slurm_checkpoint_tasks(JobID, JobStep,
                                                   BeginTime, ImageDir,
                                                   MaxWait, NodeList)

    if errCode != 0:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


#
# Slurm Job Class to Control Configuration Read/Update
#


cdef class job:
    u"""Class to access/modify Slurm Job Information."""

    cdef:
        slurm.job_info_msg_t *_job_ptr
        slurm.slurm_job_info_t *_record
        slurm.time_t _lastUpdate
        uint16_t _ShowFlags
        dict _JobDict

    def __cinit__(self):
        self._job_ptr = NULL
        self._lastUpdate = 0
        self._ShowFlags = slurm.SHOW_DETAIL | slurm.SHOW_DETAIL2

    def __dealloc__(self):
        pass

    def lastUpdate(self):
        u"""Get the time (epoch seconds) the job data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    cpdef ids(self):
        u"""Return the job IDs from retrieved data.

        :returns: Dictionary of job IDs
        :rtype: `dict`
        """

        cdef:
            int rc
            int apiError
            uint32_t i
            list all_jobs

        rc = slurm.slurm_load_jobs(<time_t> NULL, &self._job_ptr, self._ShowFlags)

        if rc == slurm.SLURM_SUCCESS:
            all_jobs = []
            for i in range(self._job_ptr.record_count):
                all_jobs.append(self._job_ptr.job_array[i].job_id)
            slurm.slurm_free_job_info_msg(self._job_ptr)
            self._job_ptr = NULL
            return all_jobs
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    def find(self, name='', val=''):
        u"""Search for a property and associated value in the retrieved job data.

        :param str name: key string to search
        :param str value: value string to match
        :returns: List of IDs that match
        :rtype: `list`
        """
        cdef:
            list retList = []
            dict _job_dict = {}

        _job_dict = self.get()

        if val != '':
            for key, value in _job_dict.items():
                if _job_dict[key][name] == val:
                    retList.append(key)

        return retList

    def find_id(self, jobid):
        u"""Retrieve job ID data.

        This method calls slurm_xlate_job_id() to convert a jobid string to a
        jobid int.  For example, a subjob of 123_4 would translate to 124.
        Then, slurm_load_job() gets all job_table records associated with that
        specific job. This works for single jobs and job arrays.

        :param str jobID: Job id key string to search
        :returns: List of dictionary of values for given job id
        :rtype: `list`
        """
        cdef:
            int apiError
            int rc

        if isinstance(jobid, int) or isinstance(jobid, long):
            jobid = str(jobid).encode("UTF-8")
        else:
            jobid = jobid.encode("UTF-8")

        jobid_xlate = slurm.slurm_xlate_job_id(jobid)
        rc = slurm.slurm_load_job(&self._job_ptr, jobid_xlate, self._ShowFlags)

        if rc == slurm.SLURM_SUCCESS:
            return list(self.get_job_ptr().values())
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    cpdef find_user(self, user):
        u"""Retrieve a user's job data.

        This method calls slurm_load_job_user to get all job_table records
        associated with a specific user.

        :param str user: User string to search
        :returns: Dictionary of values for all user's jobs
        :rtype: `dict`
        """
        cdef:
            int apiError
            int rc
            uint32_t uid
            char *username

        if isinstance(user, str):
            try:
                username = user
                uid = getpwnam(username)[2]
            except KeyError:
                raise KeyError("user " + user + " not found")
        else:
            uid = user

        rc = slurm.slurm_load_job_user(&self._job_ptr, uid, self._ShowFlags)

        if rc == slurm.SLURM_SUCCESS:
            return self.get_job_ptr()
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    cpdef get(self):
        u"""Get all slurm jobs information.

        This method calls slurm_load_jobs to get job_table records for all jobs

        :returns: Data where key is the job name, each entry contains a
            dictionary of job attributes
        :rtype: `dict`
        """
        cdef:
            int apiError
            int rc

        rc = slurm.slurm_load_jobs(<time_t> NULL, &self._job_ptr, self._ShowFlags)

        if rc == slurm.SLURM_SUCCESS:
            return self.get_job_ptr()
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    cdef dict get_job_ptr(self):
        u"""Convert all job arrays in buffer to dictionary.

        :returns: dictionary of job attributes
        :rtype: `dict`
        """
        cdef:
            char tmp_line[1024 * 128]
            time_t end_time
            time_t run_time
            uint16_t exit_status
            uint16_t term_sig
            uint32_t i
            dict Job_dict

        self._JobDict = {}
        self._lastUpdate = self._job_ptr.last_update
        exit_status = 0
        term_sig = 0

        for i in range(self._job_ptr.record_count):
            self._record = &self._job_ptr.job_array[i]
            Job_dict = {}

            Job_dict[u'account'] = slurm.stringOrNone(self._record.account, '')
            Job_dict[u'admin_comment'] = slurm.stringOrNone(self._record.admin_comment, '')
            Job_dict[u'alloc_node'] = slurm.stringOrNone(self._record.alloc_node, '')
            Job_dict[u'alloc_sid'] = self._record.alloc_sid

            if self._record.array_job_id:
                if self._record.array_task_str:
                    Job_dict[u'array_job_id'] = self._record.array_job_id
                    Job_dict[u'array_task_id'] = None
                    Job_dict[u'array_task_str'] = slurm.stringOrNone(
                        self._record.array_task_str, '')
                else:
                    Job_dict[u'array_job_id'] = self._record.array_job_id
                    Job_dict[u'array_task_id'] = self._record.array_task_id
                    Job_dict[u'array_task_str'] = None
            else:
                Job_dict[u'array_job_id'] = None
                Job_dict[u'array_task_id'] = None
                Job_dict[u'array_task_str'] = None

            if self._record.array_max_tasks:
                Job_dict[u'array_max_tasks'] = self._record.array_max_tasks
            else:
                Job_dict[u'array_max_tasks'] = None

            Job_dict[u'assoc_id'] = self._record.assoc_id
            Job_dict[u'batch_flag'] = self._record.batch_flag
            Job_dict[u'batch_host'] = slurm.stringOrNone(self._record.batch_host, '')
            Job_dict[u'batch_script'] = slurm.stringOrNone(
                self._record.batch_script, ''
            )
            Job_dict[u'billable_tres'] = self._record.billable_tres
            Job_dict[u'bitflags'] = self._record.bitflags
            Job_dict[u'boards_per_node'] = self._record.boards_per_node
            Job_dict[u'burst_buffer'] = slurm.stringOrNone(self._record.burst_buffer, '')
            Job_dict[u'burst_buffer_state'] = slurm.stringOrNone(self._record.burst_buffer_state, '')
            Job_dict[u'command'] = slurm.stringOrNone(self._record.command, '')
            Job_dict[u'comment'] = slurm.stringOrNone(self._record.comment, '')
            Job_dict[u'contiguous'] = bool(self._record.contiguous)
            Job_dict[u'core_spec'] = self._record.core_spec
            Job_dict[u'cores_per_socket'] = self._record.cores_per_socket
            Job_dict[u'cpus_per_task'] = self._record.cpus_per_task

            if self._record.cpu_freq_gov == slurm.NO_VAL:
                Job_dict[u'cpu_freq_gov'] = None
            else:
                Job_dict[u'cpu_freq_gov'] = self._record.cpu_freq_min

            if self._record.cpu_freq_max == slurm.NO_VAL:
                Job_dict[u'cpu_freq_max'] = None
            else:
                Job_dict[u'cpu_freq_max'] = self._record.cpu_freq_min

            if self._record.cpu_freq_min == slurm.NO_VAL:
                Job_dict[u'cpu_freq_min'] = None
            else:
                Job_dict[u'cpu_freq_min'] = self._record.cpu_freq_min

            Job_dict[u'dependency'] = slurm.stringOrNone(self._record.dependency, '')

            if WIFSIGNALED(self._record.derived_ec):
                term_sig = WTERMSIG(self._record.derived_ec)
            else:
                term_sig = 0

            exit_status = WEXITSTATUS(self._record.derived_ec)
            Job_dict[u'derived_ec'] = str(exit_status) + ":" + str(term_sig)

            Job_dict[u'eligible_time'] = self._record.eligible_time
            Job_dict[u'end_time'] = self._record.end_time
            Job_dict[u'exc_nodes'] = slurm.listOrNone(self._record.exc_nodes, ',')

            if WIFSIGNALED(self._record.exit_code):
                term_sig = WTERMSIG(self._record.exit_code)

            exit_status = WEXITSTATUS(self._record.exit_code)
            Job_dict[u'exit_code'] = str(exit_status) + ":" + str(term_sig)

            Job_dict[u'features'] = slurm.listOrNone(self._record.features, ',')
            Job_dict[u'fed_origin'] = slurm.stringOrNone(self._record.fed_origin_str, '')
            Job_dict[u'fed_siblings'] = slurm.stringOrNone(self._record.fed_siblings_str, '')
            Job_dict[u'gres'] = slurm.listOrNone(self._record.gres, ',')
            Job_dict[u'group_id'] = self._record.group_id

            # JOB RESOURCES HERE
            Job_dict[u'job_id'] = self._record.job_id
            Job_dict[u'job_state'] = slurm.stringOrNone(
                slurm.slurm_job_state_string(self._record.job_state), ''
            )

            Job_dict[u'licenses'] = __get_licenses(self._record.licenses)
            Job_dict[u'max_cpus'] = self._record.max_cpus
            Job_dict[u'max_nodes'] = self._record.max_nodes
            Job_dict[u'name'] = slurm.stringOrNone(self._record.name, '')
            Job_dict[u'network'] = slurm.stringOrNone(self._record.network, '')
            Job_dict[u'nodes'] = slurm.stringOrNone(self._record.nodes, '')
            Job_dict[u'nice'] = (<int64_t>self._record.nice) - NICE_OFFSET
            Job_dict[u'ntasks_per_core'] = self._record.ntasks_per_core
            Job_dict[u'ntasks_per_node'] = self._record.ntasks_per_node
            Job_dict[u'ntasks_per_socket'] = self._record.ntasks_per_socket
            Job_dict[u'ntasks_per_board'] = self._record.ntasks_per_board
            Job_dict[u'num_cpus'] = self._record.num_cpus
            Job_dict[u'num_nodes'] = self._record.num_nodes
            Job_dict[u'partition'] = slurm.stringOrNone(self._record.partition, '')

            if self._record.pn_min_memory & slurm.MEM_PER_CPU:
                self._record.pn_min_memory &= (~slurm.MEM_PER_CPU)
                Job_dict[u'mem_per_cpu'] = True
                Job_dict[u'min_memory_cpu'] = self._record.pn_min_memory
                Job_dict[u'mem_per_node'] = False
                Job_dict[u'min_memory_node'] = None
            else:
                Job_dict[u'mem_per_cpu'] = False
                Job_dict[u'min_memory_cpu'] = None
                Job_dict[u'mem_per_node'] = True
                Job_dict[u'min_memory_node'] = self._record.pn_min_memory

            Job_dict[u'pn_min_memory'] = self._record.pn_min_memory
            Job_dict[u'pn_min_cpus'] = self._record.pn_min_cpus
            Job_dict[u'pn_min_tmp_disk'] = self._record.pn_min_tmp_disk
            Job_dict[u'power_flags'] = self._record.power_flags

            if self._record.preempt_time == 0:
                Job_dict[u'preempt_time'] = None
            else:
                Job_dict[u'preempt_time'] = self._record.preempt_time

            Job_dict[u'priority'] = self._record.priority
            Job_dict[u'profile'] = self._record.profile
            Job_dict[u'qos'] = slurm.stringOrNone(self._record.qos, '')
            Job_dict[u'reboot'] = self._record.reboot
            Job_dict[u'req_nodes'] = slurm.listOrNone(self._record.req_nodes, ',')
            Job_dict[u'req_switch'] = self._record.req_switch
            Job_dict[u'requeue'] = bool(self._record.requeue)
            Job_dict[u'resize_time'] = self._record.resize_time
            Job_dict[u'restart_cnt'] = self._record.restart_cnt
            Job_dict[u'resv_name'] = slurm.stringOrNone(self._record.resv_name, '')

            if IS_JOB_PENDING(self._job_ptr.job_array[i]):
                run_time = 0
            elif IS_JOB_SUSPENDED(self._job_ptr.job_array[i]):
                run_time = self._record.pre_sus_time
            else:
                if (IS_JOB_RUNNING(self._job_ptr.job_array[i]) or self._record.end_time == 0):
                    end_time = time(NULL)
                else:
                    end_time = self._record.end_time

                if self._record.suspend_time:
                    run_time = <time_t>difftime(end_time, self._record.suspend_time) + self._record.pre_sus_time
                else:
                    run_time = <time_t>difftime(end_time, self._record.start_time)

            Job_dict[u'run_time'] = run_time
            Job_dict[u'run_time_str'] = secs2time_str(run_time)
            Job_dict[u'sched_nodes'] = slurm.stringOrNone(self._record.sched_nodes, '')

            if self._record.shared == 0:
                Job_dict[u'shared'] = u"0"
            elif self._record.shared == 1:
                Job_dict[u'shared'] = u"1"
            elif self._record.shared == 2:
                Job_dict[u'shared'] = u"USER"
            else:
                Job_dict[u'shared'] = u"OK"

            Job_dict[u'show_flags'] = self._record.show_flags
            Job_dict[u'sockets_per_board'] = self._record.sockets_per_board
            Job_dict[u'sockets_per_node'] = self._record.sockets_per_node
            Job_dict[u'start_time'] = self._record.start_time

            if self._record.state_desc:
                Job_dict[u'state_reason'] = self._record.state_desc.decode("UTF-8").replace(" ", "_")
            else:
                Job_dict[u'state_reason'] = slurm.stringOrNone(
                    slurm.slurm_job_reason_string(
                        <slurm.job_state_reason>self._record.state_reason
                    ), ''
                )

            if self._record.batch_flag:
                slurm.slurm_get_job_stderr(tmp_line, sizeof(tmp_line), self._record)
                Job_dict[u'std_err'] = slurm.stringOrNone(tmp_line, '')

                slurm.slurm_get_job_stdin(tmp_line, sizeof(tmp_line), self._record)
                Job_dict[u'std_in'] = slurm.stringOrNone(tmp_line, '')

                slurm.slurm_get_job_stdout(tmp_line, sizeof(tmp_line), self._record)
                Job_dict[u'std_out'] = slurm.stringOrNone(tmp_line, '')
            else:
                Job_dict[u'std_err'] = None
                Job_dict[u'std_in'] = None
                Job_dict[u'std_out'] = None

            Job_dict[u'submit_time'] = self._record.submit_time
            Job_dict[u'suspend_time'] = self._record.suspend_time

            if self._record.time_limit == slurm.NO_VAL:
                Job_dict[u'time_limit'] = u"Partition_Limit"
                Job_dict[u'time_limit_str'] = u"Partition_Limit"
            elif self._record.time_limit == slurm.INFINITE:
                Job_dict[u'time_limit'] = u"UNLIMITED"
                Job_dict[u'time_limit_str'] = u"UNLIMITED"
            else:
                Job_dict[u'time_limit'] = self._record.time_limit
                Job_dict[u'time_limit_str'] = mins2time_str(
                    self._record.time_limit)

            Job_dict[u'time_min'] = self._record.time_min
            Job_dict[u'threads_per_core'] = self._record.threads_per_core
            Job_dict[u'tres_req_str'] = slurm.stringOrNone(self._record.tres_req_str, '')
            Job_dict[u'tres_alloc_str'] = slurm.stringOrNone(self._record.tres_alloc_str, '')
            Job_dict[u'user_id'] = self._record.user_id
            Job_dict[u'wait4switch'] = self._record.wait4switch
            Job_dict[u'wckey'] = slurm.stringOrNone(self._record.wckey, '')
            Job_dict[u'work_dir'] = slurm.stringOrNone(self._record.work_dir, '')

            Job_dict[u'altered'] = self.__get_select_jobinfo(SELECT_JOBDATA_ALTERED)
            Job_dict[u'block_id'] = self.__get_select_jobinfo(SELECT_JOBDATA_BLOCK_ID)
            Job_dict[u'blrts_image'] = self.__get_select_jobinfo(SELECT_JOBDATA_BLRTS_IMAGE)
            Job_dict[u'cnode_cnt'] = self.__get_select_jobinfo(SELECT_JOBDATA_NODE_CNT)
            Job_dict[u'ionodes'] = self.__get_select_jobinfo(SELECT_JOBDATA_IONODES)
            Job_dict[u'linux_image'] = self.__get_select_jobinfo(SELECT_JOBDATA_LINUX_IMAGE)
            Job_dict[u'mloader_image'] = self.__get_select_jobinfo(SELECT_JOBDATA_MLOADER_IMAGE)
            Job_dict[u'ramdisk_image'] = self.__get_select_jobinfo(SELECT_JOBDATA_RAMDISK_IMAGE)
            Job_dict[u'resv_id'] = self.__get_select_jobinfo(SELECT_JOBDATA_RESV_ID)
            Job_dict[u'rotate'] = bool(self.__get_select_jobinfo(SELECT_JOBDATA_ROTATE))

            Job_dict[u'conn_type'] = slurm.stringOrNone(
                slurm.slurm_conn_type_string(self.__get_select_jobinfo(SELECT_JOBDATA_CONN_TYPE)), ''
            )

            Job_dict[u'cpus_allocated'] = {}
            Job_dict[u'cpus_alloc_layout'] = {}

            if self._record.nodes is not NULL:
                hl = hostlist()
                _nodes = slurm.stringOrNone(self._record.nodes, '')
                hl.create(_nodes)
                host_list = hl.get_list()
                if host_list:
                    for node_name in host_list:
                        b_node_name = node_name.decode("UTF-8")
                        Job_dict[u'cpus_allocated'][b_node_name] = self.__cpus_allocated_on_node(node_name)
                        Job_dict[u'cpus_alloc_layout'][b_node_name] = self.__cpus_allocated_list_on_node(node_name)
                hl.destroy()

            self._JobDict[self._record.job_id] = Job_dict

        slurm.slurm_free_job_info_msg(self._job_ptr)
        self._job_ptr = NULL
        return self._JobDict

    cpdef __get_select_jobinfo(self, uint32_t dataType):
        u"""Decode opaque data type jobinfo.

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

        if dataType == SELECT_JOBDATA_GEOMETRY:  # Int array[SYSTEM_DIMENSIONS]
            pass

        if dataType == SELECT_JOBDATA_ROTATE or \
           dataType == SELECT_JOBDATA_CONN_TYPE or \
           dataType == SELECT_JOBDATA_ALTERED or \
           dataType == SELECT_JOBDATA_REBOOT:

            retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &retval16)
            if retval == 0:
                jobinfo = NULL
                return retval16

        if dataType == SELECT_JOBDATA_NODE_CNT or dataType == SELECT_JOBDATA_RESV_ID:
            retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &retval32)
            if retval == 0:
                jobinfo = NULL
                return retval32

        if dataType == SELECT_JOBDATA_BLOCK_ID or \
           dataType == SELECT_JOBDATA_NODES or \
           dataType == SELECT_JOBDATA_IONODES or \
           dataType == SELECT_JOBDATA_BLRTS_IMAGE or \
           dataType == SELECT_JOBDATA_LINUX_IMAGE or \
           dataType == SELECT_JOBDATA_MLOADER_IMAGE or \
           dataType == SELECT_JOBDATA_RAMDISK_IMAGE or \
           dataType == SELECT_JOBDATA_USER_NAME:

            # data-> char* needs to be freed with xfree

            retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &tmp_str)
            if retval == 0:
                if tmp_str != NULL:
                    retvalStr = strcpy(<char *>slurm.xmalloc(strlen(tmp_str)+1), tmp_str)
                    slurm.xfree(tmp_str)
                    jobinfo = NULL
                    return retvalStr
                else:
                    jobinfo = NULL
                    return ''

        if dataType == SELECT_JOBDATA_PTR:  # data-> select_jobinfo_t *jobinfo
            retval = slurm.slurm_get_select_jobinfo(jobinfo, dataType, &tmp_ptr)
            if retval == 0:
                # populate a dictonary ?
                pass

        jobinfo = NULL
        return None

    cpdef int __cpus_allocated_on_node_id(self, int nodeID=0):
        u"""Get the number of cpus allocated to a job on a node by node name.

        :param int nodeID: Numerical node ID
        :returns: Num of CPUs allocated to job on this node or -1 on error
        :rtype: `integer`
        """
        cdef:
            slurm.job_resources_t *job_resrcs_ptr = <slurm.job_resources_t *>self._record.job_resrcs
            int retval = slurm.slurm_job_cpus_allocated_on_node_id(job_resrcs_ptr, nodeID)

        return retval

    cdef int __cpus_allocated_on_node(self, char* nodeName=''):
        u"""Get the number of cpus allocated to a slurm job on a node by node name.

        :param string nodeName: Name of node
        :returns: Num of CPUs allocated to job on this node or -1 on error
        :rtype: `integer`
        """
        cdef:
            slurm.job_resources_t *job_resrcs_ptr = <slurm.job_resources_t *>self._record.job_resrcs
            int retval = slurm.slurm_job_cpus_allocated_on_node(job_resrcs_ptr, nodeName)

        return retval

    cdef list __cpus_allocated_list_on_node(self, char* nodeName=''):
        u"""Get a list of cpu ids allocated to current slurm job on a node by node name.

        :param string nodeName: Name of node
        :returns: list of allocated cpus (empty, if nothing found or error)
        :rtype: `list`
        """
        cdef:
            int error = 0
            int cpus_len = 1024
            char *cpus
            list cpus_list = []
            slurm.job_resources_t *job_resrcs_ptr = <slurm.job_resources_t *>self._record.job_resrcs

        cpus = <char *>malloc(cpus_len * sizeof(char))
        if cpus is not NULL:
            try:
                error = slurm.slurm_job_cpus_allocated_str_on_node(cpus, cpus_len, job_resrcs_ptr, nodeName)
                if error == 0:
                    cpus_list = self.__unrange(slurm.stringOrNone(cpus, ''))
            finally:
                free(cpus)

        return cpus_list

    def __unrange(self, bit_str):
        u"""converts a string describing a bitmap (from slurm_job_cpus_allocated_str_on_node()) to a list.

        :param string bit_str: string describing a bitmap (e.g. "0-30,45,50-60")
        :returns: list referring to bitmap (empty if not succesful)
        :rtype: `list`
        """
        r_list = []

        if not bit_str:
            return []

        for cpu_set in bit_str.split(','):
            try:
                cpus = list(map(int, cpu_set.split('-')))
                for i in range(cpus[0], cpus[-1] + 1):
                    r_list.append(i)
            except:
                return []

        return r_list

    cpdef __free(self):
        u"""Release the storage generated by the slurm_get_job_steps function."""
        if self._job_ptr is not NULL:
            slurm.slurm_free_job_info_msg(self._job_ptr)

    cpdef print_job_info_msg(self, int oneLiner=0):
        u"""Print the data structure describing all job step records.

        The job step records are loaded by the slurm_get_job_steps function.

        :param int Flag: Default=0
        """
        cdef:
            int rc
            int apiError

        rc = slurm.slurm_load_jobs(<time_t> NULL, &self._job_ptr, self._ShowFlags)

        if rc == slurm.SLURM_SUCCESS:
            slurm.slurm_print_job_info_msg(slurm.stdout, self._job_ptr,
                                           oneLiner)
            slurm.slurm_free_job_info_msg(self._job_ptr)
            self._job_ptr = NULL
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)


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
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode, JobID


cdef secs2time_str(uint32_t time):
    u"""Convert seconds to Slurm string format.

    This method converts time in seconds (86400) to Slurm's string format
    (1-00:00:00).

    :param int time: time in seconds
    :returns: time string
    :rtype: `str`
    """
    cdef:
        char *time_str
        long days, hours, minutes, seconds

    if time == slurm.INFINITE:
        time_str = "UNLIMITED"
    else:
        seconds = time % 60
        minutes = (time / 60) % 60
        hours = (time / 3600) % 24
        days = time / 86400

        if days < 0 or  hours < 0 or minutes < 0 or seconds < 0:
            time_str = "INVALID"
        elif days:
            return u"%ld-%2.2ld:%2.2ld:%2.2ld" % (days, hours,
                                                  minutes, seconds)
        else:
            return u"%2.2ld:%2.2ld:%2.2ld" % (hours, minutes, seconds)


cdef mins2time_str(uint32_t time):
    u"""Convert minutes to Slurm string format.

    This method converts time in minutes (14400) to Slurm's string format
    (10-00:00:00).

    :param int time: time in minutes
    :returns: time string
    :rtype: `str`
    """
    cdef:
        long days, hours, minutes, seconds

    if time == slurm.INFINITE:
        return u"UNLIMITED"
    else:
        seconds = 0
        minutes = time % 60
        hours = (time / 60) % 24
        days = time / 1440

        if days < 0 or  hours < 0 or minutes < 0 or seconds < 0:
            time_str = "INVALID"
        elif days:
            return u"%ld-%2.2ld:%2.2ld:%2.2ld" % (days, hours,
                                                  minutes, seconds)
        else:
            return u"%2.2ld:%2.2ld:%2.2ld" % (hours, minutes, seconds)


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
    u"""Print to standard error the supplied header.

    Header is followed by a colon, followed by a text description of the last
    Slurm error code generated.

    :param string Msg: slurm program error String
    """
    slurm.slurm_perror(Msg)


#
# Slurm Node Read/Print/Update Class
#


cdef class node:
    u"""Class to access/modify/update Slurm Node Information."""

    cdef:
        slurm.node_info_msg_t *_Node_ptr
        uint16_t _ShowFlags
        dict _NodeDict
        slurm.time_t _lastUpdate

    def __cinit__(self):
        self._Node_ptr = NULL
        self._ShowFlags = slurm.SHOW_ALL | slurm.SHOW_DETAIL
        self._lastUpdate = 0

    def __dealloc__(self):
        pass

    def lastUpdate(self):
        u"""Return last time (epoch seconds) the node data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    cpdef ids(self):
        u"""Return the node IDs from retrieved data.

        :returns: Dictionary of node IDs
        :rtype: `dict`
        """
        cdef:
            int rc
            int apiError
            uint32_t i
            list all_nodes

        rc = slurm.slurm_load_node(<time_t> NULL, &self._Node_ptr,
                                   self._ShowFlags)

        if rc == slurm.SLURM_SUCCESS:
            all_nodes = []
            for record in self._Node_ptr.node_array[:self._Node_ptr.record_count]:
                all_nodes.append(slurm.stringOrNone(record.name, ''))
            slurm.slurm_free_node_info_msg(self._Node_ptr)
            self._Node_ptr = NULL
            return all_nodes
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    def find_id(self, nodeID):
        u"""Get node information for a given node.

        :param str nodeID: Node key string to search
        :returns: Dictionary of values for given node
        :rtype: `dict`
        """
        return list(self.get_node(nodeID).values())[0]

    def get(self):
        u"""Get all slurm node information.

        :returns: Dictionary of dictionaries whose key is the node name.
        :rtype: `dict`
        """
        return self.get_node(None)

    def get_node(self, nodeID):
        u"""Get single slurm node information.

        :param str nodeID: Node key string to search. Default NULL.
        :returns: Dictionary of give node info data.
        :rtype: `dict`
        """
        cdef:
            int rc
            int apiError
            int total_used
            char *cloud_str
            char *comp_str
            char *drain_str
            char *power_str
            uint16_t err_cpus
            uint16_t alloc_cpus
            uint32_t i
            uint64_t alloc_mem
            uint32_t node_state
            slurm.node_info_t *record
            dict Host_dict

        if nodeID is None:
            rc = slurm.slurm_load_node(<time_t> NULL, &self._Node_ptr,
                                       self._ShowFlags)
        else:
            b_nodeID = nodeID.encode("UTF-8")
            rc = slurm.slurm_load_node_single(&self._Node_ptr, b_nodeID, self._ShowFlags)

        if rc == slurm.SLURM_SUCCESS:
            self._NodeDict = {}
            self._lastUpdate = self._Node_ptr.last_update
            node_scaling = self._Node_ptr.node_scaling
            last_update = self._Node_ptr.last_update

            for i in range(self._Node_ptr.record_count):
                record = &self._Node_ptr.node_array[i]
                Host_dict = {}
                cloud_str = ""
                comp_str = ""
                drain_str = ""
                power_str = ""
                err_cpus = 0
                alloc_cpus = 0
                cpus_per_node = 1

                if record.name is NULL:
                    continue

                total_used = record.cpus
                if (node_scaling):
                    cpus_per_node = total_used / node_scaling

                Host_dict[u'arch'] = slurm.stringOrNone(record.arch, '')
                Host_dict[u'boards'] = record.boards
                Host_dict[u'boot_time'] = record.boot_time
                Host_dict[u'cores'] = record.cores
                Host_dict[u'core_spec_cnt'] = record.core_spec_cnt
                Host_dict[u'cpus'] = record.cpus
                Host_dict[u'cpu_load'] = record.cpu_load
                Host_dict[u'cpu_spec_list'] = slurm.listOrNone(record.cpu_spec_list, '')
                Host_dict[u'features'] = slurm.listOrNone(record.features, '')
                Host_dict[u'features_active'] = slurm.listOrNone(record.features_act, '')
                Host_dict[u'free_mem'] = record.free_mem
                Host_dict[u'gres'] = slurm.listOrNone(record.gres, ',')
                Host_dict[u'gres_drain'] = slurm.listOrNone(record.gres_drain, '')
                Host_dict[u'gres_used'] = slurm.listOrNone(record.gres_used, ',')

                if record.mcs_label == NULL:
                    Host_dict[u'mcs_label'] = None
                else:
                    Host_dict[u'mcs_label'] = record.mcs_label

                Host_dict[u'mem_spec_limit'] = record.mem_spec_limit
                Host_dict[u'name'] = slurm.stringOrNone(record.name, '')
                Host_dict[u'node_addr'] = slurm.stringOrNone(record.node_addr, '')
                Host_dict[u'node_hostname'] = slurm.stringOrNone(record.node_hostname, '')
                Host_dict[u'os'] = slurm.stringOrNone(record.os, '')

                if record.owner == slurm.NO_VAL:
                    Host_dict[u'owner'] = None
                else:
                    Host_dict[u'owner'] = record.owner

                Host_dict[u'partitions'] = slurm.listOrNone(record.partitions, ',')
                Host_dict[u'real_memory'] = record.real_memory
                Host_dict[u'slurmd_start_time'] = record.slurmd_start_time
                Host_dict[u'sockets'] = record.sockets
                Host_dict[u'threads'] = record.threads
                Host_dict[u'tmp_disk'] = record.tmp_disk
                Host_dict[u'weight'] = record.weight
                Host_dict[u'tres_fmt_str'] = slurm.stringOrNone(record.tres_fmt_str, '')
                Host_dict[u'version'] = slurm.stringOrNone(record.version, '')

                Host_dict[u'reason'] = slurm.stringOrNone(record.reason, '')
                if record.reason_time == 0:
                    Host_dict[u'reason_time'] = None
                else:
                    Host_dict[u'reason_time'] = record.reason_time

                if record.reason_uid == slurm.NO_VAL:
                    Host_dict[u'reason_uid'] = None
                else:
                    Host_dict[u'reason_uid'] = record.reason_uid

                # Power Managment
                Host_dict[u'power_mgmt'] = {}
                if (not record.power or (record.power.cap_watts == slurm.NO_VAL)):
                    Host_dict[u'power_mgmt'][u"cap_watts"] = None
                else:
                    Host_dict[u'power_mgmt'][u"cap_watts"] = record.power.cap_watts

                # Energy statistics
                Host_dict[u'energy'] = {}
                if (not record.energy or record.energy.current_watts == slurm.NO_VAL):
                    Host_dict[u'energy'][u'current_watts'] = 0
                    Host_dict[u'energy'][u'base_consumed_energy'] = 0
                    Host_dict[u'energy'][u'consumed_energy'] = 0
                else:
                    Host_dict[u'energy'][u'current_watts'] = record.energy.current_watts
                    Host_dict[u'energy'][u'base_consumed_energy'] = int(record.energy.base_consumed_energy)
                    Host_dict[u'energy'][u'consumed_energy'] = int(record.energy.consumed_energy)

                Host_dict[u'energy'][u'base_watts'] = record.energy.base_watts
                Host_dict[u'energy'][u'previous_consumed_energy'] = int(record.energy.previous_consumed_energy)

                node_state = record.node_state
                if (node_state & NODE_STATE_CLOUD):
                    node_state &= (~NODE_STATE_CLOUD)
                    cloud_str = "+CLOUD"

                if (node_state & NODE_STATE_COMPLETING):
                    node_state &= (~NODE_STATE_COMPLETING)
                    comp_str = "+COMPLETING"

                if (node_state & NODE_STATE_DRAIN):
                    node_state &= (~NODE_STATE_DRAIN)
                    drain_str = "+DRAIN"

                if (node_state & NODE_STATE_FAIL):
                    node_state &= (~NODE_STATE_FAIL)
                    drain_str = "+FAIL"

                if (node_state & NODE_STATE_POWER_SAVE):
                    node_state &= (~NODE_STATE_POWER_SAVE)
                    power_str = "+POWER"

                slurm.slurm_get_select_nodeinfo(record.select_nodeinfo,
                                                SELECT_NODEDATA_SUBCNT,
                                                NODE_STATE_ALLOCATED,
                                                &alloc_cpus)

                Host_dict[u'alloc_cpus'] = alloc_cpus
                total_used -= alloc_cpus

                slurm.slurm_get_select_nodeinfo(record.select_nodeinfo,
                                                SELECT_NODEDATA_SUBCNT,
                                                NODE_STATE_ERROR, &err_cpus)

                Host_dict[u'err_cpus'] = err_cpus
                total_used -= err_cpus

                if (alloc_cpus and err_cpus) or (total_used and
                   (total_used != record.cpus)):
                    node_state &= NODE_STATE_FLAGS
                    node_state |= NODE_STATE_MIXED

                Host_dict[u'state'] = (
                    slurm.stringOrNone(slurm.slurm_node_state_string(node_state), '') +
                    slurm.stringOrNone(cloud_str, '') +
                    slurm.stringOrNone(comp_str, '') +
                    slurm.stringOrNone(drain_str, '') +
                    slurm.stringOrNone(power_str, '')
                )

                slurm.slurm_get_select_nodeinfo(record.select_nodeinfo,
                                                SELECT_NODEDATA_MEM_ALLOC,
                                                NODE_STATE_ALLOCATED, &alloc_mem)

                Host_dict[u'alloc_mem'] = alloc_mem

                b_name = slurm.stringOrNone(record.name, '')
                self._NodeDict[b_name] = Host_dict

            slurm.slurm_free_node_info_msg(self._Node_ptr)
            self._Node_ptr = NULL
            return self._NodeDict
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    cpdef update(self, dict node_dict):
        u"""Update slurm node information.

        :param dict node_dict: A populated node dictionary, an empty one is
            created by create_node_dict
        :returns: 0 for success or -1 for error, and the slurm error code
            is set appropriately.
        :rtype: `integer`
        """
        return slurm_update_node(node_dict)

    cpdef print_node_info_msg(self, int oneLiner=False):
        u"""Output information about all slurm nodes.

        :param int oneLiner: Print on one line - False (Default) or True
        """
        cdef:
            int rc
            int apiError

        rc = slurm.slurm_load_node(<time_t> NULL, &self._Node_ptr,
                                   self._ShowFlags)

        if rc == slurm.SLURM_SUCCESS:
            slurm.slurm_print_node_info_msg(slurm.stdout, self._Node_ptr, oneLiner)
            slurm.slurm_free_node_info_msg(self._Node_ptr)
            self._Node_ptr = NULL
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)


def slurm_update_node(dict node_dict):
    u"""Update slurm node information.

    :param dict node_dict: A populated node dictionary, an empty one is
        created by create_node_dict
    :returns: 0 for success or -1 for error, and the slurm error code
        is set appropriately.
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
        # see enum node_states
        node_msg.node_state = <uint16_t>node_dict['node_state']

    if 'features' in node_dict:
        b_features = node_dict['features'].encode("UTF-8", "replace")
        node_msg.features = b_features

    if 'gres' in node_dict:
        b_gres = node_dict['gres'].encode("UTF-8")
        node_msg.gres = b_gres

    if 'node_names' in node_dict:
        b_node_names = node_dict['node_names'].encode("UTF-8")
        node_msg.node_names = b_node_names

    if 'reason' in node_dict:
        b_reason = node_dict['reason'].encode("UTF-8")
        node_msg.reason = b_reason
        node_msg.reason_uid = <uint32_t>os.getuid()

    if 'weight' in node_dict:
        node_msg.weight = <uint32_t>node_dict['weight']

    errCode = slurm.slurm_update_node(&node_msg)

    if errCode != slurm.SLURM_SUCCESS:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


def create_node_dict():
    u"""Return a an update_node dictionary

    This dictionary can be populated by the user and used for the update_node
    call.

    :returns: Empty node dictionary
    :rtype: `dict`
    """
    return {
        'node_names': None,
        'gres': None,
        'reason': None,
        'node_state': 0,
        'weight': 0,
        'features': None
    }


#
# Jobstep Class
#


cdef class jobstep:
    u"""Class to access/modify Slurm Jobstep Information."""

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
        u"""Free the slurm job memory allocated by load jobstep method."""
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

        if not self._JobStepDict:
            self.get()

        for key, value in self._JobStepDict.items():
            for new_key in value.keys():
                jobsteps.setdefault(key, []).append(new_key)

        return jobsteps

    def find(self, jobID=-1, stepID=-1):
        cdef dict retDict = {}

        # retlist = [key for key, value in self.blockID.items()
        #            if self.blockID[key][name] == value ]

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
        u"""Load details about job steps.

        This method loads details about job steps that satisfy the job_id
        and/or step_id specifications provided if the data has been updated
        since the update_time specified.

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
            uint16_t ShowFlags = self._ShowFlags ^ slurm.SHOW_ALL
            int i = 0
            int errCode = slurm.slurm_get_job_steps(last_time, self.JobID,
                                                    self.StepID, &job_step_info_ptr,
                                                    ShowFlags)

        if errCode != 0:
            self._JobStepDict = {}
            return

        if job_step_info_ptr is not NULL:

            for i in range(job_step_info_ptr.job_step_count):

                job_id = job_step_info_ptr.job_steps[i].job_id
                step_id = job_step_info_ptr.job_steps[i].step_id

                Steps[job_id] = {}
                Step_dict = {}

                if job_step_info_ptr.job_steps[i].array_job_id:
                    Step_dict[u'array_job_id'] = job_step_info_ptr.job_steps[i].array_job_id
                    Step_dict[u'array_task_id'] = job_step_info_ptr.job_steps[i].array_task_id
                else:
                    Step_dict[u'array_job_id'] = None
                    Step_dict[u'array_task_id'] = None

                Step_dict[u'ckpt_dir'] = slurm.stringOrNone(
                    job_step_info_ptr.job_steps[i].ckpt_dir, ''
                )
                Step_dict[u'ckpt_interval'] = job_step_info_ptr.job_steps[i].ckpt_interval

                Step_dict[u'dist'] = slurm.stringOrNone(
                    slurm.slurm_step_layout_type_name(
                        <slurm.task_dist_states_t>job_step_info_ptr.job_steps[i].task_dist
                    ), ''
                )

                Step_dict[u'gres'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].gres, '')
                Step_dict[u'name'] = slurm.stringOrNone( job_step_info_ptr.job_steps[i].name, '')
                Step_dict[u'network'] = slurm.stringOrNone( job_step_info_ptr.job_steps[i].network, '')
                Step_dict[u'nodes'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].nodes, '')
                Step_dict[u'num_cpus'] = job_step_info_ptr.job_steps[i].num_cpus
                Step_dict[u'num_tasks'] = job_step_info_ptr.job_steps[i].num_tasks
                Step_dict[u'partition'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].partition, '')
                Step_dict[u'resv_ports'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].resv_ports, '')
                Step_dict[u'run_time'] = job_step_info_ptr.job_steps[i].run_time
                Step_dict[u'srun_host'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].srun_host, '')
                Step_dict[u'srun_pid'] = job_step_info_ptr.job_steps[i].srun_pid
                Step_dict[u'start_time'] = job_step_info_ptr.job_steps[i].start_time

                job_state = slurm.slurm_job_state_string(job_step_info_ptr.job_steps[i].state)
                Step_dict[u'state'] = slurm.stringOrNone(job_state, '')

                if job_step_info_ptr.job_steps[i].time_limit == slurm.INFINITE:
                    Step_dict[u'time_limit'] = u"UNLIMITED"
                    Step_dict[u'time_limit_str'] = u"UNLIMITED"
                else:
                    Step_dict[u'time_limit'] = job_step_info_ptr.job_steps[i].time_limit
                    Step_dict[u'time_limit_str'] = secs2time_str(job_step_info_ptr.job_steps[i].time_limit)

                Step_dict[u'tres_alloc_str'] = slurm.stringOrNone(
                    job_step_info_ptr.job_steps[i].tres_alloc_str, ''
                )

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
        cdef:
            slurm.slurm_step_layout_t *old_job_step_ptr
            int i = 0, j = 0, Node_cnt = 0

            dict Layout = {}
            list Nodes = [], Node_list = [], Tids_list = []

        old_job_step_ptr = slurm.slurm_job_step_layout_get(JobID, StepID)

        if old_job_step_ptr is not NULL:

            Node_cnt = old_job_step_ptr.node_cnt

            Layout[u'front_end'] = slurm.stringOrNone(old_job_step_ptr.front_end, '')
            Layout[u'node_cnt'] = Node_cnt
            Layout[u'node_list'] = slurm.stringOrNone(old_job_step_ptr.node_list, '')
            Layout[u'plane_size'] = old_job_step_ptr.plane_size
            Layout[u'task_cnt'] = old_job_step_ptr.task_cnt
            Layout[u'task_dist'] = old_job_step_ptr.task_dist
            Layout[u'task_dist'] = slurm.stringOrNone(
                slurm.slurm_step_layout_type_name(<slurm.task_dist_states_t>old_job_step_ptr.task_dist), ''
            )

            hl = hostlist()
            node_list = slurm.stringOrNone(old_job_step_ptr.node_list, '')
            hl.create(node_list)
            Nodes = hl.get_list()
            hl.destroy()

            for i, node in enumerate(Nodes):
                Tids_list = []
                for j in range(old_job_step_ptr.tasks[i]):
                    Tids_list.append(old_job_step_ptr.tids[i][j])
                Node_list.append([slurm.stringOrNone(node, ''), Tids_list])

            Layout[u'tasks'] = Node_list

            slurm.slurm_job_step_layout_free(old_job_step_ptr)

        return Layout


#
# Hostlist Class
#


cdef class hostlist:
    u"""Wrapper class for Slurm hostlist functions."""

    cdef slurm.hostlist_t hl

    def __cinit__(self):
        self.hl = NULL

    def __dealloc__(self):
        self.destroy()

    def create(self, hostnames=None):
        if not hostnames:
            self.hl = slurm.slurm_hostlist_create(NULL)
        else:
            b_hostnames = hostnames.encode("UTF-8")
            self.hl = slurm.slurm_hostlist_create(b_hostnames)
        if not self.hl:
            raise ValueError("No memory")
        else:
            return True

    def destroy(self):
        if self.hl is not NULL:
            slurm.slurm_hostlist_destroy(self.hl)
            self.hl = NULL

    def count(self):
        return slurm.slurm_hostlist_count(self.hl)

    cpdef get_list(self):
        u"""Get the list of hostnames composing the hostlist.

        For example with a hostlist created with "tux[1-3]" -> [ 'tux1', tux2',
        'tux3' ].

        :returns: the list of hostnames in case of success or None on error.
        :rtype: list
        """
        cdef:
            slurm.hostlist_t hlist = NULL
            char *hostlist_s = NULL
            char *tmp_str = NULL
            list host_list = None
            unsigned int nb_hosts
            unsigned int host_index

        py_string = ''

        if self.hl is not NULL:
            # make a copy of self.hl since slurm.slurm_hostlist_shift() is destructive.
            tmp_str = slurm.slurm_hostlist_ranged_string_xmalloc(self.hl)
            if tmp_str is not NULL:
                hlist = slurm.slurm_hostlist_create(tmp_str)
                nb_hosts = slurm.slurm_hostlist_count(hlist)
                host_list = []
                for host_index in range(nb_hosts):
                    hostlist_s = slurm.slurm_hostlist_shift(hlist)
                    py_string = hostlist_s
                    free(hostlist_s)
                    host_list.append(py_string)

                slurm.xfree(tmp_str)
                slurm.slurm_hostlist_destroy(hlist)

        return host_list

    def get(self):
        cdef:
            char *hostlist_s = NULL
            char *tmp_str = NULL

        py_string = None
        if self.hl is not NULL:
            tmp_str = slurm.slurm_hostlist_ranged_string_xmalloc(self.hl)
            if tmp_str is not NULL:
                hostlist_s = <char *>malloc(strlen(tmp_str) + 1)
                strcpy(hostlist_s, tmp_str)
                py_string = hostlist_s
                free(hostlist_s)
                slurm.xfree(tmp_str)

        return py_string

    def ranged_string(self):
        if self.hl is not NULL:
            return slurm.stringOrNone(slurm.slurm_hostlist_ranged_string_malloc(self.hl), '')

    def find(self, hostname):
        if self.hl is not NULL:
            b_hostname = hostname.encode("UTF-8")
            return slurm.slurm_hostlist_find(self.hl, b_hostname)

    def pop(self):
        if self.hl is not NULL:
            return slurm.stringOrNone(slurm.slurm_hostlist_shift(self.hl), '')

    def shift(self):
        return self.pop()

    def push(self, hosts):
        if self.hl is not NULL:
            b_hosts = hosts.encode("UTF-8")
            return slurm.slurm_hostlist_push(self.hl, b_hosts)

    def push_host(self, host):
        if self.hl is not NULL:
            b_host = host.encode("UTF-8")
            return slurm.slurm_hostlist_push_host(self.hl, b_host)

    def uniq(self):
        if self.hl is not NULL:
            slurm.slurm_hostlist_uniq(self.hl)


#
# Trigger Get/Set/Update Class
#


cdef class trigger:

    def set(self, dict trigger_dict):
        u"""Set or create a slurm trigger.

        :param dict trigger_dict: A populated dictionary of trigger information
        :returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
        :rtype: `integer`
        """
        cdef:
            slurm.trigger_info_t trigger_set
            int errCode = -1

        slurm.slurm_init_trigger_msg(&trigger_set)

        if 'jobid' in trigger_dict:
            JobId = trigger_dict[u'jobid']
            trigger_set.res_type = TRIGGER_RES_TYPE_JOB  # 1

            if isinstance(JobId, int):
                JobId = str(JobId)

            b_JobId = JobId.encode("UTF-8")
            trigger_set.res_id = b_JobId

            if 'fini' in trigger_dict:
                trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_FINI  # 0x0010
            if 'offset' in trigger_dict:
                trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_TIME  # 0x0008

        elif 'node' in trigger_dict:
            trigger_set.res_type = TRIGGER_RES_TYPE_NODE
            if trigger_dict[u'node'] == '':
                trigger_set.res_id = '*'
            else:
                b_node = trigger_dict[u'node'].encode("UTF-8")
                trigger_set.res_id = b_node

        trigger_set.offset = 0x8000
        if 'offset' in trigger_dict:
            trigger_set.offset = trigger_set.offset + trigger_dict[u'offset']

        b_program = trigger_dict[u'program'].encode("UTF-8")
        trigger_set.program = b_program

        event = trigger_dict[u'event']
        if event == 'block_err':
            trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_BLOCK_ERR  # 0x0040

        if event == 'drained':
            trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_DRAINED    # 0x0100

        if event == 'down':
            trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_DOWN       # 0x0002

        if event == 'fail':
            trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_FAIL       # 0x0004

        if event == 'up':
            trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_UP         # 0x0001

        if event == 'idle':
            trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_IDLE       # 0x0080

        if event == 'reconfig':
            trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_RECONFIG   # 0x0020

        while slurm.slurm_set_trigger(&trigger_set):
            slurm.slurm_perror('slurm_set_trigger')
            # EAGAIN
            if slurm.slurm_get_errno() != 11:
                errCode = slurm.slurm_get_errno()
                return errCode

            p_time.sleep(5)

        return 0

    def get(self):
        u"""Get the information on slurm triggers.

        :returns: Where key is the trigger ID
        :rtype: `dict`
        """
        cdef:
            slurm.trigger_info_msg_t *trigger_get = NULL
            int errCode = slurm.slurm_get_triggers(&trigger_get)
            dict Triggers = {}, Trigger_dict

        if errCode == 0:
            for record in trigger_get.trigger_array[:trigger_get.record_count]:
                trigger_id = record.trig_id

                Trigger_dict = {}
                Trigger_dict[u'flags'] = record.flags
                Trigger_dict[u'trig_id'] = trigger_id
                Trigger_dict[u'res_type'] = record.res_type
                Trigger_dict[u'res_id'] = slurm.stringOrNone(record.res_id, '')
                Trigger_dict[u'trig_type'] = record.trig_type
                Trigger_dict[u'offset'] = record.offset - 0x8000
                Trigger_dict[u'user_id'] = record.user_id
                Trigger_dict[u'program'] = slurm.stringOrNone(record.program, '')

                Triggers[trigger_id] = Trigger_dict

            slurm.slurm_free_trigger_msg(trigger_get)

        return Triggers

    def clear(self, TriggerID=0, UserID=slurm.NO_VAL, ID=0):
        u"""Clear or remove a slurm trigger.

        :param string TriggerID: Trigger Identifier
        :param string UserID: User Identifier
        :param string ID: Job Identifier
        :returns: 0 for success or a slurm error code
        :rtype: `integer`
        """
        cdef:
            slurm.trigger_info_t trigger_clear
            int errCode

        if not (TriggerID or UserID or ID):
            raise ValueError("One of `TriggerID` or `UserID` or `ID` must be provided.")

        trigger_clear.trig_id = TriggerID
        trigger_clear.user_id = UserID

        if ID:
            trigger_clear.res_type = TRIGGER_RES_TYPE_JOB  # 1
            b_job_id = str(ID).encode("UTF-8")
            trigger_clear.res_id = b_job_id

        errCode = slurm.slurm_clear_trigger(&trigger_clear)

        if errCode != slurm.SLURM_SUCCESS:
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(errCode), ''), errCode)

        return errCode


#
# Reservation Class
#


cdef class reservation:
    u"""Class to access/update/delete slurm reservation Information."""

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

    def find_id(self, resID):
        u"""Retrieve reservation ID data.

        :param str resID: Reservation key string to search
        :returns: Dictionary of values for given reservation key
        :rtype: `dict`
        """
        return self._ResDict.get(resID, {})

    def find(self, name='', val=''):
        u"""Search for property and associated value in reservation data.

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

    cdef int __load(self) except? -1:
        u"""Load slurm reservation information."""

        cdef:
            slurm.reserve_info_msg_t *new_reserve_info_ptr = NULL
            slurm.time_t last_time = <slurm.time_t>NULL
            int apiError = 0, errCode = 0

        if self._Res_ptr is not NULL:

            errCode = slurm.slurm_load_reservations(self._Res_ptr.last_update,
                                                    &new_reserve_info_ptr)
            if errCode == slurm.SLURM_SUCCESS:
                slurm.slurm_free_reservation_info_msg(self._Res_ptr)
            elif slurm.slurm_get_errno() == 1900:   # SLURM_NO_CHANGE_IN_DATA
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
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

        return errCode

    cdef __free(self):
        u"""Free slurm reservation pointer."""

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

    cdef __get(self):
        cdef:
            dict Reservations = {}
            dict Res_dict

        if self._Res_ptr is not NULL:

            for record in self._Res_ptr.reservation_array[:self._Res_ptr.record_count]:

                name = slurm.stringOrNone(record.name, '')

                Res_dict = {}
                Res_dict[u'accounts'] = slurm.listOrNone(record.accounts, ',')
                Res_dict[u'burst_buffer'] = slurm.listOrNone(record.burst_buffer, ',')
                Res_dict[u'core_cnt'] = record.core_cnt
                Res_dict[u'end_time'] = record.end_time
                Res_dict[u'features'] = slurm.listOrNone(record.features, ',')

                flags = slurm.slurm_reservation_flags_string(record.flags)
                Res_dict[u'flags'] = slurm.stringOrNone(flags, '')

                Res_dict[u'licenses'] = __get_licenses(record.licenses)
                Res_dict[u'node_cnt'] = record.node_cnt
                Res_dict[u'node_list'] = slurm.stringOrNone(record.node_list, '')
                Res_dict[u'partition'] = slurm.stringOrNone(record.partition, '')
                Res_dict[u'start_time'] = record.start_time
                Res_dict[u'resv_watts'] = record.resv_watts
                Res_dict[u'tres_str'] = slurm.listOrNone(record.tres_str, ',')
                Res_dict[u'users'] = slurm.listOrNone(record.users, ',')

                Reservations[name] = Res_dict

        self._ResDict = Reservations

    def create(self, dict reservation_dict={}):
        u"""Create slurm reservation."""
        return slurm_create_reservation(reservation_dict)

    def delete(self, ResID):
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

    def print_reservation_info_msg(self, int oneLiner=0):
        u"""Output information about all slurm reservations.

        :param int Flags: Print on one line - 0 (Default) or 1
        """
        if self._Res_ptr is not NULL:
            slurm.slurm_print_reservation_info_msg(slurm.stdout, self._Res_ptr, oneLiner)


#
# Reservation Helper Functions
#


def slurm_create_reservation(dict reservation_dict={}):
    u"""Create a slurm reservation.

    :param dict reservation_dict: A populated reservation dictionary,
        an empty one is created by create_reservation_dict
    :returns: 0 for success or -1 for error, and the slurm error code
        is set appropriately.
    :rtype: `string`
    """
    cdef:
        slurm.resv_desc_msg_t resv_msg
        char *resid = NULL
        int int_value = 0
        int free_users = 0
        int free_accounts = 0
        unsigned int uint32_value
        slurm.time_t time_value

    slurm.slurm_init_resv_desc_msg(&resv_msg)

    resv_msg.start_time = reservation_dict[u'start_time']

    if not (reservation_dict.get('duration') or reservation_dict.get('end_time')):
        raise ValueError("You must provide either duration or end_time.")

    if (reservation_dict.get('duration') and reservation_dict.get('end_time')):
        raise ValueError("You must provide either duration or end_time.")

    if reservation_dict.get('duration'):
        resv_msg.duration = reservation_dict[u'duration']

    if reservation_dict.get('end_time'):
        resv_msg.end_time = reservation_dict[u'end_time']

    if reservation_dict.get('node_cnt'):
        int_value = reservation_dict[u'node_cnt']
        resv_msg.node_cnt = <uint32_t*>slurm.xmalloc(sizeof(uint32_t) * 2)
        resv_msg.node_cnt[0] = int_value
        resv_msg.node_cnt[1] = 0

    if reservation_dict.get('core_cnt') and not reservation_dict.get('node_list'):
        uint32_value = reservation_dict[u'core_cnt'][0]
        resv_msg.core_cnt = <uint32_t*>slurm.xmalloc(sizeof(uint32_t))
        resv_msg.core_cnt[0] = uint32_value

    if reservation_dict.get('node_list'):
        b_node_list = reservation_dict[u'node_list'].encode("UTF-8")
        resv_msg.node_list = b_node_list
        if reservation_dict.get('core_cnt'):
            hl = hostlist()
            hl.create(b_node_list)
            if len(reservation_dict[u'core_cnt']) != hl.count():
                raise ValueError("core_cnt list must have the same # elements as the expanded hostlist")
            resv_msg.core_cnt = <uint32_t*>slurm.xmalloc(sizeof(uint32_t) * hl.count())
            int_value = 0
            for cores in reservation_dict[u'core_cnt']:
                uint32_value = cores
                resv_msg.core_cnt[int_value] = uint32_value
                int_value += 1

    if reservation_dict.get('users'):
        b_users = reservation_dict[u'users'].encode("UTF-8", "replace")
        resv_msg.users = b_users

    if reservation_dict.get('accounts'):
        b_accounts = reservation_dict[u'accounts'].encode("UTF-8", "replace")
        resv_msg.accounts = b_accounts

    if reservation_dict.get('licenses'):
        b_licenses = reservation_dict[u'licenses'].encode("UTF-8")
        resv_msg.licenses = b_licenses

    if reservation_dict.get('flags'):
        int_value = reservation_dict[u'flags']
        resv_msg.flags = int_value

    if reservation_dict.get('partition'):
        b_name = reservation_dict[u'partition'].encode("UTF-8")
        resv_msg.partition = b_name

    if reservation_dict.get('name'):
        b_name = reservation_dict[u'name'].encode("UTF-8")
        resv_msg.name = b_name

    resid = slurm.slurm_create_reservation(&resv_msg)

    resID = ''
    if resid is not NULL:
        resID = slurm.stringOrNone(resid, '')
        free(resid)
    else:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return resID

def slurm_update_reservation(dict reservation_dict={}):
    u"""Update a slurm reservation.

    :param dict reservation_dict: A populated reservation dictionary,
        an empty one is created by create_reservation_dict
    :returns: 0 for success or -1 for error, and the slurm error code
        is set appropriately.
    :rtype: `integer`
    """
    cdef:
        slurm.resv_desc_msg_t resv_msg
        char* name = NULL
        int free_users = 0, free_accounts = 0, errCode = 0
        uint32_t uint32_value
        slurm.time_t time_value

    slurm.slurm_init_resv_desc_msg(&resv_msg)

    # Be careful: Updating the start_time fails, if the previous start_time
    # of the reservation is in the past.
    # Set reservation_dict[u'start_time'] = -1 to handle this case.
    if reservation_dict.get('start_time'):
        time_value = reservation_dict.get('start_time')
        if time_value != -1:
            resv_msg.start_time = time_value

    if reservation_dict.get('duration'):
        resv_msg.duration = reservation_dict.get('duration')

    if reservation_dict.get('name'):
        b_name = reservation_dict[u'name'].encode("UTF-8", "replace")
        resv_msg.name = b_name

    if reservation_dict.get('node_cnt'):
        int_value = reservation_dict[u'node_cnt']
        resv_msg.node_cnt = <uint32_t*>slurm.xmalloc(sizeof(uint32_t) * 2)
        resv_msg.node_cnt[0] = int_value
        resv_msg.node_cnt[1] = 0

    if reservation_dict.get('core_cnt') and not reservation_dict.get('node_list'):
        uint32_value = reservation_dict[u'core_cnt'][0]
        resv_msg.core_cnt = <uint32_t*>slurm.xmalloc(sizeof(uint32_t))
        resv_msg.core_cnt[0] = uint32_value

    if reservation_dict.get('node_list'):
        b_node_list = reservation_dict[u'node_list'].encode("UTF-8")
        resv_msg.node_list = b_node_list
        if reservation_dict.get('core_cnt'):
            hl = hostlist()
            hl.create(b_node_list)
            if len(reservation_dict[u'core_cnt']) != hl.count():
                raise ValueError("core_cnt list must have the same # elements as the expanded hostlist")
            resv_msg.core_cnt = <uint32_t*>slurm.xmalloc(sizeof(uint32_t) * hl.count())
            int_value = 0
            for cores in reservation_dict[u'core_cnt']:
                uint32_value = cores
                resv_msg.core_cnt[int_value] = uint32_value
                int_value += 1

    if reservation_dict.get('users'):
        b_users = reservation_dict[u'users'].encode("UTF-8", "replace")
        resv_msg.users = b_users

    if reservation_dict.get('accounts'):
        b_accounts = reservation_dict[u'accounts'].encode("UTF-8", "replace")
        resv_msg.accounts = b_accounts

    if reservation_dict.get('licenses'):
        b_licenses = reservation_dict[u'licenses'].encode("UTF-8")
        resv_msg.licenses = b_licenses

    if reservation_dict.get('partition'):
        b_name = reservation_dict[u'partition'].encode("UTF-8")
        resv_msg.partition = b_name

    if reservation_dict.get('flags'):
        int_value = reservation_dict[u'flags']
        resv_msg.flags = int_value

    errCode = slurm.slurm_update_reservation(&resv_msg)

    return errCode


def slurm_delete_reservation(ResID):
    u"""Delete a slurm reservation.

    :param string ResID: Reservation Identifier
    :returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
    :rtype: `integer`
    """
    cdef slurm.reservation_name_msg_t resv_msg

    if not ResID:
        return -1

    b_resid = ResID.encode("UTF-8", "replace")
    resv_msg.name = b_resid

    cdef int apiError = 0
    cdef int errCode = slurm.slurm_delete_reservation(&resv_msg)

    if errCode != 0:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


def create_reservation_dict():
    u"""Create and empty dict for use with create_reservation method.

    Returns a dictionary that can be populated by the user an used for
    the update_reservation and create_reservation calls.

    :returns: Empty Reservation dictionary
    :rtype: `dict`
    """
    return {
        u'start_time': 0,
        u'end_time': 0,
        u'duration': None,
        u'node_cnt': 0,
        u'name': None,
        u'node_list': None,
        u'flags': None,
        u'partition': None,
        u'licenses': None,
        u'users': None,
        u'accounts': None
    }


#
# Block Class
#


cdef class block:
    u"""Class to access/update slurm block Information."""

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
        return list(self._BlockDict.keys())

    def find_id(self, blockID=None):
        u"""Retrieve block ID data.

        :param str blockID: Block key string to search
        :returns: Dictionary of values for given block key
        :rtype: `dict`
        """
        return self._BlockDict.get(blockID, {})

    def find(self, name='', val=''):
        u"""Search for property and associated value in the block data.

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
        u"""Load slurm block information."""
        self.__load()

    cdef int __load(self) except? -1:
        cdef:
            slurm.block_info_msg_t *new_block_info_ptr = NULL
            time_t last_time = <time_t>NULL
            int apiError = 0
            int errCode = 0

        if self._block_ptr is not NULL:

            errCode = slurm.slurm_load_block_info(self._block_ptr.last_update,
                                                  &new_block_info_ptr,
                                                  self._ShowFlags)
            if errCode == 0:  # SLURM_SUCCESS
                slurm.slurm_free_block_info_msg(self._block_ptr)
            elif slurm.slurm_get_errno() == 1900:   # SLURM_NO_CHANGE_IN_DATA
                errCode = 0
                new_block_info_ptr = self._block_ptr
        else:
            last_time = <time_t>NULL
            errCode = slurm.slurm_load_block_info(last_time,
                                                  &new_block_info_ptr,
                                                  self._ShowFlags)

        if errCode != 0:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)
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

    cdef __get(self):
        cdef:
            dict Block = {}, Block_dict

        if self._block_ptr is not NULL:
            self._lastUpdate = self._block_ptr.last_update
            for record in self._block_ptr.block_array[:self._block_ptr.record_count]:
                Block_dict = {}

                name = slurm.stringOrNone(record.bg_block_id, '')
                Block_dict[u'bg_block_id'] = name
                Block_dict[u'blrtsimage'] = slurm.stringOrNone(record.blrtsimage, '')

                conn_type = get_conn_type_string(record.conn_type[HIGHEST_DIMENSIONS])
                Block_dict[u'conn_type'] = slurm.stringOrNone(conn_type, '')

                Block_dict[u'ionode_str'] = slurm.listOrNone(record.ionode_str, ',')
                Block_dict[u'linuximage'] = slurm.stringOrNone(record.linuximage, '')
                Block_dict[u'mloaderimage'] = slurm.stringOrNone(record.mloaderimage, '')
                Block_dict[u'cnode_cnt'] = record.cnode_cnt
                Block_dict[u'cnode_err_cnt'] = record.cnode_err_cnt
                Block_dict[u'mp_str'] = slurm.stringOrNone(record.mp_str, '')

                node_use = get_node_use(record.node_use)
                Block_dict[u'node_use'] = slurm.stringOrNone(node_use, '')

                Block_dict[u'ramdiskimage'] = slurm.stringOrNone(record.ramdiskimage, '')
                Block_dict[u'reason'] = slurm.stringOrNone(record.reason, '')

                block_state = get_bg_block_state_string(record.state)
                Block_dict[u'state'] = slurm.stringOrNone(block_state, '')

                # Implement List job_list

                Block[name] = Block_dict

        self._BlockDict = Block

    def print_info_msg(self, int oneLiner=0):
        u"""Output information about all slurm blocks

        This is based upon data returned by the slurm_load_block.

        :param int oneLiner: Print information on one line - 0 (Default), 1
        """
        if self._block_ptr is not NULL:
            slurm.slurm_print_block_info_msg(slurm.stdout, self._block_ptr, oneLiner)

    cdef __free(self):
        u"""Free the memory returned by load method."""
        if self._block_ptr is not NULL:
            slurm.slurm_free_block_info_msg(self._block_ptr)

    def update_error(self, blockID):
        u"""Set slurm block to ERROR state.

        :param string blockID: The ID string of the block
        """
        return self.update(blockID, BLOCK_ERROR)

    def update_free(self, blockID):
        u"""Set slurm block to FREE state.

        :param string blockID: The ID string of the block
        """
        return self.update(blockID, BLOCK_FREE)

    def update_recreate(self, blockID):
        u"""Set slurm block to RECREATE state.

        :param string blockID: The ID string of the block
        """
        return self.update(blockID, BLOCK_RECREATE)

    def update_remove(self, blockID):
        u"""Set slurm block to REMOVE state.

        :param string blockID: The ID string of the block
        """
        return self.update(blockID, BLOCK_REMOVE)

    def update_resume(self, blockID):
        u"""Set slurm block to RESUME state.

        :param string blockID: The ID string of the block
        """
        return self.update(blockID, BLOCK_RESUME)

    def update(self, blockID, int blockOP=0):
        cdef slurm.update_block_msg_t block_msg

        if not blockID:
            return

        slurm.slurm_init_update_block_msg(&block_msg)

        b_blockid = blockID
        block_msg.bg_block_id = b_blockid
        block_msg.state = blockOP

        if slurm.slurm_update_block(&block_msg):
            return slurm.slurm_get_errno()

        return 0


#
# Topology Class
#


cdef class topology:
    u"""Class to access/update slurm topology information."""

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
        u"""Free the memory returned by load method."""
        if self._topo_info_ptr is not NULL:
            slurm.slurm_free_topo_info_msg(self._topo_info_ptr)

    def load(self):
        u"""Load slurm topology information."""
        self.__load()

    cpdef int __load(self) except? -1:
        u"""Load slurm topology."""
        cdef int apiError = 0
        cdef int errCode = 0

        if self._topo_info_ptr is not NULL:
            # free previous pointer
            slurm.slurm_free_topo_info_msg(self._topo_info_ptr)

        errCode = slurm.slurm_load_topo(&self._topo_info_ptr)
        if errCode != 0:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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

            for i in range(self._topo_info_ptr.record_count):

                Topo_dict = {}

                name = slurm.stringOrNone(self._topo_info_ptr.topo_array[i].name, '')
                Topo_dict[u'name'] = name
                Topo_dict[u'nodes'] = slurm.stringOrNone(self._topo_info_ptr.topo_array[i].nodes, '')
                Topo_dict[u'level'] = self._topo_info_ptr.topo_array[i].level
                Topo_dict[u'link_speed'] = self._topo_info_ptr.topo_array[i].link_speed
                Topo_dict[u'switches'] = slurm.stringOrNone(self._topo_info_ptr.topo_array[i].switches, '')

                Topo[name] = Topo_dict

        self._TopoDict = Topo

    def display(self):
        u"""Display topology information to standard output."""
        self._print_topo_info_msg()

    cpdef _print_topo_info_msg(self):
        u"""Output information about topology based upon message as loaded using slurm_load_topo.

        :param int Flags: Print on one line - False (Default), True
        """

        if self._topo_info_ptr is not NULL:
            slurm.slurm_print_topo_info_msg(slurm.stdout,
                                            self._topo_info_ptr,
                                            self._ShowFlags)


#
# PowerCapping
#


cdef class powercap:
    u"""Class to access powercap information."""

    cdef:
        slurm.powercap_info_msg_t *_msg
        dict _pwrDict

    def __cinit__(self):
        self._msg = NULL
        self._pwrDict = {}

    def __dealloc__(self):
        self.__destroy()

    cpdef __destroy(self):
        u"""Free the memory allocated by __load method."""
        if self._msg is not NULL:
            slurm.slurm_free_powercap_info_msg(self._msg)

    def load(self):
        u"""Load powercap information."""
        self.__load()

    cpdef int __load(self) except? -1:
        u"""Load powercap information."""
        cdef:
            int apiError = 0
            int errCode = 0

        if self._msg is not NULL:
            slurm.slurm_free_powercap_info_msg(self._msg)

        errCode = slurm.slurm_load_powercap(&self._msg)
        if errCode != 0:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
    # extern int slurm_update_powercap (update_powercap_msg_t * powercap_msg)


#
# Statistics
#


cdef class statistics:

    cdef:
        slurm.stats_info_request_msg_t _req
        slurm.stats_info_response_msg_t *_buf
        dict _StatsDict

    def __cinit__(self):
        self._buf = NULL
        self._StatsDict = {}

    def __dealloc__(self):
        pass

    cpdef dict get(self):
        u"""Get slurm statistics information.

        :rtype: `dict`
        """
        cdef:
            int errCode
            int apiError
            uint32_t i
            dict rpc_type_stats
            dict rpc_user_stats

        self._req.command_id = STAT_COMMAND_GET

        errCode = slurm.slurm_get_statistics(&self._buf,
                                             <slurm.stats_info_request_msg_t*>&self._req)

        if errCode == slurm.SLURM_SUCCESS:
            self._StatsDict[u'parts_packed'] = self._buf.parts_packed
            self._StatsDict[u'req_time'] = self._buf.req_time
            self._StatsDict[u'req_time_start'] = self._buf.req_time_start
            self._StatsDict[u'server_thread_count'] = self._buf.server_thread_count
            self._StatsDict[u'agent_queue_size'] = self._buf.agent_queue_size

            self._StatsDict[u'schedule_cycle_max'] = self._buf.schedule_cycle_max
            self._StatsDict[u'schedule_cycle_last'] = self._buf.schedule_cycle_last
            self._StatsDict[u'schedule_cycle_sum'] = self._buf.schedule_cycle_sum
            self._StatsDict[u'schedule_cycle_counter'] = self._buf.schedule_cycle_counter
            self._StatsDict[u'schedule_cycle_depth'] = self._buf.schedule_cycle_depth
            self._StatsDict[u'schedule_queue_len'] = self._buf.schedule_queue_len

            self._StatsDict[u'jobs_submitted'] = self._buf.jobs_submitted
            self._StatsDict[u'jobs_started'] = self._buf.jobs_started
            self._StatsDict[u'jobs_completed'] = self._buf.jobs_completed
            self._StatsDict[u'jobs_canceled'] = self._buf.jobs_canceled
            self._StatsDict[u'jobs_failed'] = self._buf.jobs_failed

            self._StatsDict[u'bf_backfilled_jobs'] = self._buf.bf_backfilled_jobs
            self._StatsDict[u'bf_last_backfilled_jobs'] = self._buf.bf_last_backfilled_jobs
            self._StatsDict[u'bf_cycle_counter'] = self._buf.bf_cycle_counter
            self._StatsDict[u'bf_cycle_sum'] = self._buf.bf_cycle_sum
            self._StatsDict[u'bf_cycle_last'] = self._buf.bf_cycle_last
            self._StatsDict[u'bf_cycle_max'] = self._buf.bf_cycle_max
            self._StatsDict[u'bf_last_depth'] = self._buf.bf_last_depth
            self._StatsDict[u'bf_last_depth_try'] = self._buf.bf_last_depth_try
            self._StatsDict[u'bf_depth_sum'] = self._buf.bf_depth_sum
            self._StatsDict[u'bf_depth_try_sum'] = self._buf.bf_depth_try_sum
            self._StatsDict[u'bf_queue_len'] = self._buf.bf_queue_len
            self._StatsDict[u'bf_queue_len_sum'] = self._buf.bf_queue_len_sum
            self._StatsDict[u'bf_when_last_cycle'] = self._buf.bf_when_last_cycle
            self._StatsDict[u'bf_active'] = self._buf.bf_active

            rpc_type_stats = {}

            for i in range(self._buf.rpc_type_size):
                rpc_type = self.__rpc_num2string(self._buf.rpc_type_id[i])
                rpc_type_stats[rpc_type] = {}
                rpc_type_stats[rpc_type][u'id'] = self._buf.rpc_type_id[i]
                rpc_type_stats[rpc_type][u'count'] = self._buf.rpc_type_cnt[i]
                if self._buf.rpc_type_cnt[i] == 0:
                    rpc_type_stats[rpc_type][u'ave_time'] = 0
                else:
                    rpc_type_stats[rpc_type][u'ave_time'] = int(self._buf.rpc_type_time[i] /
                                                                self._buf.rpc_type_cnt[i])
                rpc_type_stats[rpc_type][u'total_time'] = int(self._buf.rpc_type_time[i])
            self._StatsDict[u'rpc_type_stats'] = rpc_type_stats

            rpc_user_stats = {}

            for i in range(self._buf.rpc_user_size):
                try:
                    rpc_user = getpwuid(self._buf.rpc_user_id[i])[0]
                except KeyError:
                    rpc_user = str(self._buf.rpc_user_id[i])
                rpc_user_stats[rpc_user] = {}
                rpc_user_stats[rpc_user][u"id"] = self._buf.rpc_user_id[i]
                rpc_user_stats[rpc_user][u"count"] = self._buf.rpc_user_cnt[i]
                if self._buf.rpc_user_cnt[i] == 0:
                    rpc_user_stats[rpc_user][u"ave_time"] = 0
                else:
                    rpc_user_stats[rpc_user][u"ave_time"] = int(self._buf.rpc_user_time[i] /
                                                                self._buf.rpc_user_cnt[i])
                rpc_user_stats[rpc_user][u"total_time"] = int(self._buf.rpc_user_time[i])
            self._StatsDict[u'rpc_user_stats'] = rpc_user_stats

            slurm.slurm_free_stats_response_msg(self._buf)
            self._buf = NULL
            return self._StatsDict
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    cpdef int reset(self):
        """Reset scheduling statistics

        This method required root privileges.
        """
        cdef:
            int apiError
            int errCode

        self._req.command_id = STAT_COMMAND_RESET
        errCode = slurm.slurm_reset_statistics(<slurm.stats_info_request_msg_t*>&self._req)

        if errCode == slurm.SLURM_SUCCESS:
            return errCode
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    cpdef __rpc_num2string(self, uint16_t opcode):
        cdef dict num2string

        num2string = {
            1001: "REQUEST_NODE_REGISTRATION_STATUS",
            1002: "MESSAGE_NODE_REGISTRATION_STATUS",
            1003: "REQUEST_RECONFIGURE",
            1004: "RESPONSE_RECONFIGURE",
            1005: "REQUEST_SHUTDOWN",
            1006: "REQUEST_SHUTDOWN_IMMEDIATE",
            1007: "RESPONSE_SHUTDOWN",
            1008: "REQUEST_PING",
            1009: "REQUEST_CONTROL",
            1010: "REQUEST_SET_DEBUG_LEVEL",
            1011: "REQUEST_HEALTH_CHECK",
            1012: "REQUEST_TAKEOVER",
            1013: "REQUEST_SET_SCHEDLOG_LEVEL",
            1014: "REQUEST_SET_DEBUG_FLAGS",
            1015: "REQUEST_REBOOT_NODES",
            1016: "RESPONSE_PING_SLURMD",
            1017: "REQUEST_ACCT_GATHER_UPDATE",
            1018: "RESPONSE_ACCT_GATHER_UPDATE",
            1019: "REQUEST_ACCT_GATHER_ENERGY",
            1020: "RESPONSE_ACCT_GATHER_ENERGY",
            1021: "REQUEST_LICENSE_INFO",
            1022: "RESPONSE_LICENSE_INFO",

            2001: "REQUEST_BUILD_INFO",
            2002: "RESPONSE_BUILD_INFO",
            2003: "REQUEST_JOB_INFO",
            2004: "RESPONSE_JOB_INFO",
            2005: "REQUEST_JOB_STEP_INFO",
            2006: "RESPONSE_JOB_STEP_INFO",
            2007: "REQUEST_NODE_INFO",
            2008: "RESPONSE_NODE_INFO",
            2009: "REQUEST_PARTITION_INFO",
            2010: "RESPONSE_PARTITION_INFO",
            2011: "REQUEST_ACCTING_INFO",
            2012: "RESPONSE_ACCOUNTING_INFO",
            2013: "REQUEST_JOB_ID",
            2014: "RESPONSE_JOB_ID",
            2015: "REQUEST_BLOCK_INFO",
            2016: "RESPONSE_BLOCK_INFO",
            2017: "REQUEST_TRIGGER_SET",
            2018: "REQUEST_TRIGGER_GET",
            2019: "REQUEST_TRIGGER_CLEAR",
            2020: "RESPONSE_TRIGGER_GET",
            2021: "REQUEST_JOB_INFO_SINGLE",
            2022: "REQUEST_SHARE_INFO",
            2023: "RESPONSE_SHARE_INFO",
            2024: "REQUEST_RESERVATION_INFO",
            2025: "RESPONSE_RESERVATION_INFO",
            2026: "REQUEST_PRIORITY_FACTORS",
            2027: "RESPONSE_PRIORITY_FACTORS",
            2028: "REQUEST_TOPO_INFO",
            2029: "RESPONSE_TOPO_INFO",
            2030: "REQUEST_TRIGGER_PULL",
            2031: "REQUEST_FRONT_END_INFO",
            2032: "RESPONSE_FRONT_END_INFO",
            2033: "REQUEST_SPANK_ENVIRONMENT",
            2034: "RESPONCE_SPANK_ENVIRONMENT",
            2035: "REQUEST_STATS_INFO",
            2036: "RESPONSE_STATS_INFO",
            2037: "REQUEST_BURST_BUFFER_INFO",
            2038: "RESPONSE_BURST_BUFFER_INFO",
            2039: "REQUEST_JOB_USER_INFO",
            2040: "REQUEST_NODE_INFO_SINGLE",
            2041: "REQUEST_POWERCAP_INFO",
            2042: "RESPONSE_POWERCAP_INFO",
            2043: "REQUEST_ASSOC_MGR_INFO",
            2044: "RESPONSE_ASSOC_MGR_INFO",
            2045: "REQUEST_SICP_INFO_DEFUNCT",
            2046: "RESPONSE_SICP_INFO_DEFUNCT",
            2047: "REQUEST_LAYOUT_INFO",
            2048: "RESPONSE_LAYOUT_INFO",

            3001: "REQUEST_UPDATE_JOB",
            3002: "REQUEST_UPDATE_NODE",
            3003: "REQUEST_CREATE_PARTITION",
            3004: "REQUEST_DELETE_PARTITION",
            3005: "REQUEST_UPDATE_PARTITION",
            3006: "REQUEST_CREATE_RESERVATION",
            3007: "RESPONSE_CREATE_RESERVATION",
            3008: "REQUEST_DELETE_RESERVATION",
            3009: "REQUEST_UPDATE_RESERVATION",
            3010: "REQUEST_UPDATE_BLOCK",
            3011: "REQUEST_UPDATE_FRONT_END",
            3012: "REQUEST_UPDATE_LAYOUT",
            3013: "REQUEST_UPDATE_POWERCAP",

            4001: "REQUEST_RESOURCE_ALLOCATION",
            4002: "RESPONSE_RESOURCE_ALLOCATION",
            4003: "REQUEST_SUBMIT_BATCH_JOB",
            4004: "RESPONSE_SUBMIT_BATCH_JOB",
            4005: "REQUEST_BATCH_JOB_LAUNCH",
            4006: "REQUEST_CANCEL_JOB",
            4007: "RESPONSE_CANCEL_JOB",
            4008: "REQUEST_JOB_RESOURCE",
            4009: "RESPONSE_JOB_RESOURCE",
            4010: "REQUEST_JOB_ATTACH",
            4011: "RESPONSE_JOB_ATTACH",
            4012: "REQUEST_JOB_WILL_RUN",
            4013: "RESPONSE_JOB_WILL_RUN",
            4014: "REQUEST_JOB_ALLOCATION_INFO",
            4015: "RESPONSE_JOB_ALLOCATION_INFO",
            4016: "REQUEST_JOB_ALLOCATION_INFO_LITE",
            4017: "RESPONSE_JOB_ALLOCATION_INFO_LITE",
            4018: "REQUEST_UPDATE_JOB_TIME",
            4019: "REQUEST_JOB_READY",
            4020: "RESPONSE_JOB_READY",
            4021: "REQUEST_JOB_END_TIME",
            4022: "REQUEST_JOB_NOTIFY",
            4023: "REQUEST_JOB_SBCAST_CRED",
            4024: "RESPONSE_JOB_SBCAST_CRED",

            5001: "REQUEST_JOB_STEP_CREATE",
            5002: "RESPONSE_JOB_STEP_CREATE",
            5003: "REQUEST_RUN_JOB_STEP",
            5004: "RESPONSE_RUN_JOB_STEP",
            5005: "REQUEST_CANCEL_JOB_STEP",
            5006: "RESPONSE_CANCEL_JOB_STEP",
            5007: "REQUEST_UPDATE_JOB_STEP",
            5008: "DEFUNCT_RESPONSE_COMPLETE_JOB_STEP",
            5009: "REQUEST_CHECKPOINT",
            5010: "RESPONSE_CHECKPOINT",
            5011: "REQUEST_CHECKPOINT_COMP",
            5012: "REQUEST_CHECKPOINT_TASK_COMP",
            5013: "RESPONSE_CHECKPOINT_COMP",
            5014: "REQUEST_SUSPEND",
            5015: "RESPONSE_SUSPEND",
            5016: "REQUEST_STEP_COMPLETE",
            5017: "REQUEST_COMPLETE_JOB_ALLOCATION",
            5018: "REQUEST_COMPLETE_BATCH_SCRIPT",
            5019: "REQUEST_JOB_STEP_STAT",
            5020: "RESPONSE_JOB_STEP_STAT",
            5021: "REQUEST_STEP_LAYOUT",
            5022: "RESPONSE_STEP_LAYOUT",
            5023: "REQUEST_JOB_REQUEUE",
            5024: "REQUEST_DAEMON_STATUS",
            5025: "RESPONSE_SLURMD_STATUS",
            5026: "RESPONSE_SLURMCTLD_STATUS",
            5027: "REQUEST_JOB_STEP_PIDS",
            5028: "RESPONSE_JOB_STEP_PIDS",
            5029: "REQUEST_FORWARD_DATA",
            5030: "REQUEST_COMPLETE_BATCH_JOB",
            5031: "REQUEST_SUSPEND_INT",
            5032: "REQUEST_KILL_JOB",
            5033: "REQUEST_KILL_JOBSTEP",
            5034: "RESPONSE_JOB_ARRAY_ERRORS",
            5035: "REQUEST_NETWORK_CALLERID",
            5036: "RESPONSE_NETWORK_CALLERID",
            5037: "REQUEST_STEP_COMPLETE_AGGR",
            5038: "REQUEST_TOP_JOB",

            6001: "REQUEST_LAUNCH_TASKS",
            6002: "RESPONSE_LAUNCH_TASKS",
            6003: "MESSAGE_TASK_EXIT",
            6004: "REQUEST_SIGNAL_TASKS",
            6005: "REQUEST_CHECKPOINT_TASKS",
            6006: "REQUEST_TERMINATE_TASKS",
            6007: "REQUEST_REATTACH_TASKS",
            6008: "RESPONSE_REATTACH_TASKS",
            6009: "REQUEST_KILL_TIMELIMIT",
            6010: "REQUEST_SIGNAL_JOB",
            6011: "REQUEST_TERMINATE_JOB",
            6012: "MESSAGE_EPILOG_COMPLETE",
            6013: "REQUEST_ABORT_JOB",
            6014: "REQUEST_FILE_BCAST",
            6015: "TASK_USER_MANAGED_IO_STREAM",
            6016: "REQUEST_KILL_PREEMPTED",
            6017: "REQUEST_LAUNCH_PROLOG",
            6018: "REQUEST_COMPLETE_PROLOG",
            6019: "RESPONSE_PROLOG_EXECUTING",

            7001: "SRUN_PING",
            7002: "SRUN_TIMEOUT",
            7003: "SRUN_NODE_FAIL",
            7004: "SRUN_JOB_COMPLETE",
            7005: "SRUN_USER_MSG",
            7006: "SRUN_EXEC",
            7007: "SRUN_STEP_MISSING",
            7008: "SRUN_REQUEST_SUSPEND",

            7201: "PMI_KVS_PUT_REQ",
            7202: "PMI_KVS_PUT_RESP",
            7203: "PMI_KVS_GET_REQ",
            7204: "PMI_KVS_GET_RESP",

            8001: "RESPONSE_SLURM_RC",
            8002: "RESPONSE_SLURM_RC_MSG",

            9001: "RESPONSE_FORWARD_FAILED",

            10001: "ACCOUNTING_UPDATE_MSG",
            10002: "ACCOUNTING_FIRST_REG",
            10003: "ACCOUNTING_REGISTER_CTLD",

            11001: "MESSAGE_COMPOSITE",
            11002: "RESPONSE_MESSAGE_COMPOSITE"}

        return num2string[opcode]


#
# Front End Node Class
#


cdef class front_end:
    u"""Class to access/update slurm front end node information."""

    cdef:
        slurm.time_t Time
        slurm.time_t _lastUpdate
        slurm.front_end_info_msg_t *_FrontEndNode_ptr
        # slurm.front_end_info_t _record
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
        u"""Free the memory allocated by load front end node method."""
        if self._FrontEndNode_ptr is not NULL:
            slurm.slurm_free_front_end_info_msg(self._FrontEndNode_ptr)

    def load(self):
        u"""Load slurm front end node information."""
        self.__load()

    cdef int __load(self) except? -1:
        u"""Load slurm front end node."""
        cdef:
            # slurm.front_end_info_msg_t *new_FrontEndNode_ptr = NULL
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
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

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
        return list(self._FrontEndDict.keys())

    def get(self):
        u"""Get front end node information.

        :returns: Dictionary whose key is the Topology ID
        :rtype: `dict`
        """
        self.__load()
        self.__get()

        return self._FrontEndDict

    cdef __get(self):
        cdef:
            dict FENode = {}
            dict FE_dict = {}

        if self._FrontEndNode_ptr is not NULL:
            for record in self._FrontEndNode_ptr.front_end_array[:self._FrontEndNode_ptr.record_count]:
                FE_dict = {}
                name = slurm.stringOrNone(record.name, '')

                FE_dict[u'boot_time'] = record.boot_time
                FE_dict[u'allow_groups'] = slurm.stringOrNone(record.allow_groups, '')
                FE_dict[u'allow_users'] = slurm.stringOrNone(record.allow_users, '')
                FE_dict[u'deny_groups'] = slurm.stringOrNone(record.deny_groups, '')
                FE_dict[u'deny_users'] = slurm.stringOrNone(record.deny_users, '')

                fe_node_state = get_node_state(record.node_state)
                FE_dict[u'node_state'] = slurm.stringOrNone(fe_node_state, '')

                FE_dict[u'reason'] = slurm.stringOrNone(record.reason, '')
                FE_dict[u'reason_time'] = record.reason_time
                FE_dict[u'reason_uid'] = record.reason_uid
                FE_dict[u'slurmd_start_time'] = record.slurmd_start_time
                FE_dict[u'version'] = slurm.stringOrNone(record.version, '')

                FENode[name] = FE_dict

        self._FrontEndDict = FENode


#
# QOS Class
#


cdef class qos:
    u"""Class to access/update slurm QOS information."""

    cdef:
        void *dbconn
        dict _QOSDict
        slurm.List _QOSList

    def __cinit__(self):
        self.dbconn = <void *>NULL
        self._QOSDict = {}

    def __dealloc__(self):
        self.__destroy()

    cdef __destroy(self):
        u"""QOS Destructor method."""
        self._QOSDict = {}

    def load(self):
        u"""Load slurm QOS information."""

        self.__load()

    cdef int __load(self) except? -1:
        u"""Load slurm QOS list."""
        cdef:
            slurm.slurmdb_qos_cond_t *new_qos_cond = NULL
            int apiError = 0
            void* dbconn = slurm.slurmdb_connection_get()
            slurm.List QOSList = slurm.slurmdb_qos_get(dbconn, new_qos_cond)

        if QOSList is NULL:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)
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

    cdef __get(self):
        cdef:
            slurm.List qos_list = NULL
            slurm.ListIterator iters = NULL
            int i = 0
            int listNum = 0
            dict Q_dict = {}

        if self._QOSList is not NULL:
            listNum = slurm.slurm_list_count(self._QOSList)
            iters = slurm.slurm_list_iterator_create(self._QOSList)

            for i in range(listNum):
                qos = <slurm.slurmdb_qos_rec_t *>slurm.slurm_list_next(iters)
                name = slurm.stringOrNone(qos.name, '')

                # QOS infos
                QOS_info = {}

                if name:
                    QOS_info[u'description'] = slurm.stringOrNone(qos.description, '')
                    QOS_info[u'flags'] = qos.flags
                    QOS_info[u'grace_time'] = qos.grace_time
                    QOS_info[u'grp_jobs'] = qos.grp_jobs
                    QOS_info[u'grp_submit_jobs'] = qos.grp_submit_jobs
                    QOS_info[u'grp_tres'] = slurm.stringOrNone(qos.grp_tres, '')
                    # QOS_info[u'grp_tres_ctld']
                    QOS_info[u'grp_tres_mins'] = slurm.stringOrNone(qos.grp_tres_mins, '')
                    # QOS_info[u'grp_tres_mins_ctld']
                    QOS_info[u'grp_tres_run_mins'] = slurm.stringOrNone(qos.grp_tres_run_mins, '')
                    # QOS_info[u'grp_tres_run_mins_ctld']
                    QOS_info[u'grp_wall'] = qos.grp_wall
                    QOS_info[u'max_jobs_pu'] = qos.max_jobs_pu
                    QOS_info[u'max_submit_jobs_pu'] = qos.max_submit_jobs_pu
                    QOS_info[u'max_tres_mins_pj'] = slurm.stringOrNone(qos.max_tres_mins_pj, '')
                    # QOS_info[u'max_tres_min_pj_ctld']
                    QOS_info[u'max_tres_pj'] = slurm.stringOrNone(qos.max_tres_pj, '')
                    # QOS_info[u'max_tres_min_pj_ctld']
                    QOS_info[u'max_tres_pn'] = slurm.stringOrNone(qos.max_tres_pn, '')
                    # QOS_info[u'max_tres_min_pn_ctld']
                    QOS_info[u'max_tres_pu'] = slurm.stringOrNone(qos.max_tres_pu, '')
                    # QOS_info[u'max_tres_min_pu_ctld']
                    QOS_info[u'max_tres_run_mins_pu'] = slurm.stringOrNone(
                        qos.max_tres_run_mins_pu, '')

                    QOS_info[u'max_wall_pj'] = qos.max_wall_pj
                    QOS_info[u'min_tres_pj'] = slurm.stringOrNone(qos.min_tres_pj, '')
                    # QOS_info[u'min_tres_pj_ctld']
                    QOS_info[u'name'] = name
                    # QOS_info[u'*preempt_bitstr'] =
                    # QOS_info[u'preempt_list'] = qos.preempt_list

                    qos_preempt_mode = get_preempt_mode(qos.preempt_mode)
                    QOS_info[u'preempt_mode'] = slurm.stringOrNone(qos_preempt_mode, '')

                    QOS_info[u'priority'] = qos.priority
                    QOS_info[u'usage_factor'] = qos.usage_factor
                    QOS_info[u'usage_thres'] = qos.usage_thres

                    # NB - Need to add code to decode types of grp_tres_ctld (uint64t list) etc

                if name:
                    Q_dict[name] = QOS_info

            slurm.slurm_list_iterator_destroy(iters)
            slurm.slurm_list_destroy(self._QOSList)

        self._QOSDict = Q_dict


#
# Helper functions to convert numerical States
#


def get_last_slurm_error():
    u"""Get and return the last error from a slurm API call.

    :returns: Slurm error number and the associated error string
    :rtype: `integer`
    :returns: Slurm error string
    :rtype: `string`
    """
    rc = slurm.slurm_get_errno()

    if rc == 0:
        return (rc, 'Success')
    else:
        return (rc, slurm.stringOrNone(slurm.slurm_strerror(rc), ''))

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
            value = 1
            try:
                key, value = alist[i].split(':')
            except:
                key = alist[i]
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


def get_node_use(inx):
    u"""Returns a string that represents the block node mode.

    :param int ResType: Slurm block node usage
        - SELECT_COPROCESSOR_MODE   1
        - SELECT_VIRTUAL_NODE_MODE  2
        - SELECT_NAV_MODE           3
    :returns: Block node usage string
    :rtype: `string`
    """
    return slurm.slurm_node_state_string(inx)


def get_trigger_res_type(uint16_t inx):
    u"""Returns a string that represents the slurm trigger res type.

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
    u"""Returns a string that represents the state of the slurm trigger.

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


def get_debug_flags(uint64_t inx):
    u""" Returns a string that represents the slurm debug flags.

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

cdef inline list __get_debug_flags(uint64_t flags):
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

    if (flags & DEBUG_FLAG_PRIO):
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
            state = "UP"
        elif inx == PARTITION_DOWN:
            state = "DOWN"
        elif inx == PARTITION_INACTIVE:
            stats = "INACTIVE"
        elif inx == PARTITION_DRAIN:
            state = "DRAIN"
        else:
            state = "UNKNOWN"

    return state

cdef inline object __get_partition_state(int inx, int extended=0):
    u"""Returns a string that represents the state of the partition.

    :param int inx: Slurm partition type
    :param int extended:
    :returns: Partition state
    :rtype: `string`
    """
    cdef:
        int drain_flag = (inx & 0x0200)
        int comp_flag = (inx & 0x0400)
        int no_resp_flag = (inx & 0x0800)
        int power_flag = (inx & 0x1000)

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
        uint16_t force = max_share & SHARED_FORCE
        uint16_t val = max_share & (~SHARED_FORCE)

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
        mode[u'Shared'] = "FORCED:" + str(val)
    elif val == 1:
        mode[u'Shared'] = u"NO"
    else:
        mode[u'Shared'] = "YES:" + str(val)

    if (flags & PART_FLAG_LLN):
        mode[u'LLN'] = 1
    else:
        mode[u'LLN'] = 0

    if (flags & PART_FLAG_EXCLUSIVE_USER):
        mode[u'ExclusiveUser'] = 1
    else:
        mode[u'ExclusiveUser'] = 0

    return mode


def get_conn_type_string(inx):
    u"""Return the state of the Slurm bluegene connection type.

    :param int inx: Slurm BG connection state
    :returns: Block connection string
    :rtype: `string`
    """
    return slurm.slurm_conn_type_string(inx)


def get_bg_block_state_string(inx):
    u"""Return the state of the slurm bluegene block state.

    :param int inx: Slurm BG block state
    :returns: Block state string
    :rtype: `string`
    """
    return slurm.slurm_bg_block_state_string(inx)


def get_job_state(inx):
    u"""Return the state of the slurm job state.

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
        job_state = slurm.stringOrNone(slurm.slurm_job_state_string(inx), '')
        return job_state
    except:
        pass


def get_job_state_reason(inx):
    u"""Returns a reason why the slurm job is in a provided state.

    :param int inx: Slurm job state reason
    :returns: Reason string
    :rtype: `string`
    """
    job_reason = slurm.stringOrNone(slurm.slurm_job_reason_string(inx), '')
    return job_reason


def epoch2date(epochSecs):
    u"""Convert epoch secs to a python time string.

    :param int epochSecs: Seconds since epoch
    :returns: Date
    :rtype: `string`
    """
    try:
        dateTime = p_time.gmtime(epochSecs)
        return u"%s" % p_time.strftime("%a %b %d %H:%M:%S %Y", dateTime)
    except:
        pass


def __convertDefaultTime(uint32_t inx):
    try:
        if inx == 0xffffffff:
            return 'infinite'
        elif inx == 0xfffffffe:
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
    u"""Class to access slurm controller license information."""

    cdef:
        slurm.license_info_msg_t *_msg
        slurm.time_t _lastUpdate
        uint16_t _ShowFlags
        dict _licDict

    def __cinit__(self):
        self._msg = NULL
        self._ShowFlags = slurm.SHOW_ALL
        self._lastUpdate = <time_t> NULL

    def __dealloc__(self):
        u"""Free the memory allocated by load licenses method."""
        pass

    def lastUpdate(self):
        u"""Return last time (epoch seconds) license data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    def ids(self):
        u"""Return the current license names from retrieved license data.

        This method calls slurm_load_licenses to retrieve license information
        from the controller.  slurm_free_license_info_msg is used to free the
        license message buffer.

        :returns: Dictionary of licenses
        :rtype: `dict`
        """
        cdef:
            int rc
            int apiError
            uint32_t i
            list all_licenses

        rc = slurm.slurm_load_licenses(<time_t> NULL, &self._msg,
                                       self._ShowFlags)

        if rc == slurm.SLURM_SUCCESS:
            all_licenses = []
            self._lastUpdate = self._msg.last_update

            for i in range(self._msg.num_lic):
                all_licenses.append(self._msg.lic_array[i].name)
            slurm.slurm_free_license_info_msg(self._msg)
            self._msg = NULL
            return all_licenses
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    cpdef get(self):
        u"""Get full license information from the slurm controller.

        This method calls slurm_load_licenses to retrieve license information
        from the controller.  slurm_free_license_info_msg is used to free the
        license message buffer.

        :returns: Dictionary whose key is the license name
        :rtype: `dict`
        """
        cdef:
            int rc
            int apiError
            dict License_dict

        rc = slurm.slurm_load_licenses(<time_t> NULL, &self._msg,
                                       self._ShowFlags)

        if rc == slurm.SLURM_SUCCESS:
            self._licDict = {}
            self._lastUpdate = self._msg.last_update

            for record in self._msg.lic_array[:self._msg.num_lic]:
                License_dict = {}
                license_name = slurm.stringOrNone(record.name, '')
                License_dict["total"] = record.total
                License_dict["in_use"] = record.in_use
                License_dict["available"] = record.available
                License_dict["remote"] = record.remote
                self._licDict[license_name] = License_dict
            slurm.slurm_free_license_info_msg(self._msg)
            self._msg = NULL
            return self._licDict
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)
