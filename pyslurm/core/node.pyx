#########################################################################
# node.pyx - interface to work with nodes in slurm
#########################################################################
# Copyright (C) 2023 Toni Harzendorf <toni.harzendorf@gmail.com>
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
    humanize, 
    _getgrall_to_dict,
    _getpwall_to_dict,
    cpubind_to_num,
    instance_to_dict,
    collection_to_dict,
    group_collection_by_cluster,
    _sum_prop,
    nodelist_from_range_str,
    nodelist_to_range_str,
)


cdef class Nodes(list):

    def __dealloc__(self):
        slurm_free_node_info_msg(self.info)
        slurm_free_partition_info_msg(self.part_info)

    def __cinit__(self):
        self.info = NULL
        self.part_info = NULL

    def __init__(self, nodes=None):
        if isinstance(nodes, list):
            for node in nodes:
                if isinstance(node, str):
                    self.extend(Node(node))
                else:
                    self.extend(node)
        elif isinstance(nodes, str):
            nodelist = nodes.split(",")
            self.extend([Node(node) for node in nodelist])
        elif isinstance(nodes, dict):
            self.extend([node for node in nodes.values()])
        elif nodes is not None:
            raise TypeError("Invalid Type: {type(nodes)}")

    def as_dict(self):
        return collection_to_dict(self, False, False, Node.name)

    def group_by_cluster(self):
        return group_collection_by_cluster(self)

    @staticmethod
    def load(preload_passwd_info=False):
        """Load all nodes in the system.

        Args:
            preload_passwd_info (bool): 
                Decides whether to query passwd and groups information from
                the system.
                Could potentially speed up access to attributes of the Node
                where a UID/GID is translated to a name.
                If True, the information will fetched and stored in each of
                the Node instances. The default is False.

        Returns:
            (pyslurm.Nodes): Collection of node objects.

        Raises:
            RPCError: When getting all the Nodes from the slurmctld failed.
            MemoryError: If malloc fails to allocate memory.
        """
        cdef:
            dict passwd = {}
            dict groups = {}
            Nodes nodes = Nodes.__new__(Nodes)
            int flags = slurm.SHOW_ALL
            Node node

        verify_rpc(slurm_load_node(0, &nodes.info, flags))
        verify_rpc(slurm_load_partitions(0, &nodes.part_info, flags))
        slurm_populate_node_partitions(nodes.info, nodes.part_info)

        # If requested, preload the passwd and groups database to potentially
        # speedup lookups for an attribute in a node, e.g "owner".
        if preload_passwd_info:
            passwd = _getpwall_to_dict()
            groups = _getgrall_to_dict()

        # zero-out a dummy node_info_t
        memset(&nodes.tmp_info, 0, sizeof(node_info_t))

        # Put each node pointer into its own "Node" instance.
        for cnt in range(nodes.info.record_count):
            node = Node.from_ptr(&nodes.info.node_array[cnt])

            # Prevent double free if xmalloc fails mid-loop and a MemoryError
            # is raised by replacing it with a zeroed-out node_info_t.
            nodes.info.node_array[cnt] = nodes.tmp_info

            if preload_passwd_info:
                node.passwd = passwd
                node.groups = groups

            nodes.append(node)

        # At this point we memcpy'd all the memory for the Nodes. Setting this
        # to 0 will prevent the slurm node free function to deallocate the
        # memory for the individual nodes. This should be fine, because they
        # are free'd automatically in __dealloc__ since the lifetime of each
        # node-pointer is tied to the lifetime of its corresponding "Node"
        # instance.
        nodes.info.record_count = 0

        return nodes

    def reload(self):
        """Reload the information for nodes in a collection.

        !!! note

            Only information for nodes which are already in the collection at
            the time of calling this method will be reloaded.

        Raises:
            RPCError: When getting the Nodes from the slurmctld failed.
        """
        cdef Nodes reloaded_nodes

        if not self:
            return self

        reloaded_nodes = Nodes.load().as_dict()
        for node, idx in enumerate(self):
            node_name = node.name
            if node in reloaded_nodes:
                # Put the new data in.
                self[idx] = reloaded_nodes[node_name]

        return self

    def modify(self, Node changes):
        """Modify all Nodes in a collection.

        Args:
            changes (pyslurm.Node):
                Another Node object that contains all the changes to apply.
                Check the `Other Parameters` of the Node class to see which
                properties can be modified.

        Raises:
            RPCError: When updating the Node was not successful.

        Examples:
            >>> import pyslurm
            >>>
            >>> nodes = pyslurm.Nodes.load()
            >>> # Prepare the changes
            >>> changes = pyslurm.Node(state="DRAIN", reason="DRAIN Reason")
            >>> # Apply the changes to all the nodes
            >>> nodes.modify(changes)
        """
        cdef:
            Node n = <Node>changes
            list node_names = [node.name for node in self]
        
        node_str = nodelist_to_range_str(node_names)
        n._alloc_umsg()
        cstr.fmalloc(&n.umsg.node_names, node_str)
        verify_rpc(slurm_update_node(n.umsg))
        
    @property
    def free_memory(self):
        return _sum_prop(self, Node.free_memory)

    @property
    def real_memory(self):
        return _sum_prop(self, Node.real_memory)

    @property
    def allocated_memory(self):
        return _sum_prop(self, Node.allocated_memory)

    @property
    def total_cpus(self):
        return _sum_prop(self, Node.total_cpus)

    @property
    def idle_cpus(self):
        return _sum_prop(self, Node.idle_cpus)

    @property
    def allocated_cpus(self):
        return _sum_prop(self, Node.allocated_cpus)
    
    @property
    def effective_cpus(self):
        return _sum_prop(self, Node.effective_cpus)

    @property
    def current_watts(self):
        return _sum_prop(self, Node.current_watts)

    @property
    def avg_watts(self):
        return _sum_prop(self, Node.avg_watts)


