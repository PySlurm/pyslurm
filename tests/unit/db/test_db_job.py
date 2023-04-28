"""test_db_job.py - Unit test basic database job functionalities."""

import pytest
import pyslurm


def test_search_filter():
    job_filter = pyslurm.db.JobSearchFilter()

    job_filter.clusters = ["test1"]
    job_filter.partitions = ["partition1", "partition2"]
    job_filter._create()

    job_filter.ids = [1000, 1001]
    job_filter._create()

    job_filter.with_script = True
    job_filter._create()

    job_filter.with_env = True
    with pytest.raises(ValueError):
        job_filter._create()


def test_collection_init():
    # TODO
    assert True


def test_create_instance():
    job = pyslurm.db.Job(9999)
    assert job.id == 9999
