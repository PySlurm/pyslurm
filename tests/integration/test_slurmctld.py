#########################################################################
# test_slurmctld.py - slurmctld integration tests
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
"""test_slurmctld.py - integration test basic slurmctld functionalities."""

import pytest
import pyslurm
from pyslurm import slurmctld


def test_ping():
    resp = slurmctld.ping_primary()
    assert resp.is_responding
    assert resp.is_primary
    assert resp.index == 0
    assert resp.hostname is not None
    assert resp.latency > 0
    assert resp.to_dict()


def test_ping_all():
    pings = slurmctld.ping_all()
    assert isinstance(pings, list)

    for resp in pings:
        assert resp.hostname is not None
        assert resp.latency > 0


def test_reconfigure():
    slurmctld.reconfigure()


def test_load_config():
    conf = slurmctld.Config.load()

    assert conf
    assert conf.to_dict()
    assert conf.cgroup_config
    assert conf.accounting_gather_config
    assert conf.mpi_config


def test_debug_flags():
    slurmctld.clear_debug_flags()

    slurmctld.add_debug_flags([])
    assert slurmctld.get_debug_flags() == []

    slurmctld.add_debug_flags(["CpuFrequency", "Backfill"])
    assert slurmctld.get_debug_flags() == ["Backfill", "CpuFrequency"]

    slurmctld.add_debug_flags(["Agent"])
    assert slurmctld.get_debug_flags() == ["Agent", "Backfill", "CpuFrequency"]

    slurmctld.remove_debug_flags(["CpuFrequency"])
    assert slurmctld.get_debug_flags() == ["Agent", "Backfill"]

    slurmctld.clear_debug_flags()
    assert slurmctld.get_debug_flags() == []


def test_log_level():
    slurmctld.set_log_level("debug5")
    assert slurmctld.get_log_level() == "debug5"

    slurmctld.set_log_level("debug2")
    assert slurmctld.get_log_level() == "debug2"

    with pytest.raises(pyslurm.RPCError,
           match=r"Invalid Log*"):
        slurmctld.set_log_level("invalid")


def test_scheduler_log_level():
    assert not slurmctld.is_scheduler_logging_enabled()


def test_fair_share_dampening_factor():
    slurmctld.set_fair_share_dampening_factor(100)
    assert slurmctld.get_fair_share_dampening_factor() == 100

    slurmctld.set_fair_share_dampening_factor(1)
    assert slurmctld.get_fair_share_dampening_factor() == 1

    with pytest.raises(pyslurm.RPCError,
           match=r"Invalid Dampening*"):
        slurmctld.set_fair_share_dampening_factor(0)

    with pytest.raises(pyslurm.RPCError,
           match=r"Invalid Dampening*"):
        slurmctld.set_fair_share_dampening_factor(99999999)


def test_statistics():
    stats = slurmctld.diag()
    assert stats.to_dict()
    assert len(stats.rpcs_by_type) > 0
    data_since = stats.data_since

    slurmctld.Statistics.reset()
    new_stats = slurmctld.Statistics.load()
    assert new_stats.to_dict()
    # Check that resetting it was actually sucessful.
    assert data_since < new_stats.data_since
