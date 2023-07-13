#########################################################################
# test_job.py - job unit tests
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
"""test_job.py - Unit test basic job functionalities."""

import pytest
import pyslurm
from pyslurm import Job
from pyslurm.core.job.util import *

def test_create_instance():
    job = Job(9999)
    assert job.id == 9999


def test_parse_all():
    assert Job(9999).to_dict()


def test_parse_dependencies_to_dict():
    expected = None
    assert dependency_str_to_dict("") == expected

    expected = {
        "after": [1, 2],
        "afterany": [],
        "afterburstbuffer": [],
        "aftercorr": [],
        "afternotok": [],
        "afterok": [3],
        "singleton": False,
        "satisfy": "all",
    }
    input_str = "after:1:2,afterok:3"
    assert dependency_str_to_dict(input_str) == expected


def test_mail_types_int_to_list():
    expected = []
    assert mail_type_int_to_list(0) == expected
    

def test_acctg_profile_int_to_list():
    expected = []
    assert acctg_profile_int_to_list(0) == expected


def test_power_type_int_to_list():
    expected = []
    assert power_type_int_to_list(0) == expected


def test_cpu_freq_int_to_str():
    expected = None
    assert cpu_freq_int_to_str(0) == expected
