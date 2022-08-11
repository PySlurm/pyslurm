# cython: embedsignature=True
# cython: profile=False
# cython: language_level=3
import os
import re
import sys
import time as p_time

from socket import gethostname
from collections import defaultdict
from pwd import getpwnam, getpwuid

from libc.errno cimport errno, EAGAIN
from libc.stddef cimport size_t
from libc.stdint cimport uint8_t, uint16_t, uint32_t
from libc.stdint cimport int64_t, uint64_t
from libc.stdlib cimport malloc, free
from libc.string cimport strlen, strcpy, memset, memcpy
from posix.unistd cimport getuid, getgid
from cpython cimport bool

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
    int WIFSIGNALED(int status)
    int WTERMSIG(int status)
    int WEXITSTATUS(int status)
    int WIFEXITED(int status)

cdef extern from "<sys/types.h>" nogil:
    ctypedef long id_t

cdef extern from "<sys/resource.h>" nogil:
    enum: PRIO_PROCESS
    int getpriority(int, id_t)

#cdef extern from *:
#    # deprecated backwards compatiblity declaration
#    ctypedef char*  const_char_ptr  "const char*"
#    ctypedef char** const_char_pptr "const char**"

cdef extern from "alps_cray.h" nogil:
    cdef int ALPS_CRAY_SYSTEM

cdef extern from "xmalloc.h" nogil:
    cdef void *xmalloc(size_t size)

import builtins as __builtin__

from pyslurm cimport slurm

include "pydefines/slurm_errno_defines.pxi"
include "pydefines/slurm_errno_enums.pxi"

include "pydefines/slurm_defines.pxi"
include "pydefines/slurm_enums.pxi"

include "pydefines/slurmdb_defines.pxi"
include "pydefines/slurmdb_enums.pxi"

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

DEF MAX_RETRIES = 15

# SLURM_ID_HASH
# Description:
#   Creates a hash of a Slurm JOBID and STEPID
#   The JOB STEP ID is in the top 32 bits of the hash with the job id occupying
#   the lower 32 bits.
#
#   IN  _jobid -- SLURM's JOB ID (uint32_t)
#   IN  _stepid -- SLURM's JOB STEP ID (uint32_t)
#   RET id_hash -- (uint64_t)


cdef inline SLURM_ID_HASH(_jobid, _stepid):
    return <uint64_t>(<uint64_t>_stepid << 32 + _jobid)

cdef inline SLURM_ID_HASH_JOB_ID(hash_id):
    return <uint32_t>(hash_id & 0x00000000FFFFFFFF)

cdef inline SLURM_ID_HASH_STEP_ID(hash_id):
    return <uint32_t>(hash_id >> 32)


# Convert a hash ID to its legacy (pre-17.11) equivalent
# Used for backward compatibility for Cray PMI

cdef inline SLURM_ID_HASH_LEGACY(hash_id):
    return ((hash_id >> 32) * 10000000000 + (hash_id & 0x00000000FFFFFFFF))

#
# Defined job states
#

cdef inline IS_JOB_PENDING(slurm.slurm_job_info_t _X):
    return ((_X.job_state & JOB_STATE_BASE) == JOB_PENDING)

cdef inline IS_JOB_RUNNING(slurm.slurm_job_info_t _X):
    return ((_X.job_state & JOB_STATE_BASE) == JOB_RUNNING)

cdef inline IS_JOB_SUSPENDED(slurm.slurm_job_info_t _X):
    return ((_X.job_state & JOB_STATE_BASE) == JOB_SUSPENDED)

cdef inline IS_JOB_COMPLETE(slurm.slurm_job_info_t _X):
    return ((_X.job_state & JOB_STATE_BASE) == JOB_COMPLETE)

cdef inline IS_JOB_CANCELLED(slurm.slurm_job_info_t _X):
    return ((_X.job_state & JOB_STATE_BASE) == JOB_CANCELLED)

cdef inline IS_JOB_FAILED(slurm.slurm_job_info_t _X):
    return ((_X.job_state & JOB_STATE_BASE) == JOB_FAILED)

cdef inline IS_JOB_TIMEOUT(slurm.slurm_job_info_t _X):
    return ((_X.job_state & JOB_STATE_BASE) == JOB_TIMEOUT)

cdef inline IS_JOB_NODE_FAILED(slurm.slurm_job_info_t _X):
    return ((_X.job_state & JOB_STATE_BASE) == JOB_NODE_FAIL)

cdef inline IS_JOB_DEADLINE(slurm.slurm_job_info_t _X):
    return ((_X.job_state & JOB_STATE_BASE) == JOB_DEADLINE)

cdef inline IS_JOB_OOM(slurm.slurm_job_info_t _X):
    return ((_X.job_state & JOB_STATE_BASE) == JOB_OOM)

cdef inline IS_JOB_POWERING_UP_NODE(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_STATE_BASE)

#
# Derived job states
#

cdef inline IS_JOB_COMPLETING(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_COMPLETING)

cdef inline IS_JOB_CONFIGURING(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_CONFIGURING)

cdef inline IS_JOB_STARTED(slurm.slurm_job_info_t _X):
    return ((_X.job_state & JOB_STATE_BASE) > JOB_PENDING)

cdef inline IS_JOB_FINISHED(slurm.slurm_job_info_t _X):
    return ((_X.job_state & JOB_STATE_BASE) > JOB_SUSPENDED)

cdef inline IS_JOB_COMPLETED(slurm.slurm_job_info_t _X):
    return (IS_JOB_FINISHED(_X) and ((_X.job_state & JOB_COMPLETING) == 0))

cdef inline IS_JOB_RESIZING(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_RESIZING)

cdef inline IS_JOB_REQUEUED(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_REQUEUE)

cdef inline IS_JOB_FED_REQUEUED(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_REQUEUE_FED)

cdef inline IS_JOB_UPDATE_DB(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_UPDATE_DB)

cdef inline IS_JOB_REVOKED(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_REVOKED)

cdef inline IS_JOB_SIGNALING(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_SIGNALING)

cdef inline IS_JOB_STAGE_OUT(slurm.slurm_job_info_t _X):
    return (_X.job_state & JOB_STAGE_OUT)

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
    return (_X.node_state & NODE_STATE_CLOUD)

cdef inline IS_NODE_DRAIN(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_DRAIN)

cdef inline IS_NODE_DRAINING(slurm.node_info_t _X):
    return ((_X.node_state & NODE_STATE_DRAIN) and
            (IS_NODE_ALLOCATED(_X) or IS_NODE_MIXED(_X)))

cdef inline IS_NODE_DYNAMIC(slurm.node_info_t _X):
    return (_X.node_state and NODE_STATE_DYNAMIC)

cdef inline IS_NODE_DRAINED(slurm.node_info_t _X):
    return (IS_NODE_DRAIN(_X) and not IS_NODE_DRAINING(_X))

cdef inline IS_NODE_COMPLETING(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_COMPLETING)

cdef inline IS_NODE_NO_RESPOND(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_NO_RESPOND)

cdef inline IS_NODE_POWERED_DOWN(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_POWERED_DOWN)

cdef inline IS_NODE_POWERING_DOWN(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_POWERING_DOWN)

cdef inline IS_NODE_FAIL(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_FAIL)

cdef inline IS_NODE_POWERING_UP(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_POWERING_UP)

cdef inline IS_NODE_MAINT(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_MAINT)

cdef inline IS_NODE_REBOOT_REQUESTED(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_REBOOT_REQUESTED)

cdef inline IS_NODE_REBOOT_ISSUED(slurm.node_info_t _X):
    return (_X.node_state & NODE_STATE_REBOOT_ISSUED)

ctypedef struct config_key_pair_t:
    char *name
    char *value


#
# Cython Wrapper Functions
#


def get_controllers():
    """Get information about slurm controllers.

    :return: Name of primary controller, Name of backup controllers
    :rtype: `tuple`
    """
    cdef:
        slurm.slurm_conf_t *slurm_ctl_conf_ptr = NULL
        slurm.time_t Time = <slurm.time_t>NULL
        int apiError = 0
        int errCode = slurm.slurm_load_ctl_conf(Time, &slurm_ctl_conf_ptr)
        uint32_t length = 0

    if errCode != 0:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    control_machs = []
    if slurm_ctl_conf_ptr is not NULL:

        if slurm_ctl_conf_ptr.control_machine is not NULL:
            length = slurm_ctl_conf_ptr.control_cnt
            for index in range(length):
                primary = slurm.stringOrNone(slurm_ctl_conf_ptr.control_machine[index], '')
                control_machs.append(primary)

        slurm.slurm_free_ctl_conf(slurm_ctl_conf_ptr)

    return control_machs


def is_controller(Host=None):
    """Return slurm controller status for host.

    :param string Host: Name of host to check

    :returns: None, primary or backup
    :rtype: `string`
    """
    control_machs = get_controllers()
    if not Host:
        Host = gethostname()

    index = control_machs.index(Host)
    if index == -1:
        return None
    if index == 0:
        return 'primary'
    if index > 0:
        return 'backup'


def slurm_api_version():
    """Return the slurm API version number.

    :returns: version_major, version_minor, version_micro
    :rtype: `tuple`
    """
    cdef long version = slurm.SLURM_VERSION_NUMBER

    return (SLURM_VERSION_MAJOR(version),
            SLURM_VERSION_MINOR(version),
            SLURM_VERSION_MICRO(version))


def slurm_load_slurmd_status():
    """Issue RPC to get and load the status of Slurmd daemon.

    :returns: Slurmd information
    :rtype: `dict`
    """
    cdef:
        dict Status = {}, Status_dict = {}
        slurm.slurmd_status_t *slurmd_status = NULL
        int errCode = slurm.slurm_load_slurmd_status(&slurmd_status)

    if errCode == slurm.SLURM_SUCCESS:
        hostname = slurm.stringOrNone(slurmd_status.hostname, '')
        Status_dict['actual_boards'] = slurmd_status.actual_boards
        Status_dict['booted'] = slurmd_status.booted
        Status_dict['actual_cores'] = slurmd_status.actual_cores
        Status_dict['actual_cpus'] = slurmd_status.actual_cpus
        Status_dict['actual_real_mem'] = slurmd_status.actual_real_mem
        Status_dict['actual_sockets'] = slurmd_status.actual_sockets
        Status_dict['actual_threads'] = slurmd_status.actual_threads
        Status_dict['actual_tmp_disk'] = slurmd_status.actual_tmp_disk
        Status_dict['hostname'] = hostname
        Status_dict['last_slurmctld_msg'] = slurmd_status.last_slurmctld_msg
        Status_dict['pid'] = slurmd_status.pid
        Status_dict['slurmd_debug'] = slurmd_status.slurmd_debug
        Status_dict['slurmd_logfile'] = slurm.stringOrNone(slurmd_status.slurmd_logfile, '')
        Status_dict['step_list'] = slurm.stringOrNone(slurmd_status.step_list, '')
        Status_dict['version'] = slurm.stringOrNone(slurmd_status.version, '')

        Status[hostname] = Status_dict

    slurm.slurm_free_slurmd_status(slurmd_status)

    return Status

def slurm_init(conf_file=None):
    """
    This function MUST be called before any internal API calls to ensure
    Slurm's internal configuration structures have been populated.

    :param string conf_file: Absolute path to the configuration file
    (optional). If None (default value), libslurm automatically locates its
    own configuration.

    :returns: None
    :rtype: None
    """
    if conf_file:
        slurm.slurm_init(conf_file.encode('UTF-8'))
    else:
        slurm.slurm_init(NULL)

def slurm_fini():
    """Call at process termination to cleanup internal configuration
    structures.

    :returns: None
    :rtype: None
    """
    slurm.slurm_fini()

#
# Slurm Config Class
#

