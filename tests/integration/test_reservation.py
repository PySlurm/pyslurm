#########################################################################
# test_reservation.py - reservation integration tests
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
"""test_reservation.py - integration test reservation functionalities."""

import pyslurm
from datetime import datetime


def test_api_calls():
    start = datetime.now()
    duration = "1-00:00:00"
    resv = pyslurm.Reservation(
        name="testing",
        start_time=start,
        duration=duration,
        users=["root"],
        node_count=1,
    )
    resv.create()

    reservations = pyslurm.Reservations.load()
    resv = reservations["testing"]
    assert len(reservations) == 1
    assert resv.name == "testing"
    assert resv.to_dict()

    assert resv.start_time == int(start.timestamp())
    assert resv.duration == 60 * 24
    assert resv.end_time == resv.start_time + (60 * 60 * 24)

    resv.duration += 60 * 24
    resv.modify()

    resv = pyslurm.Reservation.load("testing")
    assert resv.name == "testing"
    assert resv.start_time == int(start.timestamp())
    assert resv.duration == 2 * 60 * 24
    assert resv.end_time == resv.start_time + (2 * 60 * 60 * 24)

    resv.delete()
    reservations = pyslurm.Reservations.load()
    assert len(reservations) == 0
