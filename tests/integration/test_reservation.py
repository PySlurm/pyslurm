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
from pyslurm import ReservationFlags, ReservationReoccurrence
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
        reoccurrence="DAILY"
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

    assert resv.reoccurrence == ReservationReoccurrence.DAILY
    assert resv.reoccurrence == "DAILY"
    # Can only remove this once the Reservation exists. Setting another
    # reoccurrence doesn't work, probably a bug in slurmctld..., because it
    # makes no sense why that shouldn't work.
    resv.reoccurrence = ReservationReoccurrence.NO
    resv.modify()

    resv = pyslurm.Reservation.load("testing")
    assert resv.reoccurrence == "NO"

    resv.flags = ReservationFlags.MAINTENANCE | ReservationFlags.FLEX
    resv.modify()

    resv = pyslurm.Reservation.load("testing")
    assert resv.flags == ReservationFlags.MAINTENANCE | ReservationFlags.FLEX

    assert ReservationFlags.PURGE not in resv.flags
    resv.purge_time = "2-00:00:00"
    resv.modify()

    resv = pyslurm.Reservation.load("testing")
    assert ReservationFlags.PURGE in resv.flags
    assert resv.purge_time == 2 * 60 * 60 * 24

    resv.purge_time = "3-00:00:00"
    resv.modify()

    resv = pyslurm.Reservation.load("testing")
    assert ReservationFlags.PURGE in resv.flags
    assert resv.purge_time == 3 * 60 * 60 * 24

    assert resv.to_dict()
    resv.delete()
    reservations = pyslurm.Reservations.load()
    assert len(reservations) == 0
