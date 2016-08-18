from __future__ import absolute_import, unicode_literals

import pyslurm
import subprocess
from nose.tools import assert_equals, assert_true

#def test_get_topology():
#    """Topology: Test get_topology() return type"""
#    test_topology_obj = pyslurm.topology.get_topology()
#    assert_true(isinstance(test_topology_obj, pyslurm.topology.Topology))


def test_topology_scontrol():
    """Topology: Compare scontrol values to PySlurm values."""
#    obj = pyslurm.topology.get_topology()

    scontrol = subprocess.Popen(
        ["scontrol", "-ddo", "show", "topology"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE
    ).communicate()

    if "No topology information" in scontrol[0]:
        pass
    else:
        scontrol_stdout = scontrol[0].strip().decode("UTF-8").split()

        # Convert scontrol show topology into a dictionary of key value pairs.
        sctl = {}
        for item in scontrol_stdout:
            kv = item.split("=", 1)
            if kv[1] in ["None", "(null)"]:
                sctl.update({kv[0]: None})
            elif kv[1].isdigit():
                sctl.update({kv[0]: int(kv[1])})
            else:
                sctl.update({kv[0]: kv[1]})

#        assert_equals(obj.switch_name, sctl.get("SwitchName"))
