# cython: embedsignature=True
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

from cpython cimport bool
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
        readonly bool accounting_store_job_comment
        readonly unicode acct_gather_energy_type
        readonly unicode acct_gather_filesystem_type
        readonly unicode acct_gather_interconnect_type
        readonly uint16_t acct_gather_node_freq
        readonly unicode acct_gather_profile_type
        readonly uint16_t allow_spec_resources_usage
        readonly unicode auth_info
        readonly unicode auth_type
        readonly uint16_t batch_start_timeout
        unicode batch_start_timeout_str
        readonly time_t boot_time
        readonly unicode boot_time_str
        readonly unicode burst_buffer_type
        readonly int cache_groups
        readonly unicode checkpoint_type
        readonly unicode cluster_name
        readonly unicode communication_parameters
        readonly uint16_t complete_wait
        unicode complete_wait_str
        readonly unicode control_addr
        readonly unicode control_machine
        readonly unicode core_spec_plugin
        readonly uint32_t cpu_freq_def
        readonly unicode cpu_freq_def_str
        readonly uint32_t cpu_freq_governors
        readonly list cpu_freq_governors_list
        readonly unicode crypto_type
        readonly uint64_t debug_flags
        readonly list debug_flags_list
        uint64_t def_mem_per_cpu
        uint64_t def_mem_per_node
        readonly bool disable_root_jobs
        readonly uint16_t eio_timeout
        readonly uint16_t enforce_part_limits
        readonly unicode enforce_part_limits_str
        readonly unicode epilog
        readonly uint32_t epilog_msg_time
        unicode epilog_msg_time_str
        readonly unicode epilog_slurmctld
        readonly unicode ext_sensors_type
        readonly uint16_t ext_sensors_freq
        unicode ext_sensors_freq_str
        readonly uint16_t fair_share_dampening_factor
        readonly uint16_t fast_schedule
        readonly unicode federation_parameters
        readonly uint32_t first_job_id
        readonly uint16_t get_env_timeout
        readonly list gres_types
        readonly int group_update_force
        readonly uint16_t group_update_time
        unicode group_update_time_str
