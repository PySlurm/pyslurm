#########################################################################
# util.py - utility functions for tests
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

from pyslurm import (
    Job,
    JobStep,
    JobSteps,
    JobSubmitDescription,
    RPCError,
)
import pyslurm
import time
import random
import string


POLL_INTERVAL = 0.25
POLL_TIMEOUT = 15


def wait_for_job_state(job_id, state, timeout=POLL_TIMEOUT):
    """Poll until a job reaches the expected state."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        job = Job.load(job_id)
        if job.state == state:
            return job
        time.sleep(POLL_INTERVAL)
    raise TimeoutError(
        f"Job {job_id} did not reach state '{state}' within {timeout}s "
        f"(current: '{job.state}')"
    )


def wait_for_job_running(job_id, timeout=POLL_TIMEOUT):
    """Poll until a job is running."""
    return wait_for_job_state(job_id, "RUNNING", timeout)


def wait_for_db_job(job_id, timeout=POLL_TIMEOUT, **kwargs):
    """Poll until a job appears in the slurmdbd."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            db_job = pyslurm.db.Job.load(job_id, **kwargs)
            if db_job.id == job_id:
                return db_job
        except Exception:
            pass
        time.sleep(POLL_INTERVAL)
    raise TimeoutError(
        f"Job {job_id} did not appear in database within {timeout}s"
    )


def wait_for_db_job_with_steps(job_id, timeout=POLL_TIMEOUT):
    """Poll until a db job has steps populated."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        db_job = pyslurm.db.Job.load(job_id)
        job_dict = db_job.to_dict()
        if job_dict.get("steps"):
            return db_job
        time.sleep(POLL_INTERVAL)
    raise TimeoutError(
        f"Job {job_id} did not get steps in database within {timeout}s"
    )


def wait_for_step(job_id, step_id, timeout=POLL_TIMEOUT):
    """Poll until a job step exists."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            return JobStep.load(job_id, step_id)
        except (RPCError, KeyError):
            time.sleep(POLL_INTERVAL)
    raise TimeoutError(
        f"Step {step_id} of Job {job_id} did not appear within {timeout}s"
    )


def wait_for_steps(job_id, expected_count, timeout=POLL_TIMEOUT):
    """Poll until a job has the expected number of steps."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            steps = JobSteps.load(job_id)
            if len(steps) >= expected_count:
                return steps
        except (KeyError, Exception):
            pass
        time.sleep(POLL_INTERVAL)
    raise TimeoutError(
        f"Job {job_id} did not reach {expected_count} steps within {timeout}s"
    )


def wait_for_step_gone(job_id, step_id, timeout=POLL_TIMEOUT):
    """Poll until a job step no longer exists or reaches a terminal state."""
    terminal = {"CANCELLED", "COMPLETED", "FAILED", "TIMEOUT", "COMPLETING"}
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            step = JobStep.load(job_id, step_id)
            if step.state in terminal:
                return
            time.sleep(POLL_INTERVAL)
        except (RPCError, KeyError):
            return
    raise TimeoutError(
        f"Step {step_id} of Job {job_id} still exists after {timeout}s"
    )


def wait_for_job_done(job_id, timeout=POLL_TIMEOUT):
    """Poll until a job reaches a terminal state (COMPLETED, CANCELLED, FAILED)."""
    terminal = {"COMPLETED", "CANCELLED", "FAILED", "TIMEOUT", "NODE_FAIL"}
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            job = Job.load(job_id)
            if job.state in terminal:
                return job
        except Exception:
            return
        time.sleep(POLL_INTERVAL)
    raise TimeoutError(
        f"Job {job_id} did not reach terminal state within {timeout}s"
    )


def randstr(strlen=10):
   chars = string.ascii_lowercase
   return ''.join(random.choice(chars) for n in range(strlen))


def create_job_script():
    job_script = """\
#!/bin/bash

echo "Got args: $@"

/usr/bin/env

sleep 500\

"""
    return job_script


def create_simple_job_desc(script=None, **kwargs):
    job = JobSubmitDescription(**kwargs)

    job.name = "test_job"
    job.standard_output = "/tmp/slurm-test-%j.out"
    job.memory_per_cpu = "100M"
    job.ntasks = 2
    job.cpus_per_task = 1
    job.script = create_job_script() if not script else script
    job.time_limit = "1-00:00:00"

    return job
