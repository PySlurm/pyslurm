from __future__ import absolute_import, unicode_literals

import pyslurm
import subprocess
from nose.tools import assert_equals, assert_true
from socket import gethostname


def test_slurm_reconfigure():
    """Misc: Test slurm_reconfigure() return."""
    slurm_reconfigure = pyslurm.slurm_reconfigure()
    assert_equals(slurm_reconfigure, 0)


def test_slurm_api_version():
    """Misc: Test slurm_api_version()."""
    ver = pyslurm.slurm_api_version()
    assert_equals(ver[0], 20)
    assert_equals(ver[1], 2)


def test_slurm_load_slurmd_status():
    """Misc: Test slurm_load_slurmd_status()."""
    test_node = pyslurm.node().ids()[-1]
    status_info = pyslurm.slurm_load_slurmd_status()[test_node]

    sctl = subprocess.Popen(["scontrol", "-d", "show", "slurmd"],
                            stdout=subprocess.PIPE).communicate()
    sctl_stdout = sctl[0].strip().decode("UTF-8").split("\n")
    sctl_dict = dict(
        (item.split("=", 1)[0].strip(), item.split("=", 1)[1].strip())
        for item in sctl_stdout
        if "=" in item
    )

    assert_equals(status_info["step_list"], sctl_dict["Active Steps"])
    assert_equals(status_info["actual_boards"], int(sctl_dict["Actual Boards"]))
    assert_equals(status_info["actual_cpus"], int(sctl_dict["Actual CPUs"]))
    assert_equals(status_info["actual_sockets"], int(sctl_dict["Actual sockets"]))
    assert_equals(status_info["actual_cores"], int(sctl_dict["Actual cores"]))
    assert_equals(status_info["slurmd_logfile"], sctl_dict["Slurmd Logfile"])
    assert_equals(status_info["version"], sctl_dict["Version"])