#        readonly unicode hash_val
        readonly uint16_t health_check_interval
        unicode health_check_interval_str
        readonly uint16_t health_check_node_state
        readonly list health_check_node_state_list
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
        readonly list job_defaults
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
        readonly list layouts
        readonly dict licenses
        readonly dict licenses_used
        readonly unicode log_time_format
        readonly unicode mail_domain
        readonly unicode mail_prog
        readonly uint32_t max_array_size
        readonly uint32_t max_job_count
        readonly uint32_t max_job_id
        uint64_t max_mem_per_cpu
        uint64_t max_mem_per_node
        readonly uint32_t max_step_count
        readonly uint16_t max_tasks_per_node
        readonly unicode mcs_plugin
        readonly list mcs_parameters
        readonly bool mem_limit_enforce
        readonly uint16_t message_timeout
        unicode message_timeout_str
        readonly uint32_t min_job_age
        unicode min_job_age_str
        readonly unicode mpi_default
        readonly unicode mpi_params
        readonly unicode msg_aggregation_params
        readonly bool multiple_slurmd
        readonly uint32_t next_job_id
        readonly list node_features_plugins
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
        readonly unicode priority_decay_half_life_str
        readonly uint32_t priority_calc_period
        readonly unicode priority_calc_period_str
        readonly bool priority_favor_small
        readonly uint32_t priority_max_age
        unicode priority_max_age_str
        readonly uint16_t priority_usage_reset_period
        readonly unicode priority_usage_reset_period_str
        readonly uint16_t priority_flags
        readonly list priority_flags_str
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
        readonly unicode resume_fail_program
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
        readonly unicode sbcast_parameters
        readonly list scheduler_parameters
        readonly uint16_t scheduler_time_slice
        unicode scheduler_time_slice_str
        readonly unicode scheduler_type
        readonly unicode select_type
        readonly list select_type_parameters
        unicode slurm_user
        readonly unicode slurm_user_name
        readonly uint32_t slurm_user_id
        readonly unicode slurmctld_addr
        readonly unicode slurmctld_debug
        readonly dict slurmctld_host
        readonly unicode slurmctld_log_file
        uint32_t slurmctld_port
        readonly uint16_t slurmctld_port_count
        readonly unicode slurmctld_syslog_debug
        readonly unicode slurmctld_primary_off_prog 
        readonly unicode slurmctld_primary_on_prog 
        readonly uint16_t slurmctld_timeout
        readonly list slurmctld_parameters
        unicode slurmctld_timeout_str
        readonly unicode slurmd_debug
        readonly unicode slurmd_log_file
        readonly list slurmd_parameters
        readonly unicode slurmd_pid_file
        readonly unicode slurmd_plugstack
        readonly uint32_t slurmd_port
        readonly unicode slurmd_spool_dir
        readonly unicode slurmd_syslog_debug
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
        readonly uint32_t suspend_time
        unicode suspend_time_str
        readonly uint16_t suspend_timeout
        unicode suspend_timeout_str
        readonly unicode switch_type
        readonly unicode task_epilog
        readonly unicode task_plugin
        readonly list task_plugin_param
        readonly unicode task_prolog
        readonly unicode tmp_fs
        readonly unicode topology_param
        readonly unicode topology_plugin
        readonly bool track_wc_key
        readonly uint16_t tree_width
        readonly uint16_t use_pam
        readonly unicode unkillable_step_program
        readonly uint16_t unkillable_step_timeout
        unicode unkillable_step_timeout_str
        readonly uint16_t v_size_factor
        unicode v_size_factor_str
        readonly uint16_t wait_time
        unicode wait_time_str
        readonly list x11_parameters

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
        if self.def_mem_per_cpu == INFINITE64:
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
        if self.max_mem_per_cpu == INFINITE64:
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
        if self.over_time_limit == INFINITE16:
            return "UNLIMITED"
        else:
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
    def suspend_time_str(self):
        """Node idle for this long before power save mode"""
        if self.suspend_time == 0:
            return None
        else:
            return "%s sec" % (<int>self.suspend_time - 1)

    @property
    def suspend_timeout_str(self):
        """Time required in order to perform a node suspend operation"""
        if self.suspend_timeout == 0:
            return None
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
    """  """ #TODO
    cdef:
        slurm_ctl_conf_t *conf_ptr
        char time_str[32]
        char tmp_str[128]
        int i
        int rc
        uint32_t cluster_flags = slurmdb_setup_cluster_flags()

    rc = slurm_load_ctl_conf(<time_t>NULL, &conf_ptr)

    if rc == SLURM_SUCCESS:
        config = Config()

        config.last_update = conf_ptr.last_update
        slurm_make_time_str(<time_t *>&conf_ptr.last_update,
                            time_str, sizeof(time_str))
        config.last_update_str = tounicode(time_str)

        config.accounting_storage_backup_host = tounicode(
                conf_ptr.accounting_storage_backup_host
        )

        slurm_accounting_enforce_string(
            conf_ptr.accounting_storage_enforce, tmp_str, sizeof(tmp_str)
        )
        if tounicode(tmp_str):
            config.accounting_storage_enforce = tmp_str.split(",")

        config.accounting_storage_host = tounicode(conf_ptr.accounting_storage_host)
        config.accounting_storage_loc = tounicode(conf_ptr.accounting_storage_loc)
        config.accounting_storage_port = conf_ptr.accounting_storage_port

        if conf_ptr.accounting_storage_tres:
            config.accounting_storage_tres = conf_ptr.accounting_storage_tres.split(",")

        config.accounting_storage_type = tounicode(conf_ptr.accounting_storage_type)
        config.accounting_storage_user = tounicode(conf_ptr.accounting_storage_user)

        if conf_ptr.acctng_store_job_comment:
            config.accounting_store_job_comment = True
        else:
            config.accounting_store_job_comment = False

        config.acct_gather_energy_type = tounicode(conf_ptr.acct_gather_energy_type)
        config.acct_gather_filesystem_type = tounicode(conf_ptr.acct_gather_filesystem_type)
        config.acct_gather_interconnect_type = tounicode(conf_ptr.acct_gather_interconnect_type)
        config.acct_gather_node_freq = conf_ptr.acct_gather_node_freq
        config.acct_gather_profile_type = tounicode(conf_ptr.acct_gather_profile_type)
        config.allow_spec_resources_usage = conf_ptr.use_spec_resources
        config.auth_info = tounicode(conf_ptr.authinfo)
        config.auth_type = tounicode(conf_ptr.authtype)
        config.batch_start_timeout = conf_ptr.batch_start_timeout
        config.boot_time = conf_ptr.boot_time

        slurm_make_time_str(<time_t *>&conf_ptr.boot_time, tmp_str, sizeof(tmp_str))
        config.boot_time_str = tounicode(tmp_str)

        config.burst_buffer_type = tounicode(conf_ptr.bb_type)
        config.checkpoint_type = tounicode(conf_ptr.checkpoint_type)
        config.cluster_name = tounicode(conf_ptr.cluster_name)
        config.communication_parameters = tounicode(conf_ptr.comm_params)
        config.complete_wait = conf_ptr.complete_wait
        config.core_spec_plugin = tounicode(conf_ptr.core_spec_plugin)
        config.cpu_freq_def = conf_ptr.cpu_freq_def

        config.cpu_freq_def_str = tounicode(
            cpu_freq_to_string(tmp_str, sizeof(tmp_str), conf_ptr.cpu_freq_def)
        )

        config.cpu_freq_governors = conf_ptr.cpu_freq_govs
        config.cpu_freq_governors_list = cpu_freq_govlist_to_list(conf_ptr.cpu_freq_govs)

        config.crypto_type = tounicode(conf_ptr.crypto_type)
        config.debug_flags = conf_ptr.debug_flags
        config.debug_flags_list = debug_flags2list(conf_ptr.debug_flags)
        config.def_mem_per_node = conf_ptr.def_mem_per_cpu

        if conf_ptr.disable_root_jobs:
            config.disable_root_jobs = True
        else:
            config.disable_root_jobs = False

        config.eio_timeout = conf_ptr.eio_timeout

        conf_ptr.enforce_part_limits = config.enforce_part_limits

        if conf_ptr.enforce_part_limits == PARTITION_ENFORCE_NONE:
            config.enforce_part_limits_str = "NO"
        elif conf_ptr.enforce_part_limits == PARTITION_ENFORCE_ANY:
            config.enforce_part_limits_str = "ANY"
        elif conf_ptr.enforce_part_limits == PARTITION_ENFORCE_ALL:
            config.enforce_part_limits_str = "ALL"

        config.epilog = tounicode(conf_ptr.epilog)
        config.epilog_msg_time = conf_ptr.epilog_msg_time
        config.epilog_slurmctld = tounicode(conf_ptr.epilog_slurmctld)
        config.ext_sensors_type = tounicode(conf_ptr.ext_sensors_type)
        config.ext_sensors_freq = conf_ptr.ext_sensors_freq

        if tounicode(conf_ptr.priority_type) == "priority/basic":
            config.fair_share_dampening_factor = conf_ptr.fs_dampening_factor

        config.fast_schedule = conf_ptr.fast_schedule
        config.federation_parameters = tounicode(conf_ptr.fed_params)
        config.first_job_id = conf_ptr.first_job_id
        config.get_env_timeout = conf_ptr.get_env_timeout

        if conf_ptr.gres_plugins:
            config.gres_types = conf_ptr.gres_plugins.split(",")

        config.group_update_force = conf_ptr.group_force
        config.group_update_time = conf_ptr.group_time
        config.health_check_interval = conf_ptr.health_check_interval
        config.health_check_node_state = conf_ptr.health_check_node_state
        config.health_check_node_state_list = health_check_node_state_list(
            conf_ptr.health_check_node_state
        )

        config.health_check_program = tounicode(conf_ptr.health_check_program)
        config.inactive_limit = conf_ptr.inactive_limit
        config.job_acct_gather_frequency = tounicode(conf_ptr.job_acct_gather_freq)
        config.job_acct_gather_type = tounicode(conf_ptr.job_acct_gather_type)
        config.job_acct_gather_params = tounicode(conf_ptr.job_acct_gather_params)
        config.job_checkpoint_dir = tounicode(conf_ptr.job_ckpt_dir)
        config.job_comp_host = tounicode(conf_ptr.job_comp_host)
        config.job_comp_loc = tounicode(conf_ptr.job_comp_loc)
        config.job_comp_port = conf_ptr.job_comp_port
        config.job_comp_type = tounicode(conf_ptr.job_comp_type)
        config.job_comp_user = tounicode(conf_ptr.job_comp_user)
        config.job_container_type = tounicode(conf_ptr.job_container_plugin)
        config.job_credential_private_key = tounicode(conf_ptr.job_credential_private_key)
        config.job_credential_public_certificate = tounicode(
            conf_ptr.job_credential_public_certificate
        )

        if conf_ptr.job_defaults_list:
            config.job_defaults = tounicode(
                job_defaults_str(conf_ptr.job_defaults_list)
            ).split(",")

        config.job_file_append = conf_ptr.job_file_append
        config.job_requeue = conf_ptr.job_requeue

        if conf_ptr.job_submit_plugins:
            config.job_submit_plugins = tounicode(conf_ptr.job_submit_plugins).split(",")

        config.keep_alive_time = conf_ptr.keep_alive_time

        config.kill_on_bad_exit = conf_ptr.kill_on_bad_exit
        config.kill_wait = conf_ptr.kill_wait
        config.launch_parameters = tounicode(conf_ptr.launch_params)
        config.launch_type = tounicode(conf_ptr.launch_type)

        if conf_ptr.layouts:
            config.layouts = tounicode(conf_ptr.layouts).split(",")

        if conf_ptr.licenses:
            licenses_dict = {}
            licenses_list = tounicode(conf_ptr.licenses).split(",")

            for lic in licenses_list:
                name, count = lic.split(":")
                licenses_dict[name] = count

            config.licenses = licenses_dict

        if conf_ptr.licenses_used:
            licenses_used_dict = {}
            licenses_used_list = tounicode(conf_ptr.licenses_used).split(",")

            for lic in licenses_used_list:
                name, count = lic.split(":")
                used, total = count.split("/")
                licenses_used_dict[name] = {"used": used, "total": total}

            config.licenses_used = licenses_used_dict

        if conf_ptr.log_fmt == LOG_FMT_ISO8601_MS:
            config.log_time_format = "iso8601_ms"
        elif conf_ptr.log_fmt == LOG_FMT_ISO8601:
            config.log_time_format = "iso8601"
        elif conf_ptr.log_fmt == LOG_FMT_RFC5424_MS:
            config.log_time_format = "rfc5424_ms"
        elif conf_ptr.log_fmt == LOG_FMT_RFC5424:
            config.log_time_format = "rfc5424"
        elif conf_ptr.log_fmt == LOG_FMT_CLOCK:
            config.log_time_format = "clock"
        elif conf_ptr.log_fmt == LOG_FMT_SHORT:
            config.log_time_format = "short"
        elif conf_ptr.log_fmt == LOG_FMT_THREAD_ID:
            config.log_time_format = "thread_id"

        config.mail_domain = tounicode(conf_ptr.mail_domain)
        config.mail_prog = tounicode(conf_ptr.mail_prog)
        config.max_array_size = conf_ptr.max_array_sz
        config.max_job_count = conf_ptr.max_job_cnt
        config.max_job_id = conf_ptr.max_job_id
        config.max_mem_per_cpu = conf_ptr.max_mem_per_cpu
        config.max_step_count = conf_ptr.max_step_cnt
        config.max_tasks_per_node = conf_ptr.max_tasks_per_node
        config.mcs_plugin = tounicode(conf_ptr.mcs_plugin)

        if conf_ptr.mcs_plugin_params:
            config.mcs_parameters = tounicode(conf_ptr.mcs_plugin_params).split(",")

        if conf_ptr.mem_limit_enforce:
            config.mem_limit_enforce = True
        else:
            config.mem_limit_enforce = False

        config.message_timeout = conf_ptr.msg_timeout
        config.min_job_age = conf_ptr.min_job_age
        config.mpi_default = tounicode(conf_ptr.mpi_default)

        if conf_ptr.mpi_params:
            config.mpi_params = tounicode(conf_ptr.mpi_params).split(",")

        if conf_ptr.msg_aggr_params:
            config.msg_aggregation_params = tounicode(conf_ptr.msg_aggr_params).split(",")

        if cluster_flags & CLUSTER_FLAG_MULTSD:
            config.multiple_slurmd = True
        else:
            config.multiple_slurmd = False

        config.next_job_id = conf_ptr.next_job_id

        if conf_ptr.node_features_plugins:
            config.node_features_plugins = tounicode(
                conf_ptr.node_features_plugins
            ).split(",")

        config.over_time_limit = conf_ptr.over_time_limit
        config.plugin_dir = tounicode(conf_ptr.plugindir)
        config.plug_stack_config = tounicode(conf_ptr.plugstack)

        if conf_ptr.power_parameters:
            config.power_parameters = tounicode(conf_ptr.power_parameters).split(",")

        config.power_plugin = tounicode(conf_ptr.power_plugin)
        config.preempt_mode = tounicode(slurm_preempt_mode_string(conf_ptr.preempt_mode))
        config.preempt_type = tounicode(conf_ptr.preempt_type)

        if conf_ptr.priority_params:
            config.priority_parameters = tounicode(conf_ptr.priority_params).split(",")

        if tounicode(conf_ptr.priority_type) == "priority/basic":
            config.priority_type = tounicode(conf_ptr.priority_type)
        else:
            config.priority_decay_half_life = conf_ptr.priority_decay_hl
            slurm_secs2time_str(<time_t>conf_ptr.priority_decay_hl,
                tmp_str, sizeof(tmp_str)
            )
            config.priority_decay_half_life_str = tounicode(tmp_str)

            config.priority_calc_period = conf_ptr.priority_calc_period
            slurm_secs2time_str(<time_t>conf_ptr.priority_calc_period,
                tmp_str, sizeof(tmp_str)
            )
            config.priority_calc_period_str = tounicode(tmp_str)

            if conf_ptr.priority_favor_small:
                config.priority_favor_small = True
            else:
                config.priority_favor_small = False

            config.priority_flags = conf_ptr.priority_flags

            if conf_ptr.priority_flags:
                config.priority_flags_list = priority_flags_list(conf_ptr.priority_flags)

            config.priority_max_age = conf_ptr.priority_max_age
            slurm_secs2time_str(<time_t>conf_ptr.priority_max_age,
                tmp_str, sizeof(tmp_str)
            )
            config.priority_max_age_str = tounicode(tmp_str)

            config.priority_usage_reset_period = conf_ptr.priority_reset_period
            config.priority_usage_reset_period_str = (
                reset_period_str(conf_ptr.priority_reset_period)
            )

            config.priority_type = tounicode(conf_ptr.priority_type)
            config.priority_weight_age = conf_ptr.priority_weight_age
            config.priority_weight_fair_share = conf_ptr.priority_weight_fs
            config.priority_weight_job_size = conf_ptr.priority_weight_js
            config.priority_weight_partition = conf_ptr.priority_weight_part
            config.priority_weight_qos = conf_ptr.priority_weight_qos
            config.priority_weight_tres = tounicode(conf_ptr.priority_weight_tres)

        slurm_private_data_string(conf_ptr.private_data, tmp_str, sizeof(tmp_str))
        config.private_data = tounicode(tmp_str)
        config.proctrack_type = tounicode(conf_ptr.proctrack_type)
        config.prolog = tounicode(conf_ptr.prolog)
        config.prolog_epilog_timeout = conf_ptr.prolog_epilog_timeout
        config.prolog_slurmctld = tounicode(conf_ptr.prolog_slurmctld)
        config.prolog_flags = prolog_flags2str(conf_ptr.prolog_flags)
        config.propagate_prio_process = conf_ptr.propagate_prio_process
        config.propagate_resource_limits = tounicode(conf_ptr.propagate_rlimits)

        config.propagate_resource_limits_except = tounicode(
            conf_ptr.propagate_rlimits_except
        )

        config.reboot_program = tounicode(conf_ptr.reboot_program)
        config.reconfig_flags = reconfig_flags2str(conf_ptr.reconfig_flags)
        config.requeue_exit = tounicode(conf_ptr.requeue_exit)
        config.requeue_exit_hold = tounicode(conf_ptr.requeue_exit_hold)
        config.resume_fail_program = tounicode(conf_ptr.resume_fail_program)
        config.resume_program = tounicode(conf_ptr.resume_program)
        config.resume_rate = conf_ptr.resume_rate
        config.resume_timeout = conf_ptr.resume_timeout
        config.resv_epilog = tounicode(conf_ptr.resv_epilog)
        config.resv_over_run = conf_ptr.resv_over_run
        config.resv_prolog = tounicode(conf_ptr.resv_prolog)
        config.return_to_service = conf_ptr.ret2service
        config.route_plugin = tounicode(conf_ptr.route_plugin)
        config.salloc_default_command = tounicode(conf_ptr.salloc_default_command)

        if conf_ptr.sbcast_parameters:
            config.sbcast_parameters = tounicode(conf_ptr.sbcast_parameters).split(",")

        if conf_ptr.sched_params:
            config.scheduler_parameters = tounicode(conf_ptr.sched_params).split(",")

        config.scheduler_time_slice = conf_ptr.sched_time_slice
        config.scheduler_type = tounicode(conf_ptr.schedtype)
        config.select_type = tounicode(conf_ptr.select_type)

        if conf_ptr.select_type_param:
            config.select_type_parameters = select_type_param_string(
                conf_ptr.select_type_param
            )

        config.slurm_user_id = conf_ptr.slurm_user_id
        config.slurm_user_name = tounicode(conf_ptr.slurm_user_name)
        config.slurmctld_addr = tounicode(conf_ptr.slurmctld_addr)
        config.slurmctld_debug = log_num2string(conf_ptr.slurmctld_debug)

        slurmctld_host_dict = {}
        for i in range(conf_ptr.control_cnt):
            slurmctld_host_dict[i] = {
                "control_machine": conf_ptr.control_machine[i],
                "control_addr": conf_ptr.control_addr[i],
            }
        config.slurmctld_host = slurmctld_host_dict 
        config.slurmctld_log_file = tounicode(conf_ptr.slurmctld_logfile)
        config.slurmctld_port = conf_ptr.slurmctld_port
        config.slurmctld_port_count = conf_ptr.slurmctld_port_count
        config.slurmctld_syslog_debug = log_num2string(conf_ptr.slurmctld_syslog_debug)
        config.slurmctld_primary_off_prog = tounicode(conf_ptr.slurmctld_primary_off_prog)
        config.slurmctld_primary_on_prog = tounicode(conf_ptr.slurmctld_primary_on_prog)
        config.slurmctld_timeout = conf_ptr.slurmctld_timeout

        if conf_ptr.slurmctld_params:
            config.slurmctld_parameters = tounicode(conf_ptr.slurmctld_params).split(",")

        config.slurmd_debug = log_num2string(conf_ptr.slurmd_debug)
        config.slurmd_log_file = tounicode(conf_ptr.slurmd_logfile)

        if conf_ptr.slurmd_params:
            config.slurmd_parameters = tounicode(conf_ptr.slurmd_params).split(",")

        config.slurmd_pid_file = tounicode(conf_ptr.slurmd_pidfile)
        config.slurmd_port = conf_ptr.slurmd_port
        config.slurmd_spool_dir = tounicode(conf_ptr.slurmd_spooldir)
        config.slurmd_syslog_debug = log_num2string(conf_ptr.slurmd_syslog_debug)
        config.slurmd_timeout = conf_ptr.slurmd_timeout
        config.slurmd_user_id = conf_ptr.slurmd_user_id
        config.slurmd_user_name = tounicode(conf_ptr.slurmd_user_name)
        config.slurm_sched_log_file = tounicode(conf_ptr.sched_logfile)
        config.slurm_sched_log_level = conf_ptr.sched_log_level
        config.slurmctld_pid_file = tounicode(conf_ptr.slurmctld_pidfile)
        config.slurmctld_plugstack = tounicode(conf_ptr.slurmctld_plugstack)
        config.slurm_conf = tounicode(conf_ptr.slurm_conf)
        config.slurm_version = tounicode(conf_ptr.version)
        config.srun_epilog = tounicode(conf_ptr.srun_epilog)
        config.srun_port_range = conf_ptr.srun_port_range
        config.srun_prolog = tounicode(conf_ptr.srun_prolog)
        config.state_save_location = tounicode(conf_ptr.state_save_location)
        config.suspend_exc_nodes = tounicode(conf_ptr.suspend_exc_nodes)
        config.suspend_exc_parts = tounicode(conf_ptr.suspend_exc_parts)
        config.suspend_program = tounicode(conf_ptr.suspend_program)
        config.suspend_rate = conf_ptr.suspend_rate
        config.suspend_time = conf_ptr.suspend_time
        config.suspend_timeout = conf_ptr.suspend_timeout
        config.switch_type = tounicode(conf_ptr.switch_type)
        config.task_epilog = tounicode(conf_ptr.task_epilog)
        config.task_plugin = tounicode(conf_ptr.task_plugin)

        config.task_plugin_param = slurm_sprint_cpu_bind_type(
            <cpu_bind_type_t>conf_ptr.task_plugin_param
        )

        config.task_prolog = tounicode(conf_ptr.task_prolog)
        config.tmp_fs = tounicode(conf_ptr.tmp_fs)
        config.topology_param = tounicode(conf_ptr.topology_param)
        config.topology_plugin = tounicode(conf_ptr.topology_plugin)

        if conf_ptr.track_wckey:
            config.track_wc_key = True
        else:
            config.track_wc_key = False

        config.tree_width = conf_ptr.tree_width
        config.use_pam = conf_ptr.use_pam
        config.unkillable_step_program = tounicode(conf_ptr.unkillable_program)
        config.unkillable_step_timeout = conf_ptr.unkillable_timeout
        config.v_size_factor = conf_ptr.vsize_factor
        config.wait_time = conf_ptr.wait_time

        if conf_ptr.x11_params:
            config.x11_parameters = tounicode(conf_ptr.x11_params).split(",")

        slurm_free_ctl_conf(conf_ptr)
        conf_ptr = NULL
        return config
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


