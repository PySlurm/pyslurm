#########################################################################
# test_db_slurm_list.py - Slurm list tests
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
"""test_db_slurm_List.py - Unit test basic Slurm list functionalities."""

import pytest
import pyslurm
from pyslurm.db.util import SlurmList


def test_create_and_destroy_list():
    slist = SlurmList()
    assert not slist.is_null

    slist2 = SlurmList(["user1", "user2"])
    assert not slist.is_null
    assert slist2.cnt == 2
    assert slist2.itr_cnt == 0 
    assert slist2.is_itr_null

    slist2._dealloc_itr()
    slist2._dealloc_list()
    assert slist2.is_null


def test_append():
    slist = SlurmList()
    input_list = ["user1", "user2", "user3"]
    slist.append(input_list)
    assert slist.cnt == len(input_list)

    input_str = "user4"
    slist.append(input_str)
    assert slist.cnt == 4

    input_int = 10
    slist.append(input_int)
    assert slist.cnt == 5

    input_ignore_none = ["user6", None]
    slist.append(input_ignore_none)
    assert slist.cnt == 6


def test_convert_to_pylist():
    input_list = ["user1", "user2", "user3"]
    slist = SlurmList(input_list)
    assert slist.cnt == 3
    assert slist.to_pylist() == input_list


def test_iter():
    input_list = ["user1", "user2", "user3"]
    slist = SlurmList(input_list)
    assert slist.itr_cnt == 0
    assert slist.is_itr_null
    assert not slist.is_null
    assert slist.cnt == 3

    for idx, slurm_item in enumerate(slist):
        assert not slist.is_itr_null
        assert slurm_item.has_data
        assert slist.itr_cnt == idx+1

    assert slist.itr_cnt == 0
    assert slist.is_itr_null

    slist._dealloc_list()
    assert slist.is_null
    assert slist.cnt == 0

    for item in slist:
        # Should not be possible to get here
        assert False


def test_iter_and_pop():
    input_list = ["user1", "user2", "user3"]
    slist = SlurmList(input_list)
    assert slist.itr_cnt == 0
    assert slist.is_itr_null
    assert slist.cnt == 3
    
    for idx, slurm_item in enumerate(SlurmList.iter_and_pop(slist)):
        assert slist.is_itr_null
        assert slurm_item.has_data

    assert slist.cnt == 0
    assert slist.itr_cnt == 0
    assert slist.is_itr_null

    # Round 2 on existing object
    slist.append(["user10", "user11"])
    assert slist.itr_cnt == 0
    assert slist.cnt == 2

    for slurm_item in SlurmList.iter_and_pop(slist):
        assert slurm_item.has_data

    assert slist.cnt == 0
    assert slist.itr_cnt == 0
    assert slist.is_itr_null


def test_iter_and_pop_on_null_list():
    input_list = ["user1", "user2", "user3"]
    slist = SlurmList(input_list)
    assert not slist.is_null
    assert slist.cnt == 3

    slist._dealloc_list()
    assert slist.is_null
    assert slist.cnt == 0

    for slurm_item in SlurmList.iter_and_pop(slist):
        # Should not be possible to get here
        assert False
