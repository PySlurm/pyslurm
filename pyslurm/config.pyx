# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
"""
=============
:mod:`config`
=============

The config extension module is used to get Slurm config information.

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

- slurm_load_ctl_conf
- slurm_free_ctl_conf
- slurm_print_ctl_conf

Config Object
-------------

Several functions in this module wrap the ``slurm_ctl_conf_t`` struct found in
`slurm.h`. The members of this struct are converted to a :class:`Config` object,
which implements Python properties to retrieve the value of each attribute.

"""
from __future__ import absolute_import, division, unicode_literals

cimport cython
from libc.stdio cimport stdout
from .c_config cimport *
from .slurm_common cimport *
from .utils cimport *
from .exceptions import PySlurmError

cdef class Config:
    """An object to wrap `` structs."""
    cdef:
        readonly unicode accounting_storage_backup_host
        readonly list accounting_storage_enforce
        readonly unicode accounting_storage_host
        readonly unicode accounting_storage_loc
        readonly list accounting_storage_tres
        readonly unicode accounting_storage_type
        readonly uint32_t accounting_storage_port
        readonly unicode accounting_storage_user
        readonly unicode accounting_store_job_comment
        readonly unicode acct_gather_energy_type
        readonly unicode acct_gather_filesystem_type
        readonly unicode acct_gather_infiniband_type
        readonly uint16_t acct_gather_node_freq
        readonly unicode acct_gather_profile_type
        readonly uint16_t allow_spec_resources_usage
        readonly unicode auth_info
        readonly unicode auth_type
        readonly unicode backup_addr
        readonly unicode backup_controller
        readonly uint16_t batch_start_timeout
        unicode batch_start_timeout_str
        readonly time_t boot_time
        readonly unicode boot_time_str
        readonly unicode burst_buffer_type
        readonly int cache_groups
        readonly unicode checkpoint_type
        readonly unicode chos_loc
        readonly unicode cluster_name
        readonly uint16_t complete_wait
        unicode complete_wait_str
        readonly unicode control_addr
        readonly unicode control_machine
        readonly unicode core_spec_plugin
        readonly uint32_t cpu_freq_def
        readonly unicode cpu_freq_def_str
        readonly uint32_t cpu_freq_governors
        readonly list cpu_freq_governors_str
        readonly unicode crypto_type
        readonly uint64_t debug_flags
        readonly list debug_flags_str
        uint32_t def_mem_per_cpu
        uint32_t def_mem_per_node
        readonly unicode disable_root_jobs
        readonly uint16_t eio_timeout
        readonly unicode enforce_part_limits
        readonly unicode epilog
        readonly uint32_t epilog_msg_time
        unicode epilog_msg_time_str
        readonly unicode epilog_slurmctld
        readonly unicode ext_sensors_type
        readonly uint16_t ext_sensors_freq
        unicode ext_sensors_freq_str
        readonly uint16_t fair_share_dampening_factor
        readonly uint16_t fast_schedule
        readonly uint32_t first_job_id
        readonly uint16_t get_env_timeout
        readonly list gres_types
        readonly int group_update_force
        readonly uint16_t group_update_time
        unicode group_update_time_str
