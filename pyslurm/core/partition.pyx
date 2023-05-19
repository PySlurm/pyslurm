#########################################################################
# partition.pyx - interface to work with partitions in slurm
#########################################################################
# Copyright (C) 2023 Toni Harzendorf <toni.harzendorf@gmail.com>
# Copyright (C) 2023 PySlurm Developers
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

from typing import Union
from pyslurm.utils import cstr
from pyslurm.utils import ctime
from pyslurm.utils.uint import *
from pyslurm.core.error import RPCError, verify_rpc
from pyslurm.utils.ctime import timestamp_to_date, _raw_time
from pyslurm.utils.helpers import (
    uid_to_name,
    gid_to_name,
    _getgrall_to_dict,
    _getpwall_to_dict,
    cpubind_to_num,
    instance_to_dict,
    _sum_prop,
    dehumanize,
)
from pyslurm.utils.ctime import (
    timestr_to_mins,
    timestr_to_secs,
)


cdef class Partitions(dict):
    def __dealloc__(self):
        slurm_free_partition_info_msg(self.info)

    def __cinit__(self):
        self.info = NULL

    @staticmethod
    def load(preload_passwd_info=False):
        """Load all Partitions in the system.

        Args:
            preload_passwd_info (bool): 
                Decides whether to query passwd and groups information from
                the system.
                If True, the information will fetched and stored in each of
                the Node instances. The default is False.

        Returns:
            (pyslurm.Partitions): Collection of Partition objects.

        Raises:
            RPCError: When getting all the Partitions from the slurmctld
                failed.
            MemoryError: If malloc fails to allocate memory.
        """
        cdef:
            dict passwd = {}
            dict groups = {}
            Partitions partitions = Partitions.__new__(Partitions)
            int flags = slurm.SHOW_ALL
            Partition partition
            slurmctld.Config slurm_conf
            int power_save_enabled = 0

        verify_rpc(slurm_load_partitions(0, &partitions.info, flags))
        slurm_conf = slurmctld.Config.load()

        # If requested, preload the passwd and groups database to potentially
        # speedup lookups for an attribute.
        if preload_passwd_info:
            passwd = _getpwall_to_dict()
            groups = _getgrall_to_dict()

        # zero-out a dummy partition_info_t
        memset(&partitions.tmp_info, 0, sizeof(partition_info_t))

        if slurm_conf.suspend_program and slurm_conf.resume_program:
            power_save_enabled = 1

        # Put each pointer into its own instance.
        for cnt in range(partitions.info.record_count):
            partition = Partition.from_ptr(&partitions.info.partition_array[cnt])

            # Prevent double free if xmalloc fails mid-loop and a MemoryError
            # is raised by replacing it with a zeroed-out partition_info_t.
            partitions.info.partition_array[cnt] = partitions.tmp_info

            if preload_passwd_info:
                partition.passwd = passwd
                partition.groups = groups

            partition.power_save_enabled = power_save_enabled
            partition.slurm_conf = slurm_conf
            partitions[partition.name] = partition

        # At this point we memcpy'd all the memory for the Partitions. Setting
        # this to 0 will prevent the slurm partition free function to
        # deallocate the memory for the individual partitions. This should be
        # fine, because they are free'd automatically in __dealloc__ since the
        # lifetime of each partition-pointer is tied to the lifetime of its
        # corresponding "Partition" instance.
        partitions.info.record_count = 0

        return partitions
    

cdef class Partition:

    def __cinit__(self):
        self.ptr = NULL
#        self.umsg = NULL

    def __init__(self, name=None, **kwargs):
        self._alloc_impl()
        self.name = name
        for k, v in kwargs.items():
            setattr(self, k, v)

    def _alloc_impl(self):
        self._alloc_info()
#        self._alloc_umsg()

    def _alloc_info(self):
        if not self.ptr:
            self.ptr = <partition_info_t*>try_xmalloc(sizeof(partition_info_t))
            if not self.ptr:
                raise MemoryError("xmalloc failed for partition_info_t")

