"""
PySlurm: Python bindings for the Slurm C API
============================================

PySlurm is a Cython wrapper around Slurm C API functions.

More information about Slurm can be found at http://slurm.schedmd.com.

Extensions
----------

::

    node            --- Get Node Information
    job             --- Get Job Information
    statistics      --- Get Slurmctld and Scheduler stats

Utility tools
-------------

::

    version         --- PySlurm version string
    api_version     --- Slurm version string


"""
from __future__ import absolute_import

__all__ = [
    "node",
    "statistics",
    "partition"
]

import sys
import ctypes

sys.setdlopenflags(sys.getdlopenflags() | ctypes.RTLD_GLOBAL)

from .node import *
from .job import *
from .statistics import *
from .misc import *
from .config import *
from .partition import *
from .license import *
from .powercap import *
