from __future__ import absolute_import, unicode_literals

import pyslurm
import subprocess
from nose.tools import assert_equals, assert_true

def test_node_get():
    """Node: Test node().get() return type."""
    all_nodes = pyslurm.node().get()
    assert_true(isinstance(all_nodes, dict))


def test_node_ids():
    """Node: Test node().ids() return type."""
    all_node_ids = pyslurm.node().ids()
    assert_true(isinstance(all_node_ids, list))


def test_node_count():
    """Node: Test node count."""
    all_nodes = pyslurm.node().get()
    all_node_ids = pyslurm.node().ids()
    assert_equals(len(all_nodes), len(all_node_ids))


def test_node_scontrol():
    """Node: Compare scontrol values to PySlurm values."""
    all_node_ids = pyslurm.node().ids()
    test_node = all_node_ids[0]

    test_node_info = pyslurm.node().find_id(test_node)
    assert_equals(test_node, test_node_info["name"])

    sctl = subprocess.Popen(["scontrol", "-d", "show", "node", test_node],
                            stdout=subprocess.PIPE).communicate()
    sctl_stdout = sctl[0].strip().decode("UTF-8").split()
    sctl_dict = dict((value.split("=")[0], value.split("=")[1])
                     for value in sctl_stdout)

    assert_equals(test_node_info["alloc_mem"], int(sctl_dict["AllocMem"]))
    assert_equals(test_node_info["boards"], int(sctl_dict["Boards"]))
    assert_equals(test_node_info["alloc_cpus"], int(sctl_dict["CPUAlloc"]))
    assert_equals(test_node_info["err_cpus"], int(sctl_dict["CPUErr"]))
    assert_equals(test_node_info["cpus"], int(sctl_dict["CPUTot"]))
    assert_equals(test_node_info["energy"]["consumed_energy"], int(sctl_dict["ConsumedJoules"]))
    assert_equals(test_node_info["cores"], int(sctl_dict["CoresPerSocket"]))
    assert_equals(test_node_info["energy"]["current_watts"], int(sctl_dict["CurrentWatts"]))
    assert_equals(test_node_info["name"], sctl_dict["NodeName"])
    assert_equals(test_node_info["node_addr"], sctl_dict["NodeAddr"])
    assert_equals(test_node_info["node_hostname"], sctl_dict["NodeHostName"])
    assert_equals(test_node_info["real_memory"], int(sctl_dict["RealMemory"]))
    assert_equals(test_node_info["sockets"], int(sctl_dict["Sockets"]))
    assert_equals(test_node_info["state"], sctl_dict["State"])
    assert_equals(test_node_info["threads"], int(sctl_dict["ThreadsPerCore"]))
    assert_equals(test_node_info["tmp_disk"], int(sctl_dict["TmpDisk"]))
    assert_equals(test_node_info["weight"], int(sctl_dict["Weight"]))
