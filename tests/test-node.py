from __future__ import print_function, division, absolute_import

import pyslurm
import re
import subprocess
from nose.tools import assert_equals


def test_get_nodes():
    """Test get_nodes(), get_nodes_ids(), their count and type."""
    all_nodes = pyslurm.node.get_nodes()
    assert isinstance(all_nodes, list)

    all_node_ids = pyslurm.node.get_nodes_ids()
    assert isinstance(all_node_ids, list)

    assert len(all_nodes) == len(all_node_ids)

    first_node = all_nodes[0]
    assert first_node.node_name in all_node_ids


def test_node_scontrol():
    """Compare scontrol values to PySlurm values."""
#    try:
#        basestring
#    except NameError:
#        basestring = str

    all_node_ids = pyslurm.node.get_nodes_ids()
    # TODO: 
    # convert to a function and  use a for loop to get a running node and a
    # drained/downed node as well, mixed and allocated
    # and a non-existent node
    test_node = all_node_ids[0]
#    assert isinstance(test_node, basestring)

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

    if sctl.get("Arch"):
        assert obj.arch == sctl["Arch"]

    assert obj.boards == sctl["Boards"]
    assert obj.boot_time_str == sctl["BootTime"]
    assert obj.cap_watts == sctl["CapWatts"]
    assert obj.cores_per_socket == sctl["CoresPerSocket"]
    assert obj.cpu_alloc == sctl["CPUAlloc"]
    assert obj.cpu_err == sctl["CPUErr"]

    try:
        assert obj.cpu_load == sctl["CPULoad"]
    except AssertionError:
        assert obj.cpu_load == float(sctl["CPULoad"])

    assert obj.cpu_tot == sctl["CPUTot"]
    assert obj.consumed_joules == sctl["ConsumedJoules"]
    assert obj.cores_per_socket == sctl["CoresPerSocket"]
    assert obj.current_watts == sctl["CurrentWatts"]
    assert obj.ext_sensors_joules == sctl["ExtSensorsJoules"]

    assert obj.ext_sensors_temp == sctl["ExtSensorsTemp"]
    assert obj.ext_sensors_watts == sctl["ExtSensorsWatts"]
    assert obj.features == sctl["Features"].split(",")
    assert obj.free_mem == sctl["FreeMem"]
    assert obj.gres == sctl["Gres"].split(",")

    assert obj.gres_drain == sctl["GresDrain"].split(",")
    assert obj.gres_used == sctl["GresUsed"].split(",")
    assert obj.lowest_joules == sctl["LowestJoules"]
    assert obj.node_name == sctl["NodeName"]
    assert obj.node_addr == sctl["NodeAddr"]
    assert obj.node_host_name == sctl["NodeHostName"]

    if sctl.get("OS"):
        assert obj.os == sctl["OS"]

    assert obj.owner == sctl["Owner"]
    assert obj.real_memory == sctl["RealMemory"]
    assert obj.slurmd_start_time_str == sctl["SlurmdStartTime"]
    assert obj.sockets == sctl["Sockets"]
    assert obj.state == sctl["State"]

    assert obj.threads_per_core == sctl["ThreadsPerCore"]
    assert obj.tmp_disk == sctl["TmpDisk"]
    assert obj.version == sctl["Version"]
    assert obj.weight == sctl["Weight"]
