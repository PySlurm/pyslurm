#########################################################################
# test_job_steps.py - job steps unit tests
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
"""test_job_steps.py - Unit test basic job step functionality."""

import pytest
from pyslurm import JobStep, Job
from pyslurm.utils.helpers import (
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
    assert JobStep(9999, 1).as_dict()
