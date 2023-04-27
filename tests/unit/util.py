import pytest
from pyslurm import (
    Job,
    JobSubmitDescription,
)

# TODO: Figure out how to share this properly between the unit and integration
# folders

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
