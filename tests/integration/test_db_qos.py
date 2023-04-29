#########################################################################
# test_db_qos.py - database qos api integration tests
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
"""test_db_qos.py - Integration test database qos api functionalities."""

import pytest
import pyslurm
import time
import util


def test_load_single():
    qos = pyslurm.db.QualityOfService.load("normal")

    assert qos.name == "normal"
    assert qos.id == 1

    with pytest.raises(pyslurm.RPCError):
        pyslurm.db.QualityOfService.load("qos_non_existent")


def test_parse_all(submit_job):
    qos = pyslurm.db.QualityOfService.load("normal")
    qos_dict = qos.as_dict()

    assert qos_dict
    assert qos_dict["name"] == qos.name


def test_load_all():
    qos = pyslurm.db.QualitiesOfService.load()
    assert qos


def test_load_with_filter_name():
    qfilter = pyslurm.db.QualityOfServiceSearchFilter(names=["non_existent"])
    qos = pyslurm.db.QualitiesOfService.load(qfilter)
    assert not qos
