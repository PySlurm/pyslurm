from __future__ import absolute_import, unicode_literals

import pyslurm
import subprocess
from nose.tools import assert_equals, assert_true

def test_get_powercap():
    """Powercap: Test get_powercap() return type"""
    test_powercap_obj = pyslurm.powercap.get_powercap()
    assert_true(isinstance(test_powercap_obj, pyslurm.powercap.Powercap))


def test_powercap_scontrol():
    """Powercap: Compare scontrol values to PySlurm values."""
    obj = pyslurm.powercap.get_powercap()

    scontrol = subprocess.Popen(
        ["scontrol", "-ddo", "show", "powercap"],
        stdout=subprocess.PIPE
    ).communicate()

    scontrol_stdout = scontrol[0].strip().decode("UTF-8")

    if "Powercapping disabled" in scontrol_stdout:
        assert_true("Powercapping disabled" in obj.power_cap)
    else:
        # Convert scontrol show powercap into a dictionary of key value pairs.
        sctl = {}
        for item in scontrol_stdout:
            kv = item.split("=", 1)
            if kv[1] in ["None", "(null)"]:
                sctl.update({kv[0]: None})
            elif kv[1].isdigit():
                sctl.update({kv[0]: int(kv[1])})
            else:
                sctl.update({kv[0]: kv[1]})

        assert_equals(obj.min_watts, sctl.get("MinWatts"))
        assert_equals(obj.current_watts, sctl.get("CurrentWatts"))
        assert_equals(obj.power_cap, sctl.get("PowerCap"))
        assert_equals(obj.power_floor, sctl.get("PowerFloor"))
        assert_equals(obj.power_change_rate, sctl.get("PowerChangeRate"))
        assert_equals(obj.adjusted_max_watts, sctl.get("AdjustedMaxWatts"))
        assert_equals(obj.max_watts, sctl.get("MaxWatts"))
