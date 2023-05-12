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

import pytest
import pyslurm
from util import create_simple_job_desc, create_job_script
from pyslurm import (
    Job,
    Jobs,
    JobSubmitDescription,
    RPCError,
)

def job_desc(**kwargs):
    return JobSubmitDescription(script=create_job_script(), **kwargs)


def test_submit_example1():
    desc = job_desc()
    desc.name = "test1"
    desc.working_directory = "/tmp"
    desc.qos = "normal"
    desc.standard_output = "/tmp/test1.out"
    desc.standard_error = "/tmp/test1.err"
    desc.ntasks = 2
    desc.cpus_per_task = 2
    desc.resource_sharing = "yes"
    desc.memory_per_cpu = "2G"
    desc.time_limit = 10
    desc.nice = 500
    desc.distribution = "block:block:cyclic"
    desc.is_requeueable = True
    desc.kill_on_node_fail = True
    desc.submit()
