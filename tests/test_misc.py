"""Test cases for loose Slurm functions."""

import subprocess

import pyslurm


def test_slurm_reconfigure():
    """Misc: Test slurm_reconfigure() return."""
    slurm_reconfigure = pyslurm.slurm_reconfigure()
    assert slurm_reconfigure == 0


def test_slurm_api_version():
    """Misc: Test slurm_api_version()."""
    ver = pyslurm.slurm_api_version()
    assert ver[0] == 20
    assert ver[1] == 11


def test_slurm_load_slurmd_status():
    """Misc: Test slurm_load_slurmd_status()."""
    status_info = pyslurm.slurm_load_slurmd_status()["slurmctl"]

    sctl = subprocess.Popen(
        ["scontrol", "-d", "show", "slurmd"], stdout=subprocess.PIPE
    ).communicate()
    sctl_stdout = sctl[0].strip().decode("UTF-8").split("\n")
    sctl_dict = dict(
        (item.split("=", 1)[0].strip(), item.split("=", 1)[1].strip())
        for item in sctl_stdout
        if "=" in item
    )

    assert status_info["step_list"] == sctl_dict["Active Steps"]
    assert status_info["actual_boards"] == int(sctl_dict["Actual Boards"])
    assert status_info["actual_cpus"] == int(sctl_dict["Actual CPUs"])
    assert status_info["actual_sockets"] == int(sctl_dict["Actual sockets"])
    assert status_info["actual_cores"] == int(sctl_dict["Actual cores"])
    assert status_info["slurmd_logfile"] == sctl_dict["Slurmd Logfile"]
    assert status_info["version"] == sctl_dict["Version"]
