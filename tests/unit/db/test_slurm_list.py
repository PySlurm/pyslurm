"""test_slurm_List.py - Unit test basic Slurm list functionalities."""

import pytest
import pyslurm
from pyslurm.core.db.util import SlurmList


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
    assert slist.cnt == 3

    for idx, slurm_item in enumerate(slist):
        assert not slist.is_itr_null
        assert slurm_item.has_data
        assert slist.itr_cnt == idx+1

    assert slist.itr_cnt == 0
    assert slist.is_itr_null


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

    for idx, slurm_item in enumerate(SlurmList.iter_and_pop(slist)):
        assert slurm_item.has_data

    assert slist.cnt == 0
    assert slist.itr_cnt == 0
    assert slist.is_itr_null