def api_version():
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


def print_ctl_conf():
    """
    Print Slurm error information to standard output

    Args:
        msg (str): error message string
    Returns:
        None
    """
    cdef:
        slurm_ctl_conf_t *conf_ptr = NULL
        int rc

    rc = slurm_load_ctl_conf(<time_t>NULL, &conf_ptr)

    if rc == SLURM_SUCCESS:
        slurm_print_ctl_conf(stdout, conf_ptr)
        slurm_free_ctl_conf(conf_ptr)
        conf_ptr = NULL
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


def write_config():
    #TODO
    raise PySlurmError("Not yet implemented", 1)


cdef cpu_freq_to_string(char *buf, int buf_size, uint32_t cpu_freq):
    """
    Convert a cpu_freq number to its equivalent string.

    Args:
        cpu_freq (int): cpu frequency
    Returns:
        Slurm equivalent cpu frequency string
    """
    if cpu_freq == CPU_FREQ_LOW:
        return "Low"
    elif cpu_freq == CPU_FREQ_MEDIUM:
        return "Medium"
    elif cpu_freq == CPU_FREQ_HIGHM1:
        return "Highm1"
    elif cpu_freq == CPU_FREQ_HIGH:
        return "High"
    elif cpu_freq == CPU_FREQ_CONSERVATIVE:
        return "Conservative"
    elif cpu_freq == CPU_FREQ_PERFORMANCE:
        return "Performance"
    elif cpu_freq == CPU_FREQ_POWERSAVE:
        return "PowerSave"
    elif cpu_freq == CPU_FREQ_USERSPACE:
        return "UserSpace"
    elif cpu_freq == CPU_FREQ_ONDEMAND:
        return "OnDemand"
    elif (cpu_freq & CPU_FREQ_RANGE_FLAG):
        return "Unknown"
    elif fuzzy_equal(cpu_freq, NO_VAL):
        return ""
    else:
        slurm_convert_num_unit2(<double>cpu_freq, buf, buf_size, UNIT_KILO, NO_VAL, 1000, 0)
        return tounicode(buf)


