"""test_job_submit.py - Test the job submit api functions."""

import sys
import time
import pytest
import pyslurm
import tempfile
import os
from os import environ as pyenviron
from conftest import create_simple_job_desc, create_job_script
from pyslurm import (
    Job,
    Jobs,
    JobSubmitDescription,
    RPCError,
)

def job_desc(**kwargs):
    return JobSubmitDescription(script=create_job_script(), **kwargs)


def test_environment():
    job = job_desc()

    # Everything in the current environment will be exported
    job.environment = "ALL"
    job._create_job_submit_desc()

    # Only SLURM_* Vars from the current env will be exported
    job.environment = "NONE"
    job._create_job_submit_desc()

    # TODO: more test cases
    # Test explicitly set vars as dict
#        job.environment = {
#            "PYSLURM_TEST_VAR_1":   2,
#            "PYSLURM_TEST_VAR_2":   "test-value",
#        }


def test_cpu_frequency():
    job = job_desc()
    job._create_job_submit_desc()

    job.cpu_freq = "Performance"
    job._create_job_submit_desc()

    job.cpu_freq = {"governor": "Performance"}
    job._create_job_submit_desc()

    job.cpu_freq = 1000000
    job._create_job_submit_desc()

    job.cpu_freq = {"max": 1000000}
    job._create_job_submit_desc()

    job.cpu_freq = "1000000-3700000"
    job._create_job_submit_desc()

    job.cpu_freq = {"min": 1000000, "max": 3700000}
    job._create_job_submit_desc()

    job.cpu_freq = "1000000-3700000:Performance"
    job._create_job_submit_desc()

    job.cpu_freq = {"min": 1000000, "max": 3700000,
                         "governor": "Performance"}
    job._create_job_submit_desc()

    with pytest.raises(ValueError,
            match=r"Invalid cpu_freq format*"):
        job.cpu_freq = "Performance:3700000"
        job._create_job_submit_desc()

    with pytest.raises(ValueError,
            match=r"min cpu-freq*"):
        job.cpu_freq = "4000000-3700000"
        job._create_job_submit_desc()

    with pytest.raises(ValueError,
            match=r"Invalid cpu freq value*"):
        job.cpu_freq = "3700000:Performance"
        job._create_job_submit_desc()

    with pytest.raises(ValueError,
            match=r"Setting Governor when specifying*"):
        job.cpu_freq = {"max": 3700000, "governor": "Performance"}
        job._create_job_submit_desc()

    with pytest.raises(ValueError,
            match=r"Setting Governor when specifying*"):
        job.cpu_freq = {"min": 3700000, "governor": "Performance"}
        job._create_job_submit_desc()


def test_nodes():
    job = job_desc()
    job._create_job_submit_desc()

    job.nodes = "5"
    job._create_job_submit_desc()

    job.nodes = {"min": 5, "max": 5}
    job._create_job_submit_desc()

    job.nodes = "5-10"
    job._create_job_submit_desc()

    job.nodes = {"min": 5, "max": 10}
    job._create_job_submit_desc()

    with pytest.raises(ValueError,
            match=r"Max Nodecount cannot be less than*"):
        job.nodes = {"min": 10, "max": 5}
        job._create_job_submit_desc()


def test_script():
    job = job_desc()
    script = create_job_script()
    job._create_job_submit_desc()

    job.script = script
    assert job.script == script
    assert job.script_args is None

    # Try passing in a path to a script.
    fd, path = tempfile.mkstemp()
    try:
        with os.fdopen(fd, 'w') as tmp:
            tmp.write(script)

        job.script = path
        job.script_args = "-t 10 input.csv"
        job._create_job_submit_desc()
    finally:
            os.remove(path)

    with pytest.raises(ValueError,
            match=r"Passing arguments to a script*"):
        job.script = "#!/bin/bash\nsleep 10"
        job.script_args = "-t 10"
        job._create_job_submit_desc()

    with pytest.raises(ValueError,
            match=r"The Slurm Controller does not allow*"):
        job.script = script + "\0"
        job.script_args = None
        job._create_job_submit_desc()

    with pytest.raises(ValueError,
            match="You need to provide a batch script."):
        job.script = ""
        job.script_args = None
        job._create_job_submit_desc()

    with pytest.raises(ValueError,
            match=r"Batch script contains DOS line breaks*"):
        job.script = script + "\r\n"
        job.script_args = None
        job._create_job_submit_desc()


