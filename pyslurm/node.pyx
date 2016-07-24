# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
# cython: cdivision=True

from __future__ import print_function, division, unicode_literals

import os as _os

from common cimport *
from utils cimport *
from exceptions import PySlurmError

include "node.pxi"

cdef class Node:
    cdef:
        uint32_t alloc_mem
        char *arch
        char *available_features
        uint16_t boards
        time_t boot_time
        char boot_time_str[32]
        uint16_t cores_per_socket
        uint16_t core_spec_cnt
        uint32_t cpu_load
        uint16_t cpu_alloc
        uint16_t cpu_err
        uint16_t cpu_tot
        char *cpu_spec_list
        uint32_t free_mem
        #char *active_features
        char *gres
        char *gres_drain
        char *gres_used
        #char *mcs_label
        uint32_t mem_spec_limit
        char *name
        char *node_addr
        char *node_hostname
        char *state
        char *os
        uint32_t owner
        uint32_t real_memory
        char *reason_str
        time_t reason_time
        char *reason_time_str
        uint32_t reason_uid
        time_t slurmd_start_time
        char slurmd_start_time_str[32]
        uint16_t sockets
        uint16_t threads_per_core
        uint32_t tmp_disk
        char *version
        uint32_t weight

    property alloc_mem:
        def __get__(self):
            return self.alloc_mem

    property arch:
        def __get__(self):
            return strOrNone(self.arch)

    property boards:
        def __get__(self):
            return self.boards

    property boot_time:
        def __get__(self):
            return self.boot_time

    property boot_time_str:
        def __get__(self):
            return self.boot_time_str

    property cores_per_socket:
        def __get__(self):
            return self.cores_per_socket

    property core_spec_cnt:
        def __get__(self):
            return self.core_spec_cnt

    property cpu_alloc:
        def __get__(self):
            return self.cpu_alloc

    property cpu_err:
        def __get__(self):
            return self.cpu_err

    property cpu_load:
        def __get__(self):
            if self.cpu_load == NO_VAL:
                return "N/A"
            else:
                return "%.2f" % (self.cpu_load / 100.0)

    property cpu_tot:
        def __get__(self):
            return self.cpu_tot

    property cpu_spec_list:
        def __get__(self):
            return listOrNone(self.cpu_spec_list)

    property available_features:
        def __get__(self):
            return listOrNone(self.available_features)

    property free_mem:
        def __get__(self):
            if self.free_mem == NO_VAL:
                return "N/A"
            else:
                return self.free_mem

    property gres:
        def __get__(self):
            return listOrNone(self.gres)

    property gres_drain:
        def __get__(self):
            return listOrNone(self.gres_drain)

    property gres_used:
        def __get__(self):
            return listOrNone(self.gres_used)

    property mem_spec_limit:
        def __get__(self):
            return self.mem_spec_limit

    property name:
        def __get__(self):
#            cdef bytes py_string = self.name
#            return py_string
            return strOrNone(self.name)

    property node_addr:
        def __get__(self):
            return strOrNone(self.node_addr)

    property node_hostname:
        def __get__(self):
            return strOrNone(self.node_hostname)

    property state:
        def __get__(self):
            return strOrNone(self.state)

    property os:
        def __get__(self):
            if self.os:
                return strOrNone(self.os)
            else:
                return None

    property owner:
        def __get__(self):
            if self.owner == NO_VAL:
                return "N/A"
            else:
                return self.owner

    property real_memory:
        def __get__(self):
            return self.real_memory

    property slurmd_start_time:
        def __get__(self):
            return self.slurmd_start_time

    property slurmd_start_time_str:
        def __get__(self):
            return self.slurmd_start_time_str

    property sockets:
        def __get__(self):
            return self.sockets

    property threads_per_core:
        def __get__(self):
            return self.threads_per_core

    property tmp_disk:
        def __get__(self):
            return self.tmp_disk

    property version:
        def __get__(self):
            return strOrNone(self.version)

    property weight:
        def __get__(self):
            return self.weight


