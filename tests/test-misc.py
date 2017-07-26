from __future__ import absolute_import, unicode_literals

import pyslurm
import subprocess
from nose.tools import assert_equals, assert_true

def test_slurm_ping():
    """Misc: Test slurm_ping() return."""
    slurm_ping = pyslurm.slurm_ping()
    assert_equals(slurm_ping, 0)


def test_slurm_reconfigure():
    """Misc: Test slurm_reconfigure() return."""
    slurm_reconfigure = pyslurm.slurm_reconfigure()
    assert_equals(slurm_reconfigure, 0)
