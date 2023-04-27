"""test_job_steps.py - Unit test basic job step functionality."""

import pytest
from pyslurm import JobStep, Job
from pyslurm.core.job.step import (
    humanize_step_id,
    dehumanize_step_id,
)

def test_create_instance():
    step = JobStep(9999, 1)
    assert step.id == 1
    assert step.job_id == 9999

    job = Job(10000)
    step2 = JobStep(job, 2)
    assert step2.id == 2
    assert step2.job_id == 10000


def test_parse_all():
    # Use the as_dict() function to test if parsing works for all
    # properties on a simple JobStep without error.
    JobStep(9999, 1).as_dict()
