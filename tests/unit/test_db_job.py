#########################################################################
# test_db_job.py - database job unit tests
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
