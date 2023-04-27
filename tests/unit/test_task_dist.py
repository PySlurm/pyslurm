"""test_task_dist.py - Test task distribution functions."""

import pyslurm
from pyslurm.core.job.task_dist import TaskDistribution


def test_from_int():
    expected = None
    assert TaskDistribution.from_int(0) == expected


def test_from_str():

    input_str = "cyclic:cyclic:cyclic"
    expected = TaskDistribution("cyclic", "cyclic", "cyclic")
    parsed = TaskDistribution.from_str(input_str)
    assert parsed == expected
    assert parsed.to_str() == input_str

    input_str = "*:*:fcyclic,NoPack"
    expected = TaskDistribution("*", "*", "fcyclic", False)
    parsed = TaskDistribution.from_str(input_str)
    assert parsed == expected
    assert parsed.to_str() == "block:cyclic:fcyclic,NoPack"

    input_plane_size = 10
    expected = TaskDistribution(plane_size=input_plane_size)
    parsed = TaskDistribution.from_str(f"plane={input_plane_size}")
    assert parsed == expected
    assert parsed.to_str() == "plane"
    assert parsed.plane == 10
#     assert parsed.as_int() == pyslurm.SLURM_DIST_PLANE
