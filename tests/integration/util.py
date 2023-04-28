import pytest
from pyslurm import (
    Job,
    JobSubmitDescription,
)
import time

# Horrendous, but works for now, because when testing against a real slurmctld
# we need to wait a bit for state changes (i.e. we cancel a job and
# immediately check after if the state is really "CANCELLED", but the state
# hasn't changed yet, so we need to wait a bit)
WAIT_SECS_SLURMCTLD = 3


def wait(secs=WAIT_SECS_SLURMCTLD):
    time.sleep(secs)


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
    job.memory_per_cpu = "1G"
    job.ntasks = 2
    job.cpus_per_task = 3
    job.script = create_job_script() if not script else script
    job.time_limit = "1-00:00:00"

    return job