cdef health_check_node_state_list(uint32_t node_state):
    """Convert HealthCheckNodeState numeric value to string."""
    nslist = []
    if (node_state & HEALTH_CHECK_CYCLE):
        nslist.append("CYCLE")

    if (node_state & HEALTH_CHECK_NODE_ANY) == HEALTH_CHECK_NODE_ANY:
        nslist.append("ANY")
        return nslist

    if (node_state & HEALTH_CHECK_NODE_IDLE):
        nslist.append("IDLE")

    if (node_state & HEALTH_CHECK_NODE_ALLOC):
        nslist.append("ALLOC")

    if (node_state & HEALTH_CHECK_NODE_MIXED):
        nslist.append("MIXED")

    return nslist


cdef priority_flags_list(uint16_t priority_flags):
    pflist = []
    if (priority_flags & PRIORITY_FLAGS_ACCRUE_ALWAYS):
        pflist.append("ACCRUE_ALWAYS")
    if (priority_flags & PRIORITY_FLAGS_SIZE_RELATIVE):
        pflist.append("SMALL_RELATIVE_TO_TIME")
    if (priority_flags & PRIORITY_FLAGS_CALCULATE_RUNNING):
        pflist.append("CALCULATE_RUNNING")
    if (priority_flags & PRIORITY_FLAGS_DEPTH_OBLIVIOUS):
        pflist.append("DEPTH_OBLIVIOUS")
    if (priority_flags & PRIORITY_FLAGS_FAIR_TREE):
        pflist.append("FAIR_TREE")
    if (priority_flags & PRIORITY_FLAGS_INCR_ONLY):
        pflist.append("INCR_ONLY")
    if (priority_flags & PRIORITY_FLAGS_MAX_TRES):
        pflist.append("MAX_TRES")
    return pflist


