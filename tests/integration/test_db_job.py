#########################################################################
# test_db_job.py - database job api integration tests
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
    job = submit_job()
    util.wait(5)

    jfilter = pyslurm.db.JobFilter(ids=[job.id])
    changes = pyslurm.db.Job(comment="test comment")
    pyslurm.db.Jobs.modify(jfilter, changes)

    job = pyslurm.db.Job.load(job.id)
    assert job.comment == "test comment"


def test_modify_with_existing_conn(submit_job):
    job = submit_job()
    util.wait(5)

    conn = pyslurm.db.Connection.open()
    jfilter = pyslurm.db.JobFilter(ids=[job.id])
    changes = pyslurm.db.Job(comment="test comment")
    pyslurm.db.Jobs.modify(jfilter, changes, conn)

    job = pyslurm.db.Job.load(job.id)
    assert job.comment != "test comment"

    conn.commit()
    job = pyslurm.db.Job.load(job.id)
    assert job.comment == "test comment"


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
