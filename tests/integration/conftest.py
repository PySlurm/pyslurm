#########################################################################
# conftest.py - pytest fixtures
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
