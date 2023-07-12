#########################################################################
# test_partition.py - partition unit tests
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
"""test_partition.py - Unit Test basic functionality of the Partition class."""

import pytest
import pyslurm
from pyslurm import Partition, Partitions


def test_create_instance():
    part = Partition("normal")
    assert part.name == "normal"


def test_parse_all():
    assert Partition("normal").to_dict()


def test_parse_memory():
    part = Partition()

    assert part.default_memory_per_cpu is None
    assert part.default_memory_per_node is None

    part.default_memory_per_cpu = "2G"
    assert part.default_memory_per_cpu == 2048
    assert part.default_memory_per_node is None

    part.default_memory_per_node = "2G"
    assert part.default_memory_per_cpu is None
    assert part.default_memory_per_node == 2048


def test_parse_job_defaults():
    part = Partition()

    assert part.default_cpus_per_gpu is None
    assert part.default_memory_per_gpu is None

    part.default_cpus_per_gpu = 10
    assert part.default_cpus_per_gpu == 10
    assert part.default_memory_per_gpu is None

    part.default_memory_per_gpu = "10G"
    assert part.default_cpus_per_gpu == 10
    assert part.default_memory_per_gpu == 10240

    part.default_cpus_per_gpu = None
    part.default_memory_per_gpu = None
    assert part.default_cpus_per_gpu is None
    assert part.default_memory_per_gpu is None
