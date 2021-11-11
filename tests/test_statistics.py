"""Test cases for Slurm statistics."""

import pyslurm


def test_get_statistics():
    """Statistics: Test get_statistics() return type"""
    test_statistics = pyslurm.statistics().get()
    assert isinstance(test_statistics, dict)
