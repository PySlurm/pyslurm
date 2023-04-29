#########################################################################
# test_job_submit.py - job submit api integration tests
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
"""test_job_submit.py - Test the job submit api functions."""

import time
import pytest
import pyslurm
from os import environ as pyenviron
from util import create_simple_job_desc, create_job_script
from pyslurm import (
    Job,
    Jobs,
    JobSubmitDescription,
    RPCError,
)


def test_submit_example1():
    # TODO
    assert True


def test_submit_example2():
    # TODO
    assert True
