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
"""test_db_job.py - Integration test database job api functionalities."""

import pytest
import pyslurm
import util
import json


def test_load_single(submit_job):
    job = submit_job()
    db_job = util.wait_for_db_job(job.id)

    assert db_job.id == job.id
    assert db_job.name == "test_job"
    assert db_job.user_name is not None
    assert db_job.account is not None
    assert db_job.partition is not None
    assert db_job.submit_time > 0

    with pytest.raises(pyslurm.RPCError):
        pyslurm.db.Job.load(0)


def test_parse_all(submit_job):
    job = submit_job()
    util.wait_for_job_running(job.id)
    db_job = util.wait_for_db_job_with_steps(job.id)
    job_dict = db_job.to_dict()

    assert isinstance(job_dict, dict)
    assert job_dict["id"] == job.id
    assert job_dict["stats"]
    assert job_dict["steps"]


def test_to_json(submit_job):
    job = submit_job()
    util.wait_for_db_job(job.id)

    jfilter = pyslurm.db.JobFilter(ids=[job.id])
    jobs = pyslurm.db.Jobs.load(jfilter)

    json_data = jobs.to_json()
    dict_data = json.loads(json_data)
    assert dict_data
    assert json_data
    assert len(dict_data) == 1


def test_modify(submit_job):
    job = submit_job()
    util.wait_for_db_job(job.id)

    jfilter = pyslurm.db.JobFilter(ids=[job.id])
    changes = pyslurm.db.Job(comment="test comment")
    pyslurm.db.Jobs.modify(jfilter, changes)

    job = pyslurm.db.Job.load(job.id)
    assert job.comment == "test comment"


def test_modify_with_existing_conn(submit_job):
    job = submit_job()
    util.wait_for_db_job(job.id)

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
    job = submit_job()
    util.wait_for_job_running(job.id)
    db_job = util.wait_for_db_job_with_steps(job.id)

    assert isinstance(db_job.steps, pyslurm.db.JobSteps)
    assert len(db_job.steps) > 0

    for step_id, step in db_job.steps.items():
        assert step.job_id == job.id
        assert step.state is not None
        assert step.ntasks is not None


def test_load_with_filter_nodelist(submit_job):
    job = submit_job()
    util.wait_for_job_running(job.id)
    db_job = util.wait_for_db_job(job.id)
    assert db_job.nodelist

    jfilter = pyslurm.db.JobFilter(
        ids=[job.id],
        nodelist=[db_job.nodelist],
    )
    jobs = pyslurm.db.Jobs.load(jfilter)
    assert job.id in jobs

    # A non-existent node should return no results for this job
    jfilter_empty = pyslurm.db.JobFilter(
        ids=[job.id],
        nodelist=["nonexistent_node"],
    )
    jobs_empty = pyslurm.db.Jobs.load(jfilter_empty)
    assert job.id not in jobs_empty


def test_load_with_filter_qos(submit_job):
    job = submit_job()
    util.wait_for_db_job(job.id)

    jfilter = pyslurm.db.JobFilter(ids=[job.id], qos=["normal"])
    jobs = pyslurm.db.Jobs.load(jfilter)
    assert job.id in jobs

    # PySlurm validates QoS names before querying — a bogus name raises ValueError
    with pytest.raises(ValueError, match="does not exist"):
        jfilter_bad = pyslurm.db.JobFilter(
            ids=[job.id], qos=["nonexistent_qos"]
        )
        pyslurm.db.Jobs.load(jfilter_bad)


def test_load_with_filter_users(submit_job):
    job = submit_job()
    util.wait_for_db_job(job.id)

    jfilter = pyslurm.db.JobFilter(ids=[job.id], users=["root"])
    jobs = pyslurm.db.Jobs.load(jfilter)
    assert job.id in jobs

    jfilter_empty = pyslurm.db.JobFilter(ids=[job.id], users=["nobody"])
    jobs_empty = pyslurm.db.Jobs.load(jfilter_empty)
    assert job.id not in jobs_empty


def test_load_with_filter_multiple(submit_job):
    job = submit_job()
    util.wait_for_db_job(job.id)

    # Combine multiple filters that should all match
    jfilter = pyslurm.db.JobFilter(
        ids=[job.id],
        users=["root"],
        qos=["normal"],
        partitions=["normal"],
        names=["test_job"],
    )
    jobs = pyslurm.db.Jobs.load(jfilter)
    assert job.id in jobs
    assert len(jobs) == 1

    db_job = jobs[job.id]
    assert db_job.user_name == "root"
    assert db_job.qos == "normal"
    assert db_job.partition == "normal"
    assert db_job.name == "test_job"

    # Mismatch on one filter (partition) should exclude the job
    jfilter_mismatch = pyslurm.db.JobFilter(
        ids=[job.id],
        users=["root"],
        partitions=["nonexistent_partition"],
    )
    jobs_mismatch = pyslurm.db.Jobs.load(jfilter_mismatch)
    assert job.id not in jobs_mismatch


def test_load_with_script(submit_job):
    script = util.create_job_script()
    job = submit_job(script=script)
    db_job = util.wait_for_db_job(job.id, with_script=True)
    assert db_job.script == script


def test_load_with_env(submit_job):
    job = submit_job()
    util.wait_for_job_running(job.id)
    db_job = util.wait_for_db_job(job.id, with_env=True)
    assert db_job.environment
