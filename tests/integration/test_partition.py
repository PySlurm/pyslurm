#########################################################################
# test_partition.py - partition api integration tests
#########################################################################
# Copyright (C) 2023 Toni Harzendorf <toni.harzendorf@gmail.com>
# Copyright (C) 2023 PySlurm Developers
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
"""test_partition.py - Test the Partition api functions."""

import pytest
import pyslurm
import json
import util
from pyslurm import Partition, Partitions, RPCError


def test_load():
    name, part = Partitions.load().popitem()

    assert part.name
    assert part.state

    with pytest.raises(RPCError,
                       match=f"Partition 'nonexistent' doesn't exist"):
        Partition.load("nonexistent")


def test_create_delete():
    part = Partition(
        name="testpart",
        default_time="20-00:00:00",
        default_memory_per_cpu=1024,
    )
    part.create()
    part.delete()


def test_modify():
    _, part = Partitions.load().popitem()

    part.modify(Partition(default_time=120))
    assert Partition.load(part.name).default_time == 120

    part.modify(Partition(default_time="1-00:00:00"))
    assert Partition.load(part.name).default_time == 24*60

    part.modify(Partition(max_time="UNLIMITED"))
    assert Partition.load(part.name).max_time == "UNLIMITED"

    part.modify(Partition(state="DRAIN"))
    assert Partition.load(part.name).state == "DRAIN"

    part.modify(Partition(state="UP"))
    assert Partition.load(part.name).state == "UP"


def test_parse_all():
    _, part = Partitions.load().popitem()
    assert part.to_dict()


def test_to_json():
    parts = Partitions.load()
    json_data = parts.to_json()
    dict_data = json.loads(json_data)

    assert dict_data
    assert len(dict_data) >= 1
    assert json_data


def test_reload():
    _partnames = [util.randstr() for i in range(3)]
    _tmp_parts = Partitions(_partnames)
    for part in _tmp_parts.values():
        part.create()

    all_parts = Partitions.load()
    assert len(all_parts) >= 3

    my_parts = Partitions(_partnames[1:]).reload()
    assert len(my_parts) == 2
    for part in my_parts.values():
        assert part.state != "UNKNOWN"
    
    for part in _tmp_parts.values():
        part.delete()
