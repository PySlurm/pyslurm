from __future__ import absolute_import, unicode_literals

import pyslurm
from nose.tools import assert_true

def test_get_qos():
    """QoS: Test get_qos() return type"""
    test_qos = pyslurm.qos().get()
    assert_true(isinstance(test_qos, dict))
