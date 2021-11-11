"""Test cases for a Slurm Node."""

import time

import pyslurm
from tests.common import scontrol_show


def test_node_get():
    """Node: Test node().get() return type."""
    all_nodes = pyslurm.node().get()
    assert isinstance(all_nodes, dict)


def test_node_ids():
    """Node: Test node().ids() return type."""
    all_node_ids = pyslurm.node().ids()
    assert isinstance(all_node_ids, list)


def test_node_count():
    """Node: Test node count."""
    all_nodes = pyslurm.node().get()
    all_node_ids = pyslurm.node().ids()
    assert len(all_nodes) == len(all_node_ids)


def test_node_scontrol():
    """Node: Compare scontrol values to PySlurm values."""
    all_node_ids = pyslurm.node().ids()
    test_node = all_node_ids[-1]

    test_node_info = pyslurm.node().find_id(test_node)
    assert test_node == test_node_info["name"]

    sctl_dict = scontrol_show("node", test_node)

    assert test_node_info["alloc_mem"] == int(sctl_dict["AllocMem"])
    assert test_node_info["boards"] == int(sctl_dict["Boards"])
    assert test_node_info["alloc_cpus"] == int(sctl_dict["CPUAlloc"])
    assert test_node_info["cpus"] == int(sctl_dict["CPUTot"])
    assert test_node_info["cores"] == int(sctl_dict["CoresPerSocket"])
    assert test_node_info["energy"]["current_watts"] == int(sctl_dict["CurrentWatts"])
    assert test_node_info["name"] == sctl_dict["NodeName"]
    assert test_node_info["node_addr"] == sctl_dict["NodeAddr"]
    assert test_node_info["node_hostname"] == sctl_dict["NodeHostName"]
    assert test_node_info["partitions"] == sctl_dict["Partitions"].split(",")
    assert test_node_info["real_memory"] == int(sctl_dict["RealMemory"])
    assert test_node_info["sockets"] == int(sctl_dict["Sockets"])
    assert test_node_info["state"] == sctl_dict["State"]
    assert test_node_info["threads"] == int(sctl_dict["ThreadsPerCore"])
    assert test_node_info["tmp_disk"] == int(sctl_dict["TmpDisk"])
    assert test_node_info["weight"] == int(sctl_dict["Weight"])


def test_node_update():
    """Node: Test node().update()."""

    time.sleep(3)
    test_node = pyslurm.node().ids()[-1]
    node_test_before = pyslurm.node().find_id(test_node)
    assert node_test_before["state"] == "IDLE"

    node_test_update = {
        "node_names": "c10",
        "node_state": pyslurm.NODE_STATE_DRAIN,
        "reason": "unit testing",
    }

    rc = pyslurm.node().update(node_test_update)
    assert rc == 0

    node_test_during = pyslurm.node().find_id("c10")
    assert node_test_during["state"] == "IDLE+DRAIN"

    node_test_update = {"node_names": "c10", "node_state": pyslurm.NODE_RESUME}

    rc = pyslurm.node().update(node_test_update)
    assert rc == 0

    node_test_after = pyslurm.node().find_id("c10")
    assert node_test_after["state"] == "IDLE"


def test_gres_used_parser():
    """Node: Test node().parse_gres()."""
    assert pyslurm.node().parse_gres("gpu:p100:2(IDX:1,3),lscratch:0") == [
        "gpu:p100:2(IDX:1,3)",
        "lscratch:0",
    ]
    assert pyslurm.node().parse_gres("gpu:0,hbm:0") == ["gpu:0", "hbm:0"]
    assert pyslurm.node().parse_gres("gpu:p100:0(IDX:N/A),hbm:0") == [
        "gpu:p100:0(IDX:N/A)",
        "hbm:0",
    ]
    assert pyslurm.node().parse_gres("gpu:p100:1(IDX:0),hbm:0") == [
        "gpu:p100:1(IDX:0)",
        "hbm:0",
    ]
    assert pyslurm.node().parse_gres("gpu:p100:1(IDX:1),hbm:0") == [
        "gpu:p100:1(IDX:1)",
        "hbm:0",
    ]
    assert pyslurm.node().parse_gres("gpu:p100:2(IDX:0-1),hbm:0") == [
        "gpu:p100:2(IDX:0-1)",
        "hbm:0",
    ]
    assert pyslurm.node().parse_gres("hbm:0") == ["hbm:0"]
    assert pyslurm.node().parse_gres("lscratch:0,hbm:0") == ["lscratch:0", "hbm:0"]