#        readonly unicode hash_val
        readonly uint16_t health_check_interval
        unicode health_check_interval_str
        readonly list health_check_node_state
        readonly unicode health_check_program
        readonly uint16_t inactive_limit
        unicode inactive_limit_str
        readonly unicode job_acct_gather_frequency
        readonly unicode job_acct_gather_type
        readonly unicode job_acct_gather_params
        readonly unicode job_checkpoint_dir
        readonly unicode job_comp_host
        readonly unicode job_comp_loc
        readonly uint32_t job_comp_port
        readonly unicode job_comp_type
        readonly unicode job_comp_user
        readonly unicode job_container_type
        readonly unicode job_credential_private_key
        readonly unicode job_credential_public_certificate
        readonly uint16_t job_file_append
        readonly uint16_t job_requeue
        readonly list job_submit_plugins
        readonly uint16_t keep_alive_time
        unicode keep_alive_time_str
        readonly uint16_t kill_on_bad_exit
        readonly uint16_t kill_wait
        unicode kill_wait_str
        readonly time_t last_update
        readonly unicode last_update_str
        readonly unicode launch_parameters
        readonly unicode launch_type
        readonly unicode layouts
        readonly list licenses
        readonly list licenses_used
        readonly unicode mail_prog
        readonly uint32_t max_array_size
        readonly uint32_t max_job_count
        readonly uint32_t max_job_id
        uint32_t max_mem_per_cpu
        uint32_t max_mem_per_node
        readonly uint32_t max_step_count
        readonly uint16_t max_tasks_per_node
        readonly unicode mem_limit_enforce
        readonly uint16_t message_timeout
        unicode message_timeout_str
        readonly uint32_t min_job_age
        unicode min_job_age_str
        readonly unicode mpi_default
        readonly unicode mpi_params
        readonly unicode msg_aggregation_params
        readonly unicode multiple_slurmd
        readonly uint32_t next_job_id
        readonly uint16_t over_time_limit
        unicode over_time_limit_str
        readonly unicode plugin_dir
        readonly unicode plug_stack_config
        readonly unicode power_parameters
        readonly unicode power_plugin
        readonly unicode preempt_mode
        readonly unicode preempt_type
        readonly unicode priority_parameters
        readonly uint32_t priority_decay_half_life
        unicode priority_decay_half_life_str
        readonly uint32_t priority_calc_period
        unicode priority_calc_period_str
        readonly unicode priority_favor_small
        readonly uint32_t priority_max_age
        unicode priority_max_age_str
        readonly uint16_t priority_usage_reset_period
        unicode priority_usage_reset_period_str
        readonly list priority_flags
        readonly unicode priority_type
        readonly uint32_t priority_weight_age
        readonly uint32_t priority_weight_fair_share
        readonly uint32_t priority_weight_job_size
        readonly uint32_t priority_weight_partition
        readonly uint32_t priority_weight_qos
        readonly unicode priority_weight_tres
        readonly unicode private_data
        readonly unicode proctrack_type
        readonly unicode prolog
        readonly uint16_t prolog_epilog_timeout
        readonly unicode prolog_slurmctld
        readonly list prolog_flags
        readonly uint16_t propagate_prio_process
        readonly unicode propagate_resource_limits
        readonly unicode propagate_resource_limits_except
        readonly unicode reboot_program
        readonly list reconfig_flags
        readonly unicode requeue_exit
        readonly unicode requeue_exit_hold
        readonly unicode resume_program
        readonly uint16_t resume_rate
        unicode resume_rate_str
        readonly uint16_t resume_timeout
        unicode resume_timeout_str
        readonly unicode resv_epilog
        readonly uint16_t resv_over_run
        unicode resv_over_run_str
        readonly unicode resv_prolog
        readonly uint16_t return_to_service
        readonly unicode route_plugin
        readonly unicode salloc_default_command
        readonly list scheduler_parameters
        readonly uint16_t scheduler_port
        readonly uint16_t scheduler_root_filter
        readonly uint16_t scheduler_time_slice
        unicode scheduler_time_slice_str
        readonly unicode scheduler_type
        readonly unicode select_type
        readonly list select_type_parameters
        unicode slurm_user
        readonly unicode slurm_user_name
        readonly uint32_t slurm_user_id
        readonly unicode slurmctld_debug
        readonly unicode slurmctld_log_file
        uint32_t slurmctld_port
        readonly uint16_t slurmctld_port_count
        readonly uint16_t slurmctld_timeout
        unicode slurmctld_timeout_str
        readonly unicode slurmd_debug
        readonly unicode slurmd_log_file
        readonly unicode slurmd_pid_file
        readonly unicode slurmd_plugstack
        readonly uint32_t slurmd_port
        readonly unicode slurmd_spool_dir
        readonly uint16_t slurmd_timeout
        unicode slurmd_timeout_str
        unicode slurmd_user
        readonly unicode slurmd_user_name
        readonly uint32_t slurmd_user_id
        readonly unicode slurm_sched_log_file
        readonly uint16_t slurm_sched_log_level
        readonly unicode slurmctld_pid_file
        readonly unicode slurmctld_plugstack
        readonly unicode slurm_conf
        readonly unicode slurm_version
        readonly unicode srun_epilog
        uint16_t *srun_port_range
        readonly unicode srun_prolog
        readonly unicode state_save_location
        readonly unicode suspend_exc_nodes
        readonly unicode suspend_exc_parts
        readonly unicode suspend_program
        readonly uint16_t suspend_rate
        unicode suspend_rate_str
        uint32_t suspend_time
        uint16_t suspend_timeout
        readonly unicode switch_type
        readonly unicode task_epilog
        readonly unicode task_plugin
        readonly list task_plugin_param
        readonly unicode task_prolog
        readonly unicode tmp_fs
        readonly unicode topology_param
        readonly unicode topology_plugin
        readonly unicode track_wc_key
        readonly uint16_t tree_width
        readonly uint16_t use_pam
        readonly unicode unkillable_step_program
        readonly uint16_t unkillable_step_timeout
        unicode unkillable_step_timeout_str
        readonly uint16_t v_size_factor
        unicode v_size_factor_str
        readonly uint16_t wait_time
        unicode wait_time_str

    @property
    def batch_start_timeout_str(self):
        """Max seconds for batch job to start"""
        return "%s sec" % self.batch_start_timeout

    @property
    def complete_wait_str(self):
        """Seconds to wait for job completion before scheduling another job"""
        return "%s sec" % self.complete_wait

    @property
    def def_mem_per_cpu(self):
        """Default MB memory per allocated CPU"""
        if (self.def_mem_per_cpu & MEM_PER_CPU):
            return self.def_mem_per_cpu & (~MEM_PER_CPU)

    @property
    def def_mem_per_node(self):
        """Default MB memory per allocated Node"""
        if self.def_mem_per_cpu == INFINITE:
            return "UNLIMITED"
        elif self.def_mem_per_cpu:
            return self.def_mem_per_cpu
        else:
            return "UNLIMITED"

    @property
    def epilog_msg_time_str(self):
        """Microseconds for slurmctld to process an epilog complete message"""
        return "%s usec" % self.epilog_msg_time

    @property
    def ext_sensors_freq_str(self):
        """Seconds between ext sensors sampling"""
        return "%s sec" % self.ext_sensors_freq

    @property
    def group_update_time_str(self):
        """ """
        return "%s sec" % (self.group_info & GROUP_TIME_MASK)

    @property
    def health_check_interval_str(self):
        """Seconds between health checks"""
        return "%s sec" % self.health_check_interval

    @property
    def inactive_limit_str(self):
        """Seconds of inactivity before an inactive resource allocation is released"""
        return "%s sec" % self.inactive_limit

    @property
    def keep_alive_time_str(self):
        """Keep alive time for srun I/O sockets"""
        if self.keep_alive_time == <uint16_t>NO_VAL:
            return "SYSTEM_DEFAULT"
        else:
            return "%s sec" % self.keep_alive_time

    @property
    def kill_wait_str(self):
        """Seconds between SIGXCPU to SIGKILL on job termination"""
        return "%s sec" % self.kill_wait

    @property
    def max_mem_per_cpu(self):
        """Maximum MB memory per allocated CPU"""
        if (self.max_mem_per_cpu & MEM_PER_CPU):
            return self.max_mem_per_cpu & (~MEM_PER_CPU)

    def max_mem_per_node(self):
        """Maximum MB memory per allocated Node"""
        if self.max_mem_per_cpu == INFINITE:
            return "UNLIMITED"
        elif self.max_mem_per_cpu:
            return self.max_mem_per_cpu
        else:
            return "UNLIMITED"

    @property
    def message_timeout_str(self):
        """Message timeout"""
        return "%s sec" % self.message_timeout

    @property
    def min_job_age_str(self):
        """COMPLETED jobs over this age (secs) purged from in memory records"""
        return "%s sec" % self.min_job_age

    @property
    def over_time_limit_str(self):
        """Job's time limit can be exceeded by this number of minutes before
        cancellation."""
        return "%s min" % self.over_time_limit

    @property
    def resume_rate_str(self):
        """Nodes to make full power, per minute"""
        return "%s nodes/min" % self.resume_rate

    @property
    def resume_timeout_str(self):
        """Time required in order to perform node resume operation"""
        return "%s sec" % self.resume_timeout

    @property
    def resv_over_run_str(self):
        """How long a running job can exceed reservation time"""
        if self.resv_over_run == <uint16_t>INFINITE:
            return "UNLIMITED"
        else:
            return "%s min" % self.resv_over_run

    @property
    def scheduler_time_slice_str(self):
        """Time required in order to perform node resume operation"""
        return "%s sec" % self.scheduler_time

    @property
    def slurm_user(self):
        """User that slurmctld runs as"""
        return "%s(%s)" % (self.slurm_user_name,
                           self.slurm_user_id)

    @property
    def slurmctld_port(self):
        """Default communications port to slurmctld"""
        cdef uint32_t high_port
        if self.slurmctld_port_count > 1:
            high_port = self.slurmctld_port
            high_port += self.slurmctld_port_count - 1
            return "%s-%s" % (self.slurmctld_port, high_port)
        else:
            return self.slurmctld_port

    @property
    def slurmctld_timeout_str(self):
        """Seconds that backup controller waits on non-responding primary
        controller"""
        return "%s sec" % self.slurmctld_timeout

    @property
    def slurmd_timeout_str(self):
        """How long slurmctld waits for slumd before considering node DOWN"""
        return "%s sec" % self.slurmd_timeout

    @property
    def slurmd_user(self):
        """User that slurmd runs as"""
        return "%s(%s)" % (self.slurmd_user_name,
                           self.slurmd_user_id)

    @property
    def srun_port_range(self):
        """Port range for srun"""
        if self.srun_port_range and self.srun_port_range[0]:
            low_port = self.srun_port_range[0]
        else:
            low_port = 0

        if self.srun_port_range and self.srun_port_range[1]:
            high_port = self.srun_port_range[1]
        else:
            high_port = 0
        return "%s-%s" % (low_port, high_port)

    @property
    def suspend_rate_str(self):
        """Nodes to make power saving, per minute"""
        return "%s nodes/min" % self.suspend_rate

    @property
    def suspend_time(self):
        """Node idle for this long before power save mode"""
        if self.suspend == 0:
            return "NONE"
        else:
            return "%s sec" % (<int>self.suspend_time - 1)

    @property
    def suspend_timeout(self):
        """Time required in order to perform a node suspend operation"""
        if self.suspend_timeout == 0:
            return "NONE"
        else:
            return "%s sec" % self.suspend_timeout

    @property
    def unkillable_step_timeout_str(self):
        """Time in seconds, after processes in a job step have been signalled,
        but they are considered unkillable"""
        return "%s sec" % self.unkillable_step_timeout

    @property
    def v_size_factor_str(self):
        """Virtual memory limit size factor"""
        return "%s percent" % self.v_size_factor

    @property
    def wait_time_str(self):
        """Default job --wait time"""
        return "%s sec" % self.wait_time


