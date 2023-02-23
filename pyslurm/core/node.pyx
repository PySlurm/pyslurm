#########################################################################
# node.pyx - interface to work with nodes in slurm
#########################################################################
# Copyright (C) 2022 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# Pyslurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Pyslurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
# cython: language_level=3

from pyslurm.slurm cimport xfree, try_xmalloc
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from pyslurm.core.common cimport cstr
from pyslurm.core.common import cstr
from pyslurm.core.common cimport ctime
from pyslurm.core.common import ctime
from pyslurm.core.common.ctime cimport time_t
from pyslurm.core.common.uint cimport *
from pyslurm.core.common.uint import *
from pyslurm.core.error import RPCError, verify_rpc
from pyslurm.core.common.ctime import timestamp_to_date, _raw_time
from pyslurm.core.common import (
    uid_to_name,
    gid_to_name,
    humanize, 
    _getgrall_to_dict,
    _getpwall_to_dict,
    cpubind_to_num,
    instance_to_dict,
    _sum_prop,
)


cdef class Nodes(dict):
    """A collection of Node objects.

    By creating a new Nodes instance, all Nodes in the system will be
    fetched from the slurmctld.

    Args:
        preload_passwd_info (bool): 
            Decides whether to query passwd and groups information from the
            system.
            Could potentially speed up access to attributes of the Node where
            a UID/GID is translated to a name.
            If True, the information will fetched and stored in each of the
            Node instances. The default is False.

    Raises:
        RPCError: When getting all the Nodes from the slurmctld failed.
        MemoryError: If malloc fails to allocate memory.
    """
    def __dealloc__(self):
        slurm_free_node_info_msg(self.info)
        slurm_free_partition_info_msg(self.part_info)

    def __init__(self, preload_passwd_info=False):
        cdef:
            dict passwd = {}
            dict groups = {}
            int flags   = slurm.SHOW_ALL
            Node node

        self.info = NULL
        self.part_info = NULL

        # If requested, preload the passwd and groups database to potentially
        # speedup lookups for an attribute in a node, e.g "owner".
        if preload_passwd_info:
            passwd = _getpwall_to_dict()
            groups = _getgrall_to_dict()

        verify_rpc(slurm_load_node(0, &self.info, slurm.SHOW_ALL))
        verify_rpc(slurm_load_partitions(0, &self.part_info, slurm.SHOW_ALL))
        slurm_populate_node_partitions(self.info, self.part_info)

        # zero-out a dummy node_info_t
        memset(&self.tmp_info, 0, sizeof(node_info_t))

        # Put each node pointer into its own "Node" instance.
        for cnt in range(self.info.record_count):
            node = Node.from_ptr(&self.info.node_array[cnt])

            # Prevent double free if xmalloc fails mid-loop and a MemoryError
            # is raised by replacing it with a zeroed-out node_info_t.
            self.info.node_array[cnt] = self.tmp_info

            if preload_passwd_info:
                node.passwd = passwd
                node.groups = groups

            self[node.name] = node

        # At this point we memcpy'd all the memory for the Nodes. Setting this
        # to 0 will prevent the slurm node free function to deallocate the
        # memory for the individual nodes. This should be fine, because they
        # are free'd automatically in __dealloc__ since the lifetime of each
        # node-pointer is tied to the lifetime of its corresponding "Node"
        # instance.
        self.info.record_count = 0

    def as_list(self):
        """Format the information as list of Node objects.

        Returns:
            list: List of Node objects
        """
        return list(self.values())

    @property
    def free_memory_raw(self):
        """int: Amount of free memory in this node collection. (Mebibytes)"""
        return _sum_prop(self, Node.free_memory)

    @property
    def free_memory(self):
        """str: Humanized amount of free memory in this node collection."""
        return humanize(self.free_memory_raw, 2)

    @property
    def real_memory_raw(self):
        """int: Amount of real memory in this node collection. (Mebibytes)"""
        return _sum_prop(self, Node.real_memory)

    @property
    def real_memory(self):
        """str: Humanized amount of real memory in this node collection."""
        return humanize(self.real_memory_raw, 2)

    @property
    def alloc_memory_raw(self):
        """int: Amount of alloc Memory in this node collection. (Mebibytes)"""
        return _sum_prop(self, Node.alloc_memory)

    @property
    def alloc_memory(self):
        """str: Total amount of allocated Memory in this node collection."""
        return humanize(self.alloc_memory_raw, 2)

    @property
    def total_cpus(self):
        """int: Total amount of CPUs in this node collection."""
        return _sum_prop(self, Node.total_cpus)

    @property
    def idle_cpus(self):
        """int: Total amount of idle CPUs in this node collection."""
        return _sum_prop(self, Node.idle_cpus)

    @property
    def alloc_cpus(self):
        """int: Total amount of allocated CPUs in this node collection."""
        return _sum_prop(self, Node.alloc_cpus)
    
    @property
    def effective_cpus(self):
        """int: Total amount of effective CPUs in this node collection."""
        return _sum_prop(self, Node.effective_cpus)

    @property
    def current_watts(self):
        """int: Total amount of Watts consumed in this node collection."""
        return _sum_prop(self, Node.current_watts)

    @property
    def average_watts(self):
        """int: Amount of average watts consumed in this node collection."""
        return _sum_prop(self, Node.average_watts)


