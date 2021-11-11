"""Test cases for Job Steps."""

import pyslurm


def test_jobstep_get():
    """Jobstep: Test jobstep().get() return type."""
    all_jobsteps = pyslurm.jobstep().get()
    assert isinstance(all_jobsteps, dict)


def test_jobstep_ids():
    """Jobstep: Test jobstep().ids() return type."""
    all_jobstep_ids = pyslurm.jobstep().ids()
    assert isinstance(all_jobstep_ids, dict)


def test_jobstep_count():
    """Jobstep: Test jobstep count."""
    all_jobsteps = pyslurm.jobstep().get()
    all_jobstep_ids = pyslurm.jobstep().ids()
    assert len(all_jobsteps) == len(all_jobstep_ids)


# def test_jobstep_scontrol():
#    """Jobstep: Compare scontrol values to PySlurm values."""
#    all_jobstep_ids = pyslurm.jobstep().ids()
#
#    # Make sure jobstep is running first
#    test_jobstep = next(iter(all_jobstep_ids)
#
#    test_jobstep_info = pyslurm.jobstep().find(test_jobstep)
#    assert_equals(test_jobstep, test_jobstep_info["job_id"])
#
#    sctl = subprocess.Popen(["scontrol", "-d", "show", "steps", str(test_job)],
#                            stdout=subprocess.PIPE).communicate()
#    sctl_stdout = sctl[0].strip().decode("UTF-8", "replace").split()
#    sctl_dict = dict((value.split("=")[0], value.split("=")[1])
#                     for value in sctl_stdout)
#
#    assert_equals(test_job_info["batch_flag"], int(sctl_dict["BatchFlag"]))
