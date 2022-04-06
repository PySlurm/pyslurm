"""test_job_steps.py - Test the job steps api functions."""

import pytest
import time
from pyslurm import (
    JobStep,
    JobSteps,
    RPCError,
)


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


def test_reload(submit_job):
    job = submit_job(script=create_job_script_multi_step())
    step = JobStep(job, "batch")

    # Nothing has been loaded at this point, just make sure everything is
    # on default values.
    assert step.name is None
    assert step.ntasks is None
    assert step.time_limit is None

    # Now load the step info, waiting one second to make sure the Step
    # actually exists.
    time.sleep(1)
    step.reload()

    assert step.id == "batch"
    assert step.job_id == job.id
    assert step.name == "batch"
    # Job was submitted with ntasks=2, but the batch step always has just 1.
    assert step.ntasks == 1
    # Job was submitted with a time-limit of 1 day, but it seems this doesn't
    # propagate through for the steps if not set explicitly.
    assert step.time_limit == "unlimited"

    # Now try to load the first and second Step started by srun
    step_zero = JobStep(job, 0).reload()
    step_one = JobStep(job, 1).reload()
  
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
    assert step.time_limit == "unlimited"

    step = step_one
    assert step.job_id == job.id
    assert step.name == "step_one"
    assert step.ntasks == 1
    assert step.alloc_cpus == 3
    assert step.time_limit == "00:10:00"


def test_collection(submit_job):
    job = submit_job(script=create_job_script_multi_step())

    time.sleep(1)
    steps = JobSteps(job)

    assert steps != {}
    # We have 3 Steps: batch, 0 and 1
    assert len(steps) == 3
    assert ("batch" in steps and
            0 in steps and
            1 in steps)


def test_distribution(submit_job):
    job = submit_job(script=create_job_script_multi_step())
    step = JobStep(job, 0)

    assert step.distribution is None

    time.sleep(1)
    step.reload()

    assert step.distribution == {"nodes": "block" , "sockets": "cyclic",
                                "cores": "block", "plane": None ,"pack": True}


def test_cancel(submit_job):
    job = submit_job(script=create_job_script_multi_step())

    time.sleep(1)
    steps = JobSteps(job)
    assert len(steps) == 3
    assert ("batch" in steps and
            0 in steps and
            1 in steps)

    steps[0].cancel()
    
    time.sleep(0.5)
    steps = JobSteps(job)
    assert len(steps) == 2
    assert ("batch" in steps and
            1 in steps)


def test_modify(submit_job):
    steps = "srun -t 20 sleep 100"
    job = submit_job(script=create_job_script_multi_step(steps))

    time.sleep(1)
    step = JobStep(job, 0).reload()
    assert step.time_limit == "00:20:00"

    step.modify(JobStep(time_limit="00:05:00"))
    assert step.reload().time_limit == "00:05:00"

    step.modify(time_limit="00:15:00")
    assert step.reload().time_limit == "00:15:00"


def test_send_signal(submit_job):
    steps = "srun -t 10 sleep 100"
    job = submit_job(script=create_job_script_multi_step(steps))
    step = JobStep(job, 0)

    time.sleep(1)
    assert step.reload().state == "RUNNING"

    # Send a SIGTERM (basically cancelling the Job)
    step.send_signal(15)

    # Make sure the job is actually cancelled.
    # If a RPCError is raised, this means the Step got cancelled.
    time.sleep(1)
    with pytest.raises(RPCError):
        step.reload()


def test_reload_with_wrong_step_id(submit_job):
    job = submit_job()
    step = JobStep(job, 3)

    with pytest.raises(RPCError):
        step.reload()


def test_parse_all(submit_job):
    job = submit_job()
    step = JobStep(job, "batch")

    # Use the as_dict() function to test if parsing works for all
    # properties on a simple JobStep without error.
    time.sleep(1)
    step.reload().as_dict()
