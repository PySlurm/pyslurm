
u'''
	PySLURM
	
	Here we modify the dlopen settings to RTLD_GLOBAL
	otherwise we cannot see the symbols correctly.

'''

import os, sys

old_dlopen_flags = ''
if hasattr(sys, "setdlopenflags"):
	old_dlopen_flags = sys.getdlopenflags()
	import DLFCN
	sys.setdlopenflags(old_dlopen_flags | DLFCN.RTLD_GLOBAL)

from pyslurm import *

__version__ = "2.2.7-1"
if old_dlopen_flags:
	if hasattr(sys, "setdlopenflags"):
		sys.setdlopenflags(old_dlopen_flags)
		
def version():
	return __version__