def test_dependencies():
    job = job_desc()
    job._create_job_submit_desc()

    job.dependencies = "after:70:90:60+30,afterok:80"
    job._create_job_submit_desc()

    job.dependencies = "after:70:90:60?afterok:80"
    job._create_job_submit_desc()

    job.dependencies = {
        "afterany": [40, 30, 20],
        "afternotok": [100],
        "satisfy": "any",
        "singleton": True,
    }
    job._create_job_submit_desc()


def test_cpus():
    job = job_desc()
    job._create_job_submit_desc()

    job.cpus_per_task = 5
    job._create_job_submit_desc()

    with pytest.raises(ValueError,
            match="cpus_per_task and cpus_per_gpu are mutually exclusive."):
        job.cpus_per_gpu = 5
        job._create_job_submit_desc()

    job.cpus_per_task = None
    job.cpus_per_gpu = 5
    job._create_job_submit_desc()

    with pytest.raises(ValueError,
            match="cpus_per_task and cpus_per_gpu are mutually exclusive."):
        job.cpus_per_task = 5
        job._create_job_submit_desc()


def test_gres_per_node():
    job = job_desc()
    job._create_job_submit_desc()

    job.gres_per_node = "gpu:tesla:1,gpu:volta:5"
    job._create_job_submit_desc()

    job.gres_per_node = {"gpu:tesla": 1, "gpu:volta": 1}
    job._create_job_submit_desc()


def test_signal():
    job = job_desc()
    job._create_job_submit_desc()

    job.signal = 7
    job._create_job_submit_desc()

    job.signal = {"batch_only": True}
    job._create_job_submit_desc()

    job.signal = "7@120"
    job._create_job_submit_desc()

    job.signal = "RB:8@180"
    job._create_job_submit_desc()


def test_distribution():
    job = job_desc()
    job._create_job_submit_desc()

    job.distribution = "cyclic:cyclic:cyclic"
    job._create_job_submit_desc()

    job.distribution = {"nodes": "cyclic", "sockets": "block", "pack": True}
    job._create_job_submit_desc()
    
    job.distribution = "*:*:fcyclic,NoPack"
    job._create_job_submit_desc()

    job.distribution = 10
    job._create_job_submit_desc()

    job.distribution = {"plane": 20}
    job._create_job_submit_desc()


def test_setting_attrs_with_env_vars():
    pyenviron["PYSLURM_JOBDESC_ACCOUNT"] = "account1"
    pyenviron["PYSLURM_JOBDESC_NAME"] = "jobname"
    pyenviron["PYSLURM_JOBDESC_WCKEY"] = "wckey"
    pyenviron["PYSLURM_JOBDESC_CLUSTERS"] = "cluster1,cluster2"
    pyenviron["PYSLURM_JOBDESC_COMMENT"] = "A simple job comment"
    pyenviron["PYSLURM_JOBDESC_CONTIGUOUS"] = "True"
    pyenviron["PYSLURM_JOBDESC_WORK_DIR"] = "/work/user1"

    job = job_desc(work_dir="/work/user2")
    job.load_environment()

    assert job.account == "account1"
    assert job.name == "jobname"
    assert job.wckey == "wckey"
    assert job.clusters == "cluster1,cluster2"
    assert job.comment == "A simple job comment"
    assert job.work_dir == "/work/user2"
    assert job.contiguous == True
    job._create_job_submit_desc()


def test_parsing_sbatch_options_from_script():
    job = job_desc(work_dir="/work/user2")

    fd, path = tempfile.mkstemp()
    try:
        with os.fdopen(fd, 'w') as tmp:
            tmp.write(
                """#!/bin/bash

                #SBATCH --time 20
                #SBATCH --mem-per-cpu     =1G
                #SBATCH -G 1
                #SBATCH --exclusive
                #SBATCH --ntasks     =    2
                #SBATCH -c=3 # inline-comments should be ignored

                sleep 1000
                """
            )

        job.script = path
        job.load_sbatch_options()
        assert job.time_limit == "20"
        assert job.mem_per_cpu == "1G"
        assert job.gpus == "1"
        assert job.resource_sharing == "no"
        assert job.ntasks == "2"
        assert job.cpus_per_task == "3"
        job._create_job_submit_desc()
    finally:
            os.remove(path)
    