def get_config():
    """ """
    cdef:
        slurm_ctl_conf_t *conf_info_msg_ptr = NULL
        char time_str[32]
        char tmp_str[128]
        int rc
        uint32_t cluster_flags = slurmdb_setup_cluster_flags()

    rc = slurm_load_ctl_conf(<time_t>NULL, &conf_info_msg_ptr)

    if rc == SLURM_SUCCESS:
        config = Config()

        config.last_update = conf_info_msg_ptr.last_update
        slurm_make_time_str(<time_t *>&conf_info_msg_ptr.last_update,
                            time_str, sizeof(time_str))
        config.last_update_str = time_str

        if conf_info_msg_ptr.accounting_storage_backup_host:
            config.accounting_storage_backup_host = (
                conf_info_msg_ptr.accounting_storage_backup_host
            )

        if conf_info_msg_ptr.accounting_storage_enforce:
            slurm_accounting_enforce_string(
                conf_info_msg_ptr.accounting_storage_enforce,
                tmp_str, sizeof(tmp_str)
            )
            config.accounting_storage_enforce = tmp_str.split(",")

        if conf_info_msg_ptr.accounting_storage_host:
            config.accounting_storage_host = conf_info_msg_ptr.accounting_storage_host

        if conf_info_msg_ptr.accounting_storage_loc:
            config.accounting_storage_loc = conf_info_msg_ptr.accounting_storage_loc

        config.accounting_storage_port = conf_info_msg_ptr.accounting_storage_port

        if conf_info_msg_ptr.accounting_storage_tres:
            config.accounting_storage_tres = (
                conf_info_msg_ptr.accounting_storage_tres.split(",")
            )

        if conf_info_msg_ptr.accounting_storage_type:
            config.accounting_storage_type = conf_info_msg_ptr.accounting_storage_type

        if conf_info_msg_ptr.accounting_storage_user:
            config.accounting_storage_user = conf_info_msg_ptr.accounting_storage_user

        if conf_info_msg_ptr.acctng_store_job_comment:
            config.accounting_store_job_comment = "Yes"
        else:
            config.accounting_store_job_comment = "No"

        if conf_info_msg_ptr.acct_gather_energy_type:
            config.acct_gather_energy_type = conf_info_msg_ptr.acct_gather_energy_type

        if conf_info_msg_ptr.acct_gather_filesystem_type:
            config.acct_gather_filesystem_type = conf_info_msg_ptr.acct_gather_filesystem_type

        if conf_info_msg_ptr.acct_gather_infiniband_type:
            config.acct_gather_infiniband_type = conf_info_msg_ptr.acct_gather_infiniband_type

        config.acct_gather_node_freq = conf_info_msg_ptr.acct_gather_node_freq

        if conf_info_msg_ptr.acct_gather_profile_type:
            config.acct_gather_profile_type = conf_info_msg_ptr.acct_gather_profile_type

        config.allow_spec_resources_usage = conf_info_msg_ptr.use_spec_resources

        if conf_info_msg_ptr.authinfo:
            config.auth_info = conf_info_msg_ptr.authinfo

        if conf_info_msg_ptr.authtype:
            config.auth_type = conf_info_msg_ptr.authtype

        if conf_info_msg_ptr.backup_addr:
            config.backup_addr = conf_info_msg_ptr.backup_addr

        if conf_info_msg_ptr.backup_controller:
            config.backup_controller = conf_info_msg_ptr.backup_controller

        config.batch_start_timeout = conf_info_msg_ptr.batch_start_timeout
        config.boot_time = conf_info_msg_ptr.boot_time
        slurm_make_time_str(
            <time_t *>&conf_info_msg_ptr.boot_time, tmp_str, sizeof(tmp_str)
        )
        config.boot_time_str = tmp_str

        if conf_info_msg_ptr.bb_type:
            config.burst_buffer_type = conf_info_msg_ptr.bb_type

        if (conf_info_msg_ptr.group_info & GROUP_CACHE):
            config.cache_groups = 1
        else:
            config.cache_groups = 0

        if conf_info_msg_ptr.checkpoint_type:
            config.checkpoint_type = conf_info_msg_ptr.checkpoint_type

        if conf_info_msg_ptr.chos_loc:
            config.chos_loc = conf_info_msg_ptr.chos_loc

        if conf_info_msg_ptr.cluster_name:
            config.cluster_name = conf_info_msg_ptr.cluster_name

        config.complete_wait = conf_info_msg_ptr.complete_wait

        if conf_info_msg_ptr.control_addr:
            config.control_addr = conf_info_msg_ptr.control_addr

        if conf_info_msg_ptr.control_machine:
            config.control_machine = conf_info_msg_ptr.control_machine

        if conf_info_msg_ptr.core_spec_plugin:
            config.core_spec_plugin = conf_info_msg_ptr.core_spec_plugin

        config.cpu_freq_def = conf_info_msg_ptr.cpu_freq_def
        config.cpu_freq_def_str = cpu_freq_to_string(
            conf_info_msg_ptr.cpu_freq_def
        )

        config.cpu_freq_governors = conf_info_msg_ptr.cpu_freq_govs
        config.cpu_freq_governors_str = cpu_freq_govlist_to_string(
            conf_info_msg_ptr.cpu_freq_govs
        )

        if conf_info_msg_ptr.crypto_type:
            config.crypto_type = conf_info_msg_ptr.crypto_type

        if conf_info_msg_ptr.debug_flags:
            config.debug_flags = conf_info_msg_ptr.debug_flags
            config.debug_flags_str = debug_flags2str(
                conf_info_msg_ptr.debug_flags
            )

        config.def_mem_per_node = conf_info_msg_ptr.def_mem_per_cpu

        if conf_info_msg_ptr.disable_root_jobs:
            config.disable_root_jobs = "Yes"
        else:
            config.disable_root_jobs = "No"

        config.eio_timeout = conf_info_msg_ptr.eio_timeout

        if conf_info_msg_ptr.enforce_part_limits:
            config.enforce_part_limits = "Yes"
        else:
            config.enforce_part_limits = "No"

        if conf_info_msg_ptr.epilog:
            config.epilog = conf_info_msg_ptr.epilog

        config.epilog_msg_time = conf_info_msg_ptr.epilog_msg_time

        if conf_info_msg_ptr.epilog_slurmctld:
            config.epilog_slurmctld = conf_info_msg_ptr.epilog_slurmctld

        if conf_info_msg_ptr.ext_sensors_type:
            config.ext_sensors_type = conf_info_msg_ptr.ext_sensors_type

        config.ext_sensors_freq = conf_info_msg_ptr.ext_sensors_freq

        if conf_info_msg_ptr.priority_type == "priority/basic":
            config.fair_share_dampening_factor = conf_info_msg_ptr.fs_dampening_factor

        config.fast_schedule = conf_info_msg_ptr.fast_schedule
        config.first_job_id = conf_info_msg_ptr.first_job_id
        config.get_env_timeout = conf_info_msg_ptr.get_env_timeout

        if conf_info_msg_ptr.gres_plugins:
            config.gres_types = conf_info_msg_ptr.gres_plugins.split(",")

        if (conf_info_msg_ptr.group_info & GROUP_FORCE):
            config.group_update_force = 1
        else:
            config.group_update_force = 0

        config.group_update_time = conf_info_msg_ptr.group_info

        # TODO: slurm_get_hash_val NOT available via libslurm