cdef class Node:
    """A Slurm node."""

    def __cinit__(self):
        self.info = NULL
        self.umsg = NULL

    def __init__(self, str name=None, **kwargs):
        """Initialize a Node instance

        Args:
            name (str):
                Name of a node
            **kwargs:
                Any writable property. Writable attributes include:
                    * name
                    * configured_gres
                    * address
                    * hostname
                    * extra
                    * comment
                    * weight
                    * available_features
                    * active_features
                    * cpu_binding
                    * state
        """
        self._alloc_impl()
        self.name = name
        for k, v in kwargs.items():
            setattr(self, k, v)

    def _alloc_impl(self):
        self._alloc_info()
        self._alloc_umsg()

    def _alloc_info(self):
        if not self.info:
            self.info = <node_info_t*>try_xmalloc(sizeof(node_info_t))
            if not self.info:
                raise MemoryError("xmalloc failed for node_info_t")

    def _alloc_umsg(self):
        if not self.umsg:
            self.umsg = <update_node_msg_t*>try_xmalloc(sizeof(update_node_msg_t))
            if not self.umsg:
                raise MemoryError("xmalloc failed for update_node_msg_t")
            slurm_init_update_node_msg(self.umsg)

    def _dealloc_impl(self):
        slurm_free_update_node_msg(self.umsg)
        self.umsg = NULL
        slurm_free_node_info_members(self.info)
        xfree(self.info)

    def __dealloc__(self):
        self._dealloc_impl() 

    def __setattr__(self, name, val):
        # When a user wants to set attributes on a Node instance that was
        # created by calling Nodes(), the "umsg" pointer is not yet allocated.
        # We only allocate memory for it by the time the user actually wants
        # to modify something.
        self._alloc_umsg()
        # Call descriptors __set__ directly
        Node.__dict__[name].__set__(self, val)

    def __eq__(self, other):
        return isinstance(other, Node) and self.name == other.name

    @staticmethod
    cdef Node from_ptr(node_info_t *in_ptr):
        cdef Node wrap = Node.__new__(Node)
        wrap._alloc_info()
        wrap.passwd = {}
        wrap.groups = {}
        memcpy(wrap.info, in_ptr, sizeof(node_info_t))
        return wrap

    def reload(self):
        """(Re)load information for a node.

        Implements the slurm_load_node_single RPC.

        Note:
            You can call this function repeatedly to refresh the information
            of an instance. Using the Node object returned is optional.

        Returns:
            Node: This function returns the current Node-instance object
                itself.

        Raises:
            RPCError: If requesting the Node information from the slurmctld
                was not successful.
            MemoryError: If malloc failed to allocate memory.

        Examples:
            >>> from pyslurm import Node
            >>> node = Node("localhost")
            >>> node.reload()
            >>> 
            >>> # You can also write this in one-line:
            >>> node = Node("localhost").reload()
        """
        cdef:
            node_info_msg_t      *node_info = NULL
            partition_info_msg_t *part_info = NULL

        if not self.name:
            raise ValueError("You need to set a node name first")

        try:
            verify_rpc(slurm_load_node_single(&node_info,
                                              self.name, slurm.SHOW_ALL))
            verify_rpc(slurm_load_partitions(0, &part_info, slurm.SHOW_ALL))
            slurm_populate_node_partitions(node_info, part_info)

            save_name = self.name
            if node_info and node_info.record_count:
                # Cleanup the old info.
                self._dealloc_impl()
                # Copy new info
                self._alloc_impl()
                memcpy(self.info, &node_info.node_array[0], sizeof(node_info_t))
                node_info.record_count = 0

                # Need to do this, because while testing even when specifying
                # a node name that doesn't exist, it still returned the
                # "localhost" node in my Test-setup. Why?
                if self.name != save_name:
                    raise RPCError(msg=f"Node '{save_name}' does not exist")
        except Exception as e:
            raise e
        finally:
            slurm_free_node_info_msg(node_info)
            slurm_free_partition_info_msg(part_info)

        return self

    def create(self, state="future"):
        """Create a node.

        Implements the slurm_create_node RPC.

        Args:
            future (str, optional): 
                An optional state the created Node should have. Allowed values
                are "future" and "cloud". "future" is the default.

        Returns:
            Node: This function returns the current Node-instance object
                itself.

        Raises:
            RPCError: If creating the Node was not successful.
            MemoryError: If malloc failed to allocate memory.

        Examples:
            >>> from pyslurm import Node
            >>> node = Node("testnode").create()
        """
        if not self.name:
            raise ValueError("You need to set a node name first.")

        self._alloc_umsg()
        cstr.fmalloc(&self.umsg.extra,
                     f"NodeName={self.name} State={state}")
        verify_rpc(slurm_create_node(self.umsg))

        return self

    def modify(self, node=None, **kwargs):
        """Modify a node.

        Implements the slurm_update_node RPC.

        Args:
            node (JobStep):
                Another Node object which contains all the changes that
                should be applied to this instance.
            **kwargs:
                You can also specify all the changes as keyword arguments.
                Allowed values are only attributes which can actually be set
                on a Node instance. If a node is explicitly specified as
                parameter, all **kwargs will be ignored.

        Raises:
            RPCError: When updating the Node was not successful.

        Examples:
            >>> from pyslurm import Node
            >>> 
            >>> # Setting a new weight for the Node
            >>> changes = Node(weight=100)
            >>> Node("localhost").modify(changes)
            >>>
            >>> # Or by specifying the changes directly to the modify function
            >>> Node("localhost").modify(weight=100)
        """
        cdef Node n = self

        # Allow the user to both specify changes via a Node instance or
        # **kwargs.
        if node and isinstance(node, Node):
            n = <Node>node
        elif kwargs:
            n = Node(**kwargs)

        n._alloc_umsg()
        cstr.fmalloc(&n.umsg.node_names, self.name)
        verify_rpc(slurm_update_node(n.umsg))

    def delete(self):
        """Delete a node.

        Implements the slurm_delete_node RPC.

        Raises:
            RPCError: If deleting the Node was not successful.
            MemoryError: If malloc failed to allocate memory.

        Examples:
            >>> from pyslurm import Node
            >>> Node("localhost").delete()
        """
        self._alloc_umsg()
        verify_rpc(slurm_delete_node(self.umsg))

    def as_dict(self):
        """Node information formatted as a dictionary.

        Returns:
            dict: Node information as dict
        """
        return instance_to_dict(self)

    @property
    def name(self):
        """str: Name of the node."""
        return cstr.to_unicode(self.info.name)

    @name.setter
    def name(self, val):
        cstr.fmalloc2(&self.info.name, &self.umsg.node_names, val)

    @property
    def architecture(self):
        """str: Architecture of the node (e.g. x86_64)"""
        return cstr.to_unicode(self.info.arch)

    @property
    def configured_gres(self):
        """dict: Generic Resources this Node is configured with."""
        return cstr.to_gres_dict(self.info.gres)

    @configured_gres.setter
    def configured_gres(self, val):
        cstr.fmalloc2(&self.info.gres, &self.umsg.gres, 
                      cstr.from_gres_dict(val))

    @property
    def owner(self):
        """str: User that owns the Node."""
        return uid_to_name(self.info.owner, lookup=self.passwd)

    @property
    def address(self):
        """str: Address of the node."""
        return cstr.to_unicode(self.info.node_addr)

    @address.setter
    def address(self, val):
        cstr.fmalloc2(&self.info.node_addr, &self.umsg.node_addr, val)

    @property
    def hostname(self):
        """str: Hostname of the node."""
        return cstr.to_unicode(self.info.node_hostname)

    @hostname.setter
    def hostname(self, val):
        cstr.fmalloc2(&self.info.node_hostname, &self.umsg.node_hostname, val)

    @property
    def extra(self):
        """str: Arbitrary string attached to the Node."""
        return cstr.to_unicode(self.info.extra)

    @extra.setter
    def extra(self, val):
        cstr.fmalloc2(&self.info.extra, &self.umsg.extra, val)
        
    @property
    def reason(self):
        """str: Reason why this node is in its current state."""
        return cstr.to_unicode(self.info.reason)

    @property
    def reason_user(self):
        """str: Name of the User who set the reason."""
        return uid_to_name(self.info.reason_uid, lookup=self.passwd)

    @property
    def comment(self):
        """str: Arbitrary node comment."""
        return cstr.to_unicode(self.info.comment)

    @comment.setter
    def comment(self, val):
        cstr.fmalloc2(&self.info.comment, &self.umsg.comment, val)

    @property
    def bcast_address(self):
        """str: Address of the node for sbcast."""
        return cstr.to_unicode(self.info.bcast_address)

    @property
    def slurm_version(self):
        """str: Version of slurm this node is running on."""
        return cstr.to_unicode(self.info.version)

    @property
    def operating_system(self):
        """str: Name of the operating system installed."""
        return cstr.to_unicode(self.info.os)

    @property
    def alloc_gres(self):
        """dict: Generic Resources currently in use on the node."""
        return cstr.to_gres_dict(self.info.gres_used)

    @property
    def mcs_label(self):
        """str: MCS label for the node."""
        return cstr.to_unicode(self.info.mcs_label)

    @property
    def alloc_memory_raw(self):
        """int: Memory allocated on the node. (Mebibytes)"""
        cdef uint64_t alloc_memory = 0
        if self.info.select_nodeinfo:
            slurm_get_select_nodeinfo(
                self.info.select_nodeinfo,
                slurm.SELECT_NODEDATA_MEM_ALLOC,
                slurm.NODE_STATE_ALLOCATED,
                &alloc_memory)
        return u64_parse(alloc_memory)

    @property
    def alloc_memory(self):
        """str: Memory allocated on the node."""
        return humanize(self.alloc_memory_raw, 2)

    @property
    def real_memory_raw(self):
        """int: Real Memory configured for this node. (Mebibytes)"""
        return u64_parse(self.info.real_memory)

    @property
    def real_memory(self):
        """str: Humanized Real Memory configured for this node."""
        return humanize(self.real_memory_raw, 2)

    @property
    def free_memory_raw(self):
        """int: Free Memory on the node. (Mebibytes)"""
        return u64_parse(self.info.free_mem)

    @property
    def free_memory(self):
        """str: Humanized Free Memory on the node."""
        return humanize(self.free_memory_raw, 2)

    @property
    def memory_reserved_for_system_raw(self):
        """int: Memory reserved for the System not usable by Jobs."""
        return u64_parse(self.info.mem_spec_limit)

    @property
    def memory_reserved_for_system(self):
        """str: Memory reserved for the System not usable by Jobs."""
        return humanize(self.memory_reserved_for_system_raw, 2)

    @property
    def tmp_disk_space_raw(self):
        """int: Amount of temporary disk space this node has. (Mebibytes)"""
        return u32_parse(self.info.tmp_disk)

    @property
    def tmp_disk_space(self):
        """str: Amount of temporary disk space this node has."""
        return humanize(self.tmp_disk_space_raw)

    @property
    def weight(self):
        """int: Weight of the node in scheduling."""
        return u32_parse(self.info.weight)

    @weight.setter
    def weight(self, val):
        self.info.weight=self.umsg.weight = u32(val)

    @property
    def effective_cpus(self):
        """int: Number of effective CPUs the node has."""
        return u16_parse(self.info.cpus_efctv)

    @property
    def total_cpus(self):
        """int: Total amount of CPUs the node has."""
        return u16_parse(self.info.cpus)

    @property
    def sockets(self):
        """int: Number of sockets the node has."""
        return u16_parse(self.info.sockets)

    @property
    def cores_reserved_for_system(self):
        """int: Number of cores reserved for the System not usable by Jobs."""
        return u16_parse(self.info.core_spec_cnt)

    @property
    def boards(self):
        """int: Number of boards the node has."""
        return u16_parse(self.info.boards)

    @property
    def cores_per_socket(self):
        """int: Number of cores per socket configured for the node."""
        return u16_parse(self.info.cores)

    @property
    def threads_per_core(self):
        """int: Number of threads per core configured for the node."""
        return u16_parse(self.info.threads)

    @property
    def available_features(self):
        """list: List of features available on the node."""
        return cstr.to_list(self.info.features)

    @available_features.setter
    def available_features(self, val):
        cstr.from_list2(&self.info.features, &self.umsg.features, val)

    @property
    def active_features(self):
        """list: List of features on the node."""
        return cstr.to_list(self.info.features_act)

    @active_features.setter
    def active_features(self, val):
        cstr.from_list2(&self.info.features_act, &self.umsg.features_act, val)

    @property
    def partitions(self):
        """list: List of partitions this Node is in."""
        return cstr.to_list(self.info.partitions)

    @property
    def boot_time_raw(self):
        """int: Time the node has booted. (Unix timestamp)"""
        return _raw_time(self.info.boot_time)

    @property
    def boot_time(self):
        """str: Time the node has booted. (formatted)"""
        return timestamp_to_date(self.info.boot_time)

    @property
    def slurmd_start_time_raw(self):
        """int: Time the slurmd has started on the Node. (Unix timestamp)"""
        return _raw_time(self.info.slurmd_start_time)

    @property
    def slurmd_start_time(self):
        """str: Time the slurmd has started on the Node. (formatted)"""
        return timestamp_to_date(self.info.slurmd_start_time)

    @property
    def last_busy_time_raw(self):
        """int: Time this node was last busy. (Unix timestamp)"""
        return _raw_time(self.info.last_busy)

    @property
    def last_busy_time(self):
        """str: Time this node was last busy. (formatted)"""
        return timestamp_to_date(self.info.last_busy)

    @property
    def reason_time_raw(self):
        """int: Time the reason was set for the node. (Unix timestamp)"""
        return _raw_time(self.info.reason_time)

    @property
    def reason_time(self):
        """str: Time the reason was set for the node. (formatted)"""
        return timestamp_to_date(self.info.reason_time)

