"""
PySLURM is a Python/Cython extension module to the Simple Linux Unified
Resource Manager (SLURM) API. SLURM is typically used on HPC clusters such as
those listed on the TOP500 but can also be used on clusters of any size.
"""
from __future__ import absolute_import

import os
import sys

old_dlopen_flags = ''
if hasattr(sys, "setdlopenflags"):
	old_dlopen_flags = sys.getdlopenflags()
	import DLFCN
	sys.setdlopenflags(old_dlopen_flags | DLFCN.RTLD_GLOBAL)

from .pyslurm import *

if old_dlopen_flags:
	if hasattr(sys, "setdlopenflags"):
		sys.setdlopenflags(old_dlopen_flags)

__version__ = "15.08.0-0rc1"
def version():
	return __version__
