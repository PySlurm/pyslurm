from __future__ import division, print_function

import pyslurm
import subprocess
from types import *

def setup():
    pass


def teardown():
    pass


def test_node_get():
    all_nodes = pyslurm.node().get()
    assert type(all_nodes) is DictType


def test_node_ids():
    all_node_ids = pyslurm.node().ids()
    assert type(all_node_ids) is ListType


def test_node_count():
    all_nodes = pyslurm.node().get()
    all_node_ids = pyslurm.node().ids()
    assert len(all_nodes) == len(all_node_ids)


def test_node_scontrol():
    all_node_ids = pyslurm.node().ids()
    test_node = all_node_ids[0]
#    assert type(test_node) is StringType

    test_node_info = pyslurm.node().find_id(test_node)
    assert test_node == test_node_info["name"]

    scontrol = subprocess.Popen(["scontrol", "-d", "show", "node", test_node],
                                stdout=subprocess.PIPE).communicate()
    scontrol_stdout = scontrol[0].strip().split()
    scontrol_dict = {value.split("=")[0]: value.split("=")[1]
                     for value in scontrol_stdout}

    assert test_node_info["alloc_mem"] == int(scontrol_dict["AllocMem"])
#    assert test_node_info["arch"] == scontrol_dict["Arch"]
    assert test_node_info["boards"] == int(scontrol_dict["Boards"])
    #BootTime=2016-01-12T23:56:26
    assert test_node_info["alloc_cpus"] == int(scontrol_dict["CPUAlloc"])
    assert test_node_info["err_cpus"] == int(scontrol_dict["CPUErr"])
    assert test_node_info["cpus"] == int(scontrol_dict["CPUTot"])
    #CPULoad=0.01
    #CapWatts=n/a
    assert test_node_info["energy"]["consumed_energy"] == int(scontrol_dict["ConsumedJoules"])
    assert test_node_info["cores"] == int(scontrol_dict["CoresPerSocket"])
    assert test_node_info["energy"]["current_watts"] == int(scontrol_dict["CurrentWatts"])
    # TODO: skipping some
#    assert test_node_info["features"] == scontrol_dict["Features"]
#    assert test_node_info["free_mem"] == int(scontrol_dict["FreeMem"])
    # TODO: skipping some
    assert test_node_info["name"] == scontrol_dict["NodeName"]
    assert test_node_info["node_addr"] == scontrol_dict["NodeAddr"]
    assert test_node_info["node_hostname"] == scontrol_dict["NodeHostName"]
#    assert test_node_info["os"] == scontrol_dict["OS"]
    assert test_node_info["real_memory"] == int(scontrol_dict["RealMemory"])
    assert test_node_info["sockets"] == int(scontrol_dict["Sockets"])
    assert test_node_info["state"] == scontrol_dict["State"]
    assert test_node_info["threads"] == int(scontrol_dict["ThreadsPerCore"])
    assert test_node_info["tmp_disk"] == int(scontrol_dict["TmpDisk"])
#    assert test_node_info["version"] == scontrol_dict["Version"]
    assert test_node_info["weight"] == int(scontrol_dict["Weight"])
