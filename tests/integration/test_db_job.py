"""test_db_job.py - Unit test database job api functionalities."""

import pytest
import pyslurm
import time
import util


# TODO: Instead of submitting new Jobs and waiting to test Database API
# functionality, we could just fill a slurm database with data on a host, then
# dump the slurm_acct_db to a SQL file and import it in the test environment
# before the integration tests are ran.
# Just a few Jobs and other stuff is enough to keep it small, so it could also
# be put in the repository and uploaded to github.


def test_load_single(submit_job):
    job = submit_job()
    util.wait()
    db_job = pyslurm.db.Job.load(job.id)

    assert db_job.id == job.id

    with pytest.raises(pyslurm.RPCError):
        pyslurm.db.Job.load(1000)


def test_parse_all(submit_job):
    job = submit_job()
    util.wait()
    db_job = pyslurm.db.Job.load(job.id)
    job_dict = db_job.as_dict()

    assert job_dict["stats"]
    assert job_dict["steps"]


def test_modify(submit_job):
    # TODO
    pass


def test_if_steps_exist(submit_job):
    # TODO
    pass


def test_load_with_filter_node(submit_job):
    # TODO
    pass


def test_load_with_filter_qos(submit_job):
    # TODO
    pass


def test_load_with_filter_cluster(submit_job):
    # TODO
    pass


def test_load_with_filter_multiple(submit_job):
    # TODO
    pass


def test_load_with_script(submit_job):
    script = util.create_job_script()
    job = submit_job(script=script)
    util.wait(5)
    db_job = pyslurm.db.Job.load(job.id, with_script=True)
    assert db_job.script == script


def test_load_with_env(submit_job):
    job = submit_job()
    util.wait(5)
    db_job = pyslurm.db.Job.load(job.id, with_env=True)
    assert db_job.environment
