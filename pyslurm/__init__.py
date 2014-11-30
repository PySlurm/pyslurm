
#
# Absolute Import introduced in Python2.5 ?
#

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

<<<<<<< HEAD
__version__ = "2.6.0-0pre2"
=======
__version__ = "14.11.0-0"
>>>>>>> slurm-14.11
def version():
	return __version__
