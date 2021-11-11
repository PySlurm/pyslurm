"""Test cases for QoS."""

import pyslurm


def test_get_qos():
    """QoS: Test get_qos() return type"""
    test_qos = pyslurm.qos().get()
    assert isinstance(test_qos, dict)