#   @property
#   def tres_configured(self):
#       """dict: TRES that are configured on the node."""
#       return cstr.to_dict(self.info.tres_fmt_str)

#   @property
#   def tres_alloc(self):
#       cdef char *alloc_tres = NULL
#       if self.info.select_nodeinfo:
#           slurm_get_select_nodeinfo(
#               self.info.select_nodeinfo,
#               slurm.SELECT_NODEDATA_TRES_ALLOC_FMT_STR,
#               slurm.NODE_STATE_ALLOCATED,
#               &alloc_tres
#           )
#       return cstr.to_gres_dict(alloc_tres)

    @property
    def alloc_cpus(self):
        """int: Number of allocated CPUs on the node."""
        cdef uint16_t alloc_cpus = 0
        if self.info.select_nodeinfo:
            slurm_get_select_nodeinfo(
                self.info.select_nodeinfo,
                slurm.SELECT_NODEDATA_SUBCNT,
                slurm.NODE_STATE_ALLOCATED,
                &alloc_cpus
            )
        return alloc_cpus

    @property
    def idle_cpus(self):
        """int: Number of idle CPUs."""
        efctv = self.effective_cpus
        if not efctv:
            return None

        return efctv - self.alloc_cpus

    @property
    def cpu_binding(self):
        """str: Default CPU-Binding on the node."""
        cdef char cpu_bind[128]
        slurm_sprint_cpu_bind_type(cpu_bind,
                                   <cpu_bind_type_t>self.info.cpu_bind)
        if cpu_bind == "(null type)":
            return None

        return cstr.to_unicode(cpu_bind)

    @cpu_binding.setter
    def cpu_binding(self, val):
        self.info.cpu_bind=self.umsg.cpu_bind = cpubind_to_num(val)

    @property
    def cap_watts(self):
        """int: Node cap watts."""
        if not self.info.power:
            return None
        return u32_parse(self.info.power.cap_watts)

    @property
    def current_watts(self):
        """int: Current amount of watts consumed on the node."""
        if not self.info.energy:
            return None
        return u32_parse(self.info.energy.current_watts)

    @property
    def average_watts(self):
        """int: Average amount of watts consumed on the node."""
        if not self.info.energy:
            return None
        return u32_parse(self.info.energy.ave_watts)

    @property
    def external_sensors(self):
        """
        dict: External Sensor info for the Node.

        The dict returned contains the following information:
            * joules_total (int)
            * current_watts (int)
            * temperature (int)
        """
        if not self.info.ext_sensors:
            return {}

        return {
            "joules_total":  u64_parse(self.info.ext_sensors.consumed_energy),
            "current_watts": u32_parse(self.info.ext_sensors.current_watts),
            "temperature":   u32_parse(self.info.ext_sensors.temperature)
        }

    @property
    def state(self):
        """str: State the node is currently in."""
        cdef char* state = slurm_node_state_string_complete(
                self.info.node_state)
        state_str = cstr.to_unicode(state)
        xfree(state)
        return state_str

    @property
    def next_state(self):
        """str: Next state the node will be in."""
        if ((self.info.next_state != slurm.NO_VAL)
                and (self.info.node_state & slurm.NODE_STATE_REBOOT_REQUESTED
                or   self.info.node_state & slurm.NODE_STATE_REBOOT_ISSUED)):
            return cstr.to_unicode(
                    slurm_node_state_string(self.info.next_state))
        else:
            return None

    @state.setter
    def state(self, val):
        self.umsg.node_state=self.info.node_state = _node_state_from_str(val)

    @property
    def cpu_load(self):
        """float: CPU Load on the Node."""
        load = u32_parse(self.info.cpu_load)
        return load / 100.0 if load is not None else None

    @property
    def port(self):
        """int: Port the slurmd is listening on the node."""
        return u16_parse(self.info.port)


def _node_state_from_str(state, err_on_invalid=True):
    if not state:
        return slurm.NO_VAL

    for i in range(slurm.NODE_STATE_END):
        if state == slurm_node_state_string(i):
            return i

    if err_on_invalid:
        raise ValueError(f"Invalid Node state: {state}")
    else:
        return slurm.NO_VAL