cpdef list get_nodes_ids():
    """
    Return a list of all node ids.

    This function calls slurm_load_node and returns a list of node names
    configured in the cluster.

    Args:
        None
    Returns:
        A list of all node ids.
    Raises:
        PySlurmError: if slurm_load_node is not successful.
    """
    cdef:
        node_info_msg_t *node_info_msg_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        uint32_t i
        int rc
        list all_nodes = []

    rc = slurm_load_node(<time_t>NULL, &node_info_msg_ptr, show_flags)

    if rc == SLURM_SUCCESS:
        for i in range(node_info_msg_ptr.record_count):
            all_nodes.append(node_info_msg_ptr.node_array[i].name)

        slurm_free_node_info_msg(node_info_msg_ptr)
        node_info_msg_ptr = NULL
        return all_nodes
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


cpdef list get_nodes():
    """
    Return a list of all Node objects.

    This function calls slurm_load_node. It reuses the get_node function.

    Args:
        None
    Returns:
        A list of Node objects, one for each node in the cluster.
    Raises:
        PySlurmError: if slurm_load_node is unsuccessful.
    """
    return get_node(NULL)


cpdef get_node(char *nodeID):
    """Return a list of one or all Node objects.

    This function calls either slurm_load_node or slurm_load_node_single to
    return Node objects.  slurm_load_node_single will return a single Node
    object, whereas slurm_load_node will return all Node objects, one for each
    node configured in the cluster.

    If nodeID is NULL, then call slurm_load_node to get all nodes.
    If nodeID is not NULL, then call slurm_load_node_single to get specific
    node.

    Args:
        nodeID (str): node id to query
    Returns:
        A single node object or a list of all Node objects
    Raises:
        PySlurmError: if slurm_load_node or slurm_load_node_single is
        unsuccessful.
    """
    cdef:
        node_info_msg_t *node_info_msg_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        int cpus_per_node = 1
        int idle_cpus
        int inx
        int rc
        int total_used
        char *cloud_str = ""
        char *comp_str = ""
        char *drain_str = ""
        char *power_str = ""
        char *reason_str = NULL
        char *select_reason_str = NULL
        char time_str[32]
        char *save_ptr = NULL
        char *tok
        char *user_name
        uint16_t err_cpus = 0
        uint16_t alloc_cpus = 0
        uint32_t i
        uint32_t alloc_memory
        uint32_t my_state
        #uint32_t cluster_flags = slurmdb_setup_cluster_flags()
        list node_list = []

    if nodeID == NULL:
        rc = slurm_load_node(<time_t>NULL, &node_info_msg_ptr, show_flags)
    else:
        rc = slurm_load_node_single(&node_info_msg_ptr, nodeID, show_flags)

    if rc == SLURM_SUCCESS:
        for i in range(node_info_msg_ptr.record_count):
            record = &node_info_msg_ptr.node_array[i]

            my_state = record.node_state

#            if node_scaling:
#                cpus_per_node = record.cpus / node_scaling

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

            slurm_get_select_nodeinfo(record.select_nodeinfo,
                                      SELECT_NODEDATA_SUBCNT,
                                      NODE_STATE_ALLOCATED,
                                      &alloc_cpus)

#            if (cluster_flags & CLUSTER_FLAG_BG):
#                if (not alloc_cpus and
#                    (IS_NODE_ALLOCATED(record) or
#                     IS_NODE_COMPLETING(record))):
#                    alloc_cpus = record.cpus
#                else:
#                    alloc_cpus *= cpus_per_node

            idle_cpus = record.cpus - alloc_cpus

            slurm_get_select_nodeinfo(record.select_nodeinfo,
                                      SELECT_NODEDATA_SUBCNT,
                                      NODE_STATE_ERROR,
                                      &err_cpus)

#            if (cluster_flags & CLUSTER_FLAG_BG):
#                err_cpus *= cpus_per_node

            idle_cpus -= err_cpus

            if (alloc_cpus and err_cpus) or (idle_cpus and
                   (idle_cpus != record.cpus)):
                    my_state &= NODE_STATE_FLAGS
                    my_state |= NODE_STATE_MIXED

            # Instantiate empty Node class instance for storing attributes
            this_node = Node()

            this_node.name = record.name