def get_private_data_list(data):
    """Return the list of enciphered Private Data configuration."""

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
    """Class to access slurm config Information."""

    cdef:
        slurm.slurm_conf_t *slurm_ctl_conf_ptr
        slurm.slurm_conf_t *__Config_ptr
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
        """Get the time (epoch seconds) the retrieved data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    def ids(self):
        """Return the config IDs from retrieved data.

        :returns: Dictionary of config key IDs
        :rtype: `dict`
        """
        return self.__ConfigDict.keys()

    def find_id(self, char *keyID=''):
        """Retrieve config ID data.

        :param str keyID: Config key string to search
        :returns: Dictionary of values for given config key
        :rtype: `dict`
        """
        return self.__ConfigDict.get(keyID, {})

    cdef void __free(self):
        """Free memory allocated by slurm_load_ctl_conf."""
        if self.__Config_ptr is not NULL:
            slurm.slurm_free_ctl_conf(self.__Config_ptr)
            self.__Config_ptr = NULL
            self.__ConfigDict = {}
            self.__lastUpdate = 0

    def display_all(self):
        """Print slurm control configuration information."""
        slurm.slurm_print_ctl_conf(slurm.stdout, self.__Config_ptr)

    cdef int __load(self) except? -1:
        """Load the slurm control configuration information.

        :returns: slurm error code
        :rtype: `integer`
        """
        cdef:
            slurm.slurm_conf_t *slurm_ctl_conf_ptr = NULL
            slurm.time_t Time = <slurm.time_t>NULL
            int apiError = 0
            int errCode = slurm.slurm_load_ctl_conf(Time, &slurm_ctl_conf_ptr)

        if errCode != 0:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

        self.__Config_ptr = slurm_ctl_conf_ptr
        return errCode

    def key_pairs(self):
        """Return a dict of the slurm control data as key pairs.

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
        """Return the slurm control configuration information.

        :returns: Configuration data
        :rtype: `dict`
        """
        self.__load()
        self.__get()

        return self.__ConfigDict

    cpdef dict __get(self):
        """Get the slurm control configuration information.

        :returns: Configuration data
        :rtype: `dict`
        """
        cdef:
            void *ret_list = NULL
            slurm.List config_list = NULL
            slurm.ListIterator iters = NULL
            char tmp_str[128]

            config_key_pair_t *keyPairs
            int i = 0
            int listNum
            dict Ctl_dict = {}
            dict key_pairs = {}

        if self.__Config_ptr is not NULL:

            self.__lastUpdate = self.__Config_ptr.last_update

            Ctl_dict['accounting_storage_tres'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_tres, '')
            Ctl_dict['accounting_storage_enforce'] = self.__Config_ptr.accounting_storage_enforce
            Ctl_dict['accounting_storage_backup_host'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_backup_host, '')
            Ctl_dict['accounting_storage_ext_host'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_ext_host, '')
            Ctl_dict['accounting_storage_host'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_host, '')
            Ctl_dict['accounting_storage_pass'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_pass, '')
            Ctl_dict['accounting_storage_port'] = self.__Config_ptr.accounting_storage_port
            Ctl_dict['accounting_storage_type'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_type, '')
            Ctl_dict['accounting_storage_user'] = slurm.stringOrNone(self.__Config_ptr.accounting_storage_user, '')
            Ctl_dict['acct_gather_energy_type'] = slurm.stringOrNone(self.__Config_ptr.acct_gather_energy_type, '')
            Ctl_dict['acct_gather_profile_type'] = slurm.stringOrNone(self.__Config_ptr.acct_gather_profile_type, '')
            Ctl_dict['acct_gather_interconnect_type'] = slurm.stringOrNone(self.__Config_ptr.acct_gather_interconnect_type, '')
            Ctl_dict['acct_gather_filesystem_type'] = slurm.stringOrNone(self.__Config_ptr.acct_gather_filesystem_type, '')
            Ctl_dict['acct_gather_node_freq'] = self.__Config_ptr.acct_gather_node_freq
            Ctl_dict['auth_alt_types'] = slurm.stringOrNone(self.__Config_ptr.authalttypes, '')
            Ctl_dict['authinfo'] = slurm.stringOrNone(self.__Config_ptr.authinfo, '')
            Ctl_dict['authtype'] = slurm.stringOrNone(self.__Config_ptr.authtype, '')
            Ctl_dict['batch_start_timeout'] = self.__Config_ptr.batch_start_timeout
            Ctl_dict['bb_type'] = slurm.stringOrNone(self.__Config_ptr.bb_type, '')
            Ctl_dict['bcast_exclude'] = slurm.stringOrNone(self.__Config_ptr.bcast_exclude, '')
            Ctl_dict['bcast_parameters'] = slurm.stringOrNone(self.__Config_ptr.bcast_parameters, '')
            Ctl_dict['boot_time'] = self.__Config_ptr.boot_time
            Ctl_dict['core_spec_plugin'] = slurm.stringOrNone(self.__Config_ptr.core_spec_plugin, '')
            Ctl_dict['cli_filter_plugins'] = slurm.stringOrNone(self.__Config_ptr.cli_filter_plugins, '')
            Ctl_dict['cluster_name'] = slurm.stringOrNone(self.__Config_ptr.cluster_name, '')
            Ctl_dict['comm_params'] = slurm.stringOrNone(self.__Config_ptr.comm_params, '')
            Ctl_dict['complete_wait'] = self.__Config_ptr.complete_wait
            Ctl_dict['conf_flags'] = self.__Config_ptr.conf_flags
            Ctl_dict['cpu_freq_def'] = slurm.int32orNone(self.__Config_ptr.cpu_freq_def)
            Ctl_dict['cpu_freq_govs'] = self.__Config_ptr.cpu_freq_govs
            Ctl_dict['cred_type'] = slurm.stringOrNone(self.__Config_ptr.cred_type, '')
            Ctl_dict['debug_flags'] = self.__Config_ptr.debug_flags
            Ctl_dict['def_mem_per_cpu'] = self.__Config_ptr.def_mem_per_cpu
            Ctl_dict['dependency_params'] = slurm.stringOrNone(self.__Config_ptr.dependency_params, '')
            Ctl_dict['eio_timeout'] = self.__Config_ptr.eio_timeout
            Ctl_dict['enforce_part_limits'] = bool(self.__Config_ptr.enforce_part_limits)
            Ctl_dict['epilog'] = slurm.stringOrNone(self.__Config_ptr.epilog, '')
            Ctl_dict['epilog_msg_time'] = self.__Config_ptr.epilog_msg_time
            Ctl_dict['epilog_slurmctld'] = slurm.stringOrNone(self.__Config_ptr.epilog_slurmctld, '')
            Ctl_dict['ext_sensors_type'] = slurm.stringOrNone(self.__Config_ptr.ext_sensors_type, '')
            Ctl_dict['federation_parameters'] = slurm.stringOrNone(self.__Config_ptr.fed_params, '')
            Ctl_dict['first_job_id'] = self.__Config_ptr.first_job_id
            Ctl_dict['fs_dampening_factor'] = self.__Config_ptr.fs_dampening_factor
            Ctl_dict['get_env_timeout'] = self.__Config_ptr.get_env_timeout
            Ctl_dict['gpu_freq_def'] = slurm.stringOrNone(self.__Config_ptr.gpu_freq_def, '')
            Ctl_dict['gres_plugins'] = slurm.listOrNone(self.__Config_ptr.gres_plugins, ',')
            Ctl_dict['group_time'] = self.__Config_ptr.group_time
            Ctl_dict['group_update_force'] = self.__Config_ptr.group_force
            Ctl_dict['hash_val'] = self.__Config_ptr.hash_val
            Ctl_dict['health_check_interval'] = self.__Config_ptr.health_check_interval
            Ctl_dict['health_check_node_state'] = self.__Config_ptr.health_check_node_state
            Ctl_dict['health_check_program'] = slurm.stringOrNone(self.__Config_ptr.health_check_program, '')
            Ctl_dict['inactive_limit'] = self.__Config_ptr.inactive_limit
            Ctl_dict['job_acct_gather_freq'] = slurm.stringOrNone(self.__Config_ptr.job_acct_gather_freq, '')
            Ctl_dict['job_acct_gather_type'] = slurm.stringOrNone(self.__Config_ptr.job_acct_gather_type, '')
            Ctl_dict['job_acct_gather_params'] = slurm.stringOrNone(self.__Config_ptr.job_acct_gather_params, '')
            Ctl_dict['job_comp_host'] = slurm.stringOrNone(self.__Config_ptr.job_comp_host, '')
            Ctl_dict['job_comp_loc'] = slurm.stringOrNone(self.__Config_ptr.job_comp_loc, '')
            Ctl_dict['job_comp_params'] = slurm.stringOrNone(self.__Config_ptr.job_comp_params, '')
            Ctl_dict['job_comp_pass'] = slurm.stringOrNone(self.__Config_ptr.job_comp_pass, '')
            Ctl_dict['job_comp_port'] = self.__Config_ptr.job_comp_port
            Ctl_dict['job_comp_type'] = slurm.stringOrNone(self.__Config_ptr.job_comp_type, '')
            Ctl_dict['job_comp_user'] = slurm.stringOrNone(self.__Config_ptr.job_comp_user, '')
            Ctl_dict['job_container_plugin'] = slurm.stringOrNone(self.__Config_ptr.job_container_plugin, '')
            Ctl_dict['job_credential_private_key'] = slurm.stringOrNone(
                self.__Config_ptr.job_credential_private_key, ''
            )
            Ctl_dict['job_credential_public_certificate'] = slurm.stringOrNone(
                self.__Config_ptr.job_credential_public_certificate, ''
            )
            # TODO: wrap with job_defaults_str()
            #Ctl_dict['job_defaults_list'] = slurm.stringOrNone(self.__Config_ptr.job_defaults_list, ',')

            Ctl_dict['job_file_append'] = bool(self.__Config_ptr.job_file_append)
            Ctl_dict['job_requeue'] = bool(self.__Config_ptr.job_requeue)
            Ctl_dict['job_submit_plugins'] = slurm.stringOrNone(self.__Config_ptr.job_submit_plugins, '')
            Ctl_dict['keep_alive_time'] = slurm.int16orNone(self.__Config_ptr.keep_alive_time)
            Ctl_dict['kill_on_bad_exit'] = bool(self.__Config_ptr.kill_on_bad_exit)
            Ctl_dict['kill_wait'] = self.__Config_ptr.kill_wait
            Ctl_dict['launch_params'] = slurm.stringOrNone(self.__Config_ptr.launch_type, '')
            Ctl_dict['launch_type'] = slurm.stringOrNone(self.__Config_ptr.launch_type, '')
            Ctl_dict['licenses'] = __get_licenses(self.__Config_ptr.licenses)
            Ctl_dict['log_fmt'] = self.__Config_ptr.log_fmt
            Ctl_dict['mail_domain'] = slurm.stringOrNone(self.__Config_ptr.mail_domain, '')
            Ctl_dict['mail_prog'] = slurm.stringOrNone(self.__Config_ptr.mail_prog, '')
            Ctl_dict['max_array_sz'] = self.__Config_ptr.max_array_sz
            Ctl_dict['max_dbd_msgs'] = self.__Config_ptr.max_dbd_msgs
            Ctl_dict['max_job_cnt'] = self.__Config_ptr.max_job_cnt
            Ctl_dict['max_job_id'] = self.__Config_ptr.max_job_id
            Ctl_dict['max_mem_per_cp'] = self.__Config_ptr.max_mem_per_cpu
            Ctl_dict['max_step_cnt'] = self.__Config_ptr.max_step_cnt
            Ctl_dict['max_tasks_per_node'] = self.__Config_ptr.max_tasks_per_node
            Ctl_dict['min_job_age'] = self.__Config_ptr.min_job_age
            Ctl_dict['mpi_default'] = slurm.stringOrNone(self.__Config_ptr.mpi_default, '')
            Ctl_dict['mpi_params'] = slurm.stringOrNone(self.__Config_ptr.mpi_params, '')
            Ctl_dict['msg_timeout'] = self.__Config_ptr.msg_timeout
            Ctl_dict['next_job_id'] = self.__Config_ptr.next_job_id
            Ctl_dict['node_prefix'] = slurm.stringOrNone(self.__Config_ptr.node_prefix, '')
            Ctl_dict['over_time_limit'] = slurm.int16orNone(self.__Config_ptr.over_time_limit)
            Ctl_dict['plugindir'] = slurm.stringOrNone(self.__Config_ptr.plugindir, '')
            Ctl_dict['plugstack'] = slurm.stringOrNone(self.__Config_ptr.plugstack, '')
            Ctl_dict['power_parameters'] = slurm.stringOrNone(self.__Config_ptr.power_parameters, '')
            Ctl_dict['power_plugin'] = slurm.stringOrNone(self.__Config_ptr.power_plugin, '')
            Ctl_dict['prep_params'] = slurm.stringOrNone(self.__Config_ptr.prep_params, '')
            Ctl_dict['prep_plugins'] = slurm.stringOrNone(self.__Config_ptr.prep_plugins, '')

            config_get_preempt_mode = get_preempt_mode(self.__Config_ptr.preempt_mode)
            Ctl_dict['preempt_mode'] = slurm.stringOrNone(config_get_preempt_mode, '')

            Ctl_dict['preempt_type'] = slurm.stringOrNone(self.__Config_ptr.preempt_type, '')

            if self.__Config_ptr.preempt_exempt_time == slurm.INFINITE:
                Ctl_dict['preempt_exempt_time'] = "NONE"
            else:
                secs2time_str(self.__Config_ptr.preempt_exempt_time)
                Ctl_dict['preempt_exempt_time'] = slurm.stringOrNone(tmp_str, '')

            Ctl_dict['priority_decay_hl'] = self.__Config_ptr.priority_decay_hl
            Ctl_dict['priority_calc_period'] = self.__Config_ptr.priority_calc_period
            Ctl_dict['priority_favor_small'] = self.__Config_ptr.priority_favor_small
            Ctl_dict['priority_flags'] = self.__Config_ptr.priority_flags
            Ctl_dict['priority_max_age'] = self.__Config_ptr.priority_max_age
            Ctl_dict['priority_params'] = slurm.stringOrNone(self.__Config_ptr.priority_params, '')
            Ctl_dict['priority_site_factor_params'] = slurm.stringOrNone(self.__Config_ptr.site_factor_params, '')
            Ctl_dict['priority_site_factor_plugin'] = slurm.stringOrNone(self.__Config_ptr.site_factor_plugin, '')
            Ctl_dict['priority_reset_period'] = self.__Config_ptr.priority_reset_period
            Ctl_dict['priority_type'] = slurm.stringOrNone(self.__Config_ptr.priority_type, '')
            Ctl_dict['priority_weight_age'] = self.__Config_ptr.priority_weight_age
            Ctl_dict['priority_weight_assoc'] = self.__Config_ptr.priority_weight_assoc
            Ctl_dict['priority_weight_fs'] = self.__Config_ptr.priority_weight_fs
            Ctl_dict['priority_weight_js'] = self.__Config_ptr.priority_weight_js
            Ctl_dict['priority_weight_part'] = self.__Config_ptr.priority_weight_part
            Ctl_dict['priority_weight_qos'] = self.__Config_ptr.priority_weight_qos
            Ctl_dict['proctrack_type'] = slurm.stringOrNone(self.__Config_ptr.proctrack_type, '')
            Ctl_dict['private_data'] = self.__Config_ptr.private_data
            Ctl_dict['private_data_list'] = get_private_data_list(self.__Config_ptr.private_data)
            Ctl_dict['priority_weight_tres'] = slurm.stringOrNone(self.__Config_ptr.priority_weight_tres, '')
            Ctl_dict['prolog'] = slurm.stringOrNone(self.__Config_ptr.prolog, '')
            Ctl_dict['prolog_epilog_timeout'] = slurm.int16orNone(self.__Config_ptr.prolog_epilog_timeout)
            Ctl_dict['prolog_slurmctld'] = slurm.stringOrNone(self.__Config_ptr.prolog_slurmctld, '')
            Ctl_dict['propagate_prio_process'] = self.__Config_ptr.propagate_prio_process
            Ctl_dict['prolog_flags'] = self.__Config_ptr.prolog_flags
            Ctl_dict['propagate_rlimits'] = slurm.stringOrNone(self.__Config_ptr.propagate_rlimits, '')
            Ctl_dict['propagate_rlimits_except'] = slurm.stringOrNone(self.__Config_ptr.propagate_rlimits_except, '')
            Ctl_dict['reboot_program'] = slurm.stringOrNone(self.__Config_ptr.reboot_program, '')
            Ctl_dict['reconfig_flags'] = self.__Config_ptr.reconfig_flags
            Ctl_dict['resume_fail_program'] = slurm.stringOrNone(self.__Config_ptr.resume_fail_program, '')
            Ctl_dict['requeue_exit'] = slurm.stringOrNone(self.__Config_ptr.requeue_exit, '')
            Ctl_dict['requeue_exit_hold'] = slurm.stringOrNone(self.__Config_ptr.requeue_exit_hold, '')
            Ctl_dict['resume_fail_program'] = slurm.stringOrNone(self.__Config_ptr.resume_fail_program, '')
            Ctl_dict['resume_program'] = slurm.stringOrNone(self.__Config_ptr.resume_program, '')
            Ctl_dict['resume_rate'] = self.__Config_ptr.resume_rate
            Ctl_dict['resume_timeout'] = self.__Config_ptr.resume_timeout
            Ctl_dict['resv_epilog'] = slurm.stringOrNone(self.__Config_ptr.resv_epilog, '')
            Ctl_dict['resv_over_run'] = self.__Config_ptr.resv_over_run
            Ctl_dict['resv_prolog'] = slurm.stringOrNone(self.__Config_ptr.resv_prolog, '')
            Ctl_dict['ret2service'] = self.__Config_ptr.ret2service
            Ctl_dict['route_plugin'] = slurm.stringOrNone(self.__Config_ptr.route_plugin, '')
            Ctl_dict['sched_logfile'] = slurm.stringOrNone(self.__Config_ptr.sched_logfile, '')
            Ctl_dict['sched_log_level'] = self.__Config_ptr.sched_log_level
            Ctl_dict['sched_params'] = slurm.stringOrNone(self.__Config_ptr.sched_params, '')
            Ctl_dict['sched_time_slice'] = self.__Config_ptr.sched_time_slice
            Ctl_dict['schedtype'] = slurm.stringOrNone(self.__Config_ptr.schedtype, '')
            Ctl_dict['scron_params'] = slurm.stringOrNone(self.__Config_ptr.scron_params, '')
            Ctl_dict['select_type'] = slurm.stringOrNone(self.__Config_ptr.select_type, '')
            Ctl_dict['select_type_param'] = self.__Config_ptr.select_type_param
            Ctl_dict['slurm_conf'] = slurm.stringOrNone(self.__Config_ptr.slurm_conf, '')
            Ctl_dict['slurm_user_id'] = self.__Config_ptr.slurm_user_id
            Ctl_dict['slurm_user_name'] = slurm.stringOrNone(self.__Config_ptr.slurm_user_name, '')
            Ctl_dict['slurmd_user_id'] = self.__Config_ptr.slurmd_user_id
            Ctl_dict['slurmd_user_name'] = slurm.stringOrNone(self.__Config_ptr.slurmd_user_name, '')
            Ctl_dict['slurmctld_addr'] = slurm.stringOrNone(self.__Config_ptr.slurmctld_addr, '')
            Ctl_dict['slurmctld_debug'] = self.__Config_ptr.slurmctld_debug
            # TODO: slurmctld_host
            Ctl_dict['slurmctld_logfile'] = slurm.stringOrNone(self.__Config_ptr.slurmctld_logfile, '')
            Ctl_dict['slurmctld_pidfile'] = slurm.stringOrNone(self.__Config_ptr.slurmctld_pidfile, '')
            Ctl_dict['slurmctld_plugstack'] = slurm.stringOrNone(self.__Config_ptr.slurmctld_plugstack, '')
            Ctl_dict['slurmctld_port'] = self.__Config_ptr.slurmctld_port
            Ctl_dict['slurmctld_port_count'] = self.__Config_ptr.slurmctld_port_count
            Ctl_dict['slurmctld_primary_off_prog'] = slurm.stringOrNone(self.__Config_ptr.slurmctld_primary_off_prog, '')
            Ctl_dict['slurmctld_primary_on_prog'] = slurm.stringOrNone(self.__Config_ptr.slurmctld_primary_on_prog, '')
            Ctl_dict['slurmctld_syslog_debug'] = self.__Config_ptr.slurmctld_syslog_debug
            Ctl_dict['slurmctld_timeout'] = self.__Config_ptr.slurmctld_timeout
            Ctl_dict['slurmd_debug'] = self.__Config_ptr.slurmd_debug
            Ctl_dict['slurmd_logfile'] = slurm.stringOrNone(self.__Config_ptr.slurmd_logfile, '')
            Ctl_dict['slurmd_parameters'] = slurm.stringOrNone(self.__Config_ptr.slurmd_params, '')
            Ctl_dict['slurmd_pidfile'] = slurm.stringOrNone(self.__Config_ptr.slurmd_pidfile, '')
            Ctl_dict['slurmd_port'] = self.__Config_ptr.slurmd_port
            Ctl_dict['slurmd_spooldir'] = slurm.stringOrNone(self.__Config_ptr.slurmd_spooldir, '')
            Ctl_dict['slurmd_syslog_debug'] = self.__Config_ptr.slurmd_syslog_debug
            Ctl_dict['slurmd_timeout'] = self.__Config_ptr.slurmd_timeout
            Ctl_dict['srun_epilog'] = slurm.stringOrNone(self.__Config_ptr.srun_epilog, '')

            a = [0,0]
            if self.__Config_ptr.srun_port_range != NULL:
                a[0] = self.__Config_ptr.srun_port_range[0]
                a[1] = self.__Config_ptr.srun_port_range[1]
            Ctl_dict['srun_port_range'] = tuple(a)

            Ctl_dict['srun_prolog'] = slurm.stringOrNone(self.__Config_ptr.srun_prolog, '')
            Ctl_dict['state_save_location'] = slurm.stringOrNone(self.__Config_ptr.state_save_location, '')
            Ctl_dict['suspend_exc_nodes'] = slurm.listOrNone(self.__Config_ptr.suspend_exc_nodes, ',')
            Ctl_dict['suspend_exc_parts'] = slurm.listOrNone(self.__Config_ptr.suspend_exc_parts, ',')
            Ctl_dict['suspend_program'] = slurm.stringOrNone(self.__Config_ptr.suspend_program, '')
            Ctl_dict['suspend_rate'] = self.__Config_ptr.suspend_rate
            Ctl_dict['suspend_time'] = self.__Config_ptr.suspend_time
            Ctl_dict['suspend_timeout'] = self.__Config_ptr.suspend_timeout
            Ctl_dict['switch_type'] = slurm.stringOrNone(self.__Config_ptr.switch_type, '')
            Ctl_dict['switch_param'] = slurm.stringOrNone(self.__Config_ptr.switch_param, '')
            Ctl_dict['task_epilog'] = slurm.stringOrNone(self.__Config_ptr.task_epilog, '')
            Ctl_dict['task_plugin'] = slurm.stringOrNone(self.__Config_ptr.task_plugin, '')
            Ctl_dict['task_plugin_param'] = self.__Config_ptr.task_plugin_param
            Ctl_dict['task_prolog'] = slurm.stringOrNone(self.__Config_ptr.task_prolog, '')
            Ctl_dict['tcp_timeout'] = self.__Config_ptr.tcp_timeout
            Ctl_dict['tmp_fs'] = slurm.stringOrNone(self.__Config_ptr.tmp_fs, '')
            Ctl_dict['topology_param'] = slurm.stringOrNone(self.__Config_ptr.topology_param, '')
            Ctl_dict['topology_plugin'] = slurm.stringOrNone(self.__Config_ptr.topology_plugin, '')
            Ctl_dict['tree_width'] = self.__Config_ptr.tree_width
            Ctl_dict['unkillable_program'] = slurm.stringOrNone(self.__Config_ptr.unkillable_program, '')
            Ctl_dict['unkillable_timeout'] = self.__Config_ptr.unkillable_timeout
            Ctl_dict['version'] = slurm.stringOrNone(self.__Config_ptr.version, '')
            Ctl_dict['vsize_factor'] = self.__Config_ptr.vsize_factor
            Ctl_dict['wait_time'] = self.__Config_ptr.wait_time
            Ctl_dict['x11_params'] = slurm.stringOrNone(self.__Config_ptr.x11_params, '')

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
#                Ctl_dict['key_pairs'] = key_pairs

        self.__ConfigDict = Ctl_dict


#
# Partition Class
#


cdef class partition:
    """Class to access/modify Slurm Partition Information."""

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
        """Return time (epoch seconds) the partition data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    def ids(self):
        """Return the partition IDs from retrieved data.

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
        """Get partition information for a given partition.

        :param str partID: Partition key string to search
        :returns: Dictionary of values for given partition
        :rtype: `dict`
        """
        return self.get().get(partID)

    def find(self, name='', val=''):
        """Search for a property and associated value in the retrieved partition data.

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
        """Display the partition information from previous load partition method.

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
        """Delete a give slurm partition.

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
        """Get all slurm partition information

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
                       record.allow_accounts[0] == "\0".encode("UTF-8"):
                        Part_dict['allow_accounts'] = "ALL"
                    else:
                        Part_dict['allow_accounts'] = slurm.listOrNone(
                            record.allow_accounts, ',')

                    Part_dict['deny_accounts'] = None
                else:
                    Part_dict['allow_accounts'] = None
                    Part_dict['deny_accounts'] = slurm.listOrNone(
                        record.deny_accounts, ',')

                if record.allow_alloc_nodes == NULL:
                    Part_dict['allow_alloc_nodes'] = "ALL"
                else:
                    Part_dict['allow_alloc_nodes'] = slurm.listOrNone(
                        record.allow_alloc_nodes, ',')

                if record.allow_groups == NULL or \
                   record.allow_groups[0] == "\0".encode("UTF-8"):
                    Part_dict['allow_groups'] = "ALL"
                else:
                    Part_dict['allow_groups'] = slurm.listOrNone(
                        record.allow_groups, ',')

                if record.allow_qos or not record.deny_qos:
                    if record.allow_qos == NULL or \
                       record.allow_qos[0] == "\0".encode("UTF-8"):
                        Part_dict['allow_qos'] = "ALL"
                    else:
                        Part_dict['allow_qos'] = slurm.listOrNone(
                            record.allow_qos, ',')
                    Part_dict['deny_qos'] = None
                else:
                    Part_dict['allow_qos'] = None
                    Part_dict['deny_qos'] = slurm.listOrNone(record.allow_qos, ',')

                if record.alternate != NULL:
                    Part_dict['alternate'] = slurm.stringOrNone(record.alternate, '')
                else:
                    Part_dict['alternate'] = None

                Part_dict['billing_weights_str'] = slurm.stringOrNone(
                    record.billing_weights_str, '')

                #TODO: cpu_bind
                Part_dict['cr_type'] = record.cr_type

                if record.def_mem_per_cpu & slurm.MEM_PER_CPU:
                    if record.def_mem_per_cpu == slurm.MEM_PER_CPU:
                        Part_dict['def_mem_per_cpu'] = "UNLIMITED"
                        Part_dict['def_mem_per_node'] = None
                    else:
                        Part_dict['def_mem_per_cpu'] = record.def_mem_per_cpu & (~slurm.MEM_PER_CPU)
                        Part_dict['def_mem_per_node'] = None
                elif record.def_mem_per_cpu == 0:
                    Part_dict['def_mem_per_cpu'] = None
                    Part_dict['def_mem_per_node'] = "UNLIMITED"
                else:
                    Part_dict['def_mem_per_cpu'] = None
                    Part_dict['def_mem_per_node'] = record.def_mem_per_cpu

                if record.default_time == slurm.INFINITE:
                    Part_dict['default_time'] = "UNLIMITED"
                    Part_dict['default_time_str'] = "UNLIMITED"
                elif record.default_time == slurm.NO_VAL:
                    Part_dict['default_time'] = "NONE"
                    Part_dict['default_time_str'] = "NONE"
                else:
                    Part_dict['default_time'] = record.default_time * 60
                    Part_dict['default_time_str'] = secs2time_str(
                        record.default_time * 60)

                Part_dict['flags'] = get_partition_mode(record.flags,
                                                         record.max_share)
                Part_dict['grace_time'] = record.grace_time

                # TODO: job_defaults
                if record.max_cpus_per_node == slurm.INFINITE:
                    Part_dict['max_cpus_per_node'] = "UNLIMITED"
                else:
                    Part_dict['max_cpus_per_node'] = record.max_cpus_per_node

                if record.max_mem_per_cpu & slurm.MEM_PER_CPU:
                    if record.max_mem_per_cpu == slurm.MEM_PER_CPU:
                        Part_dict['max_mem_per_cp'] = "UNLIMITED"
                        Part_dict['max_mem_per_node'] = None
                    else:
                        Part_dict['max_mem_per_cp'] = record.max_mem_per_cpu & (~slurm.MEM_PER_CPU)
                        Part_dict['max_mem_per_node'] = None
                elif record.max_mem_per_cpu == 0:
                    Part_dict['max_mem_per_cp'] = None
                    Part_dict['max_mem_per_node'] = "UNLIMITED"
                else:
                    Part_dict['max_mem_per_cp'] = None
                    Part_dict['max_mem_per_node'] = record.max_mem_per_cpu

                if record.max_nodes == slurm.INFINITE:
                    Part_dict['max_nodes'] = "UNLIMITED"
                else:
                    Part_dict['max_nodes'] = record.max_nodes

                Part_dict['max_share'] = record.max_share

                if record.max_time == slurm.INFINITE:
                    Part_dict['max_time'] = "UNLIMITED"
                    Part_dict['max_time_str'] = "UNLIMITED"
                else:
                    Part_dict['max_time'] = record.max_time * 60
                    Part_dict['max_time_str'] = secs2time_str(record.max_time * 60)

                Part_dict['min_nodes'] = record.min_nodes
                Part_dict['name'] = slurm.stringOrNone(record.name, '')
                Part_dict['nodes'] = slurm.stringOrNone(record.nodes, '')

                if record.over_time_limit == slurm.NO_VAL16:
                    Part_dict['over_time_limit'] = "NONE"
                elif record.over_time_limit == slurm.INFINITE16:
                    Part_dict['over_time_limit'] = "UNLIMITED"
                else:
                    Part_dict['over_time_limit'] = record.over_time_limit

                # FIXME
                # They removed the slurm_get_preempt_mode() function
                # It must now be read from the slurm config
                # https://github.com/SchedMD/slurm/commit/bd76db3cd28f418f31de877f3c39a439b09289f7

                preempt_mode = record.preempt_mode
                if preempt_mode == slurm.NO_VAL16:
                      Part_dict['preempt_mode'] = slurm.stringOrNone(
                                slurm.slurm_preempt_mode_string(preempt_mode), ''
                                )
                Part_dict['priority_job_factor'] = record.priority_job_factor
                Part_dict['priority_tier'] = record.priority_tier
                Part_dict['qos_char'] = slurm.stringOrNone(record.qos_char, '')
                Part_dict['resume_timeout'] = record.resume_timeout
                Part_dict['state'] = get_partition_state(record.state_up)
                Part_dict['suspend_time'] = record.suspend_time
                Part_dict['suspend_timout'] = record.suspend_timeout
                Part_dict['total_cpus'] = record.total_cpus
                Part_dict['total_nodes'] = record.total_nodes
                Part_dict['tres_fmt_str'] = slurm.stringOrNone(record.tres_fmt_str, '')

                self._PartDict["%s" % name] = Part_dict
            slurm.slurm_free_partition_info_msg(self._Partition_ptr)
            self._Partition_ptr = NULL
            return self._PartDict
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)


    def update(self, dict Partition_dict):
        """Update a slurm partition.

        :param dict partition_dict: A populated partition dictionary,
            an empty one is created by create_partition_dict
        :returns: 0 for success, -1 for error, and the slurm error code
            is set appropriately.
        :rtype: `integer`
        """
        cdef int errCode = slurm_update_partition(Partition_dict)
        return errCode

    def create(self, dict Partition_dict):
        """Create a slurm partition.

        :param dict partition_dict: A populated partition dictionary,
            an empty one can be created by create_partition_dict
        :returns: 0 for success or -1 for error, and the slurm error
            code is set appropriately.
        :rtype: `integer`
        """
        cdef int errCode = slurm_create_partition(Partition_dict)
        return errCode


def create_partition_dict():
    """Returns a dictionary that can be populated by the user
    and used for the update_partition and create_partition calls.

    :returns: Empty reservation dictionary
    :rtype: `dict`
    """
    return {
        'Alternate': None,
        'Name': None,
        'MaxTime': 0,
        'DefaultTime': 0,
        'MaxNodes': 0,
        'MinNodes': 0,
        'Default': 0,
        'Hidden': 0,
        'RootOnly': 0,
        'Shared': 0,
        'Priority': 0,
        'State': 0,
        'Nodes': None,
        'AllowGroups': None,
        'AllocNodes': None
    }


