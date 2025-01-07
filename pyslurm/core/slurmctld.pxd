#########################################################################
# slurmctld.pxd - pyslurm slurmctld api
#########################################################################
# Copyright (C) 2025 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# This file is part of PySlurm
#
# PySlurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# PySlurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PySlurm; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3

from pyslurm cimport slurm
from pyslurm.slurm cimport (
    slurm_conf_t,
    slurm_load_ctl_conf,
    slurm_free_ctl_conf,
    slurm_preempt_mode_string,
    slurm_accounting_enforce_string,
    slurm_sprint_cpu_bind_type,
    slurm_ctl_conf_2_key_pairs,
    slurm_reconfigure,
    slurm_shutdown,
    slurm_ping,
    slurm_takeover,
    ping_all_controllers,
    controller_ping_t,
    cpu_bind_type_t,
    try_xmalloc,
    list_t,
    xfree,
)
from pyslurm.utils cimport cstr
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t, int64_t
from pyslurm.utils.uint cimport (
    u16_parse,
    u32_parse,
    u64_parse,
    u16_parse_bool,
)

from pyslurm.db.util cimport (
    SlurmList,
    SlurmListItem,
)


cdef dict _parse_config_key_pairs(void *ptr, owned=*)


ctypedef struct config_key_pair_t:
    char *name
    char *value


cdef class PingResponse:
    """Slurm Controller Ping response information"""

    cdef public:
        is_primary
        is_responding
        index
        hostname
        latency


cdef class Config:
    cdef slurm_conf_t *ptr

    cdef public:
        CgroupConfig cgroup_config
        AccountingGatherConfig accounting_gather_config
        MPIConfig mpi_config


cdef class MPIConfig:
    """Slurm MPI Config (mpi.conf)"""

    cdef public:
        pmix_cli_tmp_dir_base
        pmix_coll_fence
        pmix_debug
        pmix_direct_conn
        pmix_direct_conn_early
        pmix_direct_conn_ucx
        pmix_direct_same_arch
        pmix_environment
        pmix_fence_barrier
        pmix_net_devices_ucx
        pmix_timeout
        pmix_tls_ucx

    @staticmethod
    cdef MPIConfig from_ptr(void *ptr)

cdef class CgroupConfig:
    """Slurm Cgroup Config (cgroup.conf)"""

    cdef public:
        mountpoint
        plugin
        systemd_timeout
        ignore_systemd
        ignore_systemd_on_failure
        enable_controllers

        allowed_ram_space
        allowed_swap_space
        constrain_cores
        constrain_devices
        constrain_ram_space
        constrain_swap_space
        max_ram_percent
        max_swap_percent
        memory_swappiness
        min_ram_space

        signal_children_processes

    @staticmethod
    cdef CgroupConfig from_ptr(void *ptr)


cdef class AccountingGatherConfig:
    """Slurm Accounting Gather Config (acct_gather.conf)"""

    cdef public:
        energy_ipmi_frequency
        energy_ipmi_calc_adjustment
        energy_ipmi_power_sensors
        energy_ipmi_user_name
        energy_ipmi_password
        energy_ipmi_timeout

        profile_hdf5_dir
        profile_hdf5_default

        profile_influxdb_database
        profile_influxdb_default
        profile_influxdb_host
        profile_influxdb_password
        profile_influxdb_rtpolicy
        profile_influxdb_user
        profile_influxdb_timeout

        infiniband_ofed_port

        sysfs_interfaces

    @staticmethod
    cdef AccountingGatherConfig from_ptr(void *ptr)