cdef reset_period_str(uint16_t reset_period):
    if reset_period == PRIORITY_RESET_NONE:
        return "NONE"
    elif reset_period == PRIORITY_RESET_NOW:
        return "NOW"
    elif reset_period == PRIORITY_RESET_DAILY:
        return "DAILY"
    elif reset_period == PRIORITY_RESET_WEEKLY:
        return "WEEKLY"
    elif reset_period == PRIORITY_RESET_MONTHLY:
        return "MONTHLY"
    elif reset_period == PRIORITY_RESET_QUARTERLY:
        return "QUARTERLY"
    elif reset_period == PRIORITY_RESET_YEARLY:
        return "YEARLY"
    else:
        return "UNKNOWN"

cdef prolog_flags2str(uint16_t prolog_flags):
    pflist = []
    if (prolog_flags & PROLOG_FLAG_ALLOC):
        pflist.append("Alloc")
    if (prolog_flags & PROLOG_FLAG_CONTAIN):
        pflist.append("Contain")
    if (prolog_flags & PROLOG_FLAG_NOHOLD):
        pflist.append("NoHold")
    if (prolog_flags & PROLOG_FLAG_SERIAL):
        pflist.append("Serial")
    if (prolog_flags & PROLOG_FLAG_X11):
        pflist.append("X11")
    return pflist

