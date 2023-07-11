#########################################################################
# test_node.py - node unit tests
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
"""test_node.py - Unit Test basic functionality of the Node class."""

import pytest
import pyslurm
from pyslurm import Node, Nodes
from pyslurm.core.node import _node_state_from_str


def test_create_instance():
    node = Node("localhost")
    assert node.name == "localhost"


def test_parse_all():
    assert Node("localhost").as_dict()


def test_set_node_state():
    assert _node_state_from_str("RESUME")
    assert _node_state_from_str("undrain")
    assert _node_state_from_str("POWER_DOWN")


def test_setting_attributes():
    # TODO
    assert True
