from __future__ import print_function, division, absolute_import

import pyslurm
import re
import subprocess
from nose.tools import assert_equals, assert_true


def test_get_partition():
    """Partition: Test get_partition() return type"""
    all_partition_ids = pyslurm.partition.get_partitions(ids=True)
    assert_true(isinstance(all_partition_ids, list))

    test_part = all_partition_ids[0]
    test_part_obj = pyslurm.partition.get_partition(test_part)
    assert_true(isinstance(test_part_obj, pyslurm.partition.Partition))


def test_get_partitions():
    """Partition: Test get_partitions(), its count and type."""
    all_partitions = pyslurm.partition.get_partitions()
    assert_true(isinstance(all_partitions, list))

    all_partition_ids = pyslurm.partition.get_partitions(ids=True)
    assert_true(isinstance(all_partition_ids, list))

    assert_true(len(all_partitions) == len(all_partition_ids))

    first_partition = all_partitions[0]
    assert_true(first_partition.partition_name in all_partition_ids)


def test_partition_scontrol():
    """Partition: Compare scontrol values to PySlurm values."""
#    try:
#        basestring
#    except NameError:
#        basestring = str

    all_partition_ids = pyslurm.partition.get_partitions(ids=True)
    # TODO: 
    # convert to a function and  use a for loop to get a running partition and
    # a drained/downed partition as well, mixed and allocated and a
    # non-existent partition

    # TODO:
    # Need to test against all partitions!
    # Or at a minimum, test against a regular partition, a root only partition,
    # and a hidden partition.

    # FIXME:
    # Check if partition is root_only.  If there is a root only partition, or
    # even hidden, it may not return and tests will fail.
    test_partition = all_partition_ids[4]
#    assert isinstance(test_partition, basestring)

    obj = pyslurm.partition.get_partition(test_partition)
    assert_equals(test_partition, obj.partition_name)

    scontrol = subprocess.Popen(
        ["scontrol", "-ddo", "show", "partition", test_partition],
        stdout=subprocess.PIPE
    ).communicate()

    scontrol_stdout = scontrol[0].strip().decode("UTF-8", "replace").split()

    # Convert scontrol show partition <partition> into a dictionary of key
    # value pairs.
    sctl = {}
    for item in scontrol_stdout:
        kv = item.split("=")
        if kv[1] in ["None", "(null)"]:
            sctl.update({kv[0]: None})
        elif kv[1].isdigit():
            sctl.update({kv[0]: int(kv[1])})
        else:
            sctl.update({kv[0]: kv[1]})

    assert_equals(obj.alloc_nodes, sctl["AllocNodes"])

    if sctl.get("AllowAccounts"):
        try:
            assert_equals(obj.allow_accounts, "ALL")
        except AssertionError:
            assert_equals(obj.allow_accounts, sctl["AllowAccounts"].split(","))
    else:
        assert_equals(obj.allow_accounts, sctl.get("AllowAccounts"))


    if sctl.get("AllowGroups"):
        try:
            assert_equals(obj.allow_groups, "ALL")
        except AssertionError:
            assert_equals(obj.allow_groups, sctl["AllowGroups"].split(","))
    else:
        assert_equals(obj.allow_groups, sctl.get("AllowGroups"))


    if sctl.get("AllowQos"):
        try:
            assert_equals(obj.allow_qos, "ALL")
        except AssertionError:
            assert_equals(obj.allow_qos, sctl["AllowQos"].split(","))
    else:
        assert_equals(obj.allow_qos, sctl.get("AllowQos"))

    assert_equals(obj.alternate, sctl.get("Alternate"))
    assert_equals(obj.default, sctl["Default"])
    assert_equals(obj.default_time_str, sctl["DefaultTime"])
    assert_equals(obj.def_mem_per_cpu, sctl.get("DefMemPerCPU"))
    assert_equals(obj.def_mem_per_node, sctl.get("DefMemPerNode"))

    if sctl.get("DenyAccounts"):
        try:
            assert_equals(obj.deny_accounts, "ALL")
        except AssertionError:
            assert_equals(obj.deny_accounts, sctl.get("DenyAccounts").split(","))
    else:
        assert_equals(obj.deny_accounts, sctl.get("DenyAccounts"))

    if sctl.get("DenyQos"):
        try:
            assert_equals(obj.deny_qos, "ALL")
        except AssertionError:
            assert_equals(obj.deny_qos, sctl.get("DenyQos").split(","))
    else:
        assert_equals(obj.deny_qos, sctl.get("DenyQos"))

    assert_equals(obj.disable_root_jobs, sctl["DisableRootJobs"])
    assert_equals(obj.exclusive_user, sctl["ExclusiveUser"])
    assert_equals(obj.grace_time, sctl["GraceTime"])
    assert_equals(obj.hidden, sctl["Hidden"])
    assert_equals(obj.lln, sctl["LLN"])
    assert_equals(obj.max_cpus_per_node, sctl.get("MaxCPUsPerNode"))
    assert_equals(obj.max_mem_per_cpu, sctl.get("MaxMemPerCPU"))
    assert_equals(obj.max_nodes, sctl["MaxNodes"])
    assert_equals(obj.max_time_str, sctl["MaxTime"])
    assert_equals(obj.midplanes, sctl.get("Midplanes"))
    assert_equals(obj.min_nodes, sctl["MinNodes"])
    assert_equals(obj.nodes, sctl.get("Nodes"))
    assert_equals(obj.partition_name, sctl["PartitionName"])
    assert_equals(obj.preempt_mode_str, sctl["PreemptMode"])
    assert_equals(obj.priority, sctl["Priority"])
    assert_equals(obj.qos, sctl["QoS"])
    assert_equals(obj.req_resv, sctl["ReqResv"])
    assert_equals(obj.root_only, sctl["RootOnly"])
    assert_equals(obj.select_type_parameters, sctl["SelectTypeParameters"])
    assert_equals(obj.shared, sctl["Shared"])
    assert_equals(obj.state, sctl["State"])
    assert_equals(obj.total_cpus, sctl["TotalCPUs"])
    assert_equals(obj.total_nodes, sctl["TotalNodes"])
    assert_equals(obj.tres_billing_weights, sctl.get("TRESBillingWeights"))
