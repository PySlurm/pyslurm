#########################################################################
# test_task_dist.py - task distribution unit tests
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
"""test_task_dist.py - Test task distribution functions."""

import pyslurm
from pyslurm.core.job.task_dist import TaskDistribution


def test_from_int():
    expected = None
    assert TaskDistribution.from_int(0) == expected


def test_from_str():

    input_str = "cyclic:cyclic:cyclic"
    expected = TaskDistribution("cyclic", "cyclic", "cyclic")
    parsed = TaskDistribution.from_str(input_str)
    assert parsed == expected
    assert parsed.to_str() == input_str

    input_str = "*:*:fcyclic,NoPack"
    expected = TaskDistribution("*", "*", "fcyclic", False)
    parsed = TaskDistribution.from_str(input_str)
    assert parsed == expected
    assert parsed.to_str() == "block:cyclic:fcyclic,NoPack"

    input_plane_size = 10
    expected = TaskDistribution(plane_size=input_plane_size)
    parsed = TaskDistribution.from_str(f"plane={input_plane_size}")
    assert parsed == expected
    assert parsed.to_str() == "plane"
    assert parsed.plane == 10
#     assert parsed.as_int() == pyslurm.SLURM_DIST_PLANE
