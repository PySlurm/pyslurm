#########################################################################
# test_tres.py - test TRES parsing functionality
#########################################################################
# Copyright (C) 2026 Toni Harzendorf <toni.harzendorf@gmail.com>
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
"""test_tres.py - Test TRES parsing functionality"""

import pyslurm
import pytest
from pyslurm.db import (
    TrackableResource,
    TrackableResources,
    GenericResourceLayout,
    GPU,
)
from pyslurm.utils import cstr


def test_parse_tres_str():
    input_str = "gres/gpu=5,gres/gpu:nvidia-a100=10,cpu=1,mem=10G,billing=2"
    tres = TrackableResources.from_str(input_str)
    assert tres.cpu.count == 1
    assert tres.mem.count == 10240
    assert tres.billing.count == 2
    assert len(tres.gres) == 2

    gres = tres.gres["gpu:nvidia-a100"]
    assert isinstance(gres, GPU)
    assert gres.count == 10
    assert gres.type == "nvidia-a100"

    gres = tres.gres["gpu"]
    assert isinstance(gres, GPU)
    assert gres.count == 5
    assert gres.type == None

    # Simulating the global TRES-data that is required when translating
    # such strings that only come with IDs, but without names.
    global_tres_data = {
        1: TrackableResource("cpu", count=5, name=None, tres_id=1),
        2: TrackableResource("mem", count=20 * 2**10, name=None, tres_id=2),
        5: TrackableResource("billing", count=2, name=None, tres_id=5),
    }

    input_str = "1=5,2=20G,5=2"
    tres = TrackableResources.from_str(input_str, global_tres_data)
    assert tres.cpu.count == 5
    assert tres.cpu.id == 1
    assert tres.cpu.type == "cpu"
    assert tres.mem.count == 20 * 2**10
    assert tres.mem.id == 2
    assert tres.mem.type == "mem"
    assert tres.billing.count == 2
    assert tres.billing.id == 5
    assert tres.billing.type == "billing"


def test_parse_gres_layout_str():
    input_str = "gpu:nvidia-a100:5"
    gres_dict = GenericResourceLayout.from_str(input_str)
    assert len(gres_dict) == 1
    gres = gres_dict["gpu:nvidia-a100"]
    assert gres.name == "gpu"
    assert gres.type == "nvidia-a100"
    assert gres.count == 5
    assert gres.indexes == []

    input_str = "gres/gpu:2,gres/gpu:nvidia-a100:6"
    gres_dict = GenericResourceLayout.from_str(input_str)
    assert len(gres_dict) == 2
    gres = gres_dict["gpu"]
    assert gres.name == "gpu"
    assert gres.type is None
    assert gres.count == 2
    assert gres.indexes == []

    gres = gres_dict["gpu:nvidia-a100"]
    assert gres.name == "gpu"
    assert gres.type == "nvidia-a100"
    assert gres.count == 6
    assert gres.indexes == []

    input_str = "gpu:nvidia-a100:3(IDX:0)"
    gres_dict = GenericResourceLayout.from_str(input_str)
    assert len(gres_dict) == 1
    gres = gres_dict["gpu:nvidia-a100"]
    assert gres.name == "gpu"
    assert gres.type == "nvidia-a100"
    assert gres.count == 3
    assert gres.indexes == [0]

    input_str = "gpu:nvidia-a100:3(IDX:0,2,4),gres/gpu:nvidia-h100:2(IDX:1,3)"
    gres_dict = GenericResourceLayout.from_str(input_str)
    assert len(gres_dict) == 2
    gres = gres_dict["gpu:nvidia-a100"]
    assert gres.name == "gpu"
    assert gres.type == "nvidia-a100"
    assert gres.count == 3
    assert gres.indexes == [0, 2, 4]

    gres = gres_dict["gpu:nvidia-h100"]
    assert gres.name == "gpu"
    assert gres.type == "nvidia-h100"
    assert gres.count == 2
    assert gres.indexes == [1, 3]


def test_set_tres_limits():
    # This info will come from Slurm
    global_tres_data = {
        1: TrackableResource("cpu", tres_id=1, name=None, count=0),
        2: TrackableResource("mem", tres_id=2, name=None, count=0),
        6: TrackableResource("fs", tres_id=6, name="disk", count=0),
        10: TrackableResource("gres", tres_id=10, name="gpu:nvidia-a100", count=0),
        11: TrackableResource("gres", tres_id=11, name="gpu:nvidia-h100", count=0),
        12: TrackableResource("gres", tres_id=12, name="gpu", count=0),
    }
    tres = TrackableResources(
        cpu = 10,
        mem = 10 * 2**10,
        fs = { "disk": 20 * 2**10 },
        gres = { "gpu:nvidia-a100": 15,  "gpu:nvidia-h100": 20, "gpu": 35},
    )
    expected_tres = { 1: 10, 2: 10240, 10: 15, 11: 20, 12: 35, 6: 20480 }
    validated_tres = tres._validate(global_tres_data)
    assert expected_tres == validated_tres

    with pytest.raises(ValueError,
            match=r"Invalid TRES specified*"):
        tres = TrackableResources(invalid_tres = 10)
        tres._validate(global_tres_data)
