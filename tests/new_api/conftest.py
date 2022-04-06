import pytest
from pyslurm import (
    Job,
    JobSubmitDescription,
)


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
    job.stdout = "/tmp/slurm-test-%j.out"
    job.mem_per_cpu = "1G"
    job.ntasks = 2
    job.cpus_per_task = 3
    job.script = create_job_script() if not script else script
    job.time_limit = "1-00:00:00"

    return job


@pytest.fixture
def submit_job():

    jobs = []
    def _job(script=None, **kwargs):
        job_desc = create_simple_job_desc(script, **kwargs)
        job = Job(job_desc.submit())

        jobs.append(job)
        return job

    yield _job

    for j in jobs:
        j.cancel()
