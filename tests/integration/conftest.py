import pytest
from pyslurm import (
    Job,
    JobSubmitDescription,
)
from util import create_simple_job_desc


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
