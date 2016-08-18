from __future__ import absolute_import, unicode_literals

import pyslurm
import subprocess
from nose.tools import assert_equals, assert_true

def test_get_license():
    """License: Test get_license() return type"""
    all_license_ids = pyslurm.license.get_licenses(ids=True)
    assert_true(isinstance(all_license_ids, list))

    test_license = all_license_ids[0]
    test_license_obj = pyslurm.license.get_license(test_license)
    assert_true(isinstance(test_license_obj, pyslurm.license.License))


def test_get_licenses():
    """License: Test get_licenses(), count, and type."""
    all_licenses = pyslurm.license.get_licenses()
    assert_true(isinstance(all_licenses, list))

    all_license_ids = pyslurm.license.get_licenses(ids=True)
    assert_true(isinstance(all_license_ids, list))

    assert_equals(len(all_licenses), len(all_license_ids))

    first_license = all_licenses[0]
    assert_true(first_license.license_name in all_license_ids)


def test_license_scontrol():
    """License: Compare scontrol values to PySlurm values."""
#    try:
#        basestring
#    except NameError:
#        basestring = str

    all_license_ids = pyslurm.license.get_licenses(ids=True)
    # TODO:
    # convert to a function and  use a for loop to get a running license and a
    # drained/downed license as well, mixed and allocated
    # and a non-existent license
    test_license = all_license_ids[0]
#    assert_equals(isinstance(test_license, basestring)

    obj = pyslurm.license.get_license(test_license)
    assert_equals(test_license, obj.license_name)

    scontrol = subprocess.Popen(
        ["scontrol", "-ddo", "show", "license", test_license],
        stdout=subprocess.PIPE
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

    assert_equals(obj.license_name, sctl.get("LicenseName"))
    assert_equals(obj.total, sctl.get("Total"))
    assert_equals(obj.used, sctl.get("Used"))
    assert_equals(obj.free, sctl.get("Free"))
    assert_equals(obj.remote, sctl.get("Remote"))