#        if conf_info_msg_ptr.hash_val != NO_VAL:
#            if conf_info_msg_ptr.hash_val == slurm_get_hash_val():
#                config.hash_val = "Match"
#            else:
#                config.hash_val = "Different Ours=0x%s Slurmctld=0x%s" % (
#                    slurm_get_hash_val(), conf_info_msg_ptr.hash_val
#                )

        config.health_check_interval = conf_info_msg_ptr.health_check_interval
        config.health_check_node_state = health_check_node_state_str(
            conf_info_msg_ptr.health_check_node_state
        )

        if conf_info_msg_ptr.health_check_program:
            config.health_check_program = conf_info_msg_ptr.health_check_program

        config.inactive_limit = conf_info_msg_ptr.inactive_limit

        if conf_info_msg_ptr.job_acct_gather_freq:
            config.job_acct_gather_frequency = conf_info_msg_ptr.job_acct_gather_freq

        if conf_info_msg_ptr.job_acct_gather_type:
            config.job_acct_gather_type = conf_info_msg_ptr.job_acct_gather_type

        if conf_info_msg_ptr.job_acct_gather_params:
            config.job_acct_gather_params = conf_info_msg_ptr.job_acct_gather_params

        if conf_info_msg_ptr.job_ckpt_dir:
            config.job_checkpoint_dir = conf_info_msg_ptr.job_ckpt_dir

        if conf_info_msg_ptr.job_comp_host:
            config.job_comp_host = conf_info_msg_ptr.job_comp_host

        if conf_info_msg_ptr.job_comp_loc:
            config.job_comp_loc = conf_info_msg_ptr.job_comp_loc

        config.job_comp_port = conf_info_msg_ptr.job_comp_port

        if conf_info_msg_ptr.job_comp_type:
            config.job_comp_type = conf_info_msg_ptr.job_comp_type

        if conf_info_msg_ptr.job_comp_user:
            config.job_comp_user = conf_info_msg_ptr.job_comp_user

        if conf_info_msg_ptr.job_container_plugin:
            config.job_container_type = conf_info_msg_ptr.job_container_plugin

        if conf_info_msg_ptr.job_credential_private_key:
            config.job_credential_private_key = (
                conf_info_msg_ptr.job_credential_private_key
            )

        if conf_info_msg_ptr.job_credential_public_certificate:
            config.job_credential_public_certificate = (
                conf_info_msg_ptr.job_credential_public_certificate
            )

        config.job_file_append = conf_info_msg_ptr.job_file_append
        config.job_requeue = conf_info_msg_ptr.job_requeue

        if conf_info_msg_ptr.job_submit_plugins:
            config.job_submit_plugins = (
                conf_info_msg_ptr.job_submit_plugins.split(",")
            )

        config.keep_alive_time = conf_info_msg_ptr.keep_alive_time
        config.kill_on_bad_exit = conf_info_msg_ptr.kill_on_bad_exit
        config.kill_wait = conf_info_msg_ptr.kill_wait

        if conf_info_msg_ptr.launch_params:
            config.launch_parameters = conf_info_msg_ptr.launch_params

        if conf_info_msg_ptr.launch_type:
            config.launch_type = conf_info_msg_ptr.launch_type

        if conf_info_msg_ptr.layouts:
            config.layouts = conf_info_msg_ptr.layouts


        # TODO: convert to dict
        if conf_info_msg_ptr.licenses:
            config.licenses = conf_info_msg_ptr.licenses.split(",")

        # TODO: convert to dict
        if conf_info_msg_ptr.licenses_used:
            config.licenses_used = conf_info_msg_ptr.licenses_used.split(",")

        if conf_info_msg_ptr.mail_prog:
            config.mail_prog = conf_info_msg_ptr.mail_prog

        config.max_array_size = conf_info_msg_ptr.max_array_sz
        config.max_job_count = conf_info_msg_ptr.max_job_cnt
        config.max_job_id = conf_info_msg_ptr.max_job_id
        config.max_mem_per_cpu = conf_info_msg_ptr.max_mem_per_cpu
        config.max_step_count = conf_info_msg_ptr.max_step_cnt
        config.max_tasks_per_node = conf_info_msg_ptr.max_tasks_per_node

        if conf_info_msg_ptr.mem_limit_enforce:
            config.mem_limit_enforce = "Yes"
        else:
            config.mem_limit_enforce = "No"

        config.message_timeout = conf_info_msg_ptr.msg_timeout
        config.min_job_age = conf_info_msg_ptr.min_job_age

        if conf_info_msg_ptr.mpi_default:
            config.mpi_default = conf_info_msg_ptr.mpi_default

        if conf_info_msg_ptr.mpi_params:
            config.mpi_params = conf_info_msg_ptr.mpi_params

        if conf_info_msg_ptr.msg_aggr_params:
            config.msg_aggregation_params = conf_info_msg_ptr.msg_aggr_params

        if cluster_flags & CLUSTER_FLAG_MULTSD:
            config.multiple_slurmd = "Yes"

        config.next_job_id = conf_info_msg_ptr.next_job_id
        config.over_time_limit = conf_info_msg_ptr.over_time_limit

        if conf_info_msg_ptr.plugindir:
            config.plugin_dir = conf_info_msg_ptr.plugindir

        if conf_info_msg_ptr.plugstack:
            config.plug_stack_config = conf_info_msg_ptr.plugstack

        if conf_info_msg_ptr.power_parameters:
            config.power_parameters = conf_info_msg_ptr.power_parameters

        if conf_info_msg_ptr.power_plugin:
            config.power_plugin = conf_info_msg_ptr.power_plugin

        config.preempt_mode = slurm_preempt_mode_string(
            conf_info_msg_ptr.preempt_mode
        )

        if conf_info_msg_ptr.preempt_type:
            config.preempt_type = conf_info_msg_ptr.preempt_type

        if conf_info_msg_ptr.priority_params:
            config.priority_parameters = conf_info_msg_ptr.priority_params

        if conf_info_msg_ptr.priority_type == "priority/basic":
            config.priority_type = conf_info_msg_ptr.priority_type
        else:
            config.priority_decay_half_life = conf_info_msg_ptr.priority_decay_hl
            slurm_secs2time_str(<time_t>conf_info_msg_ptr.priority_decay_hl,
                tmp_str, sizeof(tmp_str)
            )
            config.priority_decay_half_life_str = tmp_str

            config.priority_calc_period = conf_info_msg_ptr.priority_calc_period
            slurm_secs2time_str(<time_t>conf_info_msg_ptr.priority_calc_period,
                tmp_str, sizeof(tmp_str)
            )
            config.priority_calc_period_str = tmp_str

            if conf_info_msg_ptr.priority_favor_small:
                config.priority_favor_small = "Yes"
            else:
                config.priority_favor_small = "No"

            config.priority_flags = priority_flags_string(
                conf_info_msg_ptr.priority_flags
            )

            config.priority_max_age = conf_info_msg_ptr.priority_max_age
            slurm_secs2time_str(<time_t>conf_info_msg_ptr.priority_max_age,
                tmp_str, sizeof(tmp_str)
            )
            config.priority_max_age_str = tmp_str

            config.priority_usage_reset_period = conf_info_msg_ptr.priority_reset_period
            config.priority_usage_reset_period_str = (
                reset_period_str(conf_info_msg_ptr.priority_reset_period)
            )

            if conf_info_msg_ptr.priority_type:
                config.priority_type = conf_info_msg_ptr.priority_type

            config.priority_weight_age = conf_info_msg_ptr.priority_weight_age
            config.priority_weight_fair_share = conf_info_msg_ptr.priority_weight_fs
            config.priority_weight_job_size = conf_info_msg_ptr.priority_weight_js
            config.priority_weight_partition = conf_info_msg_ptr.priority_weight_part
            config.priority_weight_qos = conf_info_msg_ptr.priority_weight_qos

            if conf_info_msg_ptr.priority_weight_tres:
                config.priority_weight_tres = conf_info_msg_ptr.priority_weight_tres

        slurm_private_data_string(conf_info_msg_ptr.private_data,
                                  tmp_str, sizeof(tmp_str))
        config.private_data = tmp_str

        if conf_info_msg_ptr.proctrack_type:
            config.proctrack_type = conf_info_msg_ptr.proctrack_type

        if conf_info_msg_ptr.prolog:
            config.prolog = conf_info_msg_ptr.prolog

        config.prolog_epilog_timeout = conf_info_msg_ptr.prolog_epilog_timeout

        if conf_info_msg_ptr.prolog_slurmctld:
            config.prolog_slurmctld = conf_info_msg_ptr.prolog_slurmctld

        config.prolog_flags = prolog_flags2str(
            conf_info_msg_ptr.prolog_flags
        )

        config.propagate_prio_process = (
            conf_info_msg_ptr.propagate_prio_process
        )

        if conf_info_msg_ptr.propagate_rlimits:
            config.propagate_resource_limits = (
                conf_info_msg_ptr.propagate_rlimits
            )

        if conf_info_msg_ptr.propagate_rlimits_except:
            config.propagate_resource_limits_except = (
                conf_info_msg_ptr.propagate_rlimits_except
            )

        if conf_info_msg_ptr.reboot_program:
            config.reboot_program = conf_info_msg_ptr.reboot_program

        config.reconfig_flags = reconfig_flags2str(
            conf_info_msg_ptr.reconfig_flags
        )

        if conf_info_msg_ptr.requeue_exit:
            config.requeue_exit = conf_info_msg_ptr.requeue_exit

        if conf_info_msg_ptr.requeue_exit_hold:
            config.requeue_exit_hold = conf_info_msg_ptr.requeue_exit_hold

        if conf_info_msg_ptr.resume_program:
            config.resume_program = conf_info_msg_ptr.resume_program

        config.resume_rate = conf_info_msg_ptr.resume_rate
        config.resume_timeout = conf_info_msg_ptr.resume_timeout

        if conf_info_msg_ptr.resv_epilog:
            config.resv_epilog = conf_info_msg_ptr.resv_epilog

        config.resv_over_run = conf_info_msg_ptr.resv_over_run

        if conf_info_msg_ptr.resv_prolog:
            config.resv_prolog = conf_info_msg_ptr.resv_prolog

        config.return_to_service = conf_info_msg_ptr.ret2service

        if conf_info_msg_ptr.route_plugin:
            config.route_plugin = conf_info_msg_ptr.route_plugin

        if conf_info_msg_ptr.salloc_default_command:
            config.salloc_default_command = (
                conf_info_msg_ptr.salloc_default_command
            )

        if conf_info_msg_ptr.sched_params:
            config.scheduler_parameters = (
                conf_info_msg_ptr.sched_params.split(",")
            )

        config.scheduler_port = conf_info_msg_ptr.schedport
        config.scheduler_root_filter = conf_info_msg_ptr.schedrootfltr
        config.scheduler_time_slice = conf_info_msg_ptr.sched_time_slice

        if conf_info_msg_ptr.schedtype:
            config.scheduler_type = conf_info_msg_ptr.schedtype

        if conf_info_msg_ptr.select_type:
            config.select_type = conf_info_msg_ptr.select_type

        config.select_type_parameters = select_type_param_string(
            conf_info_msg_ptr.select_type_param
        )

        config.slurm_user_id = conf_info_msg_ptr.slurm_user_id
        if conf_info_msg_ptr.slurm_user_name:
            config.slurm_user_name = conf_info_msg_ptr.slurm_user_name

        config.slurmctld_debug = log_num2string(
            conf_info_msg_ptr.slurmctld_debug
        )

        if conf_info_msg_ptr.slurmctld_logfile:
            config.slurmctld_log_file = conf_info_msg_ptr.slurmctld_logfile

        config.slurmctld_port = conf_info_msg_ptr.slurmctld_port
        config.slurmctld_port_count = conf_info_msg_ptr.slurmctld_port_count
        config.slurmctld_timeout = conf_info_msg_ptr.slurmctld_timeout

        config.slurmd_debug = log_num2string(
            conf_info_msg_ptr.slurmd_debug
        )

        if conf_info_msg_ptr.slurmd_logfile:
            config.slurmd_log_file = conf_info_msg_ptr.slurmd_logfile

        if conf_info_msg_ptr.slurmd_pidfile:
            config.slurmd_pid_file = conf_info_msg_ptr.slurmd_pidfile

        if conf_info_msg_ptr.slurmd_plugstack:
            config.slurmd_plugstack = conf_info_msg_ptr.slurmd_plugstack

