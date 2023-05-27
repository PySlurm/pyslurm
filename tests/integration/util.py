#########################################################################
# util.py - utility functions for tests
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
import time
import random, string

# Horrendous, but works for now, because when testing against a real slurmctld
# we need to wait a bit for state changes (i.e. we cancel a job and
# immediately check after if the state is really "CANCELLED", but the state
# hasn't changed yet, so we need to wait a bit)
WAIT_SECS_SLURMCTLD = 3


def wait(secs=WAIT_SECS_SLURMCTLD):
    time.sleep(secs)


def randstr(strlen=10):
   chars = string.ascii_lowercase
   return ''.join(random.choice(chars) for n in range(strlen))


def create_job_script():
    job_script = """\
#!/bin/bash

echo "Got args: $@"

/usr/bin/env

sleep 500\

"""
    return job_script


def create_simple_job_desc(script=None, **kwargs):
    job = JobSubmitDescription(**kwargs)

    job.name = "test_job"
    job.standard_output = "/tmp/slurm-test-%j.out"
    job.memory_per_cpu = "1G"
    job.ntasks = 2
    job.cpus_per_task = 3
    job.script = create_job_script() if not script else script
    job.time_limit = "1-00:00:00"

    return job
