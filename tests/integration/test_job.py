#########################################################################
# test_job.py - job api integration tests
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
"""test_job.py - Integration test job api functionalities."""

import time
import pytest
import pyslurm
import json
import util
from util import create_simple_job_desc
from pyslurm import (
    Job,
    Jobs,
    JobSubmitDescription,
    RPCError,
)
from pyslurm.db import JobStatistics


def test_parse_all(submit_job):
    job = submit_job()
    Job.load(job.id).to_dict()


def test_load(submit_job):
    job = submit_job()
    jid = job.id

    # Nothing has been loaded at this point, just make sure everything is
    # on default values.
    assert job.ntasks == 1
    assert job.cpus_per_task == 1
    assert job.time_limit == None

    # Now load the job info
    job = Job.load(jid)

    assert job.id == jid
    assert job.ntasks == 2
    assert job.cpus_per_task == 3
    assert job.time_limit == 1440

    with pytest.raises(RPCError):
        Job.load(99999)


def test_cancel(submit_job):
    job = submit_job()
    job.cancel()
    # make sure the job is actually cancelled
    util.wait()
    assert Job.load(job.id).state == "CANCELLED"


def test_send_signal(submit_job):
    job = submit_job()

    util.wait()
    assert Job.load(job.id).state == "RUNNING"

    # Send a SIGKILL (basically cancelling the Job)
    job.send_signal(9)

    # make sure the job is actually cancelled
    util.wait()
    assert Job.load(job.id).state == "CANCELLED"


def test_suspend_unsuspend(submit_job):
    job = submit_job()

    util.wait()
    job.suspend()
    assert Job.load(job.id).state == "SUSPENDED"

    job.unsuspend()
    # make sure the job is actually running again
    util.wait()
    assert Job.load(job.id).state == "RUNNING"


# Don't need to test hold/resume, since it uses just job.modify() to set
# priority to 0/INFINITE.
def test_modify(submit_job):
    job = submit_job(priority=0)
    job = Job(job.id)

    changes = JobSubmitDescription(
        time_limit = "2-00:00:00",
        ntasks = 5,
        cpus_per_task = 4,
    )

    job.modify(changes)
    job = Job.load(job.id)

    assert job.time_limit == 2880
    assert job.ntasks == 5
    assert job.cpus_per_task == 4


def test_requeue(submit_job):
    job = submit_job()
    job = Job.load(job.id)

    assert job.requeue_count == 0

    util.wait()
    job.requeue()
    job = Job.load(job.id)

    assert job.requeue_count == 1


def test_notify(submit_job):
    job = submit_job()
    util.wait()

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

    jobs = Jobs.load()
    for job in job_list:
        # Check to see if all the Jobs we submitted exist
        assert job.id in jobs
        assert isinstance(jobs[job.id], Job)


def test_load_steps(submit_job):
    job_list = [submit_job() for i in range(3)]
    util.wait()

    jobs = Jobs.load()
    jobs.load_steps()

    for _job in job_list:
        job = jobs[_job.id]
        assert job.state == "RUNNING"
        assert job.steps
        assert isinstance(job.steps, pyslurm.JobSteps)
        assert job.steps.get("batch")


def test_load_stats(submit_job):
    job = submit_job()
    util.wait(100)

    job = Job.load(job.id)
    job.load_stats()

    assert job.state == "RUNNING"
    assert job.stats
    assert isinstance(job.stats, JobStatistics)
    assert job.stats.elapsed_cpu_time > 0

    for step in job.steps.values():
        assert step.stats
        assert step.state == "RUNNING"
        assert isinstance(step.stats, JobStatistics)
        assert step.stats.avg_virtual_memory > 0
        assert step.stats.avg_resident_memory > 0


def test_to_json(submit_job):
    job_list = [submit_job() for i in range(3)]
    util.wait()

    jobs = Jobs.load()
    jobs.load_steps()

    json_data = jobs.to_json()
    dict_data = json.loads(json_data)
    assert dict_data
    assert json_data
    assert len(dict_data) >= 3


def test_get_resource_layout_per_node(submit_job):
    # TODO
    assert True
