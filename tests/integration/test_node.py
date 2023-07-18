#########################################################################
# test_node.py - node api integration tests
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
"""test_node.py - Test the node api functions."""

import pytest
import pyslurm
import json
from pyslurm import Node, Nodes, RPCError


def test_load():
    name, _ = Nodes.load().popitem()

    # Now load the node info
    node = Node.load(name)
    assert node.name == name
    assert node.weight is not None
    assert node.slurm_version is not None

    with pytest.raises(RPCError,
                       match=f"Node 'nonexistent' does not exist"):
        Node.load("nonexistent")


def test_modify():
    _, node = Nodes.load().popitem()

    node.modify(Node(weight=10000))
    assert Node.load(node.name).weight == 10000

    node.modify(Node(weight=20000))
    assert Node.load(node.name).weight == 20000

    node.modify(Node(weight=5000))
    assert Node.load(node.name).weight == 5000


def test_parse_all():
    _, node = Nodes.load().popitem()
    assert node.to_dict()


def test_to_json():
    nodes = Nodes.load()
    json_data = nodes.to_json()
    dict_data = json.loads(json_data)

    assert dict_data
    assert len(dict_data) >= 1
    assert json_data