#            if (cluster_flags & CLUSTER_FLAG_BG):
#                slurm_get_select_nodeinfo(record.select_nodeinfo,
#                                          SELECT_NODEDATA_RACK_MP,
#                                          0, &select_reason_str)
#                if select_reason_str:
#                    this_node.rack_midplane = select_reason_str

            if record.arch:
                this_node.arch = record.arch

            this_node.cores_per_socket = record.cores
            this_node.cpu_alloc = alloc_cpus
            this_node.cpu_err = err_cpus
            this_node.cpu_tot = record.cpus
            this_node.cpu_load = record.cpu_load
            this_node.available_features = record.features
            #this_node.active_features = record.features_act
            this_node.gres = record.gres

            if record.gres_drain:
                this_node.gres_drain = record.gres_drain

            if record.gres_used:
                this_node.gres_used = record.gres_used

            if record.node_hostname or record.node_addr:
                this_node.node_addr = record.node_addr
                this_node.node_hostname = record.node_hostname
                this_node.version = record.version

            if record.os:
                this_node.os = record.os

            slurm_get_select_nodeinfo(record.select_nodeinfo,
                                      SELECT_NODEDATA_MEM_ALLOC,
                                      NODE_STATE_ALLOCATED,
                                      &alloc_memory)

            this_node.real_memory = record.real_memory
            this_node.alloc_mem = alloc_memory
            this_node.free_mem = record.free_mem
            this_node.sockets = record.sockets
            this_node.boards = record.boards

            # Core and Memory Specialization
            if (record.core_spec_cnt or record.cpu_spec_list or
                record.mem_spec_limit):
                if record.core_spec_cnt:
                    this_node.core_spec_count = record.core_spec_cnt
                if record.cpu_spec_list:
                    this_node.cpu_spec_list = record.cpu_spec_list
                if record.mem_spec_limit:
                    this_node.mem_spec_limit = record.mem_spec_limit

#            this_node.state = (slurm_node_state_string(my_state) + cloud_str +
#                               comp_str + drain_str + power_str)
            this_node.state = slurm_node_state_string(my_state)

            this_node.threads_per_core = record.threads
            this_node.tmp_disk = record.tmp_disk
            this_node.weight = record.weight
            this_node.owner = record.owner

#            if record.mcs_label == NULL:
#                this_node.mcs_label = "N/A"
#            else:
#                this_node.mcs_label = record.mcs_label

            if record.boot_time:
                this_node.boot_time = record.boot_time
                slurm_make_time_str(<time_t *>&record.boot_time,
                                    time_str, sizeof(time_str))
                this_node.boot_time_str = time_str

            if record.slurmd_start_time:
                slurm_make_time_str(<time_t *>&record.slurmd_start_time,
                                    time_str, sizeof(time_str))
                this_node.slurmd_start_time_str = time_str
                this_node.slurmd_start_time = record.slurmd_start_time

#            # Power Management
#            if (not record.power or (record.power.cap_watts == NO_VAL)):
#                this_node.cap_watts = "n/a"
#            else:
#                this_node.cap_watts = record.power.cap_watts
#
#            # Power Consumption
#            if (not record.energy or (record.energy.current_watts == NO_VAL)):
#                this_node.current_watts = "n/s"
#                this_node.lowest_joules = "n/s"
#                this_node.consumed_joules = "n/s"
#            else:
#                this_node.current_watts = record.energy.current_watts
#                this_node.lowest_joules = int(record.energy.base_consumed_energy)
#                this_node.consumed_joules = int(record.energy.consumed_energy)
#
#            # External Sensors
#            if (not record.ext_sensors or (record.ext_sensors.consumed_energy == NO_VAL)):
#                this_node.ext_sensors_joules = "n/s"
#            else:
#                this_node.ext_sensors_joules = int(record.ext_sensors.consumed_energy)
#
#            if (not record.ext_sensors or (record.ext_sensors.current_watts == NO_VAL)):
#                this_node.ext_sensors_watts = "n/s"
#            else:
#                this_node.ext_sensors_watts = record.ext_sensors.current_watts
#
#            if (not record.ext_sensors or (record.ext_sensors.temperature == NO_VAL)):
#                this_node.ext_sensors_temp = "n/s"
#            else:
#                this_node.ext_sensors_temp = record.ext_sensors.temperature

