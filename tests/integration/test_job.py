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
from pyslurm.db import JobStatistics, JobStepStatistics


def test_parse_all(submit_job):
    job = submit_job(priority=0)
    job_dict = Job.load(job.id).to_dict()

    assert isinstance(job_dict, dict)
    assert "id" in job_dict
    assert "name" in job_dict
    assert "state" in job_dict
    assert "ntasks" in job_dict
    assert job_dict["id"] == job.id
    assert job_dict["name"] == "test_job"


def test_load(submit_job):
    job = submit_job()
    jid = job.id

    # Nothing has been loaded at this point, just make sure everything is
    # on default values.
    assert job.ntasks == 1
    assert job.cpus_per_task == 1
    assert job.time_limit is None

    # Now load the job info
    job = Job.load(jid)

    assert job.id == jid
    assert job.ntasks == 2
    assert job.cpus_per_task == 1
    assert job.time_limit == 1440
    assert job.name == "test_job"
    assert job.memory_per_cpu is not None
    assert job.state in ("PENDING", "RUNNING", "COMPLETING", "COMPLETED")

    with pytest.raises(RPCError):
        Job.load(99999)


def test_cancel(submit_job):
    job = submit_job()
    job.cancel()
    util.wait_for_job_state(job.id, "CANCELLED")


def test_send_signal(submit_job):
    job = submit_job()
    util.wait_for_job_running(job.id)

    # Send a SIGKILL (basically cancelling the Job)
    job.send_signal(9)

    util.wait_for_job_state(job.id, "CANCELLED", timeout=30)


def test_suspend_unsuspend(submit_job):
    job = submit_job()

    util.wait_for_job_running(job.id)
    job.suspend()
    assert Job.load(job.id).state == "SUSPENDED"

    job.unsuspend()
    util.wait_for_job_state(job.id, "RUNNING")


# Don't need to test hold/resume, since it uses just job.modify() to set
# priority to 0/INFINITE.
def test_modify(submit_job):
    job = submit_job(priority=0)
    job = Job(job.id)

    changes = JobSubmitDescription(
        time_limit="2-00:00:00",
        ntasks=5,
        cpus_per_task=4,
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

    util.wait_for_job_running(job.id)
    job.requeue()
    job = Job.load(job.id)

    assert job.requeue_count == 1


def test_notify(submit_job):
    job = submit_job()
    util.wait_for_job_running(job.id)

    # Could check the logfile, but we just assume for now
    # that when this function raises no Exception, everything worked.
    job.notify("Hello Friends!")


def test_get_batch_script(submit_job):
    script_body = create_simple_job_desc().script
    job = submit_job()

    assert script_body == job.get_batch_script()


def test_get_job_queue(submit_job):
    # Submit 10 held jobs (priority=0) to avoid consuming cluster resources
    job_list = [submit_job(priority=0) for i in range(10)]

    jobs = Jobs.load()
    for job in job_list:
        # Check to see if all the Jobs we submitted exist
        assert job.id in jobs
        assert isinstance(jobs[job.id], Job)


def test_load_steps(submit_job):
    submitted = submit_job()
    util.wait_for_job_running(submitted.id)

    jobs = Jobs.load()
    jobs.load_steps()

    job = jobs[submitted.id]
    assert job.state == "RUNNING"
    assert job.steps
    assert isinstance(job.steps, pyslurm.JobSteps)
    assert job.steps.get("batch")


def test_load_stats(submit_job):
    import time

    # Use a script that generates CPU time and disk I/O so all
    # stats fields are nonzero when sampled.
    stats_script = """\
#!/bin/bash
for i in $(seq 1 10000); do echo "$i" > /dev/null; done
dd if=/dev/zero of=/tmp/pyslurm-stats-test bs=1K count=100 2>/dev/null
cat /tmp/pyslurm-stats-test > /dev/null
rm -f /tmp/pyslurm-stats-test
sleep 60
"""
    job = submit_job(script=stats_script)
    util.wait_for_job_running(job.id)

    # Stats are sampled every JobAcctGatherFrequency seconds (5s).
    # Poll until all stats fields are populated (needs at least two samples).
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        job = Job.load(job.id)
        job.load_stats()
        if (
            job.stats
            and job.stats.resident_memory > 0
            and job.stats.elapsed_cpu_time > 0
        ):
            break
        time.sleep(1)

    assert job.state == "RUNNING"
    assert job.stats
    assert isinstance(job.stats, JobStatistics)
    assert job.stats.elapsed_cpu_time > 0
    assert job.stats.resident_memory > 0
    assert job.stats.disk_read > 0
    assert job.stats.disk_write > 0

    for step in job.steps.values():
        assert step.stats
        assert step.state == "RUNNING"
        assert isinstance(step.stats, JobStepStatistics)
        assert step.stats.avg_resident_memory > 0
        assert step.stats.avg_disk_read > 0
        assert step.stats.avg_disk_write > 0
        assert step.stats.elapsed_cpu_time > 0


def test_to_json(submit_job):
    _ = [submit_job(priority=0) for i in range(3)]

    jobs = Jobs.load()
    jobs.load_steps()

    json_data = jobs.to_json()
    dict_data = json.loads(json_data)
    assert dict_data
    assert json_data
    assert len(dict_data) >= 3
