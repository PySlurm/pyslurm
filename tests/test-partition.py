from __future__ import absolute_import, unicode_literals

import pyslurm
from nose.tools import assert_equals, assert_true

from common import scontrol_show

def test_partition_get():
    """Partition: Test partition().get() return type."""
    all_partitions = pyslurm.partition().get()
    assert_true(isinstance(all_partitions, dict))


def test_partition_ids():
    """Partition: Test partition().ids() return type."""
    all_partition_ids = pyslurm.partition().ids()
    assert_true(isinstance(all_partition_ids, list))


def test_partition_count():
    """Partition: Test partition count."""
    all_partitions = pyslurm.partition().get()
    all_partition_ids = pyslurm.partition().ids()
    assert_equals(len(all_partitions), len(all_partition_ids))


def test_partition_scontrol():
    """Partition: Compare scontrol values to PySlurm values."""
    all_partition_ids = pyslurm.partition().ids()
    test_partition = all_partition_ids[0]

    test_partition_info = pyslurm.partition().find_id(test_partition)
    assert_equals(test_partition, test_partition_info["name"])

    sctl_dict = scontrol_show('partition', str(test_partition))

    assert_equals(test_partition_info["allow_alloc_nodes"], sctl_dict["AllocNodes"])
    assert_equals(test_partition_info["allow_accounts"], sctl_dict["AllowAccounts"])
    assert_equals(test_partition_info["allow_groups"], sctl_dict["AllowGroups"])
    assert_equals(test_partition_info["allow_qos"], sctl_dict["AllowQos"])
    assert_equals(test_partition_info["def_mem_per_cpu"], int(sctl_dict["DefMemPerCPU"]))
    assert_equals(test_partition_info["default_time_str"], sctl_dict["DefaultTime"])
    assert_equals(test_partition_info["grace_time"], int(sctl_dict["GraceTime"]))
    assert_equals(test_partition_info["max_cpus_per_node"], sctl_dict["MaxCPUsPerNode"])
    assert_equals(test_partition_info["max_mem_per_node"], sctl_dict["MaxMemPerNode"])
    assert_equals(test_partition_info["max_nodes"], int(sctl_dict["MaxNodes"]))
    assert_equals(test_partition_info["max_time_str"], sctl_dict["MaxTime"])
    assert_equals(test_partition_info["min_nodes"], int(sctl_dict["MinNodes"]))
    assert_equals(test_partition_info["nodes"], sctl_dict["Nodes"])
    assert_equals(test_partition_info["name"], sctl_dict["PartitionName"])
    assert_equals(test_partition_info["preempt_mode"], sctl_dict["PreemptMode"])
    assert_equals(test_partition_info["state"], sctl_dict["State"])
    assert_equals(test_partition_info["total_cpus"], int(sctl_dict["TotalCPUs"]))
    assert_equals(test_partition_info["total_nodes"], int(sctl_dict["TotalNodes"]))


def test_partition_create():
    """Partition: Test partition().create()."""
    part_test = {"Name": "part_test"}
    rc = pyslurm.partition().create(part_test)
    assert_equals(rc, 0)

    partition_ids = pyslurm.partition().ids()
    assert_true("part_test" in partition_ids)


def test_partition_update():
    """Partition: Test partition().update()."""
    part_test_before = pyslurm.partition().find_id("part_test")
    assert_equals(part_test_before["state"], "UP")

    part_test_update = {"Name": "part_test", "State": "DOWN"}
    rc = pyslurm.partition().update(part_test_update)
    assert_equals(rc, 0)

    part_test_after = pyslurm.partition().find_id("part_test")
    assert_equals(part_test_after["state"], "DOWN")


def test_partition_delete():
    """Partition: Test partition().delete()."""
    rc = pyslurm.partition().delete("part_test")
    assert_equals(rc, 0)

    partition_ids = pyslurm.partition().ids()
    assert_true("part_test" not in partition_ids)