cdef reconfig_flags2str(uint16_t reconfig_flags):
    rflist = []
    if (reconfig_flags & RECONFIG_KEEP_PART_INFO):
        rflist.append("KeepPartInfo")
    if (reconfig_flags & RECONFIG_KEEP_PART_STAT):
        rflist.append("KeepPartState")
    return rflist


cdef log_num2string(uint16_t inx):
    if inx == 0:
        return "quiet"
    if inx == 1:
        return "fatal"
    if inx == 2:
        return "error"
    if inx == 3:
        return "info"
    if inx == 4:
        return "verbose"
    if inx == 5:
        return "debug"
    if inx == 6:
        return "debug2"
    if inx == 7:
        return "debug3"
    if inx == 8:
        return "debug4"
    if inx == 9:
        return "debug5"
    return "unknown"


cdef cpu_freq_govlist_to_list(uint32_t govs):
    """
    Convert a composite cpu governor enum to its equivalent list.

    Args:
        govs (int): composite enum of governors
    Returns:
        Slurm equivalient cpu governor list
    """
    govlist = []

    if (govs & CPU_FREQ_CONSERVATIVE) == CPU_FREQ_CONSERVATIVE:
        govlist.append("Conservative")
    if (govs & CPU_FREQ_PERFORMANCE) == CPU_FREQ_PERFORMANCE:
        govlist.append("Performance")
    if (govs & CPU_FREQ_POWERSAVE) == CPU_FREQ_POWERSAVE:
        govlist.append("PowerSave")
    if (govs & CPU_FREQ_ONDEMAND) == CPU_FREQ_ONDEMAND:
        govlist.append("OnDemand")
    if (govs & CPU_FREQ_USERSPACE) == CPU_FREQ_USERSPACE:
        govlist.append("UserSpace")

    return govlist