cdef class Node:

    def __cinit__(self):
        self.info = NULL
        self.umsg = NULL

    def __init__(self, name=None, **kwargs):
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

    cdef _swap_data(Node dst, Node src):
        cdef node_info_t *tmp = NULL
        if dst.info and src.info:
            tmp = dst.info 
            dst.info = src.info
            src.info = tmp

    @staticmethod
    def load(name):
        """Load information for a specific node.

        Implements the slurm_load_node_single RPC.

        Returns:
            (pyslurm.Node): Returns a new Node instance.

        Raises:
            RPCError: If requesting the Node information from the slurmctld
                was not successful.
            MemoryError: If malloc failed to allocate memory.

        Examples:
            >>> import pyslurm
            >>> node = pyslurm.Node.load("localhost")
        """
        cdef:
            node_info_msg_t      *node_info = NULL
            partition_info_msg_t *part_info = NULL
            Node wrap = Node.__new__(Node)

        try:
            verify_rpc(slurm_load_node_single(&node_info,
                                              name, slurm.SHOW_ALL))
            verify_rpc(slurm_load_partitions(0, &part_info, slurm.SHOW_ALL))
            slurm_populate_node_partitions(node_info, part_info)

            if node_info and node_info.record_count:
                # Copy info
                wrap._alloc_impl()
                memcpy(wrap.info, &node_info.node_array[0], sizeof(node_info_t))
                node_info.record_count = 0
            else:
                raise RPCError(msg=f"Node '{name}' does not exist")
        except Exception as e:
            raise e
        finally:
            slurm_free_node_info_msg(node_info)
            slurm_free_partition_info_msg(part_info)

        return wrap

    def create(self, state="future"):
        """Create a node.

        Implements the slurm_create_node RPC.

        Args:
            state (str, optional): 
                An optional state the created Node should have. Allowed values
                are "future" and "cloud". "future" is the default.

        Returns:
            (pyslurm.Node): This function returns the current Node-instance
                object itself.

        Raises:
            RPCError: If creating the Node was not successful.
            MemoryError: If malloc failed to allocate memory.

        Examples:
            >>> import pyslurm
            >>> node = pyslurm.Node("testnode").create()
        """
        if not self.name:
            raise ValueError("You need to set a node name first.")

        self._alloc_umsg()
        cstr.fmalloc(&self.umsg.extra,
                     f"NodeName={self.name} State={state}")
        verify_rpc(slurm_create_node(self.umsg))

        return self

    def modify(self, Node changes):
        """Modify a node.

        Implements the slurm_update_node RPC.

        Args:
            changes (pyslurm.Node):
                Another Node object that contains all the changes to apply.
                Check the `Other Parameters` of the Node class to see which
                properties can be modified.

        Raises:
            RPCError: When updating the Node was not successful.

        Examples:
            >>> import pyslurm
            >>>
            >>> mynode = pyslurm.Node.load("localhost")
            >>> # Prepare the changes
            >>> changes = pyslurm.Node(state="DRAIN", reason="DRAIN Reason")
            >>> # Modify it
            >>> mynode.modify(changes)
        """
        cdef Node n = <Node>changes
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
            >>> import pyslurm
            >>> pyslurm.Node("localhost").delete()
        """
        self._alloc_umsg()
        verify_rpc(slurm_delete_node(self.umsg))

    def as_dict(self):
        """Node information formatted as a dictionary.

        Returns:
            (dict): Node information as dict

        Examples:
            >>> import pyslurm
            >>> mynode = pyslurm.Node.load("mynode")
            >>> mynode_dict = mynode.as_dict()
        """
        return instance_to_dict(self)

    @property
    def name(self):
        return cstr.to_unicode(self.info.name)

    @name.setter
    def name(self, val):
        cstr.fmalloc2(&self.info.name, &self.umsg.node_names, val)

    @property
    def architecture(self):
        return cstr.to_unicode(self.info.arch)

    @property
    def configured_gres(self):
        return cstr.to_gres_dict(self.info.gres)

    @configured_gres.setter
    def configured_gres(self, val):
        cstr.fmalloc2(&self.info.gres, &self.umsg.gres, 
                      cstr.from_gres_dict(val))

    @property
    def owner(self):
        return uid_to_name(self.info.owner, lookup=self.passwd)

    @property
    def address(self):
        return cstr.to_unicode(self.info.node_addr)

    @address.setter
    def address(self, val):
        cstr.fmalloc2(&self.info.node_addr, &self.umsg.node_addr, val)

    @property
    def hostname(self):
        return cstr.to_unicode(self.info.node_hostname)

    @hostname.setter
    def hostname(self, val):
        cstr.fmalloc2(&self.info.node_hostname, &self.umsg.node_hostname, val)

    @property
    def extra(self):
        return cstr.to_unicode(self.info.extra)

    @extra.setter
    def extra(self, val):
        cstr.fmalloc2(&self.info.extra, &self.umsg.extra, val)
        
    @property
    def reason(self):
        return cstr.to_unicode(self.info.reason)

    @reason.setter
    def reason(self, val):
        cstr.fmalloc2(&self.info.reason, &self.umsg.reason, val)

    @property
    def reason_user(self):
        return uid_to_name(self.info.reason_uid, lookup=self.passwd)

    @property
    def comment(self):
        return cstr.to_unicode(self.info.comment)

    @comment.setter
    def comment(self, val):
        cstr.fmalloc2(&self.info.comment, &self.umsg.comment, val)

    @property
    def bcast_address(self):
        return cstr.to_unicode(self.info.bcast_address)

    @property
    def slurm_version(self):
        return cstr.to_unicode(self.info.version)

    @property
    def operating_system(self):
        return cstr.to_unicode(self.info.os)

    @property
    def allocated_gres(self):
        return cstr.to_gres_dict(self.info.gres_used)

    @property
    def mcs_label(self):
        return cstr.to_unicode(self.info.mcs_label)

    @property
    def allocated_memory(self):
        cdef uint64_t alloc_memory = 0
        if self.info.select_nodeinfo:
            slurm_get_select_nodeinfo(
                self.info.select_nodeinfo,
                slurm.SELECT_NODEDATA_MEM_ALLOC,
                slurm.NODE_STATE_ALLOCATED,
                &alloc_memory)
        return alloc_memory

    @property
    def real_memory(self):
        return u64_parse(self.info.real_memory)

    @property
    def free_memory(self):
        return u64_parse(self.info.free_mem)

    @property
    def memory_reserved_for_system(self):
        return u64_parse(self.info.mem_spec_limit)

    @property
    def temporary_disk_space(self):
        return u32_parse(self.info.tmp_disk)

    @property
    def weight(self):
        return u32_parse(self.info.weight)

    @weight.setter
    def weight(self, val):
        self.info.weight=self.umsg.weight = u32(val)

    @property
    def effective_cpus(self):
        return u16_parse(self.info.cpus_efctv)

    @property
    def total_cpus(self):
        return u16_parse(self.info.cpus, on_noval=0)

    @property
    def sockets(self):
        return u16_parse(self.info.sockets, on_noval=0)

    @property
    def cores_reserved_for_system(self):
        return u16_parse(self.info.core_spec_cnt)

    @property
    def boards(self):
        return u16_parse(self.info.boards)

    @property
    def cores_per_socket(self):
        return u16_parse(self.info.cores)

    @property
    def threads_per_core(self):
        return u16_parse(self.info.threads)

    @property
    def available_features(self):
        return cstr.to_list(self.info.features)

    @available_features.setter
    def available_features(self, val):
        cstr.from_list2(&self.info.features, &self.umsg.features, val)

    @property
    def active_features(self):
        return cstr.to_list(self.info.features_act)

    @active_features.setter
    def active_features(self, val):
        cstr.from_list2(&self.info.features_act, &self.umsg.features_act, val)

    @property
    def partitions(self):
        return cstr.to_list(self.info.partitions)

    @property
    def boot_time(self):
        return _raw_time(self.info.boot_time)

    @property
    def slurmd_start_time(self):
        return _raw_time(self.info.slurmd_start_time)

    @property
    def last_busy_time(self):
        return _raw_time(self.info.last_busy)

    @property
    def reason_time(self):
        return _raw_time(self.info.reason_time)

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
    def allocated_cpus(self):
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
        efctv = self.effective_cpus
        if not efctv:
            return None

        return efctv - self.allocated_cpus

    @property
    def cpu_binding(self):
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
        if not self.info.power:
            return 0
        return u32_parse(self.info.power.cap_watts, on_noval=0)

    @property
    def current_watts(self):
        if not self.info.energy:
            return 0
        return u32_parse(self.info.energy.current_watts, on_noval=0)

    @property
    def avg_watts(self):
        if not self.info.energy:
            return 0
        return u32_parse(self.info.energy.ave_watts, on_noval=0)

    @property
    def external_sensors(self):
        if not self.info.ext_sensors:
            return {}

        return {
            "joules_total":  u64_parse(self.info.ext_sensors.consumed_energy),
            "current_watts": u32_parse(self.info.ext_sensors.current_watts),
            "temperature":   u32_parse(self.info.ext_sensors.temperature)
        }

    @property
    def state(self):
        cdef char* state = slurm_node_state_string_complete(
                self.info.node_state)
        state_str = cstr.to_unicode(state)
        xfree(state)
        return state_str

    @state.setter
    def state(self, val):
        self.umsg.node_state=self.info.node_state = _node_state_from_str(val)

    @property
    def next_state(self):
        if ((self.info.next_state != slurm.NO_VAL)
                and (self.info.node_state & slurm.NODE_STATE_REBOOT_REQUESTED
                or   self.info.node_state & slurm.NODE_STATE_REBOOT_ISSUED)):
            return cstr.to_unicode(
                    slurm_node_state_string(self.info.next_state))
        else:
            return None

    @property
    def cpu_load(self):
        load = u32_parse(self.info.cpu_load)
        return load / 100.0 if load is not None else 0.0

    @property
    def slurmd_port(self):
        return u16_parse(self.info.port)


def _node_state_from_str(state, err_on_invalid=True):
    if not state:
        return slurm.NO_VAL
    ustate = state.upper()

    # Following states are explicitly possible as per documentation
    # https://slurm.schedmd.com/scontrol.html#OPT_State_1
    if ustate == "CANCEL_REBOOT":
        return slurm.NODE_STATE_CANCEL_REBOOT
    elif ustate == "DOWN":
        return slurm.NODE_STATE_DOWN
    elif ustate == "DRAIN":
        return slurm.NODE_STATE_DRAIN
    elif ustate == "FAIL":
        return slurm.NODE_STATE_FAIL
    elif ustate == "FUTURE":
        return slurm.NODE_STATE_FUTURE
    elif ustate == "NORESP" or ustate == "NO_RESP":
        return slurm.NODE_STATE_NO_RESPOND
    elif ustate == "POWER_DOWN":
        return slurm.NODE_STATE_POWER_DOWN
    elif ustate == "POWER_DOWN_ASAP":
        # Drain and mark for power down
        return slurm.NODE_STATE_POWER_DOWN | slurm.NODE_STATE_POWER_DRAIN
    elif ustate == "POWER_DOWN_FORCE":
        # Kill all Jobs and power down
        return slurm.NODE_STATE_POWER_DOWN | slurm.NODE_STATE_POWERED_DOWN
    elif ustate == "POWER_UP":
        return slurm.NODE_STATE_POWER_UP
    elif ustate == "RESUME":
        return slurm.NODE_RESUME
    elif ustate == "UNDRAIN":
        return slurm.NODE_STATE_UNDRAIN

    if err_on_invalid:
        raise ValueError(f"Invalid Node state: {state}")
    else:
        return slurm.NO_VAL