#            if record.reason and record.reason[0]:
#                reason_str = record.reason
#
#            slurm_get_select_nodeinfo(record.select_nodeinfo,
#                                      SELECT_NODEDATA_EXTRA_INFO,
#                                      0, &select_reason_str)
#
#            if select_reason_str and select_reason_str[0]:
#                reason_str += select_reason_str
#
#            #xfree(select_reason_str)
#
#            if reason_str:
#                inx = 1
#                tok = strtok_r(reason_str, "\n", &save_ptr)
#
#                while tok:
#                    this_node.reason_str += tok
#                    inx += 1
#                    if (inx == 1) and (record.reason_time):
#                        slurm_make_time_str(<time_t *>&record.reason_time,
#                                            time_str, sizeof(time_str))
#                        this_node.reason_str += record.reason_uid + "@" + time_str
#                    tok = strtok_r(NULL, "\n", &save_ptr)
#                this_node.reason_uid = record.reason_uid
#                this_node.reason_time = record.reason_time
#                this_node.reason_time_str = time_str
#                #xfree(reason_str)

            node_list.append(this_node)

        slurm_free_node_info_msg(node_info_msg_ptr)
        node_info_msg_ptr = NULL

        if nodeID == NULL:
            return node_list
        else:
            return this_node
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


cpdef print_node_info_msg(int one_liner=False):
    """
    Print information about all nodes to stdout.

    This function outputs information about all Slurm nodes based upon the
    message loaded by slurm_load_node. It uses the slurm_print_node_info_msg
    function to print to stdout.

    Args:
        one_liner (bool): print each node on one line if True (default False)
    Returns:
        None
    Raises:
        PySlurmError: if slurm_load_node is not successful.
    """
    cdef:
        node_info_msg_t *node_info_msg_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        int rc

    rc = slurm_load_node(<time_t>NULL, &node_info_msg_ptr, show_flags)

    if rc == SLURM_SUCCESS:
        slurm_print_node_info_msg(stdout, node_info_msg_ptr, one_liner)
        slurm_free_node_info_msg(node_info_msg_ptr)
        node_info_msg_ptr = NULL
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


cpdef print_node_info_table(char *nodeID, int one_liner=False):
    """
    Print information about a specific node to stdout.

    This function outputs information about all Slurm nodes based upon the
    message loaded by slurm_load_node_single. It uses the
    slurm_print_node_table function to print to stdout.

    return {
        "node_names": "",
        "gres": "",
        "reason": "",
        "node_state": -1,
        "weight": -1,
        "features": ""
    }

    Args:
        one_liner (bool): print each node on one line if True (default False)
    Returns:
        None
    Raises:
        PySlurmError: if slurm_load_node is not successful.
    """
    cdef:
        node_info_msg_t *node_info_msg_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        int rc

    rc = slurm_load_node_single(&node_info_msg_ptr, nodeID, show_flags)

    if rc == SLURM_SUCCESS:
        slurm_print_node_table(stdout, &node_info_msg_ptr.node_array[0],
                               node_info_msg_ptr.node_scaling, one_liner)
        slurm_free_node_info_msg(node_info_msg_ptr)
        node_info_msg_ptr = NULL
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


cpdef int update_node(dict node_dict):
    """

    This method required root privileges.
    """
    cdef:
        update_node_msg_t update_node_msg
        int rc

    if not node_dict:
        raise PySlurmError("You must provide a valid node update dictionary.")

    slurm_init_update_node_msg(&update_node_msg)

    if "features" in node_dict:
        update_node_msg.features = node_dict["features"]

    if "gres" in node_dict:
        update_node_msg.gres = node_dict["gres"]

    # Optional
    if "node_addr" in node_dict:
        update_node_msg.node_addr = node_dict["node_addr"]

    # Optional
    if "node_hostname" in node_dict:
        update_node_msg.node_hostname = node_dict["node_hostname"]

    if "node_names" in node_dict:
        update_node_msg.node_names = node_dict["node_names"]

    if "node_state" in node_dict:
        update_node_msg.node_state = <uint32_t>node_dict["node_state"]

    if "reason" in node_dict:
        update_node_msg.reason = node_dict["reason"]
        update_node_msg.reason_uid = <uint32_t>_os.getuid()

    if "weight" in node_dict:
        update_node_msg.weight = <uint32_t>node_dict["weight"]

    rc = slurm_update_node(&update_node_msg)

    if rc != SLURM_SUCCESS:
        raise PySlurmError(slurm_strerror(rc), rc)

    return rc
