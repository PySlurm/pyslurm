"""Test cases for Slurm Topologies."""

import subprocess

import pyslurm


def test_get_topology():
    """Topology: Test get_topology() return type"""
    test_topology = pyslurm.topology().get()
    assert isinstance(test_topology, dict)


def test_topology_scontrol():
    """Topology: Compare scontrol values to PySlurm values."""

    test_topology = pyslurm.topology().get()

    scontrol = subprocess.Popen(
        ["scontrol", "-ddo", "show", "topology", "s2"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).communicate()

    scontrol_stdout = scontrol[0].strip().decode("UTF-8")
    scontrol_stderr = scontrol[1].strip().decode("UTF-8")

    if "No topology information" in scontrol_stderr:
        pass
    else:
        # Convert scontrol show topology into a dictionary of key value pairs.
        sctl = {}
        for item in scontrol_stdout.split():
            kv = item.split("=", 1)
            if kv[1] in ["None", "(null)"]:
                sctl.update({kv[0]: None})
            elif kv[1].isdigit():
                sctl.update({kv[0]: int(kv[1])})
            else:
                sctl.update({kv[0]: kv[1]})

    s2 = test_topology["s2"]
    assert s2.get("name") == sctl.get("SwitchName")
    assert s2.get("level") == sctl.get("Level")
    assert s2.get("link_speed") == sctl.get("LinkSpeed")
    assert s2.get("nodes") == sctl.get("Nodes")
    assert s2.get("switches") == sctl.get("Switches")
