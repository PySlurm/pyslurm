#########################################################################
# test_job_submit.py - job submission unit tests
#########################################################################
# Copyright (C) 2023 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# This file is part of PySlurm
#
# PySlurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# PySlurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PySlurm; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
"""test_job_submit.py - Test the job submit api functions."""

import sys
import time
import pytest
import pyslurm
import tempfile
import os
from os import environ as pyenviron
from util import create_simple_job_desc, create_job_script
from pyslurm.utils.uint import u32
from pyslurm import (
    Job,
    Jobs,
    JobSubmitDescription,
    RPCError,
)
from pyslurm.core.job.submission import (
    _parse_cpu_freq_str_to_dict,
    _validate_cpu_freq,
    _parse_nodes,
    _parse_dependencies,
    _parse_signal_str_to_dict,
    _validate_batch_script,
)
from pyslurm.core.job.util import (
    mail_type_list_to_int,
    acctg_profile_list_to_int,
    cpu_freq_str_to_int,
    cpu_gov_str_to_int,
    shared_type_str_to_int,
    power_type_list_to_int,
)


def job_desc(**kwargs):
    return JobSubmitDescription(script=create_job_script(), **kwargs)


def test_parse_environment():
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


def test_parse_cpu_frequency():
    freq = "Performance"
    freq_dict = _parse_cpu_freq_str_to_dict(freq)
    assert freq_dict["governor"] == "Performance"
    assert len(freq_dict) == 1
    _validate_cpu_freq(freq_dict)

    freq = 1000000
    freq_dict = _parse_cpu_freq_str_to_dict(freq)
    assert freq_dict["max"] == "1000000"
    assert len(freq_dict) == 1
    _validate_cpu_freq(freq_dict)

    freq = "1000000-3700000"
    freq_dict = _parse_cpu_freq_str_to_dict(freq)
    assert freq_dict["min"] == "1000000"
    assert freq_dict["max"] == "3700000"
    assert len(freq_dict) == 2
    _validate_cpu_freq(freq_dict)

    freq = "1000000-3700000:Performance"
    freq_dict = _parse_cpu_freq_str_to_dict(freq)
    assert freq_dict["min"] == "1000000"
    assert freq_dict["max"] == "3700000"
    assert freq_dict["governor"] == "Performance"
    _validate_cpu_freq(freq_dict)

    with pytest.raises(ValueError,
            match=r"Invalid cpu_frequency format*"):
        freq = "Performance:3700000"
        freq_dict = _parse_cpu_freq_str_to_dict(freq)

    with pytest.raises(ValueError,
            match=r"min cpu-freq*"):
        freq = "4000000-3700000"
        freq_dict = _parse_cpu_freq_str_to_dict(freq)
        _validate_cpu_freq(freq_dict)

#    with pytest.raises(ValueError,
#            match=r"Invalid cpu freq value*"):
#        freq = "3700000:Performance"
#        job._create_job_submit_desc()

    with pytest.raises(ValueError,
            match=r"Setting Governor when specifying*"):
        freq = {"max": 3700000, "governor": "Performance"}
        _validate_cpu_freq(freq)

    with pytest.raises(ValueError,
            match=r"Setting Governor when specifying*"):
        freq = {"min": 3700000, "governor": "Performance"}
        _validate_cpu_freq(freq)


def test_parse_nodes():
    nodes = "5"
    nmin, nmax = _parse_nodes(nodes)
    assert nmin == 5
    assert nmax == 5

    nodes = {"min": 5, "max": 5}
    nmin, nmax = _parse_nodes(nodes)
    assert nmin == 5
    assert nmax == 5

    nodes = "5-10"
    nmin, nmax = _parse_nodes(nodes)
    assert nmin == 5
    assert nmax == 10

    with pytest.raises(ValueError,
            match=r"Max Nodecount cannot be less than*"):
        nodes = {"min": 10, "max": 5}
        nmin, nmax = _parse_nodes(nodes)


def test_parse_script():
    script = create_job_script()

    # Try passing in a path to a script.
    fd, path = tempfile.mkstemp()
    try:
        with os.fdopen(fd, 'w') as tmp:
            tmp.write(script)

        _validate_batch_script(path, "-t 10 input.csv")
    finally:
            os.remove(path)

    with pytest.raises(ValueError,
            match=r"Passing arguments to a script*"):
        script = "#!/bin/bash\nsleep 10"
        script_args = "-t 10"
        _validate_batch_script(script, script_args)

    with pytest.raises(ValueError,
            match=r"The Slurm Controller does not allow*"):
        script = "#!/bin/bash\nsleep 10" + "\0"
        script_args = None
        _validate_batch_script(script, script_args)

    with pytest.raises(ValueError,
            match="Batch script is empty or none was provided."):
        script = ""
        script_args = None
        _validate_batch_script(script, script_args)

    with pytest.raises(ValueError,
            match=r"Batch script contains DOS line breaks*"):
        script = "#!/bin/bash\nsleep 10" + "\r\n"
        script_args = None
        _validate_batch_script(script, script_args)