#   def _alloc_umsg(self):
#       if not self.umsg:
#           self.umsg = <update_part_msg_t*>try_xmalloc(sizeof(update_part_msg_t))
#           if not self.umsg:
#               raise MemoryError("xmalloc failed for update_part_msg_t")
#           slurm_init_part_desc_msg(self.umsg)

    def _dealloc_impl(self):
        slurm_free_partition_info_members(self.ptr)
        xfree(self.ptr)

    def __dealloc__(self):
        self._dealloc_impl() 

    @staticmethod
    cdef Partition from_ptr(partition_info_t *in_ptr):
        cdef Partition wrap = Partition.__new__(Partition)
        wrap._alloc_info()
        wrap.passwd = {}
        wrap.groups = {}
        memcpy(wrap.ptr, in_ptr, sizeof(partition_info_t))
        return wrap

    def as_dict(self):
        """Partition information formatted as a dictionary.

        Returns:
            (dict): Partition information as dict

        Examples:
            >>> import pyslurm
            >>> mypart = pyslurm.Partition.load("mypart")
            >>> mypart_dict = mypart.as_dict()
        """
        return instance_to_dict(self)

    @property
    def name(self):
        return cstr.to_unicode(self.ptr.name)

    @name.setter
    def name(self, val):
        cstr.fmalloc(&self.ptr.name, val)

    @property
    def allowed_allocating_nodes(self):
        return cstr.to_list(self.ptr.allow_alloc_nodes, ["ALL"])

    @allowed_allocating_nodes.setter
    def allowed_allocating_nodes(self, val):
        cstr.from_list(&self.ptr.allow_alloc_nodes, val)

    @property
    def allowed_accounts(self):
        return cstr.to_list(self.ptr.allow_accounts, ["ALL"])

    @allowed_accounts.setter
    def allowed_accounts(self, val):
        cstr.from_list(&self.ptr.allow_accounts, val)

    @property
    def allowed_groups(self):
        return cstr.to_list(self.ptr.allow_groups, ["ALL"])

    @allowed_groups.setter
    def allowed_groups(self, val):
        cstr.from_list(&self.ptr.allow_groups, val)

    @property
    def allowed_qos(self):
        return cstr.to_list(self.ptr.allow_qos, ["ALL"])

    @allowed_qos.setter
    def allowed_qos(self, val):
        cstr.from_list(&self.ptr.allow_qos, val)

    @property
    def alternate(self):
        return cstr.to_unicode(self.ptr.alternate)

    @alternate.setter
    def alternate(self, val):
        cstr.fmalloc(&self.ptr.alternate, val)

    @property
    def select_types(self):
        return _select_type_int_to_list(self.ptr.cr_type)

    @property
    def cpu_binding(self):
        cdef char cpu_bind[128]
        slurm_sprint_cpu_bind_type(cpu_bind,
                                   <cpu_bind_type_t>self.ptr.cpu_bind)
        if cpu_bind == "(null type)":
            return None

        return cstr.to_unicode(cpu_bind)

    @cpu_binding.setter
    def cpu_binding(self, val):
        self.ptr.cpu_bind = cpubind_to_num(val)

    @property
    def default_memory_per_cpu(self):
        if self.ptr.def_mem_per_cpu != slurm.NO_VAL64:
            if self.ptr.def_mem_per_cpu & slurm.MEM_PER_CPU:
                mem = self.ptr.def_mem_per_cpu & (~slurm.MEM_PER_CPU)
                return u64_parse(mem)
        else:
            return None

    @default_memory_per_cpu.setter
    def default_memory_per_cpu(self, val):
        self.ptr.def_mem_per_cpu = u64(dehumanize(val))
        self.ptr.def_mem_per_cpu |= slurm.MEM_PER_CPU

    @property
    def default_memory_per_node(self):
        if self.ptr.def_mem_per_cpu != slurm.NO_VAL64:
            if not self.ptr.def_mem_per_cpu & slurm.MEM_PER_CPU:
                return u64_parse(self.ptr.def_mem_per_cpu)
        else:
            return None

    @default_memory_per_node.setter
    def default_memory_per_node(self, val):
        self.ptr.def_mem_per_cpu = u64(dehumanize(val))

    @property
    def max_memory_per_cpu(self):
        if self.ptr.max_mem_per_cpu != slurm.NO_VAL64:
            if self.ptr.max_mem_per_cpu & slurm.MEM_PER_CPU:
                mem = self.ptr.max_mem_per_cpu & (~slurm.MEM_PER_CPU)
                return u64_parse(mem)
        else:
            return None

    @max_memory_per_cpu.setter
    def max_memory_per_cpu(self, val):
        self.ptr.max_mem_per_cpu = u64(dehumanize(val))
        self.ptr.max_mem_per_cpu |= slurm.MEM_PER_CPU

    @property
    def max_memory_per_node(self):
        # TODO: handle unlimited?
        if self.ptr.max_mem_per_cpu != slurm.NO_VAL64:
            if not self.ptr.max_mem_per_cpu & slurm.MEM_PER_CPU:
                return u64_parse(self.ptr.max_mem_per_cpu)
        else:
            return None

    @max_memory_per_node.setter
    def max_memory_per_node(self, val):
        self.ptr.max_mem_per_cpu = u64(dehumanize(val))

    @property
    def default_time(self):
        return _raw_time(self.ptr.default_time)

    @default_time.setter
    def default_time(self, val):
        self.ptr.default_time = timestr_to_mins(val)

    @property
    def denied_qos(self):
        return cstr.to_list(self.ptr.deny_qos, ["ALL"])

    @denied_qos.setter
    def denied_qos(self, val):
        cstr.from_list(&self.ptr.deny_qos, val)

    @property
    def denied_accounts(self):
        return cstr.to_list(self.ptr.deny_accounts, ["ALL"])

    @denied_accounts.setter
    def denied_accounts(self, val):
        cstr.from_list(&self.ptr.deny_accounts, val)

    @property
    def grace_time(self):
        return _raw_time(self.ptr.grace_time)

    @grace_time.setter
    def grace_time(self, val):
        self.ptr.grace_time = timestr_to_secs(val)

    @property
    def default_cpus_per_gpu(self):
        # TODO: parse List job_defaults_list
        return None

    @default_cpus_per_gpu.setter
    def default_cpus_per_gpu(self, val):
        # TODO
        pass

    @property
    def default_memory_per_gpu(self):
        # TODO: parse List job_defaults_list
        return None

    @default_memory_per_gpu.setter
    def default_memory_per_gpu(self, val):
        # TODO
        pass

    @property
    def max_cpus_per_node(self):
        # how to handle infinite?
        return u32_parse(self.ptr.max_cpus_per_node)

    @max_cpus_per_node.setter
    def max_cpus_per_node(self, val):
        self.ptr.max_cpus_per_node = u32(val)

    @property
    def max_cpus_per_socket(self):
        # how to handle infinite?
        return u32_parse(self.ptr.max_cpus_per_socket)

    @max_cpus_per_socket.setter
    def max_cpus_per_socket(self, val):
        self.ptr.max_cpus_per_socket = u32(val)

    @property
    def max_nodes(self):
        return u32_parse(self.ptr.max_nodes)

    @max_nodes.setter
    def max_nodes(self, val):
        self.ptr.max_nodes = u32(val)

    @property
    def min_nodes(self):
        return u32_parse(self.ptr.min_nodes)

    @min_nodes.setter
    def min_nodes(self, val):
        self.ptr.min_nodes = u32(val)

    @property
    def max_time_limit(self):
        return _raw_time(self.ptr.max_time, on_inf="UNLIMITED")

    @max_time_limit.setter
    def max_time_limit(self, val):
        self.ptr.max_time = timestr_to_mins(val)

    # maybe namedtuple for this?
