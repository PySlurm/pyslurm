"""Test cases for Slurm Partitions."""

import pyslurm
from tests.common import scontrol_show


def test_partition_get():
    """Partition: Test partition().get() return type."""
    all_partitions = pyslurm.partition().get()
    assert isinstance(all_partitions, dict)


def test_partition_ids():
    """Partition: Test partition().ids() return type."""
    all_partition_ids = pyslurm.partition().ids()
    assert isinstance(all_partition_ids, list)


def test_partition_count():
    """Partition: Test partition count."""
    all_partitions = pyslurm.partition().get()
    all_partition_ids = pyslurm.partition().ids()
    assert len(all_partitions) == len(all_partition_ids)


def test_partition_scontrol():
    """Partition: Compare scontrol values to PySlurm values."""
    all_partition_ids = pyslurm.partition().ids()
    test_partition = all_partition_ids[0]

    test_partition_info = pyslurm.partition().find_id(test_partition)
    assert test_partition == test_partition_info["name"]

    sctl_dict = scontrol_show("partition", str(test_partition))

    assert test_partition_info["allow_alloc_nodes"] == sctl_dict["AllocNodes"]
    assert test_partition_info["allow_accounts"] == sctl_dict["AllowAccounts"]
    assert test_partition_info["allow_groups"] == sctl_dict["AllowGroups"]
    assert test_partition_info["allow_qos"] == sctl_dict["AllowQos"]
    # assert test_partition_info["def_mem_per_node"] == sctl_dict["DefMemPerNode"]
    assert test_partition_info["default_time_str"] == sctl_dict["DefaultTime"]
    assert test_partition_info["grace_time"] == int(sctl_dict["GraceTime"])
    assert test_partition_info["max_cpus_per_node"] == sctl_dict["MaxCPUsPerNode"]
    assert test_partition_info["max_mem_per_node"] == sctl_dict["MaxMemPerNode"]
    assert test_partition_info["max_nodes"] == int(sctl_dict["MaxNodes"])
    assert test_partition_info["max_time_str"] == sctl_dict["MaxTime"]
    assert test_partition_info["min_nodes"] == int(sctl_dict["MinNodes"])
    assert test_partition_info["nodes"] == sctl_dict["Nodes"]
    assert test_partition_info["name"] == sctl_dict["PartitionName"]
    # assert test_partition_info["preempt_mode"] == sctl_dict["PreemptMode"]
    assert test_partition_info["state"] == sctl_dict["State"]
    assert test_partition_info["total_cpus"] == int(sctl_dict["TotalCPUs"])
    assert test_partition_info["total_nodes"] == int(sctl_dict["TotalNodes"])


def test_partition_create():
    """Partition: Test partition().create()."""
    part_test = {"Name": "part_test"}
    rc = pyslurm.partition().create(part_test)
    assert rc == 0

    partition_ids = pyslurm.partition().ids()
    assert "part_test" in partition_ids


def test_partition_update():
    """Partition: Test partition().update()."""
    part_test_before = pyslurm.partition().find_id("part_test")
    assert part_test_before["state"] == "UP"

    part_test_update = {"Name": "part_test", "State": "DOWN"}
    rc = pyslurm.partition().update(part_test_update)
    assert rc == 0

    part_test_after = pyslurm.partition().find_id("part_test")
    assert part_test_after["state"] == "DOWN"


def test_partition_delete():
    """Partition: Test partition().delete()."""
    rc = pyslurm.partition().delete("part_test")
    assert rc == 0

    partition_ids = pyslurm.partition().ids()
    assert "part_test" not in partition_ids