def test_parse_dependencies():
    dep = {
        "afterany": [40, 30, 20],
        "afternotok": [100],
        "satisfy": "any",
        "singleton": True,
    }
    dep_str = _parse_dependencies(dep)
    assert dep_str == "afterany:40:30:20?afternotok:100?singleton"

    dep = {
        "after": [100, "200+30"],
        "afterok": [300],
    }
    dep_str = _parse_dependencies(dep)
    assert dep_str == "after:100:200+30,afterok:300"

    dep = {
        "after": 200,
        "afterok": 300,
    }
    dep_str = _parse_dependencies(dep)
    assert dep_str == "after:200,afterok:300"


def test_validate_cpus():
    job = job_desc()
    job.cpus_per_task = 5
    job._validate_options()

    with pytest.raises(ValueError,
            match="cpus_per_task and cpus_per_gpu are mutually exclusive."):
        job.cpus_per_gpu = 5
        job._validate_options()

    job.cpus_per_task = None
    job.cpus_per_gpu = 5
    job._validate_options()

    with pytest.raises(ValueError,
            match="cpus_per_task and cpus_per_gpu are mutually exclusive."):
        job.cpus_per_task = 5
        job._validate_options()


def test_parse_signal():
    signal = 7
    signal_dict = _parse_signal_str_to_dict(signal)
    assert signal_dict["signal"] == "7"
    assert len(signal_dict) == 1

    signal = "7@120"
    signal_dict = _parse_signal_str_to_dict(signal)
    assert signal_dict["signal"] == "7"
    assert signal_dict["time"] == "120"
    assert len(signal_dict) == 2

    signal = "RB:8@180"
    signal_dict = _parse_signal_str_to_dict(signal)
    assert signal_dict["signal"] == "8"
    assert signal_dict["time"] == "180"
    assert signal_dict["batch_only"]
    assert signal_dict["allow_reservation_overlap"]
    assert len(signal_dict) == 4


def test_mail_type_list_to_int():
    typ = "ARRAY_TASKS,BEGIN"
    assert mail_type_list_to_int(typ) > 0

    with pytest.raises(ValueError, match=r"Invalid *"):
        typ = "BEGIN,END,INVALID_TYPE"
        mail_type_list_to_int(typ)


def test_acctg_profile_list_to_int():
    typ = "energy,task"
    assert acctg_profile_list_to_int(typ) > 0

    with pytest.raises(ValueError, match=r"Invalid *"):
        typ = "energy,invalid_type"
        acctg_profile_list_to_int(typ)


def test_power_type_list_to_int():
    typ = "level"
    assert power_type_list_to_int(typ) > 0

    with pytest.raises(ValueError, match=r"Invalid *"):
        typ = "invalid_type"
        power_type_list_to_int(typ)


def test_cpu_gov_str_to_int():
    typ = "PERFORMANCE"
    assert cpu_gov_str_to_int(typ) > 0

    with pytest.raises(ValueError, match=r"Invalid *"):
        typ = "INVALID_GOVERNOR"
        cpu_gov_str_to_int(typ)


def test_cpu_freq_str_to_int():
    typ = "HIGH"
    assert cpu_freq_str_to_int(typ) > 0

    with pytest.raises(ValueError, match=r"Invalid *"):
        typ = "INVALID_FREQ_STR"
        cpu_freq_str_to_int(typ)

    with pytest.raises(OverflowError):
        typ = 2**32
        cpu_freq_str_to_int(typ)


def test_setting_attrs_with_env_vars():
    pyenviron["PYSLURM_JOBDESC_ACCOUNT"] = "account1"
    pyenviron["PYSLURM_JOBDESC_NAME"] = "jobname"
    pyenviron["PYSLURM_JOBDESC_WCKEY"] = "wckey"
    pyenviron["PYSLURM_JOBDESC_CLUSTERS"] = "cluster1,cluster2"
    pyenviron["PYSLURM_JOBDESC_COMMENT"] = "A simple job comment"
    pyenviron["PYSLURM_JOBDESC_REQUIRES_CONTIGUOUS_NODES"] = "True"
    pyenviron["PYSLURM_JOBDESC_WORKING_DIRECTORY"] = "/work/user1"

    job = job_desc(working_directory="/work/user2")
    job.load_environment()

    assert job.account == "account1"
    assert job.name == "jobname"
    assert job.wckey == "wckey"
    assert job.clusters == "cluster1,cluster2"
    assert job.comment == "A simple job comment"
    assert job.requires_contiguous_nodes == True
    assert job.working_directory == "/work/user2"

    job = job_desc(working_directory="/work/user2", account="account2")
    job.load_environment(overwrite=True)

    assert job.account == "account1"
    assert job.name == "jobname"
    assert job.wckey == "wckey"
    assert job.clusters == "cluster1,cluster2"
    assert job.comment == "A simple job comment"
    assert job.requires_contiguous_nodes == True
    assert job.working_directory == "/work/user1"


def test_parsing_sbatch_options_from_script():
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

        job = job_desc(ntasks=5)
        job.script = path
        job.load_sbatch_options()
        assert job.time_limit == "20"
        assert job.memory_per_cpu == "1G"
        assert job.gpus == "1"
        assert job.resource_sharing == "no"
        assert job.ntasks == 5
        assert job.cpus_per_task == "3"

        job = job_desc(ntasks=5)
        job.script = path
        job.load_sbatch_options(overwrite=True)
        assert job.time_limit == "20"
        assert job.memory_per_cpu == "1G"
        assert job.gpus == "1"
        assert job.resource_sharing == "no"
        assert job.ntasks == "2"
        assert job.cpus_per_task == "3"
    finally:
            os.remove(path)
    
