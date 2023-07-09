#########################################################################
# test_db_qos.py - database qos unit tests
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
"""test_db_qos.py - Unit test basic database qos functionalities."""

import pytest
import pyslurm


def test_search_filter():
    qos_filter = pyslurm.db.QualityOfServiceFilter()
    qos_filter._create()

    qos_filter.ids = [1, 2]
    qos_filter._create()

    qos_filter.preempt_modes = ["cluster"]
    qos_filter._create()

    with pytest.raises(ValueError):
        qos_filter.preempt_modes = ["invalid_preempt_mode"]
        qos_filter._create()


def test_create_instance():
    qos = pyslurm.db.QualityOfService("test")
    assert qos.name == "test"