#        ifndef MULTIPLE_SLURMD:
#            config.slurmd_port = conf_info_msg_ptr.slurmd_port

        if conf_info_msg_ptr.slurmd_spooldir:
            config.slurmd_spool_dir = conf_info_msg_ptr.slurmd_spooldir

        config.slurmd_timeout = conf_info_msg_ptr.slurmd_timeout

        config.slurmd_user_id = conf_info_msg_ptr.slurmd_user_id
        if conf_info_msg_ptr.slurmd_user_name:
            config.slurmd_user_name = conf_info_msg_ptr.slurmd_user_name

        if conf_info_msg_ptr.sched_logfile:
            config.slurm_sched_log_file = conf_info_msg_ptr.sched_logfile

        config.slurm_sched_log_level = conf_info_msg_ptr.sched_log_level

        if conf_info_msg_ptr.slurmctld_pidfile:
            config.slurmctld_pid_file = conf_info_msg_ptr.slurmctld_pidfile

        if conf_info_msg_ptr.slurmctld_plugstack:
            config.slurmctld_plugstack = conf_info_msg_ptr.slurmctld_plugstack

        if conf_info_msg_ptr.slurm_conf:
            config.slurm_conf = conf_info_msg_ptr.slurm_conf

        if conf_info_msg_ptr.version:
            config.slurm_version = conf_info_msg_ptr.version

        if conf_info_msg_ptr.srun_epilog:
            config.srun_epilog = conf_info_msg_ptr.srun_epilog

        config.srun_port_range = conf_info_msg_ptr.srun_port_range

        if conf_info_msg_ptr.srun_prolog:
            config.srun_prolog = conf_info_msg_ptr.srun_prolog

        if conf_info_msg_ptr.state_save_location:
            config.state_save_location = conf_info_msg_ptr.state_save_location

        if conf_info_msg_ptr.suspend_exc_nodes:
            config.suspend_exc_nodes = conf_info_msg_ptr.suspend_exc_nodes

        if conf_info_msg_ptr.suspend_exc_parts:
            config.suspend_exc_parts = conf_info_msg_ptr.suspend_exc_parts

        if conf_info_msg_ptr.suspend_program:
            config.suspend_program = conf_info_msg_ptr.suspend_program

        config.suspend_rate = conf_info_msg_ptr.suspend_rate
        config.suspend_time = conf_info_msg_ptr.suspend_time
        config.suspend_timeout = conf_info_msg_ptr.suspend_timeout

        if conf_info_msg_ptr.switch_type:
            config.switch_type = conf_info_msg_ptr.switch_type

        if conf_info_msg_ptr.task_epilog:
            config.task_epilog = conf_info_msg_ptr.task_epilog

        if conf_info_msg_ptr.task_plugin:
            config.task_plugin = conf_info_msg_ptr.task_plugin

        config.task_plugin_param = slurm_sprint_cpu_bind_type(
            <cpu_bind_type_t>conf_info_msg_ptr.task_plugin_param
        )

        if conf_info_msg_ptr.task_prolog:
            config.task_prolog = conf_info_msg_ptr.task_prolog

        if conf_info_msg_ptr.tmp_fs:
            config.tmp_fs = conf_info_msg_ptr.tmp_fs

        if conf_info_msg_ptr.topology_param:
            config.topology_param = conf_info_msg_ptr.topology_param

        if conf_info_msg_ptr.topology_plugin:
            config.topology_plugin = conf_info_msg_ptr.topology_plugin

        if conf_info_msg_ptr.track_wckey:
            config.track_wc_key = "Yes"
        else:
            config.track_wc_key = "No"

        config.tree_width = conf_info_msg_ptr.tree_width
        config.use_pam = conf_info_msg_ptr.use_pam

        if conf_info_msg_ptr.unkillable_program:
            config.unkillable_step_program = (
                conf_info_msg_ptr.unkillable_program
            )

        config.unkillable_step_timeout = conf_info_msg_ptr.unkillable_timeout
        config.v_size_factor = conf_info_msg_ptr.vsize_factor
        config.wait_time = conf_info_msg_ptr.wait_time

        slurm_free_ctl_conf(conf_info_msg_ptr)
        conf_info_msg_ptr = NULL
        return config
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


cpdef api_version():
    """
    Return Slurm API version number.

    Args:
        None
    Returns:
        A tuple representing the API version number (MAJOR, MINOR, MICRO).
    """
    return (SLURM_VERSION_MAJOR(SLURM_VERSION_NUMBER),
            SLURM_VERSION_MINOR(SLURM_VERSION_NUMBER),
            SLURM_VERSION_MICRO(SLURM_VERSION_NUMBER))


cpdef print_ctl_conf():
    """
    Print Slurm error information to standard output

    Args:
        msg (str): error message string
    Returns:
        None
    """
    cdef:
        slurm_ctl_conf_t *conf_info_msg_ptr = NULL
        int rc

    rc = slurm_load_ctl_conf(<time_t>NULL, &conf_info_msg_ptr)

    if rc == SLURM_SUCCESS:
        slurm_print_ctl_conf(stdout, conf_info_msg_ptr)
        slurm_free_ctl_conf(conf_info_msg_ptr)
        conf_info_msg_ptr = NULL
    else:
        raise PySlurmError(slurm_strerror(rc), rc)
