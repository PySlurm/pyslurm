#########################################################################
# test_job_steps.py - job steps api integration tests
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
"""test_job_steps.py - Test the job steps api functions."""

import pytest
import time
from pyslurm import (
    JobStep,
    JobSteps,
    RPCError,
)
import util


def create_job_script_multi_step(steps=None):
    default = f"""
    srun -n1 -N1 -c2 \
         -J step_zero --distribution=block:cyclic:block,Pack \
         sleep 300 &
    srun -n1 -N1 -c3 \
         -t 10 -J step_one --distribution=block:cyclic:block,Pack \
         sleep 300 &"""

    job_script = f"""\
#!/bin/bash

echo "Got args: $@"

/usr/bin/env

{default if steps is None else steps}
wait
"""
    return job_script


def test_load(submit_job):
    job = submit_job(script=create_job_script_multi_step())

    # Load the step info, waiting one second to make sure the Step
    # actually exists.
    util.wait()
    step = JobStep.load(job.id, "batch")

    assert step.id == "batch"
    assert step.job_id == job.id
    assert step.name == "batch"
    # Job was submitted with ntasks=2, but the batch step always has just 1.
    assert step.ntasks == 1
    # Job was submitted with a time-limit of 1 day, but it seems this doesn't
    # propagate through for the steps if not set explicitly.
    assert step.time_limit is None

    # Now try to load the first and second Step started by srun
    step_zero = JobStep.load(job, 0)
    step_one = JobStep.load(job, 1)
  
    # It is possible that the srun executed as the second command will
    # become the Step with ID '0' - so we just swap it.
    if step_zero.name == "step_one":
        tmp = step_zero
        step_zero = step_one
        step_one = tmp

        assert step_one.id == 0
        assert step_zero.id == 1

    step = step_zero
    assert step.job_id == job.id
    assert step.name == "step_zero"
    assert step.ntasks == 1
    assert step.alloc_cpus == 2
    assert step.time_limit is None

    step = step_one
    assert step.job_id == job.id
    assert step.name == "step_one"
    assert step.ntasks == 1
    assert step.alloc_cpus == 3
    assert step.time_limit == 10


def test_collection(submit_job):
    job = submit_job(script=create_job_script_multi_step())

    util.wait()
    steps = JobSteps.load(job)

    assert steps
    # We have 3 Steps: batch, 0 and 1
    assert len(steps) == 3
    assert ("batch" in steps and
            0 in steps and
            1 in steps)


def test_cancel(submit_job):
    job = submit_job(script=create_job_script_multi_step())

    util.wait()
    steps = JobSteps.load(job)
    assert len(steps) == 3
    assert ("batch" in steps and
            0 in steps and
            1 in steps)

    steps[0].cancel()
    
    util.wait()
    steps = JobSteps.load(job)
    assert len(steps) == 2
    assert ("batch" in steps and
            1 in steps)


def test_modify(submit_job):
    steps = "srun -t 20 sleep 100"
    job = submit_job(script=create_job_script_multi_step(steps))

    util.wait()
    step = JobStep.load(job, 0)
    assert step.time_limit == 20

    step.modify(JobStep(time_limit="00:05:00"))
    assert JobStep.load(job, 0).time_limit == 5

    step.modify(JobStep(time_limit="00:15:00"))
    assert JobStep.load(job, 0).time_limit == 15


def test_send_signal(submit_job):
    steps = "srun -t 10 sleep 100"
    job = submit_job(script=create_job_script_multi_step(steps))

    util.wait()
    step = JobStep.load(job, 0)
    assert step.state == "RUNNING"

    # Send a SIGTERM (basically cancelling the Job)
    step.send_signal(15)

    # Make sure the job is actually cancelled.
    # If a RPCError is raised, this means the Step got cancelled.
    util.wait()
    with pytest.raises(RPCError):
        step = JobStep.load(job, 0)


def test_load_with_wrong_step_id(submit_job):
    job = submit_job()

    with pytest.raises(RPCError):
        JobStep.load(job, 3)


def test_parse_all(submit_job):
    job = submit_job()
    util.wait()
    JobStep.load(job, "batch").to_dict()
