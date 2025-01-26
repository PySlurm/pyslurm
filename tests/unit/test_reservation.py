#########################################################################
# test_reservation.py - reservation unit tests
#########################################################################
# Copyright (C) 2025 Toni Harzendorf <toni.harzendorf@gmail.com>
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
"""test_reservation.py - Unit test basic reservation functionalities."""

import pyslurm
from datetime import datetime


def test_create_instance():
    resv = pyslurm.Reservation("test")
    assert resv.name == "test"
    assert resv.accounts == []
    assert resv.start_time == None
    assert resv.end_time == None
    assert resv.duration == 0
    assert resv.is_active is False
    assert resv.cpus_by_node == {}
    assert resv.to_dict()

    start = datetime.now()
    resv.start_time = start
    resv.duration = "1-00:00:00"

    assert resv.start_time == int(start.timestamp())
    assert resv.duration == 60 * 24
    assert resv.end_time == resv.start_time + (60 * 60 * 24)

    resv.duration += pyslurm.utils.timestr_to_mins("1-00:00:00")

    assert resv.start_time == int(start.timestamp())
    assert resv.duration == 2 * 60 * 24
    assert resv.end_time == resv.start_time + (2 * 60 * 60 * 24)

    start = datetime.fromisoformat("2022-04-03T06:00:00")
    end = resv.end_time
    resv.start_time = int(start.timestamp())

    assert resv.start_time == int(start.timestamp())
    assert resv.end_time == end
    assert resv.duration == int((resv.end_time - resv.start_time) / 60)

    duration = resv.duration
    resv.end_time += 60 * 60 * 24
    assert resv.start_time == int(start.timestamp())
    assert resv.end_time == end + (60 * 60 * 24)
    assert resv.duration == duration + (60 * 24)
