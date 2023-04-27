"""test_job.py - Unit test basic job functionalities."""

import time
import pytest
import pyslurm
from pyslurm import Job
from pyslurm.core.job.util import *


def test_parse_all():
    # Use the as_dict() function to test if parsing works for all
    # properties on a simple Job without error.
    Job(9999).as_dict()


def test_parse_dependencies_to_dict():
    expected = None
    assert dependency_str_to_dict("") == expected

    expected = {
        "after": [1, 2],
        "afterany": [],
        "afterburstbuffer": [],
        "aftercorr": [],
        "afternotok": [],
        "afterok": [3],
        "singleton": False,
        "satisfy": "all",
    }
    input_str = "after:1:2,afterok:3"
    assert dependency_str_to_dict(input_str) == expected


def test_mail_types_int_to_list():
    expected = []
    assert mail_type_int_to_list(0) == expected
    

def test_acctg_profile_int_to_list():
    expected = []
    assert acctg_profile_int_to_list(0) == expected


def test_power_type_int_to_list():
    expected = []
    assert power_type_int_to_list(0) == expected


def test_cpu_freq_int_to_str():
    expected = None
    assert cpu_freq_int_to_str(0) == expected