cdef debug_flags2list(uint64_t debug_flags):
    """
    Convert a DebugFlags uint64_t to the equivalent list.

    Args:
        debug_flags (int): DebugFlags uint64_t
    Returns:
        Slurm equivalent Debug Flags list
    """
    dflist = []

    if (debug_flags & DEBUG_FLAG_BACKFILL):
        dflist.append("Backfill")
    if (debug_flags & DEBUG_FLAG_BACKFILL_MAP):
        dflist.append("BackfillMap")
    if (debug_flags & DEBUG_FLAG_BG_ALGO):
        dflist.append("BGBlockAlgo")
    if (debug_flags & DEBUG_FLAG_BG_ALGO_DEEP):
        dflist.append("BGBlockAlgoDeep")
    if (debug_flags & DEBUG_FLAG_BG_PICK):
        dflist.append("BGBlockPick")
    if (debug_flags & DEBUG_FLAG_BG_WIRES):
        dflist.append("BGBlockWires")
    if (debug_flags & DEBUG_FLAG_BURST_BUF):
        dflist.append("BurstBuffer")
    if (debug_flags & DEBUG_FLAG_CPU_FREQ):
        dflist.append("CpuFrequency")
    if (debug_flags & DEBUG_FLAG_CPU_BIND):
        dflist.append("Cpu_Bind")
    if (debug_flags & DEBUG_FLAG_DB_ARCHIVE):
        dflist.append("DB_Archive")
    if (debug_flags & DEBUG_FLAG_DB_ASSOC):
        dflist.append("DB_Assoc")
    if (debug_flags & DEBUG_FLAG_DB_TRES):
        dflist.append("DB_TRES")
    if (debug_flags & DEBUG_FLAG_DB_EVENT):
        dflist.append("DB_Event")
    if (debug_flags & DEBUG_FLAG_DB_JOB):
        dflist.append("DB_Job")
    if (debug_flags & DEBUG_FLAG_DB_QOS):
        dflist.append("DB_QOS")
    if (debug_flags & DEBUG_FLAG_DB_QUERY):
        dflist.append("DB_Query")
    if (debug_flags & DEBUG_FLAG_DB_RESV):
        dflist.append("DB_Reservation")
    if (debug_flags & DEBUG_FLAG_DB_RES):
        dflist.append("DB_Resource")
    if (debug_flags & DEBUG_FLAG_DB_STEP):
        dflist.append("DB_Step")
    if (debug_flags & DEBUG_FLAG_DB_USAGE):
        dflist.append("DB_Usage")
    if (debug_flags & DEBUG_FLAG_DB_WCKEY):
        dflist.append("DB_WCKey")
    if (debug_flags & DEBUG_FLAG_ESEARCH):
        dflist.append("Elasticsearch")
    if (debug_flags & DEBUG_FLAG_ENERGY):
        dflist.append("Energy")
    if (debug_flags & DEBUG_FLAG_EXT_SENSORS):
        dflist.append("ExtSensors")
    if (debug_flags & DEBUG_FLAG_FILESYSTEM):
        dflist.append("Filesystem")
    if (debug_flags & DEBUG_FLAG_FEDR):
        dflist.append("Federation")
    if (debug_flags & DEBUG_FLAG_FRONT_END):
        dflist.append("FrontEnd")
    if (debug_flags & DEBUG_FLAG_GANG):
        dflist.append("Gang")
    if (debug_flags & DEBUG_FLAG_GRES):
        dflist.append("Gres")
    if (debug_flags & DEBUG_FLAG_HETERO_JOBS):
        dflist.append("HeteroJobs")
    if (debug_flags & DEBUG_FLAG_INTERCONNECT):
        dflist.append("Interconnect")
    if (debug_flags & DEBUG_FLAG_JOB_CONT):
        dflist.append("JobContainer")
    if (debug_flags & DEBUG_FLAG_NODE_FEATURES):
        dflist.append("NodeFeatures")
    if (debug_flags & DEBUG_FLAG_LICENSE):
        dflist.append("License")
    if (debug_flags & DEBUG_FLAG_NO_CONF_HASH):
        dflist.append("NO_CONF_HASH")
    if (debug_flags & DEBUG_FLAG_NO_REALTIME):
        dflist.append("NoRealTime")
    if (debug_flags & DEBUG_FLAG_POWER):
        dflist.append("Power")
    if (debug_flags & DEBUG_FLAG_PRIO):
        dflist.append("Priority")
    if (debug_flags & DEBUG_FLAG_PROFILE):
        dflist.append("Profile")
    if (debug_flags & DEBUG_FLAG_PROTOCOL):
        dflist.append("Protocol")
    if (debug_flags & DEBUG_FLAG_RESERVATION):
        dflist.append("Reservation")
    if (debug_flags & DEBUG_FLAG_ROUTE):
        dflist.append("Route")
    if (debug_flags & DEBUG_FLAG_SELECT_TYPE):
        dflist.append("SelectType")
    if (debug_flags & DEBUG_FLAG_STEPS):
        dflist.append("Steps")
    if (debug_flags & DEBUG_FLAG_SWITCH):
        dflist.append("Switch")
    if (debug_flags & DEBUG_FLAG_TASK):
        dflist.append("Task")
    if (debug_flags & DEBUG_FLAG_TIME_CRAY):
        dflist.append("TimeCray")
    if (debug_flags & DEBUG_FLAG_TRACE_JOBS):
        dflist.append("TraceJobs")
    if (debug_flags & DEBUG_FLAG_TRIGGERS):
        dflist.append("Triggers")

    return dflist
