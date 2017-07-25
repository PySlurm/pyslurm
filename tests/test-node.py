from __future__ import print_function, division, absolute_import

import pyslurm
import re
import subprocess
from nose.tools import assert_equals, assert_true

def test_get_node():
    """Node: Test get_node() return type"""
    all_node_ids = pyslurm.node.get_nodes(ids=True)
    assert_true(isinstance(all_node_ids, list))

    test_node = all_node_ids[0]
    test_node_obj = pyslurm.node.get_node(test_node)
    assert_true(isinstance(test_node_obj, pyslurm.node.Node))


def test_get_nodes():
    """Node: Test get_nodes(), their count and type."""
    all_nodes = pyslurm.node.get_nodes()
    assert_true(isinstance(all_nodes, list))

    all_node_ids = pyslurm.node.get_nodes(ids=True)
    assert_true(isinstance(all_node_ids, list))

    assert_equals(len(all_nodes), len(all_node_ids))

    first_node = all_nodes[0]
    assert_true(first_node.node_name in all_node_ids)


def test_node_scontrol():
    """Node: Compare scontrol values to PySlurm values."""
#    try:
#        basestring
#    except NameError:
#        basestring = str

    all_node_ids = pyslurm.node.get_nodes(ids=True)
    # TODO: 
    # convert to a function and  use a for loop to get a running node and a
    # drained/downed node as well, mixed and allocated
    # and a non-existent node
    test_node = all_node_ids[0]
#    assert_equals(isinstance(test_node, basestring)

    obj = pyslurm.node.get_node(test_node)
    assert_equals(test_node, obj.node_name)

    scontrol = subprocess.Popen(["scontrol", "-ddo", "show", "node", test_node],
                                stdout=subprocess.PIPE).communicate()
    scontrol = scontrol[0].strip().decode("UTF-8", "replace")

    # Convert scontrol show node <node> into a dictionary of key value pairs.
    # The regex is to search for values that have a space, typically this would
    # be the Reason parameter if a node has been drained
    sctl = {}
    for item in re.finditer("(\w+)=([^\s]+)(\s(?=\[).*\])?", scontrol):
        kv = item.group().split("=")
        if kv[1] in ["None", "(null)"]:
            sctl.update({kv[0]: None})
        elif kv[1].isdigit():
            sctl.update({kv[0]: int(kv[1])})
        else:
            sctl.update({kv[0]: kv[1]})

    assert_equals(obj.alloc_mem, sctl["AllocMem"])

    assert_equals(obj.arch, sctl.get("Arch"))
    assert_equals(obj.boards, sctl["Boards"])
    assert_equals(obj.boot_time_str, sctl["BootTime"])
    assert_equals(obj.cap_watts, sctl["CapWatts"])
    assert_equals(obj.cores_per_socket, sctl["CoresPerSocket"])
    assert_equals(obj.cpu_alloc, sctl["CPUAlloc"])
    assert_equals(obj.cpu_err, sctl["CPUErr"])

    try:
        assert_equals(obj.cpu_load, sctl["CPULoad"])
    except AssertionError:
        assert_equals(obj.cpu_load, float(sctl["CPULoad"]))

    assert_equals(obj.consumed_joules, sctl["ConsumedJoules"])

    if sctl.get("CoreSpecCount"):
        assert_equals(obj.core_spec_count, sctl["CoreSpecCount"])

    assert_equals(obj.cores_per_socket, sctl["CoresPerSocket"])

    if sctl.get("CPUSpecList"):
        assert_equals(obj.cpu_spec_list, sctl["CPUSpecList"].split(","))

    assert_equals(obj.cpu_tot, sctl["CPUTot"])
    assert_equals(obj.current_watts, sctl["CurrentWatts"])
    assert_equals(obj.ext_sensors_joules, sctl["ExtSensorsJoules"])
    assert_equals(obj.ext_sensors_temp, sctl["ExtSensorsTemp"])
    assert_equals(obj.ext_sensors_watts, sctl["ExtSensorsWatts"])

    if sctl.get("AvailableFeatures"):
        assert_equals(obj.available_features, sctl["AvailableFeatures"].split(","))

    if sctl.get("ActiveFeatures"):
        assert_equals(obj.active_features, sctl["ActiveFeatures"].split(","))

    assert_equals(obj.free_mem, sctl["FreeMem"])

    if sctl.get("Gres"):
        assert_equals(obj.gres, sctl["Gres"].split(","))

    if sctl.get("GresDrain"):
        assert_equals(obj.gres_drain, sctl["GresDrain"].split(","))

    if sctl.get("GresUsed"):
        assert_equals(obj.gres_used, sctl["GresUsed"].split(","))

    assert_equals(obj.lowest_joules, sctl["LowestJoules"])

    if sctl.get("MemSpecLimit"):
        assert_equals(obj.mem_spec_limit, sctl.get("MemSpecLimit"))

    assert_equals(obj.node_name, sctl["NodeName"])
    assert_equals(obj.node_addr, sctl["NodeAddr"])
    assert_equals(obj.node_host_name, sctl["NodeHostName"])
    assert_equals(obj.os, sctl.get("OS"))
    assert_equals(obj.owner, sctl["Owner"])
    assert_equals(obj.partitions, sctl["Partitions"])
    assert_equals(obj.real_memory, sctl["RealMemory"])
    assert_equals(obj.reason_str, sctl.get("Reason"))
    assert_equals(obj.slurmd_start_time_str, sctl["SlurmdStartTime"])
    assert_equals(obj.sockets, sctl["Sockets"])
    assert_equals(obj.state, sctl["State"])
    assert_equals(obj.threads_per_core, sctl["ThreadsPerCore"])
    assert_equals(obj.tmp_disk, sctl["TmpDisk"])

    if sctl.get("Version"):
        assert_equals(obj.version, sctl["Version"])

    assert_equals(obj.weight, sctl["Weight"])
