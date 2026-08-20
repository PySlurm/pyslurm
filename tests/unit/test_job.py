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

from pyslurm import Job, JobExclusive, JobOversubscribe
from pyslurm.core.job.util import (
    acctg_profile_int_to_list,
    dependency_str_to_dict,
    mail_type_int_to_list,
)
from pyslurm.utils.helpers import cpu_freq_int_to_str


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


def test_cpu_freq_int_to_str():
    expected = None
    assert cpu_freq_int_to_str(0) == expected


def test_job_exclusive_from_value():
    assert JobExclusive.from_value(0, default=JobExclusive.NONE) == "NONE"
    assert JobExclusive.from_value(1, default=JobExclusive.NONE) == "NODE"
    assert JobExclusive.from_value(2, default=JobExclusive.NONE) == "USER"
    assert JobExclusive.from_value(3, default=JobExclusive.NONE) == "MCS"
    assert JobExclusive.from_value(4, default=JobExclusive.NONE) == "TOPO"


def test_job_exclusive_unknown_value_falls_back_to_default():
    # A value from a newer Slurm must not raise, and must not be misdecoded
    # as some unrelated member.
    assert JobExclusive.from_value(99, default=JobExclusive.NONE) == "NONE"


def test_job_oversubscribe_from_value():
    assert JobOversubscribe.from_value(0, default=JobOversubscribe.NO) == "NO"
    assert JobOversubscribe.from_value(1, default=JobOversubscribe.NO) == "YES"
    assert JobOversubscribe.from_value(2, default=JobOversubscribe.NO) == "OK"


def test_job_exclusive_is_str_comparable():
    assert JobExclusive.MCS == "MCS"
    assert str(JobExclusive.MCS) == "MCS"