def slurm_create_partition(dict partition_dict):
    """Create a slurm partition.

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
        part_msg_ptr.default_time = partition_dict['DefaultTime']

    if partition_dict.get('MaxNodes'):
        part_msg_ptr.max_nodes = partition_dict['MaxNodes']

    if partition_dict.get('MinNodes'):
        part_msg_ptr.min_nodes = partition_dict['MinNodes']

    errCode = slurm.slurm_create_partition(&part_msg_ptr)
    return errCode


def slurm_update_partition(dict partition_dict):
    """Update a slurm partition.

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

    if partition_dict.get('Name'):
        b_name = partition_dict['Name'].encode("UTF-8", "replace")
        part_msg_ptr.name = b_name

    if partition_dict.get('Alternate'):
        b_alternate = partition_dict['Alternate'].encode("UTF-8", "replace")
        part_msg_ptr.alternate = b_alternate

    if partition_dict.get('MaxTime'):
        part_msg_ptr.max_time = partition_dict['MaxTime']

    if partition_dict.get('DefaultTime'):
        part_msg_ptr.default_time = partition_dict['DefaultTime']

    if partition_dict.get('MaxNodes'):
        part_msg_ptr.max_nodes = partition_dict['MaxNodes']

    if partition_dict.get('MinNodes'):
        part_msg_ptr.min_nodes = partition_dict['MinNodes']

    state = partition_dict.get('State')
    if state:
        if state == 'DOWN':
            part_msg_ptr.state_up = PARTITION_DOWN
        elif state == 'UP':
            part_msg_ptr.state_up = PARTITION_UP
        elif state == 'DRAIN':
            part_msg_ptr.state_up = PARTITION_DRAIN
        else:
            errCode = -1

    if partition_dict.get('Nodes'):
        b_nodes = partition_dict['Nodes'].encode("UTF-8")
        part_msg_ptr.nodes = b_nodes

    if partition_dict.get('AllowGroups'):
        b_allow_groups = partition_dict['AllowGroups'].encode("UTF-8")
        part_msg_ptr.allow_groups = b_allow_groups

    if partition_dict.get('AllocNodes'):
        b_allow_alloc_nodes = partition_dict['AllocNodes'].encode("UTF-8")
        part_msg_ptr.allow_alloc_nodes = b_allow_alloc_nodes

    errCode = slurm.slurm_update_partition(&part_msg_ptr)
    return errCode


def slurm_delete_partition(PartID):
    """Delete a slurm partition.

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


cpdef int slurm_ping(int Controller=0) except? -1:
    """Issue RPC to check if slurmctld is responsive.

    :param int Controller: 0 for primary (Default=0), 1 for backup, 2 for backup2, ...
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
    """Issue RPC to have slurmctld reload its configuration file.

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
    """Issue RPC to have slurmctld cease operations.

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


cpdef int slurm_takeover(int backup_inx) except? -1:
    """Issue a RPC to have slurmctld backup controller take over.

    The backup controller takes over the primary controller.

    :returns: 0 for success or a slurm error code
    :rtype: `integer`
    """
    cdef int apiError = 0
    cdef int errCode = slurm.slurm_takeover(backup_inx)

    return errCode


cpdef int slurm_set_debug_level(uint32_t DebugLevel=0) except? -1:
    """Set the slurm controller debug level.

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
    """Set the slurm controller debug flags.

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
    """Set the slurm scheduler debug level.

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
    """Suspend a running slurm job.

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
    """Resume a running slurm job step.

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
    """Requeue a running slurm job step.

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
    """Get the remaining time in seconds for a slurm job step.

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
    """Get the end time in seconds for a slurm job step.

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
    """Return if a node could run a slurm job now if dispatched.

    :param int JobID: Job identifier
    :returns: Node Ready code
    :rtype: `integer`
    """
    cdef int apiError = 0
    cdef int errCode = slurm.slurm_job_node_ready(JobID)

    return errCode


cpdef int slurm_signal_job(uint32_t JobID=0, uint16_t Signal=0) except? -1:
    """Send a signal to a slurm job step.

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
    """Send a signal to a slurm job step.

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
    """Terminate a running slurm job step.

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
    """Terminate a running slurm job step.

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


cpdef int slurm_kill_job2(slurm.const_char_ptr JobID='', uint16_t Signal=0,
                          uint16_t BatchFlag=0, char* sibling=NULL) except? -1:
    """Terminate a running slurm job step.

    :param const char * JobID: Job identifier
    :param int Signal: Signal to send
    :param int BatchFlag: Job batch flag (default=0)
    :param string sibling: optional string of sibling cluster to send the message to
    :returns: 0 for success or -1 for error and set slurm errno
    :rtype: `integer`
    """
    cdef int apiError = 0
    cdef int errCode = slurm.slurm_kill_job2(JobID, Signal, BatchFlag, sibling)

    if errCode != 0:
        apiError = slurm.slurm_get_errno()
        raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    return errCode


