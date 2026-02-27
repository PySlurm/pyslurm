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
import json


# TODO: Instead of submitting new Jobs and waiting to test Database API
# functionality, we could just fill a slurm database with data on a host, then
# dump the slurm_acct_db to a SQL file and import it in the test environment
# before the integration tests are ran.
# Just a few Jobs and other stuff is enough to keep it small, so it could also
# be put in the repository and uploaded to github.


def test_load_single(submit_job):
    job = submit_job()
    util.wait()

    with pyslurm.db.connect() as conn:
        db_job = pyslurm.db.Job.load(conn, job.id)

        assert db_job.id == job.id

        with pytest.raises(pyslurm.core.error.NotFoundError):
            pyslurm.db.Job.load(conn, 0)


def test_parse_all(submit_job):
    job = submit_job()
    util.wait()

    with pyslurm.db.connect() as conn:
        db_job = pyslurm.db.Job.load(conn, job.id)

    job_dict = db_job.to_dict()

    assert job_dict["stats"]
    assert job_dict["steps"]


def test_to_json(submit_job):
    job = submit_job()
    util.wait()

    with pyslurm.db.connect() as conn:
        jfilter = pyslurm.db.JobFilter(ids=[job.id])
        jobs = conn.jobs.load(jfilter)

    json_data = jobs.to_json()
    dict_data = json.loads(json_data)
    assert dict_data
    assert json_data
    assert len(dict_data) == 1


def test_modify(submit_job):
    job = submit_job()
    util.wait(5)

    # With explicit separate Job object as changes
    with pyslurm.db.connect() as conn:
        comment = "comment two"

        job = pyslurm.db.Job.load(conn, job.id)
        assert job.comment != comment

        jfilter = pyslurm.db.JobFilter(ids=[job.id])
        changes = pyslurm.db.Job(comment=comment)
        conn.jobs.modify(jfilter, changes)
        job = pyslurm.db.Job.load(conn, job.id)
        assert job.comment == comment

    # With filter via **kwargs
    with pyslurm.db.connect(commit_on_success=False) as conn:
        comment = "comment two"
        job = pyslurm.db.Job.load(conn, job.id)
        assert job.comment != comment

        jfilter = pyslurm.db.JobFilter(ids=[job.id])
        conn.jobs.modify(jfilter, comment=comment)

        conn.commit()
        job = pyslurm.db.Job.load(conn, job.id)
        assert job.comment == comment

        with pytest.raises(pyslurm.core.error.ArgumentError):
            conn.jobs.modify(jfilter)

    # Without filter, using modify() on the instance
    # By default, connections are inherited
    with pyslurm.db.connect() as conn:
        comment = "comment three"
        job = pyslurm.db.Job.load(conn, job.id)
        assert job.comment != comment

        job.modify(comment=comment)

        job = pyslurm.db.Job.load(conn, job.id)
        assert job.comment == comment

    # Without inherited connection, not supplying a connection will fail
    with pyslurm.db.connect(reuse_connection=False) as conn:
        comment = "comment four"
        job = pyslurm.db.Job.load(conn, job.id)
        assert job.comment != comment

        job.modify(db_conn=conn, comment=comment)

        job = pyslurm.db.Job.load(conn, job.id)
        assert job.comment == comment

        with pytest.raises(pyslurm.db.connection.InvalidConnectionError):
            job.modify(comment=comment)


#   def test_if_steps_exist(submit_job):
#       # TODO
#       pass


#   def test_load_with_filter_node(submit_job):
#       # TODO
#       pass


#   def test_load_with_filter_qos(submit_job):
#       # TODO
#       pass


#   def test_load_with_filter_cluster(submit_job):
#       # TODO
#       pass


#   def test_load_with_filter_multiple(submit_job):
#       # TODO
#       pass


def test_load_with_script(submit_job):
    script = util.create_job_script()
    job = submit_job(script=script)
    util.wait(5)

    with pyslurm.db.connect() as conn:
        db_job = pyslurm.db.Job.load(conn, job.id, with_script=True)
    assert db_job.script == script


def test_load_with_env(submit_job):
    job = submit_job()
    util.wait(5)

    with pyslurm.db.connect() as conn:
        db_job = pyslurm.db.Job.load(conn, job.id, with_env=True)
    assert db_job.environment
