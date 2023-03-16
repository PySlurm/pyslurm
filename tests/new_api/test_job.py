"""test_job.py - Test the job api functions."""

import sys
import time
import pytest
import pyslurm
import tempfile
import os
from os import environ as pyenviron
from conftest import create_simple_job_desc
from pyslurm import (
    Job,
    Jobs,
    JobSubmitDescription,
    RPCError,
)


def test_reload(submit_job):
    job = submit_job()
    jid = job.id

    # Nothing has been loaded at this point, just make sure everything is
    # on default values.
    assert job.ntasks == 1
    assert job.cpus_per_task == 1
    assert job.time_limit == None

    # Now load the job info
    job.reload()

    assert job.id == jid
    assert job.ntasks == 2
    assert job.cpus_per_task == 3
    assert job.time_limit == 1440

    with pytest.raises(RPCError):
        Job(99999).reload()


def test_cancel(submit_job):
    job = submit_job()

    job.cancel()

    # make sure the job is actually cancelled
    time.sleep(0.5)
    assert job.reload().state == "CANCELLED"


def test_parse_all(submit_job):
    job = submit_job()

    # Use the as_dict() function to test if parsing works for all
    # properties on a simple Job without error.
    job.reload().as_dict()


def test_send_signal(submit_job):
    job = submit_job()

    time.sleep(1)
    assert job.reload().state == "RUNNING"

    # Send a SIGKILL (basically cancelling the Job)
    job.send_signal(9)

    # make sure the job is actually cancelled
    time.sleep(1)
    assert job.reload().state == "CANCELLED"


def test_suspend_unsuspend(submit_job):
    job = submit_job()

    time.sleep(1)
    job.suspend()
    assert job.reload().state == "SUSPENDED"

    job.unsuspend()
    # make sure the job is actually running again
    time.sleep(1)
    assert job.reload().state == "RUNNING"


# Don't need to test hold/resume, since it uses just job.modify() to set
# priority to 0/INFINITE.
def test_modify(submit_job):
    job = submit_job(priority=0)
    job = job.reload()

    changes = JobSubmitDescription(
        time_limit = "2-00:00:00",
        ntasks = 5,
        cpus_per_task = 4,
    )

    job.modify(changes)
    job.reload()

    assert job.time_limit == 2880
    assert job.ntasks == 5
    assert job.cpus_per_task == 4


def test_requeue(submit_job):
    job = submit_job()
    job.reload()

    assert job.requeue_count == 0

    time.sleep(1.5)
    job.requeue()
    job.reload()

    assert job.requeue_count == 1


def test_notify(submit_job):
    job = submit_job()
    time.sleep(1)

    # Could check the logfile, but we just assume for now
    # that when this function raises no Exception, everything worked.
    job.notify("Hello Friends!")


def test_get_batch_script(submit_job):
    script_body = create_simple_job_desc().script
    job = submit_job()

    assert script_body == job.get_batch_script()


def test_get_job_queue(submit_job):
    # Submit 10 jobs, gather the job_ids in a list
    job_list = [submit_job() for i in range(10)]

    jobs = Jobs()
    for job in job_list:
        # Check to see if all the Jobs we submitted exist
        assert job.id in jobs
        assert isinstance(jobs[job.id], Job)