cpdef int slurm_complete_job(uint32_t JobID=0, uint32_t JobCode=0) except? -1:
    """Complete a running slurm job step.

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
    """Notify a message to a running slurm job step.

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
    """Terminate a running slurm job step.

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
# Slurm Job Class to Control Configuration Read/Update
#


cdef class job:
    """Class to access/modify Slurm Job Information."""

    cdef:
        slurm.job_info_msg_t *_job_ptr
        slurm.slurm_job_info_t *_record
        slurm.time_t _lastUpdate
        slurm.time_t _lastBackfill
        uint16_t _ShowFlags
        dict _JobDict

    def __cinit__(self):
        self._job_ptr = NULL
        self._lastUpdate = 0
        self._lastBackfill = 0
        self._ShowFlags = slurm.SHOW_DETAIL | slurm.SHOW_ALL

    def __dealloc__(self):
        pass

    def lastUpdate(self):
        """Get the time (epoch seconds) the job data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    def lastBackfill(self):
        """Get the time (epoch seconds) of last backfilling run.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastBackfill

    cpdef ids(self):
        """Return the job IDs from retrieved data.

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
        """Search for a property and associated value in the retrieved job data.

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
        """Retrieve job ID data.

        This method accepts both string and integer formats of the jobid.  It
        calls slurm_xlate_job_id() to convert the jobid appropriately.
        This works for single jobs and job arrays.

        :param str jobid: Job id key string to search
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

    def find_user(self, user):
        """Retrieve a user's job data.

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

        if isinstance(user, str):
            try:
                uid = getpwnam(user).pw_uid
            except KeyError:
                raise KeyError("user %s not found on this system." % user)
        else:
            uid = user

        rc = slurm.slurm_load_job_user(&self._job_ptr, uid, self._ShowFlags)

        if rc == slurm.SLURM_SUCCESS:
            return self.get_job_ptr()
        else:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

    cpdef get(self):
        """Get all slurm jobs information.

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
        """Convert all job arrays in buffer to dictionary.

        :returns: dictionary of job attributes
        :rtype: `dict`
        """
        cdef:
            char time_str[32]
            char tmp_line[1024 * 128]
            time_t end_time
            time_t run_time
            uint16_t exit_status
            uint16_t term_sig
            uint32_t i
            dict Job_dict

        self._JobDict = {}
        self._lastUpdate = self._job_ptr.last_update
        self._lastBackfill = self._job_ptr.last_backfill
        exit_status = 0
        term_sig = 0

        for i in range(self._job_ptr.record_count):
            self._record = &self._job_ptr.job_array[i]
            Job_dict = {}

            Job_dict['account'] = slurm.stringOrNone(self._record.account, '')

            slurm.slurm_make_time_str(&self._record.accrue_time, time_str,
                                      sizeof(time_str))
            Job_dict['accrue_time'] = slurm.stringOrNone(time_str, '')

            Job_dict['admin_comment'] = slurm.stringOrNone(self._record.admin_comment, '')
            Job_dict['alloc_node'] = slurm.stringOrNone(self._record.alloc_node, '')
            Job_dict['alloc_sid'] = self._record.alloc_sid

            if self._record.array_job_id:
                if self._record.array_task_str:
                    Job_dict['array_job_id'] = self._record.array_job_id
                    Job_dict['array_task_id'] = None
                    Job_dict['array_task_str'] = slurm.stringOrNone(
                        self._record.array_task_str, ''
                    )
                else:
                    Job_dict['array_job_id'] = self._record.array_job_id
                    Job_dict['array_task_id'] = self._record.array_task_id
                    Job_dict['array_task_str'] = None
                if self._record.array_max_tasks:
                    Job_dict['array_task_throttle'] = self._record.array_max_tasks
            else:
                Job_dict['array_job_id'] = None
                Job_dict['array_task_id'] = None
                Job_dict['array_task_str'] = None

            if self._record.het_job_id:
                Job_dict['het_job_id'] = self._record.het_job_id
                Job_dict['het_job_id_set'] = slurm.stringOrNone(
                    self._record.het_job_id_set, ''
                )
                Job_dict['het_job_offset'] = self._record.het_job_offset
            else:
                Job_dict['het_job_id'] = None
                Job_dict['het_job_id_set'] = None
                Job_dict['het_job_offset'] = None

            if self._record.array_max_tasks:
                Job_dict['array_max_tasks'] = self._record.array_max_tasks
            else:
                Job_dict['array_max_tasks'] = None

            Job_dict['assoc_id'] = self._record.assoc_id
            Job_dict['batch_flag'] = self._record.batch_flag
            Job_dict['batch_features'] = slurm.stringOrNone(self._record.batch_features, '')
            Job_dict['batch_host'] = slurm.stringOrNone(self._record.batch_host, '')

            if self._record.billable_tres == NO_VAL_DOUBLE:
                Job_dict['billable_tres'] = None
            else:
                Job_dict['billable_tres'] = self._record.billable_tres

            Job_dict['bitflags'] = self._record.bitflags
            Job_dict['boards_per_node'] = self._record.boards_per_node
            Job_dict['burst_buffer'] = slurm.stringOrNone(self._record.burst_buffer, '')
            Job_dict['burst_buffer_state'] = slurm.stringOrNone(
                self._record.burst_buffer_state, ''
            )

            if self._record.cluster_features:
                Job_dict['cluster_features'] = slurm.stringOrNone(
                    self._record.cluster_features, ''
                )

            Job_dict['command'] = slurm.stringOrNone(self._record.command, '')
            Job_dict['comment'] = slurm.stringOrNone(self._record.comment, '')
            Job_dict['contiguous'] = bool(self._record.contiguous)
            Job_dict['core_spec'] = slurm.int16orNone(self._record.core_spec)
            Job_dict['cores_per_socket'] = slurm.int16orNone(self._record.cores_per_socket)

            if self._record.cpus_per_task == slurm.NO_VAL16:
                Job_dict['cpus_per_task'] = "N/A"
            else:
                Job_dict['cpus_per_task'] = self._record.cpus_per_task

            Job_dict['cpus_per_tres'] = slurm.stringOrNone(self._record.cpus_per_tres, '')
            Job_dict['cpu_freq_gov'] = slurm.int32orNone(self._record.cpu_freq_gov)
            Job_dict['cpu_freq_max'] = slurm.int32orNone(self._record.cpu_freq_max)
            Job_dict['cpu_freq_min'] = slurm.int32orNone(self._record.cpu_freq_min)
            Job_dict['dependency'] = slurm.stringOrNone(self._record.dependency, '')

            if WIFSIGNALED(self._record.derived_ec):
                term_sig = WTERMSIG(self._record.derived_ec)
            elif WIFEXITED(self._record.derived_ec):
                exit_status = WEXITSTATUS(self._record.derived_ec)

            Job_dict['derived_ec'] = str(exit_status) + ":" + str(term_sig)

            Job_dict['eligible_time'] = self._record.eligible_time
            Job_dict['end_time'] = self._record.end_time
            Job_dict['exc_nodes'] = slurm.listOrNone(self._record.exc_nodes, ',')

            if WIFSIGNALED(self._record.exit_code):
                term_sig = WTERMSIG(self._record.exit_code)
            elif WIFEXITED(self._record.exit_code):
                exit_status = WEXITSTATUS(self._record.exit_code)

            Job_dict['exit_code'] = str(exit_status) + ":" + str(term_sig)

            Job_dict['features'] = slurm.listOrNone(self._record.features, ',')

            if self._record.fed_siblings_active or self._record.fed_siblings_viable:
                Job_dict['fed_origin'] = slurm.stringOrNone(
                    self._record.fed_origin_str, ''
                )
                Job_dict['fed_viable_siblings'] = slurm.stringOrNone(
                    self._record.fed_siblings_viable_str, ''
                )
                Job_dict['fed_active_siblings'] = slurm.stringOrNone(
                    self._record.fed_siblings_active_str, ''
                )

            if self._record.bitflags & (GRES_DISABLE_BIND |
                                        GRES_ENFORCE_BIND |
                                        KILL_INV_DEP |
                                        NO_KILL_INV_DEP |
                                        SPREAD_JOB):
                if self._record.bitflags & GRES_DISABLE_BIND:
                    Job_dict['gres_enforce_bind'] = "No"
                if self._record.bitflags & GRES_ENFORCE_BIND:
                    Job_dict['gres_enforce_bind'] = "Yes"
                if self._record.bitflags & KILL_INV_DEP:
                    Job_dict['kill_on_invalid_dependent'] = "Yes"
                if self._record.bitflags & NO_KILL_INV_DEP:
                    Job_dict['kill_on_invalid_dependent'] = "No"
                if self._record.bitflags & SPREAD_JOB:
                    Job_dict['spread_job'] = "Yes"

            Job_dict['group_id'] = self._record.group_id

            # JOB RESOURCES HERE
            Job_dict['job_id'] = self._record.job_id
            Job_dict['job_state'] = slurm.stringOrNone(
                slurm.slurm_job_state_string(self._record.job_state), ''
            )

            slurm.slurm_make_time_str(&self._record.last_sched_eval, time_str,
                                      sizeof(time_str))
            Job_dict['last_sched_eval'] = slurm.stringOrNone(time_str, '')

            Job_dict['licenses'] = __get_licenses(self._record.licenses)
            Job_dict['max_cpus'] = self._record.max_cpus
            Job_dict['max_nodes'] = self._record.max_nodes
            Job_dict['mem_per_tres'] = slurm.stringOrNone(self._record.mem_per_tres, '')
            Job_dict['name'] = slurm.stringOrNone(self._record.name, '')
            Job_dict['network'] = slurm.stringOrNone(self._record.network, '')
            Job_dict['nodes'] = slurm.stringOrNone(self._record.nodes, '')
            Job_dict['nice'] = (<int64_t>self._record.nice) - NICE_OFFSET
            Job_dict['ntasks_per_core'] = slurm.int16orUnlimited(self._record.ntasks_per_core, "int")
            Job_dict['ntasks_per_core_str'] = slurm.int16orUnlimited(self._record.ntasks_per_core, "string")
            Job_dict['ntasks_per_node'] = self._record.ntasks_per_node
            Job_dict['ntasks_per_socket'] = slurm.int16orUnlimited(self._record.ntasks_per_socket, "int")
            Job_dict['ntasks_per_socket_str'] = slurm.int16orUnlimited(self._record.ntasks_per_socket, "string")
            Job_dict['ntasks_per_board'] = self._record.ntasks_per_board
            Job_dict['num_cpus'] = self._record.num_cpus
            Job_dict['num_nodes'] = self._record.num_nodes
            Job_dict['num_tasks'] = self._record.num_tasks
            Job_dict['partition'] = slurm.stringOrNone(self._record.partition, '')

            if self._record.pn_min_memory & slurm.MEM_PER_CPU:
                self._record.pn_min_memory &= (~slurm.MEM_PER_CPU)
                Job_dict['mem_per_cp'] = True
                Job_dict['min_memory_cp'] = self._record.pn_min_memory
                Job_dict['mem_per_node'] = False
                Job_dict['min_memory_node'] = None
            else:
                Job_dict['mem_per_cp'] = False
                Job_dict['min_memory_cp'] = None
                Job_dict['mem_per_node'] = True
                Job_dict['min_memory_node'] = self._record.pn_min_memory

            Job_dict['pn_min_memory'] = self._record.pn_min_memory
            Job_dict['pn_min_cpus'] = self._record.pn_min_cpus
            Job_dict['pn_min_tmp_disk'] = self._record.pn_min_tmp_disk
            Job_dict['power_flags'] = self._record.power_flags

            if self._record.preemptable_time:
                slurm.slurm_make_time_str(
                    &self._record.preemptable_time, time_str, sizeof(time_str)
                )
                Job_dict['preempt_eligible_time'] = slurm.stringOrNone(time_str, '')

                if self._record.preempt_time == 0:
                    Job_dict['preempt_time'] = "None"
                else:
                    slurm.slurm_make_time_str(&self._record.preempt_time, time_str, sizeof(time_str))
                    Job_dict['preempt_time'] = slurm.stringOrNone(time_str, '')

            Job_dict['priority'] = self._record.priority
            Job_dict['profile'] = self._record.profile
            Job_dict['qos'] = slurm.stringOrNone(self._record.qos, '')
            Job_dict['reboot'] = self._record.reboot
            Job_dict['req_nodes'] = slurm.listOrNone(self._record.req_nodes, ',')
            Job_dict['req_switch'] = self._record.req_switch
            Job_dict['requeue'] = bool(self._record.requeue)
            Job_dict['resize_time'] = self._record.resize_time
            Job_dict['restart_cnt'] = self._record.restart_cnt
            Job_dict['resv_name'] = slurm.stringOrNone(self._record.resv_name, '')

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

            Job_dict['run_time'] = run_time
            Job_dict['run_time_str'] = secs2time_str(run_time)
            Job_dict['sched_nodes'] = slurm.stringOrNone(self._record.sched_nodes, '')
            Job_dict['selinux_context'] = slurm.stringOrNone(self._record.selinux_context, '')

            if self._record.shared == 0:
                Job_dict['shared'] = "0"
            elif self._record.shared == 1:
                Job_dict['shared'] = "1"
            elif self._record.shared == 2:
                Job_dict['shared'] = "USER"
            else:
                Job_dict['shared'] = "OK"

            Job_dict['show_flags'] = self._record.show_flags
            Job_dict['sockets_per_board'] = self._record.sockets_per_board
            Job_dict['sockets_per_node'] = slurm.int16orNone(self._record.sockets_per_node)
            Job_dict['start_time'] = self._record.start_time

            if self._record.state_desc:
                Job_dict['state_reason'] = self._record.state_desc.decode("UTF-8").replace(" ", "_")
            else:
                Job_dict['state_reason'] = slurm.stringOrNone(
                    slurm.slurm_job_reason_string(
                        <slurm.job_state_reason>self._record.state_reason
                    ), ''
                )

            if self._record.batch_flag:
                slurm.slurm_get_job_stderr(tmp_line, sizeof(tmp_line), self._record)
                Job_dict['std_err'] = slurm.stringOrNone(tmp_line, '')

                slurm.slurm_get_job_stdin(tmp_line, sizeof(tmp_line), self._record)
                Job_dict['std_in'] = slurm.stringOrNone(tmp_line, '')

                slurm.slurm_get_job_stdout(tmp_line, sizeof(tmp_line), self._record)
                Job_dict['std_out'] = slurm.stringOrNone(tmp_line, '')
            else:
                Job_dict['std_err'] = None
                Job_dict['std_in'] = None
                Job_dict['std_out'] = None

            Job_dict['submit_time'] = self._record.submit_time
            Job_dict['suspend_time'] = self._record.suspend_time
            Job_dict['system_comment'] = slurm.stringOrNone(self._record.system_comment, '')

            if self._record.time_limit == slurm.NO_VAL:
                Job_dict['time_limit'] = "Partition_Limit"
                Job_dict['time_limit_str'] = "Partition_Limit"
            elif self._record.time_limit == slurm.INFINITE:
                Job_dict['time_limit'] = "UNLIMITED"
                Job_dict['time_limit_str'] = "UNLIMITED"
            else:
                Job_dict['time_limit'] = self._record.time_limit
                Job_dict['time_limit_str'] = mins2time_str(
                    self._record.time_limit)

            Job_dict['time_min'] = self._record.time_min
            Job_dict['threads_per_core'] = slurm.int16orNone(self._record.threads_per_core)
            Job_dict['tres_alloc_str'] = slurm.stringOrNone(self._record.tres_alloc_str, '')
            Job_dict['tres_bind'] = slurm.stringOrNone(self._record.tres_bind, '')
            Job_dict['tres_freq'] = slurm.stringOrNone(self._record.tres_freq, '')
            Job_dict['tres_per_job'] = slurm.stringOrNone(self._record.tres_per_job, '')
            Job_dict['tres_per_node'] = slurm.stringOrNone(self._record.tres_per_node, '')
            Job_dict['tres_per_socket'] = slurm.stringOrNone(self._record.tres_per_socket, '')
            Job_dict['tres_per_task'] = slurm.stringOrNone(self._record.tres_per_task, '')
            Job_dict['tres_req_str'] = slurm.stringOrNone(self._record.tres_req_str, '')
            Job_dict['user_id'] = self._record.user_id
            Job_dict['wait4switch'] = self._record.wait4switch
            Job_dict['wckey'] = slurm.stringOrNone(self._record.wckey, '')
            Job_dict['work_dir'] = slurm.stringOrNone(self._record.work_dir, '')

            Job_dict['cpus_allocated'] = {}
            Job_dict['cpus_alloc_layout'] = {}

            if self._record.nodes is not NULL:
                hl = hostlist()
                _nodes = slurm.stringOrNone(self._record.nodes, '')
                hl.create(_nodes)
                host_list = hl.get_list()
                if host_list:
                    for node_name in host_list:
                        b_node_name = node_name.decode("UTF-8")
                        Job_dict['cpus_allocated'][b_node_name] = self.__cpus_allocated_on_node(node_name)
                        Job_dict['cpus_alloc_layout'][b_node_name] = self.__cpus_allocated_list_on_node(node_name)
                hl.destroy()

            self._JobDict[self._record.job_id] = Job_dict

        slurm.slurm_free_job_info_msg(self._job_ptr)
        self._job_ptr = NULL
        return self._JobDict

    cpdef int __cpus_allocated_on_node_id(self, int nodeID=0):
        """Get the number of cpus allocated to a job on a node by node name.

        :param int nodeID: Numerical node ID
        :returns: Num of CPUs allocated to job on this node or -1 on error
        :rtype: `integer`
        """
        cdef:
            slurm.job_resources_t *job_resrcs_ptr = <slurm.job_resources_t *>self._record.job_resrcs
            int retval = slurm.slurm_job_cpus_allocated_on_node_id(job_resrcs_ptr, nodeID)

        return retval

    cdef int __cpus_allocated_on_node(self, char* nodeName=''):
        """Get the number of cpus allocated to a slurm job on a node by node name.

        :param string nodeName: Name of node
        :returns: Num of CPUs allocated to job on this node or -1 on error
        :rtype: `integer`
        """
        cdef:
            slurm.job_resources_t *job_resrcs_ptr = <slurm.job_resources_t *>self._record.job_resrcs
            int retval = slurm.slurm_job_cpus_allocated_on_node(job_resrcs_ptr, nodeName)

        return retval

    cdef list __cpus_allocated_list_on_node(self, char* nodeName=''):
        """Get a list of cpu ids allocated to current slurm job on a node by node name.

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
        """converts a string describing a bitmap (from slurm_job_cpus_allocated_str_on_node()) to a list.

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
        """Release the storage generated by the slurm_get_job_steps function."""
        if self._job_ptr is not NULL:
            slurm.slurm_free_job_info_msg(self._job_ptr)

    cpdef print_job_info_msg(self, int oneLiner=0):
        """Print the data structure describing all job step records.

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

    def slurm_job_batch_script(self, jobid):
        """
        Retrieve the batch script for a given jobid.

        :param str jobid: Job id key string to search
        :returns: String output of a jobid's batch script
        :rtype: `str`
        """
        if isinstance(jobid, int) or isinstance(jobid, long):
            jobid = str(jobid).encode("UTF-8")
        else:
            jobid = jobid.encode("UTF-8")

        jobid_xlate = slurm.slurm_xlate_job_id(jobid)
        return slurm.slurm_job_batch_script(slurm.stdout, jobid_xlate)

    cdef int fill_job_desc_from_opts(self, dict job_opts, slurm.job_desc_msg_t *desc):
        """
        https://github.com/SchedMD/slurm/blob/0bc4ac4902c4c150ee66b90fb41f3c67352f85ba/src/api/init_msg.c#L54
        https://github.com/SchedMD/slurm/blob/a8f0ff71504e77feb7fa744ba1f6d44daedb6989/src/sbatch/opt.c#L294

        Do I even need to set some of the defaults?

        python dict options should match slurm sbatch long options:
            https://github.com/SchedMD/slurm/blob/63a06811441dd7882083c282d92ae6596ec00a8a/src/sbatch/opt.c#L755

        * make sure options match sbatch command line opts and not struct member names.
        """
        cdef:
            int i

        # TODO: jobid_set
        # https://github.com/SchedMD/slurm/blob/a8f0ff71504e77feb7fa744ba1f6d44daedb6989/src/sbatch/opt.c#L384
        if job_opts.get("contiguous") == 1:
            desc.contiguous = 1
        else:
            desc.contiguous = 0

        if job_opts.get("container"):
            container = job_opts.get("container").encode("UTF-8", "replace")
            desc.container = container

        if job_opts.get("core_spec"):
            desc.core_spec = job_opts.get("core_spec")
        else:
            desc.core_spec = slurm.NO_VAL16

        if job_opts.get("constraints"):
            features = job_opts.get("constraints").encode("UTF-8", "replace")
            desc.features = features

        if job_opts.get("immediate"):
            desc.immediate = job_opts.get("immediate")
        else:
            desc.immediate = 0

        if job_opts.get("job_name"):
            name = job_opts.get("job_name").encode("UTF-8", "replace")
            desc.name = name
        else:
            desc.name = "sbatch"

        if job_opts.get("reservation"):
            reservation = job_opts.get("reservation").encode("UTF-8", "replace")
            desc.reservation = reservation

        if job_opts.get("wckey"):
            wckey = job_opts.get("wckey").encode("UTF-8", "replace")
            desc.wckey = wckey

        # TODO when nodelist is set, min_nodes needs to be adjusted accordingly
        if job_opts.get("nodelist"):
            req_nodes = job_opts.get("nodelist").encode("UTF-8", "replace")
            desc.req_nodes = req_nodes

        if job_opts.get("exc_nodes"):
            exc_nodes = job_opts.get("exc_nodes").encode("UTF-8", "replace")
            desc.exc_nodes = exc_nodes

        if job_opts.get("partition"):
            partition = job_opts.get("partition").encode("UTF-8", "replace")
            desc.partition = partition

        if job_opts.get("profile"):
            desc.profile = job_opts.get("profile")
        else:
            desc.profile = ACCT_GATHER_PROFILE_NOT_SET

        if job_opts.get("licenses"):
            licenses = job_opts.get("licenses").encode("UTF-8", "replace")
            desc.licenses = licenses

        if job_opts.get("min_nodes"):
            desc.min_nodes = job_opts.get("min_nodes")
            if job_opts.get("max_nodes"):
                desc.max_nodes = job_opts.get("max_nodes")
        elif "ntasks" in job_opts and job_opts.get("min_nodes") == 0:
            desc.min_nodes = 0

        if job_opts.get("ntasks_per_node"):
            ntasks_per_node = job_opts.get("ntasks_per_node")
            desc.ntasks_per_node = ntasks_per_node

        if job_opts.get("uid"):
            desc.user_id = job_opts.get("uid")
        else:
            desc.user_id = getuid()

        if job_opts.get("gid"):
            desc.group_id = job_opts.get("gid")
        else:
            desc.group_id = getgid()

        if job_opts.get("dependency"):
            dependency = job_opts.get("dependency").encode("UTF-8", "replace")
            desc.dependency = dependency

        if job_opts.get("array_inx"):
            array_inx = job_opts.get("array_inx").encode("UTF-8")
            desc.array_inx = array_inx

        if job_opts.get("mem_bind"):
            mem_bind = job_opts.get("mem_bind").encode("UTF-8")
            desc.mem_bind = mem_bind

        if job_opts.get("mem_bind_type"):
            desc.mem_bind_type = job_opts.get("mem_bind_type")
        else:
            desc.mem_bind_type = 0

        if job_opts.get("plane_size"):
            desc.plane_size = job_opts.get("plane_size")

        if job_opts.get("distribution"):
            desc.task_dist = job_opts.get("distribution")
        else:
            desc.task_dist = slurm.SLURM_DIST_UNKNOWN

        if job_opts.get("container"):
            container = job_opts.get("container").encode("UTF-8", "replace")
            desc.container = container

        # TODO: what's the default opt.network?
        # Slurm on Cray
        if job_opts.get("network"):
            network = job_opts.get("network").encode("UTF-8", "replace")
            desc.network = network

        if job_opts.get("nice"):
            desc.nice = NICE_OFFSET + job_opts.get("nice")

        if job_opts.get("priority"):
            desc.priority = job_opts.get("priority")

        if job_opts.get("mail_type"):
            desc.mail_type = job_opts.get("mail_type")
        else:
            desc.mail_type = 0

        if job_opts.get("mail_user"):
            mail_user = job_opts.get("mail_user").encode("UTF-8", "replace")
            desc.mail_user = mail_user

        # TODO: does begin need to get translated from string/epoch to time_t?
        if job_opts.get("begin"):
            desc.begin_time = job_opts.get("begin")
        else:
            desc.begin_time = 0

        # TODO: does deadline need to get translated from string/epoch to time_t?
        if job_opts.get("deadline"):
            desc.deadline = job_opts.get("deadline")
        else:
            desc.deadline = 0

        if job_opts.get("delay_boot"):
            desc.delay_boot = job_opts.get("delay_boot")

        if job_opts.get("account"):
            account = job_opts.get("account").encode("UTF-8", "replace")
            desc.account = account

        if job_opts.get("comment"):
            comment = job_opts.get("comment").encode("UTF-8", "replace")
            desc.comment = comment

        if job_opts.get("qos"):
            qos = job_opts.get("qos").encode("UTF-8", "replace")
            desc.qos = qos

        if job_opts.get("hold"):
            desc.priority = 0

        # BG parameters
        # opt.geometry
        #   slurmdb_setup_cluster_dims() doesn't appear to be externalized
        # opt.conn_type

        if job_opts.get("reboot"):
            desc.reboot = 1

        # job constraints
        if job_opts.get("mincpus"):
            desc.pn_min_cpus = job_opts.get("mincpus")

        if job_opts.get("realmem"):
            desc.pn_min_memory = job_opts.get("realmem")
        elif job_opts.get("mem_per_cp"):
            desc.pn_min_memory = job_opts.get("mem_per_cp") | slurm.MEM_PER_CPU

        if job_opts.get("tmpdisk"):
            desc.pn_min_tmp_disk = job_opts.get("tmpdisk")

        if job_opts.get("overcommit"):
            desc.min_cpus = max(job_opts.get("min_nodes", 1), 1)
            desc.overcommit = job_opts.get("overcommit")
        elif job_opts.get("cpus_per_task"):
            desc.min_cpus = job_opts.get("ntasks", 1) * job_opts.get("cpus_per_task")
        elif job_opts.get("nodelist") and job_opts.get("min_nodes") == 0:
            desc.min_cpus = 0
        else:
            desc.min_cpus = job_opts.get("ntasks", 1)

        if job_opts.get("cpus_per_task"):
            desc.cpus_per_task = job_opts.get("cpus_per_task")

        if job_opts.get("ntasks"):
            desc.num_tasks = job_opts.get("ntasks")

        if job_opts.get("ntasks_per_socket"):
            desc.ntasks_per_socket = job_opts.get("ntasks_per_socket")

        if job_opts.get("ntasks_per_core"):
            desc.ntasks_per_core = job_opts.get("ntasks_per_core")

        # node constraints
        if job_opts.get("sockets_per_node"):
            desc.sockets_per_node = job_opts.get("sockets_per_node")

        if job_opts.get("cores_per_socket"):
            desc.cores_per_socket = job_opts.get("cores_per_socket")

        if job_opts.get("threads_per_core"):
            desc.threads_per_core = job_opts.get("threads_per_core")

        if job_opts.get("no_kill"):
            desc.kill_on_node_fail = 0

        if job_opts.get("time_limit"):
            desc.time_limit = job_opts.get("time_limit")

        if job_opts.get("time_min"):
            desc.time_min = job_opts.get("time_min")

        if job_opts.get("shared"):
            desc.shared = job_opts.get("shared")

        if job_opts.get("wait_all_nodes"):
            desc.wait_all_nodes = job_opts.get("wait_all_nodes")
        else:
            desc.wait_all_nodes = slurm.NO_VAL16

        if job_opts.get("warn_flags"):
            desc.warn_flags = job_opts.get("warn_flags")

        if job_opts.get("warn_signal"):
            desc.warn_signal = job_opts.get("warn_signal")

        if job_opts.get("warn_time"):
            desc.warn_time = job_opts.get("warn_time")

        # src/sbatch/sbatch.c#L595
        desc.environment = NULL
        if job_opts.get("export_file"):
            # desc->environment = env_array_from_file(opt.export_file);
            #   if (desc->environment == NULL)
            #   exit(1);
            pass

        job_opts["get_user_env_time"] = -1

        if not job_opts.get("export_env"):
            slurm.slurm_env_array_merge(&desc.environment, <slurm.const_char_pptr>slurm.environ)
        elif job_opts.get("export_env") == "ALL":
            slurm.slurm_env_array_merge(&desc.environment, <slurm.const_char_pptr>slurm.environ)
        elif job_opts.get("export_env") == "NONE":
            desc.environment = slurm.slurm_env_array_create()
            # env_array_merge_slurm(&desc->environment, (const char **)environ);
            job_opts["get_user_env_time"] = 0
        else:
            # _env_merge_filter(desc)
            job_opts["get_user_env_time"] = 0

        if job_opts["get_user_env_time"] >= 0:
            slurm.slurm_env_array_overwrite(&desc.environment, "SLURM_GET_USER_ENV", "1")

        desc.env_size = self.envcount(desc.environment)

        # don't need argv/argc since jobscript is not submitted via cmdline with arguments.

        if job_opts.get("error"):
            std_err = job_opts.get("error").encode("UTF-8", "replace")
            desc.std_err = std_err

        if job_opts.get("input"):
            std_in = job_opts.get("input").encode("UTF-8", "replace")
            desc.std_in = std_in
        else:
            desc.std_in = "/dev/null"

        if job_opts.get("output"):
            std_out = job_opts.get("output").encode("UTF-8", "replace")
            desc.std_out = std_out

        # FIXME: should this be python's getcwd or C's getcwd?
        # also, allow option to specify work_dir, if not, set default

        if job_opts.get("work_dir"):
            work_dir = job_opts.get("work_dir").encode("UTF-8", "replace")
            desc.work_dir = work_dir
        else:
            cwd = os.getcwd().encode("UTF-8", "replace")
            desc.work_dir = cwd

        if job_opts.get("requeue"):
            desc.requeue = job_opts.get("requeue")

        if job_opts.get("open_mode"):
            desc.open_mode = job_opts.get("open_mode")

        if job_opts.get("acctg_freq"):
            acctg_freq = job_opts.get("acctg_freq").encode("UTF-8")
            desc.acctg_freq = acctg_freq

        # TODO: spank_job_env_size

        if job_opts.get("cpu_freq_min"):
            desc.cpu_freq_min = job_opts.get("cpu_freq_min")
        else:
            desc.cpu_freq_min = slurm.NO_VAL

        if job_opts.get("cpu_freq_max"):
            desc.cpu_freq_max = job_opts.get("cpu_freq_max")
        else:
            desc.cpu_freq_max = slurm.NO_VAL

        if job_opts.get("cpu_freq_gov"):
            desc.cpu_freq_gov = job_opts.get("cpu_freq_gov")
        else:
            desc.cpu_freq_gov = slurm.NO_VAL

        if job_opts.get("req_switch") and job_opts.get("req_switch") >= 0:
            desc.req_switch = job_opts.get("req_switch")

        if job_opts.get("wait4switch") and job_opts.get("wait4switch") >= 0:
            desc.wait4switch = job_opts.get("wait4switch")

        if job_opts.get("power_flags"):
            desc.power_flags = job_opts.get("power_flags")

        if job_opts.get("job_flags"):
            desc.bitflags = job_opts.get("job_flags")

        if job_opts.get("mcs_label"):
            mcs_label = job_opts.get("mcs_label").encode("UTF-8", "replace")
            desc.mcs_label = mcs_label

        if job_opts.get("tres_per_job"):
            tres_per_job = job_opts.get("tres_per_job").encode("UTF-8", "replace")
            desc.tres_per_job = tres_per_job

        if job_opts.get("tres_per_node"):
            tres_per_node = job_opts.get("tres_per_node").encode("UTF-8", "replace")
            desc.tres_per_node = tres_per_node

        if job_opts.get("tres_per_task"):
            tres_per_task = job_opts.get("tres_per_task").encode("UTF-8", "replace")
            desc.tres_per_task = tres_per_task

        return 0

    cdef int envcount(self, char **env):
        """Return the number of elements in the environment `env`."""
        cdef int envc = 0
        while (env[envc] != NULL):
            envc += 1
        return envc

    cdef void print_db_notok(self, slurm.const_char_ptr cname, bool isenv):
        b_all = "all".encode("UTF-8", "replace")
        if errno:
            sys.stderr.write("There is a problem talking to the database:") # %m.  "
#                  "Only local cluster communication is available, remove "
#                  "%s or contact your admin to resolve the problem.",
#                  isenv ? "SLURM_CLUSTERS from your environment" :
#                  "--cluster from your command line")
            sys.exit(slurm.SLURM_ERROR)
        elif cname == b_all:
            sys.stderr.write("No clusters can be reached now. Contact your admin to resolve the problem.")
            sys.exit(slurm.SLURM_ERROR)
        else:
            sys.stderr.write("%s can't be reached now, or it is an invalid entry for %s.  " % cname)
#                  "Use 'sacctmgr list clusters' to see available clusters.",
#                  cname, isenv ? "SLURM_CLUSTERS" : "--cluster")
            sys.exit(slurm.SLURM_ERROR)

    cdef bool is_alps_cray_system(self):
        if slurm.working_cluster_rec:
            return slurm.working_cluster_rec.flags & slurm.CLUSTER_FLAG_CRAY
        if ALPS_CRAY_SYSTEM:
            return True
        return False

    cdef int _check_cluster_specific_settings(self, slurm.job_desc_msg_t *req):
        cdef int rc = slurm.SLURM_SUCCESS

        if self.is_alps_cray_system():
            if req.shared and req.shared != <uint16_t>slurm.NO_VAL:
                print("--share is not supported on Cray/ALPS systems.")
                req.shared = <uint16_t>slurm.NO_VAL
            if req.overcommit and req.overcommit != <uint8_t>slurm.NO_VAL:
                print("--overcommit is not supported on Cray/ALPS systems.")
                req.overcommit = False
            if req.wait_all_nodes and req.wait_all_nodes != <uint16_t>slurm.NO_VAL:
                print("--wait-all-nodes is handled automatically on Cray/ALPS systems.")
                req.wait_all_nodes = <uint16_t>slurm.NO_VAL
        return rc

    def submit_batch_job(self, job_opts):
        """Submit batch job.
        * make sure options match sbatch command line opts and not struct member names.
        """
        cdef:
            slurm.job_desc_msg_t desc
            slurm.submit_response_msg_t *resp
            #slurm.slurmdb_cluster_rec_t *working_cluster_rec = NULL
            int rc = 0
            int fill_job_desc_rc
            int retries = 0
            int error_exit = 1


        # _set_exit_code()
        val = os.environ.get("SLURM_EXIT_ERROR")
        if val:
            if int(val) == 0:
                sys.stderr.write("SLURM_EXIT_ERROR has zero value")
                sys.exit(slurm.SLURM_ERROR)
            else:
                error_exit = int(val)

        # script_name = process_options_first_pass() -> calls _opt_default(true)
        # possibly not needed here in the API

        if job_opts.get("wrap"):
            # _script_wrap
            wrap_script = "#!/bin/bash\n"
            wrap_script += "# This script was create by PySlurm.\n\n"
            wrap_script += job_opts.get("wrap")
            script_body = wrap_script.encode("UTF-8", "replace")
        elif job_opts.get("script"):
            # _get_script_buffer
            with open(job_opts.get("script"), "r") as script:
                script_body = script.read()
                if len(script_body) == 0:
                    raise ValueError("Batch script is empty!")
                elif script_body.isspace():
                    raise ValueError("Batch script contains only whitespace!.")
                elif not script_body.startswith("#!"):
                    msg = "This does not look like a batch script.  The first"
                    msg += " line must start with #! followed by the path"
                    msg += " to an interpreter."
                    raise ValueError(msg)
                elif "\x00" in script_body:
                    # TODO: should this be \0 or \x00, are these the same in Python?
                    msg = "The SLURM controller does not allow scripts that"
                    msg += " contain a NULL character '\\0'."
                    raise ValueError(msg)
                elif "\r\n" in script_body:
                    msg = "Batch script contains DOS line breaks (\\r\\n)"
                    msg += " instead of expected UNIX line breaks (\\n)."
                    raise ValueError(msg)
            script_body = script_body.encode("UTF-8", "replace")
        elif job_opts.get("script") is None:
            sys.exit(1)

        # process_options_second_pass
        #   - _opt_default(first_pass)
        #   - _opt_batch_script( )
        #   - _opt_env()
        #   - _opt_verify()
        #   - _opt_list ??
        # add burst buffer to script
        # spank_init_post_opt
        # check get_user_env_time
        #   - _set_rlimit_env()

        if job_opts.get("export_file"):
            # if the environment is coming from a file, the
            # environment at execution startup must be unset
            os.environ.clear()

        # _set_prio_process_env();
        errno = 0
        retval = 0
        retval = getpriority(PRIO_PROCESS, 0)
        if retval == -1:
            if errno:
                raise ValueError("getpriority(PRIO_PROCESS): %m")

        try:
            os.environ["SLURM_PRIO_PROCESS"] = str(retval)
        except:
            raise ValueError("unable to set SLURM_PRIO_PROCESS in environment")

        # _set_spank_env();

        # _set_submit_dir_env();
        try:
            os.environ["SLURM_SUBMIT_DIR"] = os.getcwd()
        except:
            raise ValueError("unable to set SLURM_SUBMIT_DIR in environment")

        try:
            os.environ["SLURM_SUBMIT_HOST"] = gethostname()
        except:
            raise ValueError("unable to set SLURM_SUBMIT_HOST in environment")

        # _set_umask_env();
        if not os.environ.get("SLURM_UMASK"):
            mask = os.umask(0)
            _ = os.umask(mask)
            try:
                os.environ["SLURM_UMASK"] = "0" + str((mask>>6)&07) + str((mask>>3)&07) + str(mask&07)
            except:
                raise ValueError("unable to set SLURM_UMASK in environment")

        # slurm_init_job_desc_msg(&desc)
        slurm.slurm_init_job_desc_msg(&desc)
        fill_job_desc_rc = self.fill_job_desc_from_opts(job_opts, &desc)

        if fill_job_desc_rc == -1:
            sys.exit(error_exit)

        desc.script = script_body

        # If can run on multiple clusters, find the earliest run time
        # and run it there
        if job_opts.get("clusters"):
            clusters = job_opts.get("clusters").encode("UTF-8", "replace")
            desc.clusters = clusters
            if slurm.slurmdb_get_first_avail_cluster(&desc, clusters,
                &slurm.working_cluster_rec) != slurm.SLURM_SUCCESS:
                    self.print_db_notok(clusters, 0)
                    sys.exit(error_exit)

        if self._check_cluster_specific_settings(&desc) != slurm.SLURM_SUCCESS:
            sys.exit(error_exit)


        if job_opts.get("test_only"):
            if slurm.slurm_job_will_run(&desc) != slurm.SLURM_SUCCESS:
                slurm.slurm_perror("allocation failure")
                sys.exit(1)
            sys.exit(0)

        while slurm.slurm_submit_batch_job(&desc, &resp) < 0:
            if errno == slurm.ESLURM_ERROR_ON_DESC_TO_RECORD_COPY:
                msg = "Slurm job queue full, sleeping and retrying."
            elif errno == slurm.ESLURM_NODES_BUSY:
                msg = "Job step creation temporarily disabled, retrying"
            elif errno == EAGAIN:
                msg = "Slurm temporarily unable to accept job, sleeping and retrying."
            else:
                msg = None

            if msg is None or retries >= MAX_RETRIES:
                raise ValueError("Batch job submission failed: %s", msg)

#            if retries:
            retries += 1
            p_time.sleep(retries)

        job_id = resp.job_id
        slurm.slurm_free_submit_response_response_msg(resp)

        #return "Submitted batch job %s" % job_id
        return job_id

    def wait_finished(self, jobid):
        """
        Block until the job given by the jobid finishes.
        :param jobid: The job id of the slurm job.
        :returns: None
        :rtype: `None`
        """
        job_info = self.find_id(jobid)
        while job_info[0]["job_state"] != "COMPLETED":
            p_time.sleep(5)
            job_info = self.find_id(jobid)


def slurm_pid2jobid(uint32_t JobPID=0):
    """Get the slurm job id from a process id.

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
    """Convert seconds to Slurm string format.

    This method converts time in seconds (86400) to Slurm's string format
    (1-00:00:00).

    :param int time: time in seconds
    :returns: time string
    :rtype: `str`
    """
    cdef:
        char *time_str
        double days, hours, minutes, seconds

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
            return "%ld-%2.2ld:%2.2ld:%2.2ld" % (days, hours,
                                                  minutes, seconds)
        else:
            return "%2.2ld:%2.2ld:%2.2ld" % (hours, minutes, seconds)


