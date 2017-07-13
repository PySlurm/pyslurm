
#
# Absolute Import introduced in Python2.5 ?
#

from __future__ import absolute_import

import os
import sys

old_dlopen_flags = ''
if hasattr(sys, "setdlopenflags"):
    old_dlopen_flags = sys.getdlopenflags()
    if sys.version_info >= (3,6):
        from os import RTLD_GLOBAL
    else:
        from DLFCN import RTLD_GLOBAL
    sys.setdlopenflags(old_dlopen_flags | RTLD_GLOBAL)

from .pyslurm import *

if old_dlopen_flags:
    if hasattr(sys, "setdlopenflags"):
        sys.setdlopenflags(old_dlopen_flags)

__version__ = "17.02.0"
def version():
    return __version__
