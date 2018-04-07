"""
PySlurm: Python bindings for the Slurm C API
============================================

PySlurm is a Cython wrapper around Slurm C API functions.

More information about Slurm can be found at https://slurm.schedmd.com.
"""
from __future__ import absolute_import

import ctypes
import sys

__version__ = "17.11.0.7"

sys.setdlopenflags(sys.getdlopenflags() | ctypes.RTLD_GLOBAL)

from .pyslurm import *

def version():
    return __version__
