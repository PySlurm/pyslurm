#########################################################################
# test_slurmctld.py - slurmctld unit tests
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
"""test_slurmctld.py - Unit test basic slurmctld functionalities."""

import pyslurm
from pyslurm import slurmctld
from pyslurm.core.slurmctld.stats import _parse_test_data


def test_statistics():
    stats = _parse_test_data()
    assert stats.to_dict()

    assert len(stats.rpcs_by_type) == 3
    for typ, val in stats.rpcs_by_type.items():
        assert val.count > 0
        assert val.time > 0
        assert val.average_time > 0
        assert typ is not None

    assert len(stats.rpcs_pending) == 5
    for typ, val in stats.rpcs_pending.items():
        assert val.count > 0
        assert typ is not None
        assert isinstance(typ, str)

    assert len(stats.rpcs_by_user) == 1
    for typ, val in stats.rpcs_by_user.items():
        assert val.user_id == 0
        assert val.user_name == "root"
        assert val.time > 0
        assert val.average_time > 0
        assert typ is not None

    assert stats.schedule_exit
    assert stats.backfill_exit
    assert stats.jobs_submitted == 20
    assert stats.jobs_running == 3
    assert stats.schedule_cycle_last == 40
    assert stats.schedule_cycle_sum == 45
    assert stats.schedule_cycle_mean == 4
    assert stats.schedule_cycle_counter == 10

    assert stats.backfill_cycle_counter == 100
    assert stats.backfill_active is False
    assert stats.backfilled_jobs == 10
    assert stats.backfill_cycle_sum == 200
    assert stats.backfill_depth_try_sum == 300
    assert stats.backfill_queue_length_sum == 600
    assert stats.backfill_table_size_sum == 200
    assert stats.backfill_cycle_mean == 2