cdef mins2time_str(uint32_t time):
    """Convert minutes to Slurm string format.

    This method converts time in minutes (14400) to Slurm's string format
    (10-00:00:00).

    :param int time: time in minutes
    :returns: time string
    :rtype: `str`
    """
    cdef:
        double days, hours, minutes, seconds

    if time == slurm.INFINITE:
        return "UNLIMITED"
    else:
        seconds = 0
        minutes = time % 60
        hours = (time / 60) % 24
        days = time / 1440

        if days < 0 or  hours < 0 or minutes < 0 or seconds < 0:
            time_str = "INVALID"
        elif days:
            return "%ld-%2.2ld:%2.2ld:%2.2ld" % (days, hours,
                                                  minutes, seconds)
        else:
            return "%2.2ld:%2.2ld:%2.2ld" % (hours, minutes, seconds)


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
    """Return the slurm error as set by a slurm API call.

    :returns: slurm error number
    :rtype: `integer`
    """
    cdef int errNum = slurm.slurm_get_errno()

    return errNum


def slurm_strerror(int Errno=0):
    """Return slurm error message represented by a given slurm error number.

    :param int Errno: slurm error number.
    :returns: slurm error string
    :rtype: `string`
    """
    cdef char* errMsg = slurm.slurm_strerror(Errno)

    return "%s" % errMsg


def slurm_seterrno(int Errno=0):
    """Set the slurm error number.

    :param int Errno: slurm error number
    """
    slurm.slurm_seterrno(Errno)


def slurm_perror(char* Msg=''):
    """Print to standard error the supplied header.

    Header is followed by a colon, followed by a text description of the last
    Slurm error code generated.

    :param string Msg: slurm program error String
    """
    slurm.slurm_perror(Msg)


#
#
# Slurm Node Read/Print/Update Class
#


