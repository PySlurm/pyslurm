"""Test cases for Slurm license."""

import subprocess

import pyslurm


def test_get_license():
    """License: Test licenses().get() return type"""
    licenses = pyslurm.licenses().get()
    assert isinstance(licenses, dict)


def test_license_scontrol():
    """License: Compare scontrol values to PySlurm values."""
    all_licenses = pyslurm.licenses().get()
    test_license = all_licenses["matlab"]

    scontrol = subprocess.Popen(
        ["scontrol", "-ddo", "show", "license", "matlab"], stdout=subprocess.PIPE
    ).communicate()

    scontrol_stdout = scontrol[0].strip().decode("UTF-8", "replace").split()

    # Convert scontrol show license <license> into a dictionary of key value pairs.
    sctl = {}
    for item in scontrol_stdout:
        kv = item.split("=", 1)
        if kv[1] in ["None", "(null)"]:
            sctl.update({kv[0]: None})
        elif kv[1].isdigit():
            sctl.update({kv[0]: int(kv[1])})
        else:
            sctl.update({kv[0]: kv[1]})

    assert "matlab" == sctl.get("LicenseName")
    assert test_license.get("total") == sctl.get("Total")
    assert test_license.get("in_use") == sctl.get("Used")
    assert test_license.get("available") == sctl.get("Free")


#    assert_equals(test_license.get("remote"), sctl.get("Remote"))
