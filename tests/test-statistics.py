from __future__ import absolute_import, unicode_literals

import pyslurm
from nose.tools import assert_true

def test_get_statistics():
    """Statistics: Test get_statistics() return type"""
    test_statistics = pyslurm.statistics().get()
    assert_true(isinstance(test_statistics, dict))
