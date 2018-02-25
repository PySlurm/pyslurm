from __future__ import absolute_import, unicode_literals

import pyslurm
import subprocess
from nose.tools import assert_equals, assert_true

def test_get_statistics():
    """Statistics: Test get_statistics() return type"""
    test_statistics = pyslurm.statistics().get()
    assert_true(isinstance(test_statistics, dict))
