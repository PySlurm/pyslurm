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

import json
import pytest

import pyslurm
from pyslurm import ReservationFlags, ReservationReoccurrence
from datetime import datetime
from enum import Enum


def test_create_instance():
    resv = pyslurm.Reservation("test")
    assert resv.name == "test"
    assert resv.accounts == []
    assert resv.start_time is None
    assert resv.end_time is None
    assert resv.duration == 0
    assert resv.is_active is False
    assert resv.cpu_ids_by_node == {}
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

    start = datetime(2022, 4, 3, 6, 0, 0)
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

    assert resv.reoccurrence == ReservationReoccurrence.NO
    assert resv.reoccurrence == "NO"
    resv.reoccurrence = ReservationReoccurrence.DAILY

    assert resv.flags == resv.flags.__class__(0)
    resv.flags = ReservationFlags.MAINTENANCE | ReservationFlags.FLEX
    assert resv.flags == ReservationFlags.MAINTENANCE | ReservationFlags.FLEX
    resv.flags |= ReservationFlags.MAGNETIC
    assert (
        resv.flags
        == ReservationFlags.MAINTENANCE
        | ReservationFlags.FLEX
        | ReservationFlags.MAGNETIC
    )

    resv.flags = ["FLEX", "PURGE"]
    assert resv.flags == ReservationFlags.FLEX | ReservationFlags.PURGE


def test_flags_sched_failed():
    combo = (
        ReservationFlags.SCHED_FAILED
        | ReservationFlags.SPECIFIC_NODES
        | ReservationFlags.IGNORE_RUNNING_JOBS
    )
    decoded = ReservationFlags(combo.value)
    assert ReservationFlags.SCHED_FAILED in decoded


def test_flags_gres_tres():
    # Regression: reservations with GRES/TRES (e.g. TRES=cpu=2,gres/gpu=2)
    # cause Slurm to set GRES_REQ and TRES_PER_NODE internally, which
    # previously raised ValueError due to unrecognised bits.
    combo = (
        ReservationFlags.SPECIFIC_NODES   # SLURM_BIT(15) = 32768
        | ReservationFlags.GRES_REQUIRED  # SLURM_BIT(37) = 137438953472
        | ReservationFlags.TRES_PER_NODE  # SLURM_BIT(38) = 274877906944
    )
    assert combo.value == 412316893184
    decoded = ReservationFlags(412316893184)
    assert ReservationFlags.GRES_REQUIRED in decoded
    assert ReservationFlags.TRES_PER_NODE in decoded
    assert ReservationFlags.SPECIFIC_NODES in decoded


def test_flags_to_list():
    flags = ReservationFlags.MAINTENANCE | ReservationFlags.FLEX
    assert flags.to_list() == ["MAINTENANCE", "FLEX"]


def test_flags_to_list_when_no_flags_are_set():
    assert ReservationFlags(0).to_list() == []


def test_to_dict_recursive_converts_flags_to_list():
    resv = pyslurm.Reservation("test")
    resv.flags = ReservationFlags.MAINTENANCE | ReservationFlags.FLEX

    data = resv.to_dict(recursive=True)
    assert data["flags"] == ["MAINTENANCE", "FLEX"]

    # Without recursive, the rich Flag object is kept.
    assert resv.to_dict()["flags"] == (
        ReservationFlags.MAINTENANCE | ReservationFlags.FLEX
    )


def test_to_dict_recursive_converts_reoccurrence_to_str():
    resv = pyslurm.Reservation("test")
    resv.reoccurrence = ReservationReoccurrence.DAILY

    data = resv.to_dict(recursive=True)
    assert data["reoccurrence"] == "DAILY"
    assert not isinstance(data["reoccurrence"], Enum)


def test_to_dict_recursive_is_json_serializable():
    resv = pyslurm.Reservation("test")
    resv.flags = ReservationFlags.ANY_NODES

    data = json.loads(json.dumps(resv.to_dict(recursive=True)))
    assert data["flags"] == ["ANY_NODES"]
    assert data["reoccurrence"] == "NO"


def test_to_dict_recursive_is_json_serializable_without_flags():
    # Every Reservation has a `flags` attribute, so serializing used to fail
    # even when no flag at all is set.
    resv = pyslurm.Reservation("test")

    data = json.loads(json.dumps(resv.to_dict(recursive=True)))
    assert data["flags"] == []


def test_flags_time_float_replace_and_force_start():
    # Regression: these flags are set by Slurm on reservations created with
    # e.g. `flags=TIME_FLOAT`, but had no member here, which made decoding
    # such a reservation raise ValueError.
    combo = (
        ReservationFlags.TIME_FLOAT
        | ReservationFlags.REPLACE
        | ReservationFlags.FORCE_START
    )
    decoded = ReservationFlags(combo.value)
    assert ReservationFlags.TIME_FLOAT in decoded
    assert ReservationFlags.REPLACE in decoded
    assert ReservationFlags.FORCE_START in decoded


def test_flags_from_int_ignores_unknown_bits():
    # Bits that a newer Slurm may set, but that pyslurm does not know about
    # yet, must not make decoding fail.
    value = ReservationFlags.MAINTENANCE.value | (1 << 63)
    assert ReservationFlags.from_int(value) == ReservationFlags.MAINTENANCE


def test_flags_from_int_with_known_bits():
    flags = ReservationFlags.MAINTENANCE | ReservationFlags.FLEX
    assert ReservationFlags.from_int(flags.value) == flags


def test_flags_from_int_without_any_bits():
    assert ReservationFlags.from_int(0) == ReservationFlags(0)


def test_flags_from_list_with_enum_members():
    flags = ReservationFlags.from_list(
        [ReservationFlags.MAINTENANCE, ReservationFlags.FLEX]
    )
    assert flags == ReservationFlags.MAINTENANCE | ReservationFlags.FLEX


def test_flags_from_list_is_case_insensitive():
    assert ReservationFlags.from_list(["flex"]) == ReservationFlags.FLEX


def test_flags_from_list_with_unknown_flag():
    with pytest.raises(ValueError, match="NOT_A_FLAG"):
        ReservationFlags.from_list(["NOT_A_FLAG"])


def test_flags_from_list_roundtrip():
    flags = ReservationFlags.MAINTENANCE | ReservationFlags.ANY_NODES
    assert ReservationFlags.from_list(flags.to_list()) == flags


def test_flags_setter_with_enum_member_list():
    resv = pyslurm.Reservation("test")
    resv.flags = [ReservationFlags.MAINTENANCE, "FLEX"]
    assert resv.flags == ReservationFlags.MAINTENANCE | ReservationFlags.FLEX


def test_collection_to_json():
    resv = pyslurm.Reservation("test")
    resv.flags = ReservationFlags.ANY_NODES

    reservations = pyslurm.Reservations()
    reservations.add(resv)

    data = json.loads(reservations.to_json())
    assert data["test"]["flags"] == ["ANY_NODES"]