cdef class node:
    """Class to access/modify/update Slurm Node Information."""

    cdef:
        slurm.node_info_msg_t *_Node_ptr
        slurm.partition_info_msg_t *_Part_ptr
        uint16_t _ShowFlags
        dict _NodeDict
        slurm.time_t _lastUpdate

    def __cinit__(self):
        self._Node_ptr = NULL
        self._Part_ptr = NULL
        self._ShowFlags = slurm.SHOW_ALL | slurm.SHOW_DETAIL
        self._lastUpdate = 0

    def __dealloc__(self):
        pass

    def lastUpdate(self):
        """Return last time (epoch seconds) the node data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    cpdef ids(self):
        """Return the node IDs from retrieved data.

        :returns: Dictionary of node IDs
        :rtype: `dict`
        """
        cdef:
            int rc
            int apiError
            uint32_t i
            list all_nodes

        rc = slurm.slurm_load_node(<time_t> NULL, &self._Node_ptr, self._ShowFlags)

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
        """Get node information for a given node.

        :param str nodeID: Node key string to search
        :returns: Dictionary of values for given node
        :rtype: `dict`
        """
        return list(self.get_node(nodeID).values())[0]

    def get(self):
        """Get all slurm node information.

        :returns: Dictionary of dictionaries whose key is the node name.
        :rtype: `dict`
        """
        return self.get_node(None)

    def parse_gres(self, gres_str):
        if gres_str:
            return re.split(r',(?![^(]*\))', gres_str)

    def get_node(self, nodeID):
        """Get single slurm node information.

        :param str nodeID: Node key string to search. Default NULL.
        :returns: Dictionary of give node info data.
        :rtype: `dict`
        """
        cdef:
            int rc
            int rc_part
            int apiError
            int total_used
            char *cloud_str
            char *comp_str
            char *drain_str
            char *power_str
            uint16_t err_cpus
            uint16_t alloc_cpus
            uint32_t i
            uint32_t j
            uint64_t alloc_mem
            uint32_t node_state
            slurm.node_info_t *record
            dict Host_dict
            char time_str[32]
            char tmp_str[128]
            int last_inx = 0
            slurm.slurm_conf_t *slurm_ctl_conf_ptr = NULL

        rc = slurm.slurm_load_node(<time_t>NULL, &self._Node_ptr, self._ShowFlags)

        if rc != slurm.SLURM_SUCCESS:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)

        if slurm.slurm_load_ctl_conf(<time_t>NULL, &slurm_ctl_conf_ptr) != slurm.SLURM_SUCCESS:
            raise ValueError("Cannot load slurmctld conf file")

        rc_part = slurm.slurm_load_partitions(<time_t>NULL, &self._Part_ptr, slurm.SHOW_ALL)

        if rc_part != slurm.SLURM_SUCCESS:
            self._Part_ptr = NULL
            slurm.slurm_perror("slurm_load_partitions error")

        slurm.slurm_populate_node_partitions(self._Node_ptr, self._Part_ptr)

        self._lastUpdate = self._Node_ptr.last_update
        self._NodeDict = {}

        for j in range(self._Node_ptr.record_count):
            if nodeID:
                i = (j + last_inx) % self._Node_ptr.record_count
                if self._Node_ptr.node_array[i].name == NULL or (
                    nodeID.encode("UTF-8") != self._Node_ptr.node_array[i].name):
                    continue
            elif self._Node_ptr.node_array[j].name == NULL:
                continue
            else:
                i = j

            record = &self._Node_ptr.node_array[i]

            Host_dict = {}
            cloud_str = ""
            comp_str = ""
            drain_str = ""
            power_str = ""
            err_cpus = 0
            alloc_cpus = 0

            if record.name is NULL:
                continue

            total_used = record.cpus

            Host_dict['arch'] = slurm.stringOrNone(record.arch, '')
            Host_dict['boards'] = record.boards
            Host_dict['boot_time'] = record.boot_time
            Host_dict['cores'] = record.cores
            Host_dict['core_spec_cnt'] = record.core_spec_cnt
            Host_dict['cores_per_socket'] = record.cores
            # TODO: cpu_alloc, cpu_tot
            Host_dict['cpus'] = record.cpus
            
            # FIXME
            #if record.cpu_bind:
            #    slurm.slurm_sprint_cpu_bind_type(tmp_str, record.cpu_bind)
            #    Host_dict['cpu_bind'] = slurm.stringOrNone(tmp_str, '')

            Host_dict['cpu_load'] = slurm.int32orNone(record.cpu_load)
            Host_dict['cpu_spec_list'] = slurm.listOrNone(record.cpu_spec_list, '')
            Host_dict['extra'] = slurm.stringOrNone(record.extra, '')
            Host_dict['features'] = slurm.listOrNone(record.features, '')
            Host_dict['features_active'] = slurm.listOrNone(record.features_act, '')
            Host_dict['free_mem'] = slurm.int64orNone(record.free_mem)
            Host_dict['gres'] = slurm.listOrNone(record.gres, ',')
            Host_dict['gres_drain'] = slurm.listOrNone(record.gres_drain, '')
            Host_dict['gres_used'] = self.parse_gres(
                slurm.stringOrNone(record.gres_used, '')
            )
            Host_dict['last_busy'] = record.last_busy
            Host_dict['mcs_label'] = slurm.stringOrNone(record.mcs_label, '')
            Host_dict['mem_spec_limit'] = record.mem_spec_limit
            Host_dict['name'] = slurm.stringOrNone(record.name, '')

            # TODO: next_state
            Host_dict['node_addr'] = slurm.stringOrNone(record.node_addr, '')
            Host_dict['node_hostname'] = slurm.stringOrNone(record.node_hostname, '')
            Host_dict['os'] = slurm.stringOrNone(record.os, '')

            if record.owner == slurm.NO_VAL:
                Host_dict['owner'] = None
            else:
                Host_dict['owner'] = record.owner

            Host_dict['partitions'] = slurm.listOrNone(record.partitions, ',')
            Host_dict['real_memory'] = record.real_memory
            Host_dict['slurmd_start_time'] = record.slurmd_start_time
            Host_dict['sockets'] = record.sockets
            Host_dict['threads'] = record.threads
            Host_dict['tmp_disk'] = record.tmp_disk
            Host_dict['weight'] = record.weight
            Host_dict['tres_fmt_str'] = slurm.stringOrNone(record.tres_fmt_str, '')
            Host_dict['version'] = slurm.stringOrNone(record.version, '')

            Host_dict['reason'] = slurm.stringOrNone(record.reason, '')
            if record.reason_time == 0:
                Host_dict['reason_time'] = None
            else:
                Host_dict['reason_time'] = record.reason_time

            if record.reason_uid == slurm.NO_VAL:
                Host_dict['reason_uid'] = None
            else:
                Host_dict['reason_uid'] = record.reason_uid

            # Power Management
            Host_dict['power_mgmt'] = {}
            if (not record.power or (record.power.cap_watts == slurm.NO_VAL)):
                Host_dict['power_mgmt']["cap_watts"] = None
            else:
                Host_dict['power_mgmt']["cap_watts"] = record.power.cap_watts

            # Energy statistics
            Host_dict['energy'] = {}
            if (not record.energy or record.energy.current_watts == slurm.NO_VAL):
                Host_dict['energy']['current_watts'] = 0
                Host_dict['energy']['ave_watts'] = 0
            else:
                Host_dict['energy']['current_watts'] = record.energy.current_watts
                Host_dict['energy']['ave_watts'] = int(record.energy.ave_watts)

            Host_dict['energy']['previous_consumed_energy'] = int(record.energy.previous_consumed_energy)

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

            if (node_state & NODE_STATE_POWERED_DOWN):
                node_state &= (~NODE_STATE_POWERED_DOWN)
                power_str = "+POWER"

            if (node_state & NODE_STATE_POWERING_DOWN):
                node_state &= (~NODE_STATE_POWERING_DOWN)
                power_str = "+POWERING_DOWN"

            slurm.slurm_get_select_nodeinfo(record.select_nodeinfo,
                                            SELECT_NODEDATA_SUBCNT,
                                            NODE_STATE_ALLOCATED,
                                            &alloc_cpus)

            Host_dict['alloc_cpus'] = alloc_cpus
            total_used -= alloc_cpus

            slurm.slurm_get_select_nodeinfo(record.select_nodeinfo,
                                            SELECT_NODEDATA_SUBCNT,
                                            NODE_STATE_ERROR, &err_cpus)

            Host_dict['err_cpus'] = err_cpus
            total_used -= err_cpus

            if (alloc_cpus and err_cpus) or (total_used and
               (total_used != record.cpus)):
                node_state &= NODE_STATE_FLAGS
                node_state |= NODE_STATE_MIXED

            Host_dict['state'] = (
                slurm.stringOrNone(slurm.slurm_node_state_string(node_state), '') +
                slurm.stringOrNone(cloud_str, '') +
                slurm.stringOrNone(comp_str, '') +
                slurm.stringOrNone(drain_str, '') +
                slurm.stringOrNone(power_str, '')
            )

            slurm.slurm_get_select_nodeinfo(record.select_nodeinfo,
                                            SELECT_NODEDATA_MEM_ALLOC,
                                            NODE_STATE_ALLOCATED, &alloc_mem)

            Host_dict['alloc_mem'] = alloc_mem

            b_name = slurm.stringOrNone(record.name, '')
            self._NodeDict[b_name] = Host_dict

            if nodeID:
                last_inx = i
                break

        slurm.slurm_free_node_info_msg(self._Node_ptr)
        slurm.slurm_free_partition_info_msg(self._Part_ptr)
        slurm.slurm_free_ctl_conf(slurm_ctl_conf_ptr)
        self._Node_ptr = NULL
        self._Part_ptr = NULL
        return self._NodeDict


    cpdef update(self, dict node_dict):
        """Update slurm node information.

        :param dict node_dict: A populated node dictionary, an empty one is
            created by create_node_dict
        :returns: 0 for success or -1 for error, and the slurm error code
            is set appropriately.
        :rtype: `integer`
        """
        return slurm_update_node(node_dict)

    cpdef print_node_info_msg(self, int oneLiner=False):
        """Output information about all slurm nodes.

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
    """Update slurm node information.

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
    """Return a an update_node dictionary

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
    """Class to access/modify Slurm Jobstep Information."""

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
        """Free the slurm job memory allocated by load jobstep method."""
        self._lastUpdate = 0
        self._ShowFlags = 0
        self._JobStepDict = {}

    def lastUpdate(self):
        """Get the time (epoch seconds) the jobstep data was updated.

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
            if self._JobStepDict[key]['name'] == value:
                retDict.append(key)

        return retDict

    cpdef get(self):
        """Get slurm jobstep information.

        :returns: Data whose key is the jobstep ID.
        :rtype: `dict`
        """
        self.__get()

        return self._JobStepDict

    cpdef __get(self):
        """Load details about job steps.

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
            size_t i = 0
            int errCode = slurm.slurm_get_job_steps(
                last_time, self.JobID, self.StepID, &job_step_info_ptr, ShowFlags
            )

        if errCode != 0:
            self._JobStepDict = {}
            return

        if job_step_info_ptr is not NULL:

            for i in range(job_step_info_ptr.job_step_count):

                #HVB
                job_id = job_step_info_ptr.job_steps[i].step_id.job_id
                step_id = job_step_info_ptr.job_steps[i].step_id.step_id

                Steps[job_id] = {}
                Step_dict = {}

                if job_step_info_ptr.job_steps[i].array_job_id:
                    Step_dict['array_job_id'] = job_step_info_ptr.job_steps[i].array_job_id
                    Step_dict['array_task_id'] = job_step_info_ptr.job_steps[i].array_task_id

                    if step_id == SLURM_PENDING_STEP:
                       Step_dict['step_id_str'] = "{0}_{1}.TBD".format(Step_dict['array_job_id'], Step_dict['array_task_id'])
                    elif step_id == SLURM_EXTERN_CONT:
                       Step_dict['step_id_str'] = "{0}_{1}.extern".format(Step_dict['array_job_id'], Step_dict['array_task_id'])
                    else:
                       Step_dict['step_id_str'] = "{0}_{1}.{2}".format(Step_dict['array_job_id'], Step_dict['array_task_id'], step_id)
                else:
                    if step_id == SLURM_PENDING_STEP:
                       Step_dict['step_id_str'] =  "{0}.TBD".format(job_id)
                    elif step_id == SLURM_EXTERN_CONT:
                       Step_dict['step_id_str'] =  "{0}.extern".format(job_id)
                    else:
                       Step_dict['step_id_str'] =  "{0}.{1}".format(job_id, step_id)

                Step_dict['cluster'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].cluster, '')
                Step_dict['container'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].container, '')
                Step_dict['cpus_per_tres'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].cpus_per_tres, '')

                Step_dict['dist'] = slurm.stringOrNone(
                    slurm.slurm_step_layout_type_name(
                        <slurm.task_dist_states_t>job_step_info_ptr.job_steps[i].task_dist
                    ), ''
                )

                Step_dict['mem_per_tres'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].mem_per_tres, '')
                Step_dict['name'] = slurm.stringOrNone( job_step_info_ptr.job_steps[i].name, '')
                Step_dict['network'] = slurm.stringOrNone( job_step_info_ptr.job_steps[i].network, '')
                Step_dict['nodes'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].nodes, '')
                Step_dict['num_cpus'] = job_step_info_ptr.job_steps[i].num_cpus
                Step_dict['num_tasks'] = job_step_info_ptr.job_steps[i].num_tasks
                Step_dict['partition'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].partition, '')
                Step_dict['resv_ports'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].resv_ports, '')
                Step_dict['run_time'] = job_step_info_ptr.job_steps[i].run_time
                Step_dict['srun_host'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].srun_host, '')
                Step_dict['srun_pid'] = job_step_info_ptr.job_steps[i].srun_pid
                Step_dict['start_time'] = job_step_info_ptr.job_steps[i].start_time

                job_state = slurm.slurm_job_state_string(job_step_info_ptr.job_steps[i].state)
                Step_dict['state'] = slurm.stringOrNone(job_state, '')
                Step_dict['submit_line'] = slurm.stringOrNone(job_step_info_ptr.job_steps[i].submit_line, '')

                if job_step_info_ptr.job_steps[i].time_limit == slurm.INFINITE:
                    Step_dict['time_limit'] = "UNLIMITED"
                    Step_dict['time_limit_str'] = "UNLIMITED"
                else:
                    Step_dict['time_limit'] = job_step_info_ptr.job_steps[i].time_limit
                    Step_dict['time_limit_str'] = secs2time_str(job_step_info_ptr.job_steps[i].time_limit)

                Step_dict['tres_alloc_str'] = slurm.stringOrNone(
                    job_step_info_ptr.job_steps[i].tres_alloc_str, ''
                )

                Step_dict['tres_bind'] = slurm.stringOrNone(
                    job_step_info_ptr.job_steps[i].tres_bind, ''
                )

                Step_dict['tres_freq'] = slurm.stringOrNone(
                    job_step_info_ptr.job_steps[i].tres_freq, ''
                )

                Step_dict['tres_per_step'] = slurm.stringOrNone(
                    job_step_info_ptr.job_steps[i].tres_per_step, ''
                )

                Step_dict['tres_per_node'] = slurm.stringOrNone(
                    job_step_info_ptr.job_steps[i].tres_per_node, ''
                )

                Step_dict['tres_per_socket'] = slurm.stringOrNone(
                    job_step_info_ptr.job_steps[i].tres_per_socket, ''
                )

                Step_dict['tres_per_task'] = slurm.stringOrNone(
                    job_step_info_ptr.job_steps[i].tres_per_task, ''
                )

                Step_dict['user_id'] = job_step_info_ptr.job_steps[i].user_id

                Steps[job_id][step_id] = Step_dict

            slurm.slurm_free_job_step_info_response_msg(job_step_info_ptr)

        self._JobStepDict = Steps

    cpdef layout(self, uint32_t JobID=0, uint32_t StepID=0):
        """Get the slurm job step layout from a given job and step id.

        :param int JobID: slurm job id (Default=0)
        :param int StepID: slurm step id (Default=0)
        :returns: List of job step layout.
        :rtype: `list`
        """
        cdef:
            slurm.slurm_step_id_t step_id
            slurm.slurm_step_layout_t *old_job_step_ptr = NULL
            int i = 0, j = 0, Node_cnt = 0

            dict Layout = {}
            list Nodes = [], Node_list = [], Tids_list = []

        self.step_id.job_id = JobID
        self.step_id.step_id = StepID
        self.step_id_step_het_comp = slurm.NO_VAL

        old_job_step_ptr = slurm.slurm_job_step_layout_get(&step_id)
        if old_job_step_ptr is not NULL:

            Node_cnt = old_job_step_ptr.node_cnt

            Layout['front_end'] = slurm.stringOrNone(old_job_step_ptr.front_end, '')
            Layout['node_cnt'] = Node_cnt
            Layout['node_list'] = slurm.stringOrNone(old_job_step_ptr.node_list, '')
            Layout['plane_size'] = old_job_step_ptr.plane_size
            Layout['task_cnt'] = old_job_step_ptr.task_cnt
            Layout['task_dist'] = old_job_step_ptr.task_dist
            Layout['task_dist'] = slurm.stringOrNone(
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

            Layout['tasks'] = Node_list

            slurm.slurm_job_step_layout_free(old_job_step_ptr)

        return Layout


#
# Hostlist Class
#


cdef class hostlist:
    """Wrapper class for Slurm hostlist functions."""

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
        """Get the list of hostnames composing the hostlist.

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
        """Set or create a slurm trigger.

        :param dict trigger_dict: A populated dictionary of trigger information
        :returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
        :rtype: `integer`
        """
        cdef:
            slurm.trigger_info_t trigger_set
            int errCode = -1

        slurm.slurm_init_trigger_msg(&trigger_set)

        if 'jobid' in trigger_dict:
            JobId = trigger_dict['jobid']
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
            if trigger_dict['node'] == '':
                trigger_set.res_id = '*'
            else:
                b_node = trigger_dict['node'].encode("UTF-8")
                trigger_set.res_id = b_node

        trigger_set.offset = 0x8000
        if 'offset' in trigger_dict:
            trigger_set.offset = trigger_set.offset + trigger_dict['offset']

        b_program = trigger_dict['program'].encode("UTF-8")
        trigger_set.program = b_program

        event = trigger_dict['event']
        if event == 'burst_buffer':
            trigger_set.trig_type = trigger_set.trig_type | TRIGGER_TYPE_BURST_BUFFER

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
        """Get the information on slurm triggers.

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
                Trigger_dict['flags'] = record.flags
                Trigger_dict['trig_id'] = trigger_id
                Trigger_dict['res_type'] = record.res_type
                Trigger_dict['res_id'] = slurm.stringOrNone(record.res_id, '')
                Trigger_dict['trig_type'] = record.trig_type
                Trigger_dict['offset'] = record.offset - 0x8000
                Trigger_dict['user_id'] = record.user_id
                Trigger_dict['program'] = slurm.stringOrNone(record.program, '')

                Triggers[trigger_id] = Trigger_dict

            slurm.slurm_free_trigger_msg(trigger_get)

        return Triggers

    def clear(self, TriggerID=0, UserID=slurm.NO_VAL, ID=0):
        """Clear or remove a slurm trigger.

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
    """Class to access/update/delete slurm reservation Information."""

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
        """Get the time (epoch seconds) the reservation data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    def ids(self):
        """Return a list of reservation IDs from retrieved data.

        :returns: Dictionary of reservation IDs
        :rtype: `dict`
        """
        return self._ResDict.keys()

    def find_id(self, resID):
        """Retrieve reservation ID data.

        :param str resID: Reservation key string to search
        :returns: Dictionary of values for given reservation key
        :rtype: `dict`
        """
        return self._ResDict.get(resID, {})

    def find(self, name='', val=''):
        """Search for property and associated value in reservation data.

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
        """Load slurm reservation information."""

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
        """Free slurm reservation pointer."""

        if self._Res_ptr is not NULL:
            slurm.slurm_free_reservation_info_msg(self._Res_ptr)

    def get(self):
        """Get slurm reservation information.

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
                Res_dict['accounts'] = slurm.listOrNone(record.accounts, ',')
                Res_dict['burst_buffer'] = slurm.listOrNone(record.burst_buffer, ',')
                Res_dict['core_cnt'] = record.core_cnt
                Res_dict['end_time'] = record.end_time
                Res_dict['features'] = slurm.stringOrNone(record.features, '')

                flags = slurm.slurm_reservation_flags_string(&record)
                Res_dict['flags'] = slurm.stringOrNone(flags, '')

                Res_dict['licenses'] = __get_licenses(record.licenses)
                Res_dict['node_cnt'] = record.node_cnt
                Res_dict['node_list'] = slurm.stringOrNone(record.node_list, '')
                Res_dict['partition'] = slurm.stringOrNone(record.partition, '')
                Res_dict['start_time'] = record.start_time
                Res_dict['tres_str'] = slurm.listOrNone(record.tres_str, ',')
                Res_dict['users'] = slurm.listOrNone(record.users, ',')

                Reservations[name] = Res_dict

        self._ResDict = Reservations

    def create(self, dict reservation_dict={}):
        """Create slurm reservation."""
        return slurm_create_reservation(reservation_dict)

    def delete(self, ResID):
        """Delete slurm reservation.

        :returns: 0 for success or a slurm error code
        :rtype: `integer`
        """
        return slurm_delete_reservation(ResID)

    def update(self, dict reservation_dict={}):
        """Update a slurm reservation attributes.

        :returns: 0 for success or -1 for error, and the slurm error code is set appropriately.
        :rtype: `integer`
        """
        return slurm_update_reservation(reservation_dict)

    def print_reservation_info_msg(self, int oneLiner=0):
        """Output information about all slurm reservations.

        :param int Flags: Print on one line - 0 (Default) or 1
        """
        if self._Res_ptr is not NULL:
            slurm.slurm_print_reservation_info_msg(slurm.stdout, self._Res_ptr, oneLiner)


#
# Reservation Helper Functions
#


def slurm_create_reservation(dict reservation_dict={}):
    """Create a slurm reservation.

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

    resv_msg.start_time = reservation_dict['start_time']

    if not (reservation_dict.get('duration') or reservation_dict.get('end_time')):
        raise ValueError("You must provide either duration or end_time.")

    if (reservation_dict.get('duration') and reservation_dict.get('end_time')):
        raise ValueError("You must provide either duration or end_time.")

    if reservation_dict.get('duration'):
        resv_msg.duration = reservation_dict['duration']

    if reservation_dict.get('end_time'):
        resv_msg.end_time = reservation_dict['end_time']

    if reservation_dict.get('node_cnt'):
        int_value = reservation_dict['node_cnt']
        resv_msg.node_cnt = <uint32_t*>xmalloc(sizeof(uint32_t) * 2)
        resv_msg.node_cnt[0] = int_value
        resv_msg.node_cnt[1] = 0

    if reservation_dict.get('core_cnt') and not reservation_dict.get('node_list'):
        uint32_value = reservation_dict['core_cnt'][0]
        resv_msg.core_cnt = <uint32_t*>xmalloc(sizeof(uint32_t))
        resv_msg.core_cnt[0] = uint32_value

    if reservation_dict.get('node_list'):
        b_node_list = reservation_dict['node_list'].encode("UTF-8", "replace")
        resv_msg.node_list = b_node_list
        if reservation_dict.get('core_cnt'):
            hl = hostlist()
            hl.create(b_node_list)
            if len(reservation_dict['core_cnt']) != hl.count():
                raise ValueError("core_cnt list must have the same # elements as the expanded hostlist")
            resv_msg.core_cnt = <uint32_t*>xmalloc(sizeof(uint32_t) * hl.count())
            int_value = 0
            for cores in reservation_dict['core_cnt']:
                uint32_value = cores
                resv_msg.core_cnt[int_value] = uint32_value
                int_value += 1

    if reservation_dict.get('users'):
        b_users = reservation_dict['users'].encode("UTF-8", "replace")
        resv_msg.users = b_users

    if reservation_dict.get('features'):
        b_features = reservation_dict['features'].encode("UTF-8", "replace")
        resv_msg.features = b_features

    if reservation_dict.get('accounts'):
        b_accounts = reservation_dict['accounts'].encode("UTF-8", "replace")
        resv_msg.accounts = b_accounts

    if reservation_dict.get('licenses'):
        b_licenses = reservation_dict['licenses'].encode("UTF-8")
        resv_msg.licenses = b_licenses

    if reservation_dict.get('flags'):
        int_value = reservation_dict['flags']
        resv_msg.flags = int_value

    if reservation_dict.get('partition'):
        b_name = reservation_dict['partition'].encode("UTF-8")
        resv_msg.partition = b_name

    if reservation_dict.get('name'):
        b_name = reservation_dict['name'].encode("UTF-8")
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
    """Update a slurm reservation.

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
    # Set reservation_dict['start_time'] = -1 to handle this case.
    if reservation_dict.get('start_time'):
        time_value = reservation_dict.get('start_time')
        if time_value != -1:
            resv_msg.start_time = time_value

    if reservation_dict.get('duration'):
        resv_msg.duration = reservation_dict.get('duration')

    if reservation_dict.get('name'):
        b_name = reservation_dict['name'].encode("UTF-8", "replace")
        resv_msg.name = b_name

    if reservation_dict.get('node_cnt'):
        int_value = reservation_dict['node_cnt']
        resv_msg.node_cnt = <uint32_t*>xmalloc(sizeof(uint32_t) * 2)
        resv_msg.node_cnt[0] = int_value
        resv_msg.node_cnt[1] = 0

    if reservation_dict.get('core_cnt') and not reservation_dict.get('node_list'):
        uint32_value = reservation_dict['core_cnt'][0]
        resv_msg.core_cnt = <uint32_t*>xmalloc(sizeof(uint32_t))
        resv_msg.core_cnt[0] = uint32_value

    if reservation_dict.get('node_list'):
        b_node_list = reservation_dict['node_list']
        resv_msg.node_list = b_node_list
        if reservation_dict.get('core_cnt'):
            hl = hostlist()
            hl.create(b_node_list)
            if len(reservation_dict['core_cnt']) != hl.count():
                raise ValueError("core_cnt list must have the same # elements as the expanded hostlist")
            resv_msg.core_cnt = <uint32_t*>xmalloc(sizeof(uint32_t) * hl.count())
            int_value = 0
            for cores in reservation_dict['core_cnt']:
                uint32_value = cores
                resv_msg.core_cnt[int_value] = uint32_value
                int_value += 1

    if reservation_dict.get('users'):
        b_users = reservation_dict['users'].encode("UTF-8", "replace")
        resv_msg.users = b_users

    if reservation_dict.get('features'):
        b_features = reservation_dict['features'].encode("UTF-8", "replace")
        resv_msg.features = b_features

    if reservation_dict.get('accounts'):
        b_accounts = reservation_dict['accounts'].encode("UTF-8", "replace")
        resv_msg.accounts = b_accounts

    if reservation_dict.get('licenses'):
        b_licenses = reservation_dict['licenses'].encode("UTF-8")
        resv_msg.licenses = b_licenses

    if reservation_dict.get('partition'):
        b_name = reservation_dict['partition'].encode("UTF-8")
        resv_msg.partition = b_name

    if reservation_dict.get('flags'):
        int_value = reservation_dict['flags']
        resv_msg.flags = int_value

    errCode = slurm.slurm_update_reservation(&resv_msg)

    return errCode


def slurm_delete_reservation(ResID):
    """Delete a slurm reservation.

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
    """Create and empty dict for use with create_reservation method.

    Returns a dictionary that can be populated by the user an used for
    the update_reservation and create_reservation calls.

    :returns: Empty Reservation dictionary
    :rtype: `dict`
    """
    return {
        'start_time': 0,
        'end_time': 0,
        'duration': None,
        'node_cnt': 0,
        'name': None,
        'node_list': None,
        'features': None,
        'flags': None,
        'partition': None,
        'licenses': None,
        'users': None,
        'accounts': None
    }


#
# Topology Class
#


cdef class topology:
    """Class to access/update slurm topology information."""

    cdef:
        slurm.topo_info_response_msg_t *_topo_info_ptr
        dict _TopoDict

    def __cinit__(self):
        self._topo_info_ptr = NULL
        self._TopoDict = {}

    def __dealloc__(self):
        self.__free()

    def lastUpdate(self):
        """Get the time (epoch seconds) the retrieved data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    cpdef __free(self):
        """Free the memory returned by load method."""
        if self._topo_info_ptr is not NULL:
            slurm.slurm_free_topo_info_msg(self._topo_info_ptr)

    def load(self):
        """Load slurm topology information."""
        self.__load()

    cpdef int __load(self) except? -1:
        """Load slurm topology."""
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
        """Get slurm topology information.

        :returns: Dictionary whose key is the Topology ID
        :rtype: `dict`
        """
        self.__load()
        self.__get()

        return self._TopoDict

    cpdef __get(self):
        cdef:
            size_t i = 0
            dict Topo = {}, Topo_dict

        if self._topo_info_ptr is not NULL:

            for i in range(self._topo_info_ptr.record_count):

                Topo_dict = {}

                name = slurm.stringOrNone(self._topo_info_ptr.topo_array[i].name, '')
                Topo_dict['name'] = name
                Topo_dict['nodes'] = slurm.stringOrNone(self._topo_info_ptr.topo_array[i].nodes, '')
                Topo_dict['level'] = self._topo_info_ptr.topo_array[i].level
                Topo_dict['link_speed'] = self._topo_info_ptr.topo_array[i].link_speed
                Topo_dict['switches'] = slurm.stringOrNone(self._topo_info_ptr.topo_array[i].switches, '')

                Topo[name] = Topo_dict

        self._TopoDict = Topo

    def display(self):
        """Display topology information to standard output."""
        self._print_topo_info_msg()

    cpdef _print_topo_info_msg(self):
        """Output information about topology based upon message as loaded using slurm_load_topo.

        :param int Flags: Print on one line - False (Default), True
        """

        if self._topo_info_ptr is not NULL:
            slurm.slurm_print_topo_info_msg(slurm.stdout,
                                            self._topo_info_ptr,
                                            self._ShowFlags)


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
        """Get slurm statistics information.

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
            self._StatsDict['parts_packed'] = self._buf.parts_packed
            self._StatsDict['req_time'] = self._buf.req_time
            self._StatsDict['req_time_start'] = self._buf.req_time_start
            self._StatsDict['server_thread_count'] = self._buf.server_thread_count
            self._StatsDict['agent_queue_size'] = self._buf.agent_queue_size

            self._StatsDict['schedule_cycle_max'] = self._buf.schedule_cycle_max
            self._StatsDict['schedule_cycle_last'] = self._buf.schedule_cycle_last
            self._StatsDict['schedule_cycle_sum'] = self._buf.schedule_cycle_sum
            self._StatsDict['schedule_cycle_counter'] = self._buf.schedule_cycle_counter
            self._StatsDict['schedule_cycle_depth'] = self._buf.schedule_cycle_depth
            self._StatsDict['schedule_queue_len'] = self._buf.schedule_queue_len

            self._StatsDict['jobs_submitted'] = self._buf.jobs_submitted
            self._StatsDict['jobs_started'] = self._buf.jobs_started
            self._StatsDict['jobs_completed'] = self._buf.jobs_completed
            self._StatsDict['jobs_canceled'] = self._buf.jobs_canceled
            self._StatsDict['jobs_failed'] = self._buf.jobs_failed

            self._StatsDict['jobs_pending'] = self._buf.jobs_pending
            self._StatsDict['jobs_running'] = self._buf.jobs_running
            self._StatsDict['job_states_ts'] = self._buf.job_states_ts

            self._StatsDict['bf_backfilled_jobs'] = self._buf.bf_backfilled_jobs
            self._StatsDict['bf_last_backfilled_jobs'] = self._buf.bf_last_backfilled_jobs
            self._StatsDict['bf_cycle_counter'] = self._buf.bf_cycle_counter
            self._StatsDict['bf_cycle_sum'] = self._buf.bf_cycle_sum
            self._StatsDict['bf_cycle_last'] = self._buf.bf_cycle_last
            self._StatsDict['bf_cycle_max'] = self._buf.bf_cycle_max
            self._StatsDict['bf_last_depth'] = self._buf.bf_last_depth
            self._StatsDict['bf_last_depth_try'] = self._buf.bf_last_depth_try
            self._StatsDict['bf_depth_sum'] = self._buf.bf_depth_sum
            self._StatsDict['bf_depth_try_sum'] = self._buf.bf_depth_try_sum
            self._StatsDict['bf_queue_len'] = self._buf.bf_queue_len
            self._StatsDict['bf_queue_len_sum'] = self._buf.bf_queue_len_sum
            self._StatsDict['bf_when_last_cycle'] = self._buf.bf_when_last_cycle
            self._StatsDict['bf_active'] = self._buf.bf_active

            rpc_type_stats = {}

            for i in range(self._buf.rpc_type_size):
                rpc_type = self.__rpc_num2string(self._buf.rpc_type_id[i])
                rpc_type_stats[rpc_type] = {}
                rpc_type_stats[rpc_type]['id'] = self._buf.rpc_type_id[i]
                rpc_type_stats[rpc_type]['count'] = self._buf.rpc_type_cnt[i]
                if self._buf.rpc_type_cnt[i] == 0:
                    rpc_type_stats[rpc_type]['ave_time'] = 0
                else:
                    rpc_type_stats[rpc_type]['ave_time'] = int(self._buf.rpc_type_time[i] /
                                                                self._buf.rpc_type_cnt[i])
                rpc_type_stats[rpc_type]['total_time'] = int(self._buf.rpc_type_time[i])
            self._StatsDict['rpc_type_stats'] = rpc_type_stats

            rpc_user_stats = {}

            for i in range(self._buf.rpc_user_size):
                try:
                    rpc_user = getpwuid(self._buf.rpc_user_id[i])[0]
                except KeyError:
                    rpc_user = str(self._buf.rpc_user_id[i])
                rpc_user_stats[rpc_user] = {}
                rpc_user_stats[rpc_user]["id"] = self._buf.rpc_user_id[i]
                rpc_user_stats[rpc_user]["count"] = self._buf.rpc_user_cnt[i]
                if self._buf.rpc_user_cnt[i] == 0:
                    rpc_user_stats[rpc_user]["ave_time"] = 0
                else:
                    rpc_user_stats[rpc_user]["ave_time"] = int(self._buf.rpc_user_time[i] /
                                                                self._buf.rpc_user_cnt[i])
                rpc_user_stats[rpc_user]["total_time"] = int(self._buf.rpc_user_time[i])
            self._StatsDict['rpc_user_stats'] = rpc_user_stats

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
            1023: "REQUEST_SET_FS_DAMPENING_FACTOR",

            1400: "DBD_MESSAGES_START",
            1433: "PERSIST_RC",
            2000: "DBD_MESSAGES_END",

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
            2049: "REQUEST_FED_INFO",
            2050: "RESPONSE_FED_INFO",
            2051: "REQUEST_BATCH_SCRIPT",
            2052: "RESPONSE_BATCH_SCRIPT",
            2053: "REQUEST_CONTROL_STATUS",
            2054: "RESPONSE_CONTROL_STATUS",
            2055: "REQUEST_BURST_BUFFER_STATUS",
            2056: "RESPONSE_BURST_BUFFER_STATUS",

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
            4016: "DEFUNCT_REQUEST_JOB_ALLOCATION_INFO_LITE",
            4017: "DEFUNCT_RESPONSE_JOB_ALLOCATION_INFO_LITE",
            4018: "REQUEST_UPDATE_JOB_TIME",
            4019: "REQUEST_JOB_READY",
            4020: "RESPONSE_JOB_READY",
            4021: "REQUEST_JOB_END_TIME",
            4022: "REQUEST_JOB_NOTIFY",
            4023: "REQUEST_JOB_SBCAST_CRED",
            4024: "RESPONSE_JOB_SBCAST_CRED",
            4025: "REQUEST_JOB_PACK_ALLOCATION",
            4026: "RESPONSE_JOB_PACK_ALLOCATION",
            4027: "REQUEST_JOB_PACK_ALLOC_INFO",
            4028: "REQUEST_SUBMIT_BATCH_JOB_PACK",

            4500: "REQUEST_CTLD_MULT_MSG",
            4501: "RESPONSE_CTLD_MULT_MSG",
            4502: "REQUEST_SIB_MSG",
            4503: "REQUEST_SIB_JOB_LOCK",
            4504: "REQUEST_SIB_JOB_UNLOCK",

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
            6010: "DEFUNCT_REQUEST_SIGNAL_JOB",
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
            8003: "RESPONSE_SLURM_REROUTE_MSG",

            9001: "RESPONSE_FORWARD_FAILED",

            10001: "ACCOUNTING_UPDATE_MSG",
            10002: "ACCOUNTING_FIRST_REG",
            10003: "ACCOUNTING_REGISTER_CTLD",
            10004: "ACCOUNTING_TRES_CHANGE_DB",
            10005: "ACCOUNTING_NODES_CHANGE_DB",

            11001: "MESSAGE_COMPOSITE",
            11002: "RESPONSE_MESSAGE_COMPOSITE"}

        return num2string[opcode]


#
# Front End Node Class
#


cdef class front_end:
    """Class to access/update slurm front end node information."""

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
        """Free the memory allocated by load front end node method."""
        if self._FrontEndNode_ptr is not NULL:
            slurm.slurm_free_front_end_info_msg(self._FrontEndNode_ptr)

    def load(self):
        """Load slurm front end node information."""
        self.__load()

    cdef int __load(self) except? -1:
        """Load slurm front end node."""
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
        """Return last time (sepoch seconds) the node data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    def ids(self):
        """Return the node IDs from retrieved data.

        :returns: Dictionary of node IDs
        :rtype: `dict`
        """
        return list(self._FrontEndDict.keys())

    def get(self):
        """Get front end node information.

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

                FE_dict['boot_time'] = record.boot_time
                FE_dict['allow_groups'] = slurm.stringOrNone(record.allow_groups, '')
                FE_dict['allow_users'] = slurm.stringOrNone(record.allow_users, '')
                FE_dict['deny_groups'] = slurm.stringOrNone(record.deny_groups, '')
                FE_dict['deny_users'] = slurm.stringOrNone(record.deny_users, '')

                fe_node_state = get_node_state(record.node_state)
                FE_dict['node_state'] = slurm.stringOrNone(fe_node_state, '')

                FE_dict['reason'] = slurm.stringOrNone(record.reason, '')
                FE_dict['reason_time'] = record.reason_time
                FE_dict['reason_uid'] = record.reason_uid
                FE_dict['slurmd_start_time'] = record.slurmd_start_time
                FE_dict['version'] = slurm.stringOrNone(record.version, '')

                FENode[name] = FE_dict

        self._FrontEndDict = FENode


#
# QOS Class
#


cdef class qos:
    """Class to access/update slurm QOS information."""

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
        """QOS Destructor method."""
        self._QOSDict = {}

    def load(self):
        """Load slurm QOS information."""

        self.__load()

    cdef int __load(self) except? -1:
        """Load slurm QOS list."""
        cdef:
            slurm.slurmdb_qos_cond_t *new_qos_cond = NULL
            int apiError = 0
            void* dbconn = slurm.slurmdb_connection_get(NULL)
            slurm.List QOSList = slurm.slurmdb_qos_get(dbconn, new_qos_cond)

        if QOSList is NULL:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.stringOrNone(slurm.slurm_strerror(apiError), ''), apiError)
        else:
            self._QOSList = QOSList

        slurm.slurmdb_connection_close(&dbconn)
        return 0

    def lastUpdate(self):
        """Return last time (sepoch seconds) the QOS data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    def ids(self):
        """Return the QOS IDs from retrieved data.

        :returns: Dictionary of QOS IDs
        :rtype: `dict`
        """
        return self._QOSDict.keys()

    def get(self):
        """Get slurm QOS information.

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
                    QOS_info['description'] = slurm.stringOrNone(qos.description, '')
                    QOS_info['flags'] = qos.flags
                    QOS_info['grace_time'] = qos.grace_time
                    QOS_info['grp_jobs'] = qos.grp_jobs
                    QOS_info['grp_submit_jobs'] = qos.grp_submit_jobs
                    QOS_info['grp_tres'] = slurm.stringOrNone(qos.grp_tres, '')
                    # QOS_info['grp_tres_ctld']
                    QOS_info['grp_tres_mins'] = slurm.stringOrNone(qos.grp_tres_mins, '')
                    # QOS_info['grp_tres_mins_ctld']
                    QOS_info['grp_tres_run_mins'] = slurm.stringOrNone(qos.grp_tres_run_mins, '')
                    # QOS_info['grp_tres_run_mins_ctld']
                    QOS_info['grp_wall'] = qos.grp_wall
                    QOS_info['max_jobs_p'] = qos.max_jobs_pu
                    QOS_info['max_submit_jobs_p'] = qos.max_submit_jobs_pu
                    QOS_info['max_tres_mins_pj'] = slurm.stringOrNone(qos.max_tres_mins_pj, '')
                    # QOS_info['max_tres_min_pj_ctld']
                    QOS_info['max_tres_pj'] = slurm.stringOrNone(qos.max_tres_pj, '')
                    # QOS_info['max_tres_min_pj_ctld']
                    QOS_info['max_tres_pn'] = slurm.stringOrNone(qos.max_tres_pn, '')
                    # QOS_info['max_tres_min_pn_ctld']
                    QOS_info['max_tres_p'] = slurm.stringOrNone(qos.max_tres_pu, '')
                    # QOS_info['max_tres_min_pu_ctld']
                    QOS_info['max_tres_run_mins_p'] = slurm.stringOrNone(
                        qos.max_tres_run_mins_pu, '')

                    QOS_info['max_wall_pj'] = qos.max_wall_pj
                    QOS_info['min_tres_pj'] = slurm.stringOrNone(qos.min_tres_pj, '')
                    # QOS_info['min_tres_pj_ctld']
                    QOS_info['name'] = name
                    # QOS_info['*preempt_bitstr'] =
                    # QOS_info['preempt_list'] = qos.preempt_list

                    qos_preempt_mode = get_preempt_mode(qos.preempt_mode)
                    QOS_info['preempt_mode'] = slurm.stringOrNone(qos_preempt_mode, '')

                    QOS_info['priority'] = qos.priority
                    QOS_info['usage_factor'] = qos.usage_factor
                    QOS_info['usage_thres'] = qos.usage_thres

                    # NB - Need to add code to decode types of grp_tres_ctld (uint64t list) etc

                if name:
                    Q_dict[name] = QOS_info

            slurm.slurm_list_iterator_destroy(iters)
            slurm.slurm_list_destroy(self._QOSList)

        self._QOSDict = Q_dict

#
# slurmdbd jobs Class
#
cdef class slurmdb_jobs:
    """Class to access Slurmdbd Jobs information."""

    cdef:
        void* db_conn
        slurm.slurmdb_job_cond_t *job_cond

    def __cinit__(self):
        self.job_cond = <slurm.slurmdb_job_cond_t *>xmalloc(sizeof(slurm.slurmdb_job_cond_t))
        self.db_conn = slurm.slurmdb_connection_get(NULL)

    def __dealloc__(self):
        slurm.xfree(self.job_cond)
        slurm.slurmdb_connection_close(&self.db_conn)

    def get(self, jobids=[], userids=[], starttime=0, endtime=0, flags = None, db_flags = None, clusters = []):
        """Get Slurmdb information about some jobs.

        Input formats for start and end times:
        *   today or tomorrow
        *   midnight, noon, teatime (4PM)
        *   HH:MM [AM|PM]
        *   MMDDYY or MM/DD/YY or MM.DD.YY
        *   YYYY-MM-DD[THH[:MM[:SS]]]
        *   now + count [minutes | hours | days | weeks]
        *
        Invalid time input results in message to stderr and return value of
        zero.

        :param jobids: Ids of the jobs to search. Defaults to all jobs.
        :param starttime: Select jobs eligible after this timestamp
        :param endtime: Select jobs eligible before this timestamp
        :returns: Dictionary whose key is the JOBS ID
        :rtype: `dict`
        """
        cdef:
            int i = 0
            int listNum = 0
            int apiError = 0
            dict J_dict = {}
            slurm.List JOBSList
            slurm.ListIterator iters = NULL

       
        if clusters:
            self.job_cond.cluster_list = slurm.slurm_list_create(NULL)
            for _cluster in clusters:
                _cluster = _cluster.encode("UTF-8")
                slurm.slurm_addto_char_list_with_case(self.job_cond.cluster_list, _cluster, False)

        if db_flags:
            if isinstance(db_flags, int):
                self.job_cond.db_flags = db_flags
        else:
            self.job_cond.db_flags = slurm.SLURMDB_JOB_FLAG_NOTSET

        if flags:
            if isinstance(flags, int):
                self.job_cond.flags = flags

        if jobids:
            self.job_cond.step_list = slurm.slurm_list_create(NULL)
            for _jobid in jobids:
                if isinstance(_jobid, int) or isinstance(_jobid, long):
                    _jobid = str(_jobid).encode("UTF-8")
                else:
                    _jobid = _jobid.encode("UTF-8")
                slurm.slurm_addto_step_list(self.job_cond.step_list, _jobid)

        if userids:
            self.job_cond.userid_list = slurm.slurm_list_create(NULL)
            for _userid in userids:
                if isinstance(_userid, int) or isinstance(_userid, long):
                    _userid = str(_userid).encode("UTF-8")
                else:
                    _userid = _userid.encode("UTF-8")
                slurm.slurm_addto_char_list_with_case(self.job_cond.userid_list, _userid, False)

        if starttime:
            self.job_cond.usage_start = slurm.slurm_parse_time(starttime, 1)
            errno = slurm.slurm_get_errno()
            if errno == slurm.ESLURM_INVALID_TIME_VALUE:
                raise ValueError(slurm.slurm_strerror(errno), errno)

        if endtime:
            self.job_cond.usage_end = slurm.slurm_parse_time(endtime, 1)
            errno = slurm.slurm_get_errno()
            if errno == slurm.ESLURM_INVALID_TIME_VALUE:
                raise ValueError(slurm.slurm_strerror(errno), errno)

        JOBSList = slurm.slurmdb_jobs_get(self.db_conn, self.job_cond)

        if JOBSList is NULL:
            apiError = slurm.slurm_get_errno()
            raise ValueError(slurm.slurm_strerror(apiError), apiError)

        listNum = slurm.slurm_list_count(JOBSList)
        iters = slurm.slurm_list_iterator_create(JOBSList)

        for i in range(listNum):
            job = <slurm.slurmdb_job_rec_t *>slurm.slurm_list_next(iters)

            JOBS_info = {}
            if job is not NULL:
                jobid = job.jobid
                JOBS_info['account'] = slurm.stringOrNone(job.account, '')
                JOBS_info['alloc_nodes'] = job.alloc_nodes
                JOBS_info['array_job_id'] = job.array_job_id
                JOBS_info['array_max_tasks'] = job.array_max_tasks
                JOBS_info['array_task_id'] = job.array_task_id
                JOBS_info['array_task_str'] = slurm.stringOrNone(job.array_task_str, '')
                JOBS_info['associd'] = job.associd
                JOBS_info['blockid'] = slurm.stringOrNone(job.blockid, '')
                JOBS_info['cluster'] = slurm.stringOrNone(job.cluster, '')
                JOBS_info['constraints'] = slurm.stringOrNone(job.constraints, '')
                JOBS_info['container'] = slurm.stringOrNone(job.container, '')
                JOBS_info['derived_ec'] = job.derived_ec
                JOBS_info['derived_es'] = slurm.stringOrNone(job.derived_es, '')
                JOBS_info['elapsed'] = job.elapsed
                JOBS_info['eligible'] = job.eligible
                JOBS_info['end'] = job.end
                JOBS_info['env'] = slurm.stringOrNone(job.env, '')
                JOBS_info['exitcode'] = job.exitcode
                JOBS_info['gid'] = job.gid
                JOBS_info['jobid'] = job.jobid
                JOBS_info['jobname'] = slurm.stringOrNone(job.jobname, '')
                JOBS_info['lft'] = job.lft
                JOBS_info['partition'] = slurm.stringOrNone(job.partition, '')
                JOBS_info['nodes'] = slurm.stringOrNone(job.nodes, '')
                JOBS_info['priority'] = job.priority
                JOBS_info['qosid'] = job.qosid
                JOBS_info['req_cpus'] = job.req_cpus

                if job.req_mem & slurm.MEM_PER_CPU:
                    JOBS_info['req_mem'] = job.req_mem & (~slurm.MEM_PER_CPU)
                    JOBS_info['req_mem_per_cp'] = True
                else:
                    JOBS_info['req_mem'] = job.req_mem
                    JOBS_info['req_mem_per_cp'] = False

                JOBS_info['requid'] = job.requid
                JOBS_info['resvid'] = job.resvid
                JOBS_info['resv_name'] = slurm.stringOrNone(job.resv_name,'')
                JOBS_info['script'] = slurm.stringOrNone(job.script,'')
                JOBS_info['show_full'] = job.show_full
                JOBS_info['start'] = job.start
                JOBS_info['state'] = job.state
                JOBS_info['state_str'] = slurm.stringOrNone(slurm.slurm_job_state_string(job.state), '')
                
                # TRES are reported as strings in the format `TRESID=value` where TRESID is one of:
                # TRES_CPU=1, TRES_MEM=2, TRES_ENERGY=3, TRES_NODE=4, TRES_BILLING=5, TRES_FS_DISK=6, TRES_VMEM=7, TRES_PAGES=8
                # Example: '1=0,2=745472,3=0,6=1949,7=7966720,8=0'
                JOBS_info['stats'] = {}
                stats = JOBS_info['stats']
                stats['act_cpufreq'] = job.stats.act_cpufreq
                stats['consumed_energy'] = job.stats.consumed_energy
                stats['tres_usage_in_max'] = slurm.stringOrNone(job.stats.tres_usage_in_max, '')
                stats['tres_usage_in_max_nodeid']  = slurm.stringOrNone(job.stats.tres_usage_in_max_nodeid, '')
                stats['tres_usage_in_max_taskid']  = slurm.stringOrNone(job.stats.tres_usage_in_max_taskid, '')
                stats['tres_usage_in_min'] = slurm.stringOrNone(job.stats.tres_usage_in_min, '')
                stats['tres_usage_in_min_nodeid']  = slurm.stringOrNone(job.stats.tres_usage_in_min_nodeid, '')
                stats['tres_usage_in_min_taskid']  = slurm.stringOrNone(job.stats.tres_usage_in_min_taskid, '')
                stats['tres_usage_in_tot'] = slurm.stringOrNone(job.stats.tres_usage_in_tot, '')
                stats['tres_usage_out_ave'] = slurm.stringOrNone(job.stats.tres_usage_out_ave, '')
                stats['tres_usage_out_max'] = slurm.stringOrNone(job.stats.tres_usage_out_max, '')
                stats['tres_usage_out_max_nodeid'] = slurm.stringOrNone(job.stats.tres_usage_out_max_nodeid, '')
                stats['tres_usage_out_max_taskid'] = slurm.stringOrNone(job.stats.tres_usage_out_max_taskid, '')
                stats['tres_usage_out_min'] = slurm.stringOrNone(job.stats.tres_usage_out_min, '')
                stats['tres_usage_out_min_nodeid'] = slurm.stringOrNone(job.stats.tres_usage_out_min_nodeid, '')
                stats['tres_usage_out_min_taskid'] = slurm.stringOrNone(job.stats.tres_usage_out_min_taskid, '')
                stats['tres_usage_out_tot'] = slurm.stringOrNone(job.stats.tres_usage_out_tot, '')

                # add job steps
                JOBS_info['steps'] = {}
                step_dict = JOBS_info['steps']

                stepsNum = slurm.slurm_list_count(job.steps)
                stepsIter = slurm.slurm_list_iterator_create(job.steps)
                for i in range(stepsNum):
                    step = <slurm.slurmdb_step_rec_t *>slurm.slurm_list_next(stepsIter)
                    step_info = {}
                    if step is not NULL:
                        step_id = step.step_id.step_id

                        step_info['container'] = slurm.stringOrNone(step.container, '')
                        step_info['elapsed'] = step.elapsed
                        step_info['end'] = step.end
                        step_info['exitcode'] = step.exitcode

                        # Don't add this unless you want to create an endless recursive structure 
                        # step_info['job_ptr'] = JOBS_Info # job's record

                        step_info['nnodes'] = step.nnodes
                        step_info['nodes'] = slurm.stringOrNone(step.nodes, '')
                        step_info['ntasks'] = step.ntasks
                        step_info['pid_str'] = slurm.stringOrNone(step.pid_str, '')
                        step_info['req_cpufreq_min'] = step.req_cpufreq_min
                        step_info['req_cpufreq_max'] = step.req_cpufreq_max
                        step_info['req_cpufreq_gov'] = step.req_cpufreq_gov
                        step_info['requid'] = step.requid
                        step_info['start'] = step.start
                        step_info['state'] = step.state
                        step_info['state_str'] = slurm.stringOrNone(slurm.slurm_job_state_string(step.state), '')

                        # TRES are reported as strings in the format `TRESID=value` where TRESID is one of:
                        # TRES_CPU=1, TRES_MEM=2, TRES_ENERGY=3, TRES_NODE=4, TRES_BILLING=5, TRES_FS_DISK=6, TRES_VMEM=7, TRES_PAGES=8
                        # Example: '1=0,2=745472,3=0,6=1949,7=7966720,8=0'
                        step_info['stats'] = {}
                        stats = step_info['stats']
                        stats['act_cpufreq'] = step.stats.act_cpufreq
                        stats['consumed_energy'] = step.stats.consumed_energy
                        stats['tres_usage_in_max'] = slurm.stringOrNone(step.stats.tres_usage_in_max, '')
                        stats['tres_usage_in_max_nodeid'] = slurm.stringOrNone(step.stats.tres_usage_in_max_nodeid, '')
                        stats['tres_usage_in_max_taskid'] = slurm.stringOrNone(step.stats.tres_usage_in_max_taskid, '')
                        stats['tres_usage_in_min'] = slurm.stringOrNone(step.stats.tres_usage_in_min, '')
                        stats['tres_usage_in_min_nodeid'] = slurm.stringOrNone(step.stats.tres_usage_in_min_nodeid, '')
                        stats['tres_usage_in_min_taskid'] = slurm.stringOrNone(step.stats.tres_usage_in_min_taskid, '')
                        stats['tres_usage_in_tot'] = slurm.stringOrNone(step.stats.tres_usage_in_tot, '')
                        stats['tres_usage_out_ave'] = slurm.stringOrNone(step.stats.tres_usage_out_ave, '')
                        stats['tres_usage_out_max'] = slurm.stringOrNone(step.stats.tres_usage_out_max, '')
                        stats['tres_usage_out_max_nodeid'] = slurm.stringOrNone(step.stats.tres_usage_out_max_nodeid, '')
                        stats['tres_usage_out_max_taskid'] = slurm.stringOrNone(step.stats.tres_usage_out_max_taskid, '')
                        stats['tres_usage_out_min'] = slurm.stringOrNone(step.stats.tres_usage_out_min, '')
                        stats['tres_usage_out_min_nodeid'] = slurm.stringOrNone(step.stats.tres_usage_out_min_nodeid, '')
                        stats['tres_usage_out_min_taskid'] = slurm.stringOrNone(step.stats.tres_usage_out_min_taskid, '')
                        stats['tres_usage_out_tot'] = slurm.stringOrNone(step.stats.tres_usage_out_tot, '')
                        step_info['stepid'] = step_id
                        step_info['stepname'] = slurm.stringOrNone(step.stepname, '')
                        step_info['submit_line'] = slurm.stringOrNone(step.submit_line, '')
                        step_info['suspended'] = step.suspended
                        step_info['sys_cpu_sec'] = step.sys_cpu_sec
                        step_info['sys_cpu_usec'] = step.sys_cpu_usec
                        step_info['task_dist'] = step.task_dist
                        step_info['tot_cpu_sec'] = step.tot_cpu_sec
                        step_info['tot_cpu_usec'] = step.tot_cpu_usec
                        step_info['tres_alloc_str'] = slurm.stringOrNone(step.tres_alloc_str, '')
                        step_info['user_cpu_sec'] = step.user_cpu_sec
                        step_info['user_cpu_usec'] = step.user_cpu_usec

                        step_dict[step_id] = step_info

                slurm.slurm_list_iterator_destroy(stepsIter)

                JOBS_info['submit'] = job.submit
                JOBS_info['submit_line'] = slurm.stringOrNone(job.submit_line,'')
                JOBS_info['suspended'] = job.suspended
                JOBS_info['sys_cpu_sec'] = job.sys_cpu_sec
                JOBS_info['sys_cpu_usec'] = job.sys_cpu_usec
                JOBS_info['timelimit'] = job.timelimit
                JOBS_info['tot_cpu_sec'] = job.tot_cpu_sec
                JOBS_info['tot_cpu_usec'] = job.tot_cpu_usec
                JOBS_info['track_steps'] = job.track_steps
                JOBS_info['tres_alloc_str'] = slurm.stringOrNone(job.tres_alloc_str,'')
                JOBS_info['tres_req_str'] = slurm.stringOrNone(job.tres_req_str,'')
                JOBS_info['uid'] = job.uid
                JOBS_info['used_gres'] = slurm.stringOrNone(job.used_gres, '')
                JOBS_info['user'] = slurm.stringOrNone(job.user,'')
                JOBS_info['user_cpu_sec'] = job.user_cpu_sec
                JOBS_info['user_cpu_usec'] = job.user_cpu_usec
                JOBS_info['wckey'] = slurm.stringOrNone(job.wckey, '')
                JOBS_info['wckeyid'] = job.wckeyid
                JOBS_info['work_dir'] = slurm.stringOrNone(job.work_dir, '')
                J_dict[jobid] = JOBS_info

        slurm.slurm_list_iterator_destroy(iters)
        slurm.slurm_list_destroy(JOBSList)
        if clusters:
            slurm.slurm_list_destroy(self.job_cond.cluster_list)
        if userids:
            slurm.slurm_list_destroy(self.job_cond.userid_list)
        return J_dict

#
# slurmdbd Reservations Class
#
cdef class slurmdb_reservations:
    """Class to access Slurmdbd reservations information."""

    cdef:
        void *dbconn
        slurm.slurmdb_reservation_cond_t *reservation_cond

    def __cinit__(self):
        self.reservation_cond = <slurm.slurmdb_reservation_cond_t *>xmalloc(sizeof(slurm.slurmdb_reservation_cond_t))

    def __dealloc__(self):
        slurm.slurmdb_destroy_reservation_cond(self.reservation_cond)

    def set_reservation_condition(self, start_time, end_time):
        """Limit the next get() call to reservations that start after and before a certain time.

        :param start_time: Select reservations that start after this timestamp
        :param end_time: Select reservations that end before this timestamp
        """
        if self.reservation_cond == NULL:
            self.reservation_cond = <slurm.slurmdb_reservation_cond_t *>xmalloc(sizeof(slurm.slurmdb_reservation_cond_t))

        if self.reservation_cond != NULL:
            self.reservation_cond.with_usage = 1
            self.reservation_cond.time_start = <slurm.time_t>start_time
            self.reservation_cond.time_end = <slurm.time_t>end_time
        else:
            raise MemoryError()

    def get(self):
        """Get slurm reservations information.

        :returns: Dictionary whose keys are the reservations ids
        :rtype: `dict`
        """
        cdef:
            slurm.List reservation_list
            slurm.ListIterator iters = NULL
            slurm.slurmdb_reservation_rec_t *reservation
            int i = 0
            int j = 0
            int listNum
            slurm.List _resvList

        Reservation_dict = {}
        reservation_list = slurm.slurmdb_reservations_get(self.dbconn, self.reservation_cond)

        if reservation_list is not NULL:
            listNum = slurm.slurm_list_count(reservation_list)
            iters = slurm.slurm_list_iterator_create(reservation_list)

            for i in range(listNum):
                reservation = <slurm.slurmdb_reservation_rec_t *>slurm.slurm_list_next(iters)
                Reservation_rec_dict = {}

                if reservation is not NULL:
                    reservation_id = reservation.id
                    Reservation_rec_dict['name'] = slurm.stringOrNone(reservation.name, '')
                    Reservation_rec_dict['nodes'] = slurm.stringOrNone(reservation.nodes, '')
                    Reservation_rec_dict['node_index'] = slurm.stringOrNone(reservation.node_inx, '')
                    Reservation_rec_dict['associations'] = slurm.stringOrNone(reservation.assocs, '')
                    Reservation_rec_dict['cluster'] = slurm.stringOrNone(reservation.cluster, '')
                    Reservation_rec_dict['tres_str'] = slurm.stringOrNone(reservation.tres_str, '')
                    Reservation_rec_dict['reservation_id'] = reservation.id
                    Reservation_rec_dict['time_start'] = reservation.time_start
                    Reservation_rec_dict['time_start_prev'] = reservation.time_start_prev
                    Reservation_rec_dict['time_end'] = reservation.time_end
                    Reservation_rec_dict['flags'] = reservation.flags

                    if reservation.tres_list != NULL:
                        num_tres = slurm.slurm_list_count(reservation.tres_list)
                        tres_iters = slurm.slurm_list_iterator_create(reservation.tres_list)
                        tres_dict = {}
                        Reservation_rec_dict['num_tres'] = num_tres

                        for j in range(num_tres):
                            tres = <slurm.slurmdb_tres_rec_t *>slurm.slurm_list_next(tres_iters)
                            if tres is not NULL:
                                tmp_tres_dict = {}
                                tres_id = tres.id
                                tmp_tres_dict['name'] = slurm.stringOrNone(tres.name,'')
                                tmp_tres_dict['type'] = slurm.stringOrNone(tres.type,'')
                                tmp_tres_dict['rec_count'] = tres.rec_count
                                tmp_tres_dict['count'] = tres.count
                                tmp_tres_dict['tres_id'] = tres.id
                                tmp_tres_dict['alloc_secs'] = tres.alloc_secs
                                tres_dict[tres_id] = tmp_tres_dict

                        Reservation_rec_dict['tres_list'] = tres_dict
                        slurm.slurm_list_iterator_destroy(tres_iters)

                    Reservation_dict[reservation_id] = Reservation_rec_dict

            slurm.slurm_list_iterator_destroy(iters)
            slurm.slurm_list_destroy(reservation_list)

        return Reservation_dict

#
# slurmdbd clusters Class
#
cdef class slurmdb_clusters:
    """Class to access Slurmdbd Clusters information."""

    cdef:
        void *db_conn
        slurm.slurmdb_cluster_cond_t *cluster_cond

    def __cinit__(self):
        self.cluster_cond = <slurm.slurmdb_cluster_cond_t *>xmalloc(sizeof(slurm.slurmdb_cluster_cond_t))
        slurm.slurmdb_init_cluster_cond(self.cluster_cond, 0)
        self.db_conn = slurm.slurmdb_connection_get(NULL)

    def __dealloc__(self):
        slurm.slurmdb_destroy_cluster_cond(self.cluster_cond)
        slurm.slurmdb_connection_close(&self.db_conn)

    def set_cluster_condition(self, start_time, end_time):
        """Limit the next get() call to clusters that existed after and before
        a certain time.

        :param start_time: Select clusters that existed after this timestamp
        :param end_time: Select clusters that existed before this timestamp
        """
        if self.cluster_cond == NULL:
            self.cluster_cond = <slurm.slurmdb_cluster_cond_t *>xmalloc(sizeof(slurm.slurmdb_cluster_cond_t))

        if self.cluster_cond != NULL:
            slurm.slurmdb_init_cluster_cond(self.cluster_cond, 0)
            self.cluster_cond.with_deleted = 1
            self.cluster_cond.with_usage = 1
            self.cluster_cond.usage_start = <slurm.time_t>start_time
            self.cluster_cond.usage_end = <slurm.time_t>end_time
        else:
            raise MemoryError()

    def get(self):
        """Get slurm clusters information.

        :returns: Dictionary whose keys are the clusters ids
        :rtype: `dict`
        """
        cdef:
            slurm.List clusters_list
            slurm.ListIterator iters = NULL
            slurm.slurmdb_cluster_rec_t *cluster = NULL
            int rc = slurm.SLURM_SUCCESS
            int i = 0
            int j = 0
            int listNum

        Cluster_dict = {}
        cluster_list = slurm.slurmdb_clusters_get(self.db_conn, self.cluster_cond)

        if cluster_list is not NULL:
            listNum = slurm.slurm_list_count(cluster_list)
            iters = slurm.slurm_list_iterator_create(cluster_list)

            for i in range(listNum):
                cluster = <slurm.slurmdb_cluster_rec_t *>slurm.slurm_list_next(iters)
                Cluster_rec_dict = {}

                if cluster is not NULL:
                    cluster_name = slurm.stringOrNone(cluster.name, '')
                    Cluster_rec_dict['name'] = cluster_name
                    Cluster_rec_dict['nodes'] = slurm.stringOrNone(cluster.nodes, '')
                    Cluster_rec_dict['control_host'] = slurm.stringOrNone(cluster.control_host, '')
                    Cluster_rec_dict['tres'] = slurm.stringOrNone(cluster.tres_str, '')
                    Cluster_rec_dict['control_port'] = cluster.control_port
                    Cluster_rec_dict['rpc_version'] = cluster.rpc_version
                    Cluster_rec_dict['plugin_id_select'] = cluster.plugin_id_select
                    Cluster_rec_dict['flags'] = cluster.flags
                    Cluster_rec_dict['dimensions'] = cluster.dimensions
                    Cluster_rec_dict['classification'] = cluster.classification

                    if cluster.accounting_list != NULL:
                        num_acct = slurm.slurm_list_count(cluster.accounting_list)
                        acct_iters = slurm.slurm_list_iterator_create(cluster.accounting_list)
                        acct_dict = {}
                        Cluster_rec_dict['num_acct'] = num_acct

                        for j in range(num_acct):
                            acct_tres = <slurm.slurmdb_cluster_accounting_rec_t *>slurm.slurm_list_next(acct_iters)
                            if acct_tres is not NULL:
                                acct_tres_dict = {}
                                acct_tres_rec = <slurm.slurmdb_tres_rec_t>acct_tres.tres_rec
                                acct_tres_id = acct_tres_rec.id

                                if (acct_tres_rec.name is not NULL):
                                    acct_tres_dict['name'] = slurm.stringOrNone(acct_tres_rec.name,'')
                                if (acct_tres_rec.type is not NULL):
                                    acct_tres_dict['type'] = slurm.stringOrNone(acct_tres_rec.type,'')

                                acct_tres_dict['rec_count'] = acct_tres_rec.rec_count
                                acct_tres_dict['count'] = acct_tres_rec.count
                                acct_tres_dict['alloc_secs'] = acct_tres.alloc_secs
                                acct_tres_dict['down_secs'] = acct_tres.down_secs
                                acct_tres_dict['idle_secs'] = acct_tres.idle_secs
                                acct_tres_dict['plan_secs'] = acct_tres.plan_secs
                                acct_tres_dict['pdown_secs'] = acct_tres.pdown_secs
                                acct_tres_dict['over_secs'] = acct_tres.over_secs
                                acct_tres_dict['period_start'] = acct_tres.period_start
                                acct_dict[acct_tres_id] = acct_tres_dict

                        Cluster_rec_dict['accounting'] = acct_dict
                        slurm.slurm_list_iterator_destroy(acct_iters)

                    Cluster_dict[cluster_name] = Cluster_rec_dict

            slurm.slurm_list_iterator_destroy(iters)
            slurm.slurm_list_destroy(cluster_list)

        return Cluster_dict

#
# slurmdbd Events Class
#
cdef class slurmdb_events:
    """Class to access Slurmdbd events information."""

    cdef:
        void *dbconn
        slurm.slurmdb_event_cond_t *event_cond

    def __cinit__(self):
        self.event_cond = <slurm.slurmdb_event_cond_t *>xmalloc(sizeof(slurm.slurmdb_event_cond_t))

    def __dealloc__(self):
        slurm.slurmdb_destroy_event_cond(self.event_cond)

    def set_event_condition(self, start_time, end_time):
        """Limit the next get() call to conditions that existed after and before a certain time.

        :param start_time: Select conditions that existed after this timestamp
        :param end_time: Select conditions that existed before this timestamp
        """
        if self.event_cond == NULL:
            self.event_cond = <slurm.slurmdb_event_cond_t *>xmalloc(sizeof(slurm.slurmdb_event_cond_t))

        if self.event_cond != NULL:
            ##self.event_cond.with_usage = 1
            self.event_cond.period_start = <slurm.time_t>start_time
            self.event_cond.period_end = <slurm.time_t>end_time
        else:
            raise MemoryError()

    def get(self):
        """Get slurm events information.

        :returns: Dictionary whose keys are the events ids
        :rtype: `dict`
        """
        cdef:
            slurm.List event_list
            slurm.ListIterator iters = NULL
            slurm.slurmdb_event_rec_t *event = NULL
            int i = 0
            int listNum = 0

        Event_dict = {}
        event_list = slurm.slurmdb_events_get(self.dbconn, self.event_cond)

        if event_list is not NULL:
            listNum = slurm.slurm_list_count(event_list)
            iters = slurm.slurm_list_iterator_create(event_list)

            for i in range(listNum):
                event = <slurm.slurmdb_event_rec_t *>slurm.slurm_list_next(iters)
                event_rec_dict = {}

                if event is not NULL:
                    event_id = event.period_start
                    event_rec_dict['cluster'] = slurm.stringOrNone(event.cluster, '')
                    event_rec_dict['cluster_nodes'] = slurm.stringOrNone(event.cluster_nodes, '')
                    event_rec_dict['node_name'] = slurm.stringOrNone(event.node_name, '')
                    event_rec_dict['reason'] = slurm.stringOrNone(event.reason, '')
                    event_rec_dict['tres_str'] = slurm.stringOrNone(event.tres_str, '')
                    event_rec_dict['event_type'] = event.event_type
                    event_rec_dict['time_start'] = event.period_start
                    event_rec_dict['time_end'] = event.period_end
                    event_rec_dict['tres_str'] = event.tres_str
                    event_rec_dict['state'] = event.state
                    event_rec_dict['reason_uid'] = event.reason_uid

                    Event_dict[event_id] = event_rec_dict

            slurm.slurm_list_iterator_destroy(iters)
            slurm.slurm_list_destroy(event_list)

        return Event_dict

#
# SlurmDB Reports (sreport)
#

cdef class slurmdb_reports:
    """Class to access Slurmdbd reports."""

    cdef:
        void *db_conn
        slurm.slurmdb_assoc_cond_t *assoc_cond

    def __cinit__(self):
        self.assoc_cond = <slurm.slurmdb_assoc_cond_t *>xmalloc(sizeof(slurm.slurmdb_assoc_cond_t))

    def __dealloc__(self):
        slurm.slurmdb_destroy_assoc_cond(self.assoc_cond)

    def report_cluster_account_by_user(self, starttime=None, endtime=None):
        """
        sreport cluster AccountUtilizationByUser
        """
        cdef:
            slurm.List slurmdb_report_cluster_list = NULL
            slurm.ListIterator itr = NULL
            slurm.ListIterator cluster_itr = NULL
            slurm.ListIterator tres_itr = NULL
            slurm.slurmdb_cluster_cond_t cluster_cond
            slurm.slurmdb_report_assoc_rec_t *slurmdb_report_assoc = NULL
            slurm.slurmdb_report_cluster_rec_t *slurmdb_report_cluster = NULL
            slurm.slurmdb_tres_rec_t *tres
            time_t start_time
            time_t end_time
            int i
            int j

        slurm.slurmdb_init_cluster_cond(&cluster_cond, 0)
        self.assoc_cond.with_sub_accts = 1

        if starttime:
            self.assoc_cond.usage_start = slurm.slurm_parse_time(starttime, 1)

        if endtime:
            self.assoc_cond.usage_end = slurm.slurm_parse_time(endtime, 1)

        start_time = self.assoc_cond.usage_start
        end_time = self.assoc_cond.usage_end
        slurm.slurmdb_report_set_start_end_time(&start_time, &end_time)
        self.assoc_cond.usage_start = start_time
        self.assoc_cond.usage_end = end_time

        self.assoc_cond.with_usage = 1
        self.assoc_cond.with_deleted = 1

        slurmdb_report_cluster_list = slurm.slurmdb_report_cluster_account_by_user(
            self.db_conn, self.assoc_cond
        )

        if slurmdb_report_cluster_list is NULL:
            slurm.slurmdb_destroy_assoc_cond(self.assoc_cond)
            slurm.slurm_list_destroy(slurmdb_report_cluster_list)
            slurmdb_report_cluster_list = NULL
            sys.exit(0)

        cluster_itr = slurm.slurm_list_iterator_create(slurmdb_report_cluster_list)
        Cluster_dict = {}

        for i in range(slurm.slurm_list_count(slurmdb_report_cluster_list)):
            slurmdb_report_cluster = <slurm.slurmdb_report_cluster_rec_t *>slurm.slurm_list_next(cluster_itr)
            cluster_name = slurm.stringOrNone(slurmdb_report_cluster.name, '')
            Cluster_dict[cluster_name] = {}
            itr = slurm.slurm_list_iterator_create(slurmdb_report_cluster.assoc_list)

            for j in range(slurm.slurm_list_count(slurmdb_report_cluster.assoc_list)):
                slurmdb_report_assoc = <slurm.slurmdb_report_assoc_rec_t *>slurm.slurm_list_next(itr)
                Assoc_dict = {}
                Assoc_dict["account"] = slurm.stringOrNone(slurmdb_report_assoc.acct, '')
                Assoc_dict["cluster"] = slurm.stringOrNone(slurmdb_report_assoc.cluster, '')
                Assoc_dict["parent_account"] = slurm.stringOrNone(slurmdb_report_assoc.parent_acct, '')
                Assoc_dict["user"] = slurm.stringOrNone(slurmdb_report_assoc.user, '')
                Assoc_dict["tres_list"] = []
                tres_itr = slurm.slurm_list_iterator_create(slurmdb_report_assoc.tres_list)

                for k in range(slurm.slurm_list_count(slurmdb_report_assoc.tres_list)):
                    tres = <slurm.slurmdb_tres_rec_t *>slurm.slurm_list_next(tres_itr)
                    Tres_dict = {}
                    Tres_dict["alloc_secs"] = <int>tres.alloc_secs
                    Tres_dict["rec_count"] = tres.rec_count
                    Tres_dict["count"] = <int>tres.count
                    Tres_dict["id"] = tres.id
                    Tres_dict["name"] = slurm.stringOrNone(tres.name, '')
                    Tres_dict["type"] = slurm.stringOrNone(tres.type, '')
                    Assoc_dict["tres_list"].append(Tres_dict)

                Cluster_dict[cluster_name] = Assoc_dict
                slurm.slurm_list_iterator_destroy(tres_itr)

            slurm.slurm_list_iterator_destroy(itr)

        slurm.slurm_list_iterator_destroy(cluster_itr)
        slurm.slurm_list_destroy(slurmdb_report_cluster_list)
        slurmdb_report_cluster_list = NULL

        return Cluster_dict

#
# Helper functions to convert numerical States
#


def get_last_slurm_error():
    """Get and return the last error from a slurm API call.

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
    """Returns a dict of licenses from the slurm license string.

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
            licDict["%s" % key] = value

    return licDict


def get_node_use(inx):
    """Returns a string that represents the block node mode.

    :param int ResType: Slurm block node usage
    :returns: Block node usage string
    :rtype: `string`
    """
    return slurm.slurm_node_state_string(inx)


def get_trigger_res_type(uint16_t inx):
    """Returns a string that represents the slurm trigger res type.

    :param int ResType: Slurm trigger res state
        - TRIGGER_RES_TYPE_JOB        1
        - TRIGGER_RES_TYPE_NODE       2
        - TRIGGER_RES_TYPE_SLURMCTLD  3
        - TRIGGER_RES_TYPE_SLURMDBD   4
        - TRIGGER_RES_TYPE_DATABASE   5
        - TRIGGER_RES_TYPE_FRONT_END  6
        - TRIGGER_RES_TYPE_OTHER      7
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
    elif ResType == TRIGGER_RES_TYPE_OTHER:
        rtype = 'other'

    return "%s" % rtype


def get_trigger_type(uint32_t inx):
    """Returns a string that represents the state of the slurm trigger.

    :param int TriggerType: Slurm trigger type
        - TRIGGER_TYPE_UP                 0x00000001
        - TRIGGER_TYPE_DOWN               0x00000002
        - TRIGGER_TYPE_FAIL               0x00000004
        - TRIGGER_TYPE_TIME               0x00000008
        - TRIGGER_TYPE_FINI               0x00000010
        - TRIGGER_TYPE_RECONFIG           0x00000020
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
        - TRIGGER_TYPE_BURST_BUFFER       0x00100000
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
    elif TriggerType == TRIGGER_TYPE_BURST_BUFFER:
        rtype = 'burst_buffer'

    return "%s" % rtype


#def get_res_state(uint16_t inx):
#    """Returns a string that represents the state of the slurm reservation.
#
#    :param int flags: Slurm reservation flags
#        - RESERVE_FLAG_MAINT            0x00000001
#        - RESERVE_FLAG_NO_MAINT         0x00000002
#        - RESERVE_FLAG_DAILY            0x00000004
#        - RESERVE_FLAG_NO_DAILY         0x00000008
#        - RESERVE_FLAG_WEEKLY           0x00000010
#        - RESERVE_FLAG_NO_WEEKLY        0x00000020
#        - RESERVE_FLAG_IGN_JOBS         0x00000040
#        - RESERVE_FLAG_NO_IGN_JOB       0x00000080
#        - RESERVE_FLAG_ANY_NODES        0x00000100
#        - RESERVE_FLAG_NO_ANY_NODES     0x00000200
#        - RESERVE_FLAG_STATIC           0x00000400
#        - RESERVE_FLAG_NO_STATIC        0x00000800
#        - RESERVE_FLAG_PART_NODES       0x00001000
#        - RESERVE_FLAG_NO_PART_NODES    0x00002000
#        - RESERVE_FLAG_OVERLAP          0x00004000
#        - RESERVE_FLAG_SPEC_NODES       0x00008000
#        - RESERVE_FLAG_FIRST_CORES      0x00010000
#        - RESERVE_FLAG_TIME_FLOAT       0x00020000
#        - RESERVE_FLAG_REPLACE          0x00040000
#    :returns: Reservation state string
#    :rtype: `string`
#    """
#    try:
#        return slurm.slurm_reservation_flags_string(inx)
#    except:
#        pass


def get_debug_flags(uint64_t inx):
    """ Returns a string that represents the slurm debug flags.

    :param int flags: Slurm debug flags
    :returns: Debug flag string
    :rtype: `string`
    """
    return debug_flags2str(inx)

cdef inline list debug_flags2str(uint64_t debug_flags):
    cdef list debugFlags = []

    if (debug_flags & DEBUG_FLAG_ACCRUE):
        debugFlags.append('Accrue')

    if (debug_flags & DEBUG_FLAG_AGENT):
        debugFlags.append('Agent')

    if (debug_flags & DEBUG_FLAG_BACKFILL):
        debugFlags.append('Backfill')

    if (debug_flags & DEBUG_FLAG_BACKFILL_MAP):
        debugFlags.append('BackfillMap')

    if (debug_flags & DEBUG_FLAG_BURST_BUF):
        debugFlags.append('BurstBuffer')

    if (debug_flags & DEBUG_FLAG_CGROUP):
        debugFlags.append('Cgroup')

    if (debug_flags & DEBUG_FLAG_CPU_FREQ):
        debugFlags.append('CpuFrequency')

    if (debug_flags & DEBUG_FLAG_CPU_BIND):
        debugFlags.append('CPU_Bind')

    if (debug_flags & DEBUG_FLAG_DB_ARCHIVE):
        debugFlags.append('DB_Archive')

    if (debug_flags & DEBUG_FLAG_DB_ASSOC):
        debugFlags.append('DB_Assoc')

    if (debug_flags & DEBUG_FLAG_DB_TRES):
        debugFlags.append('DB_TRES')

    if (debug_flags & DEBUG_FLAG_DB_JOB):
        debugFlags.append('DB_Job')

    if (debug_flags & DEBUG_FLAG_DB_QOS):
        debugFlags.append('DB_QOS')

    if (debug_flags & DEBUG_FLAG_DB_QUERY):
        debugFlags.append('DB_Query')

    if (debug_flags & DEBUG_FLAG_DB_RESV):
        debugFlags.append('DB_Reservation')

    if (debug_flags & DEBUG_FLAG_DB_RES):
        debugFlags.append('DB_Resource')

    if (debug_flags & DEBUG_FLAG_DB_STEP):
        debugFlags.append('DB_Step')

    if (debug_flags & DEBUG_FLAG_DB_USAGE):
        debugFlags.append('DB_Usage')

    if (debug_flags & DEBUG_FLAG_DB_WCKEY):
        debugFlags.append('DB_WCKey')

    if (debug_flags & DEBUG_FLAG_ESEARCH):
        debugFlags.append('Elasticsearch')

    if (debug_flags & DEBUG_FLAG_ENERGY):
        debugFlags.append('Energy')

    if (debug_flags & DEBUG_FLAG_EXT_SENSORS):
        debugFlags.append('ExtSensors')

    if (debug_flags & DEBUG_FLAG_FEDR):
        debugFlags.append('Federation')

    if (debug_flags & DEBUG_FLAG_FRONT_END):
        debugFlags.append('FrontEnd')

    if (debug_flags & DEBUG_FLAG_GANG):
        debugFlags.append('Gang')

    if (debug_flags & DEBUG_FLAG_GRES):
        debugFlags.append('Gres')

    if (debug_flags & DEBUG_FLAG_HETJOB):
        debugFlags.append('HeteroJobs')

    if (debug_flags & DEBUG_FLAG_INTERCONNECT):
        debugFlags.append('Interconnect')

    if (debug_flags & DEBUG_FLAG_JAG):
        debugFlags.append('Jag')

    if (debug_flags & DEBUG_FLAG_JOB_CONT):
        debugFlags.append('JobContainer')

    if (debug_flags & DEBUG_FLAG_NODE_FEATURES):
        debugFlags.append('NodeFeatures')

    if (debug_flags & DEBUG_FLAG_LICENSE):
        debugFlags.append('License')

    if (debug_flags & DEBUG_FLAG_NO_CONF_HASH):
        debugFlags.append('NO_CONF_HASH')

    if (debug_flags & DEBUG_FLAG_POWER):
        debugFlags.append('Power')

    if (debug_flags & DEBUG_FLAG_PRIO):
        debugFlags.append('Priority')

    if (debug_flags & DEBUG_FLAG_PROTOCOL):
        debugFlags.append('Protocol')

    if (debug_flags & DEBUG_FLAG_RESERVATION):
        debugFlags.append('Reservation')

    if (debug_flags & DEBUG_FLAG_ROUTE):
        debugFlags.append('Route')

    if (debug_flags & DEBUG_FLAG_SELECT_TYPE):
        debugFlags.append('SelectType')

    if (debug_flags & DEBUG_FLAG_SCRIPT):
        debugFlags.append('Script')

    if (debug_flags & DEBUG_FLAG_STEPS):
        debugFlags.append('Steps')

    if (debug_flags & DEBUG_FLAG_SWITCH):
        debugFlags.append('Switch')

    if (debug_flags & DEBUG_FLAG_TASK):
        debugFlags.append('Task')

    if (debug_flags & DEBUG_FLAG_TIME_CRAY):
        debugFlags.append('TimeCray')

    if (debug_flags & DEBUG_FLAG_TRACE_JOBS):
        debugFlags.append('TraceJobs')

    if (debug_flags & DEBUG_FLAG_TRIGGERS):
        debugFlags.append('Triggers')

    return debugFlags


def get_node_state(uint32_t inx):
    """Returns a string that represents the state of the slurm node.

    :param int inx: Slurm node state
    :returns: Node state string
    :rtype: `string`
    """
    return slurm.slurm_node_state_string(inx)


def get_rm_partition_state(int inx):
    """Returns a string that represents the partition state.

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

    return "%s" % rm_part_state


def get_preempt_mode(uint16_t inx):
    """Returns a string that represents the preempt mode.

    :param int inx: Slurm preempt mode
        - PREEMPT_MODE_OFF        0x0000
        - PREEMPT_MODE_SUSPEND    0x0001
        - PREEMPT_MODE_REQUEUE    0x0002
        - PREEMPT_MODE_CANCEL     0x0008
        - PREEMPT_MODE_GANG       0x8000
    :returns: Preempt mode string
    :rtype: `string`
    """
    return slurm.slurm_preempt_mode_string(inx)


def get_partition_state(uint16_t inx):
    """Returns a string that represents the state of the slurm partition.

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
            state = "INACTIVE"
        elif inx == PARTITION_DRAIN:
            state = "DRAIN"
        else:
            state = "UNKNOWN"

    return state

cdef inline object __get_partition_state(int inx, int extended=0):
    """Returns a string that represents the state of the partition.

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

    return "%s" % state


def get_partition_mode(uint16_t flags=0, uint16_t max_share=0):
    """Returns a string represents the state of the partition mode.

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
        mode['Default'] = 1
    else:
        mode['Default'] = 0

    if (flags & PART_FLAG_HIDDEN):
        mode['Hidden'] = 1
    else:
        mode['Hidden'] = 0

    if (flags & PART_FLAG_NO_ROOT):
        mode['DisableRootJobs'] = 1
    else:
        mode['DisableRootJobs'] = 0

    if (flags & PART_FLAG_ROOT_ONLY):
        mode['RootOnly'] = 1
    else:
        mode['RootOnly'] = 0

    if val == 0:
        mode['Shared'] = "EXCLUSIVE"
    elif force:
        mode['Shared'] = "FORCED:" + str(val)
    elif val == 1:
        mode['Shared'] = "NO"
    else:
        mode['Shared'] = "YES:" + str(val)

    if (flags & PART_FLAG_LLN):
        mode['LLN'] = 1
    else:
        mode['LLN'] = 0

    if (flags & PART_FLAG_EXCLUSIVE_USER):
        mode['ExclusiveUser'] = 1
    else:
        mode['ExclusiveUser'] = 0

    return mode


def get_job_state(inx):
    """Return the state of the slurm job state.

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
        - JOB_DEADLINE    11
        - JOB_OOM         12
        - JOB_END
    :returns: Job state string
    :rtype: `string`
    """
    try:
        job_state = slurm.stringOrNone(slurm.slurm_job_state_string(inx), '')
        return job_state
    except:
        pass


def get_job_state_reason(inx):
    """Returns a reason why the slurm job is in a provided state.

    :param int inx: Slurm job state reason
    :returns: Reason string
    :rtype: `string`
    """
    job_reason = slurm.stringOrNone(slurm.slurm_job_reason_string(inx), '')
    return job_reason


def epoch2date(epochSecs):
    """Convert epoch secs to a python time string.

    :param int epochSecs: Seconds since epoch
    :returns: Date
    :rtype: `string`
    """
    try:
        dateTime = p_time.gmtime(epochSecs)
        return "%s" % p_time.strftime("%a %b %d %H:%M:%S %Y", dateTime)
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
    """Class to access slurm controller license information."""

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
        """Free the memory allocated by load licenses method."""
        pass

    def lastUpdate(self):
        """Return last time (epoch seconds) license data was updated.

        :returns: epoch seconds
        :rtype: `integer`
        """
        return self._lastUpdate

    def ids(self):
        """Return the current license names from retrieved license data.

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
        """Get full license information from the slurm controller.

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

# Automatically load Slurm configuration data structure at pyslurm module load
slurm_init()