#   @property
#   def oversubscribe_mode(self):
#       mode, _ = _oversubscribe_mode_int_to_str(self.ptr.max_share)
#       return mode

#   @property
#   def oversubscribe_count(self):
#       _, count = _oversubscribe_mode_int_to_str(self.ptr.max_share)
#       return count

    @property
    def nodes(self):
        return cstr.to_unicode(self.ptr.nodes)

    @nodes.setter
    def nodes(self, val):
        cstr.from_list(&self.ptr.nodes, val)

    @property
    def nodesets(self):
        return cstr.to_list(self.ptr.nodesets)

    @nodesets.setter
    def nodesets(self, val):
        cstr.from_list(&self.ptr.nodesets, val)

    @property
    def over_time_limit(self):
        return u16_parse(self.ptr.over_time_limit)

    @over_time_limit.setter
    def over_time_limit(self, val):
        self.ptr.over_time_limit = u16(self.ptr.over_time_limit)

    @property
    def preempt_mode(self):
        return _preempt_mode_int_to_str(self.ptr.preempt_mode, self.slurm_conf)

    @preempt_mode.setter
    def preempt_mode(self, val):
        self.ptr.preempt_mode = _preempt_mode_str_to_int(val)

    @property
    def priority_job_factor(self):
        return u16_parse(self.ptr.priority_job_factor)

    @priority_job_factor.setter
    def priority_job_factor(self, val):
        self.ptr.priority_job_factor = u16(val)

    @property
    def priority_tier(self):
        return u16_parse(self.ptr.priority_tier)

    @priority_tier.setter
    def priority_tier(self, val):
        self.ptr.priority_tier = u16(val)

    @property
    def qos(self):
        return cstr.to_unicode(self.ptr.qos_char)

    @qos.setter
    def qos(self, val):
        cstr.fmalloc(&self.ptr.qos_char, val)

    @property
    def total_cpus(self):
        return u32_parse(self.ptr.total_cpus)

    @property
    def total_nodes(self):
        return u32_parse(self.ptr.total_nodes)

    @property
    def state(self):
        return _partition_state_int_to_str(self.ptr.state_up)

    @state.setter
    def state(self, val):
        self.ptr.state_up = _partition_state_str_to_int(val)

    @property
    def is_default(self):
        return u16_parse_bool_flag(self.ptr.flags, slurm.PART_FLAG_DEFAULT)

    @is_default.setter
    def is_default(self, val):
        u16_set_bool_flag(&self.ptr.flags, bool(val),
                          slurm.PART_FLAG_DEFAULT)

    @property
    def allow_root_jobs(self):
        return u16_parse_bool_flag(self.ptr.flags, slurm.PART_FLAG_NO_ROOT)

    @allow_root_jobs.setter
    def allow_root_jobs(self, val):
        u16_set_bool_flag(&self.ptr.flags, bool(val),
                          slurm.PART_FLAG_NO_ROOT)

    @property
    def is_user_exclusive(self):
        return u16_parse_bool_flag(self.ptr.flags,
                                   slurm.PART_FLAG_EXCLUSIVE_USER)

    @is_user_exclusive.setter
    def is_user_exclusive(self, val):
        u16_set_bool_flag(&self.ptr.flags, bool(val),
                          slurm.PART_FLAG_EXCLUSIVE_USER)
    
    @property
    def is_hidden(self):
        return u16_parse_bool_flag(self.ptr.flags, slurm.PART_FLAG_HIDDEN)

    @is_hidden.setter
    def is_hidden(self, val):
        u16_set_bool_flag(&self.ptr.flags, bool(val),
                          slurm.PART_FLAG_HIDDEN)

    @property
    def least_loaded_nodes_scheduling(self):
        return u16_parse_bool_flag(self.ptr.flags, slurm.PART_FLAG_LLN)

    @least_loaded_nodes_scheduling.setter
    def least_loaded_nodes_scheduling(self, val):
        u16_set_bool_flag(&self.ptr.flags, bool(val),
                          slurm.PART_FLAG_LLN)

    @property
    def is_root_only(self):
        return u16_parse_bool_flag(self.ptr.flags, slurm.PART_FLAG_ROOT_ONLY)

    @is_root_only.setter
    def is_root_only(self, val):
        u16_set_bool_flag(&self.ptr.flags, bool(val),
                          slurm.PART_FLAG_ROOT_ONLY)

    @property
    def requires_reservation(self):
        return u16_parse_bool_flag(self.ptr.flags, slurm.PART_FLAG_REQ_RESV)

    @requires_reservation.setter
    def requires_reservation(self, val):
        u16_set_bool_flag(&self.ptr.flags, bool(val),
                          slurm.PART_FLAG_REQ_RESV)

    # TODO: tres_fmt_str


