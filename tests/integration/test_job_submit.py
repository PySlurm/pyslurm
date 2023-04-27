"""test_job_submit.py - Test the job submit api functions."""

import time
import pytest
import pyslurm
from os import environ as pyenviron
from util import create_simple_job_desc, create_job_script
from pyslurm import (
    Job,
    Jobs,
    JobSubmitDescription,
    RPCError,
)


def test_submit_example1():
    assert True


def test_submit_example2():
    assert True