def _partition_state_int_to_str(state):
    if state == slurm.PARTITION_UP:
        return "UP"
    elif state == slurm.PARTITION_DOWN:
        return "DOWN"
    elif state == slurm.PARTITION_INACTIVE:
        return "INACTIVE"
    elif state == slurm.PARTITION_DRAIN:
        return "DRAIN"
    else:
        return "UNKNOWN"


def _partition_state_str_to_int(state):
    state = state.upper()

    if state == "UP":
        return slurm.PARTITION_UP
    elif state == "DOWN":
        return slurm.PARTITION_DOWN
    elif state == "INACTIVE":
        return slurm.PARTITION_INACTIVE
    elif state == "DRAIN":
        return slurm.PARTITION_DRAIN
    else:
        choices = "UP, DOWN, INACTIVE, DRAIN"
        raise ValueError(f"Invalid partition state: {state}, valid choices "
                         f"are {choices}")


def _oversubscribe_mode_int_to_str(shared):
    is_forced = shared & slurm.SHARED_FORCE
    value = shared & (~slurm.SHARED_FORCE)

    if not value:
        return "EXCLUSIVE", None
    elif is_forced:
        return "FORCE", value
    elif value == 1:
        return "NO", None
    else:
        return "YES", value


def _select_type_int_to_list(stype):
    # https://github.com/SchedMD/slurm/blob/257ca5e4756a493dc4c793ded3ac3c1a769b3c83/slurm/slurm.h#L996
    # The 3 main select types are mutually exclusive, and may be combined with
    # CR_MEMORY
    # CR_BOARD exists but doesn't show up in the documentation, so ignore it.
    out = []

    if stype & slurm.CR_CPU:
        out.append("CR_CPU")
    elif stype & slurm.CR_CORE:
        out.append("CR_CORE")
    elif stype & slurm.CR_SOCKET:
        out.append("CR_SOCKET")
    elif stype & slurm.CR_CPU and stype & slurm.CR_MEMORY:
        out.append("CR_CPU_MEMORY")
    elif stype & slurm.CR_CORE and stype & slurm.CR_MEMORY:
        out.append("CR_CORE_MEMORY")
    elif stype & slurm.CR_SOCKET and stype & slurm.CR_MEMORY:
        out.append("CR_SOCKET_MEMORY")

    # The rest of the CR_* stuff is not mutually exclusive
    if stype & slurm.CR_OTHER_CONS_RES:
        out.append("CR_OTHER_CONS_RES")

    if stype & slurm.CR_ONE_TASK_PER_CORE:
        out.append("CR_ONE_TASK_PER_CORE")

    if stype & slurm.CR_PACK_NODES:
        out.append("CR_PACK_NODES")

    if stype & slurm.CR_OTHER_CONS_TRES:
        out.append("CR_OTHER_CONS_TRES")

    if stype & slurm.CR_CORE_DEFAULT_DIST_BLOCK:
        out.append("CR_CORE_DEFAULT_DIST_BLOCK")

    if stype & slurm.CR_LLN:
        out.append("CR_LLN")

    return out


def _preempt_mode_str_to_int(mode):
    if not mode:
        return slurm.NO_VAL16

    pmode = slurm_preempt_mode_num(str(mode))
    if pmode == slurm.NO_VAL16:
        raise ValueError(f"Invalid Preempt mode: {mode}")

    return pmode


def _preempt_mode_int_to_str(mode, slurmctld.Config slurm_conf):
    cdef char *tmp = NULL
    if mode == slurm.NO_VAL16:
        return slurm_conf.preempt_mode
    else:
        tmp = slurm_preempt_mode_string(mode)
        return cstr.to_unicode(tmp)
