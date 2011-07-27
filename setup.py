"""

pyslurm: Python interface to slurm

"""

from distutils.core import setup
from distutils.extension import Extension
from distutils.command import clean
from distutils.sysconfig import get_python_lib
from Cython.Distutils import build_ext

import os, re
import sys, platform
from string import *
from stat import *

include_dirs = ['/home/sgorget/pyslurm/include','/home/sgorget/src/slurm-2.2.1','/usr/include/slurm','/usr/include']
library_dirs = ['/usr/lib/slurm', '/usr/lib']
libraries = ['slurm']
runtime_library_dirs = ['/usr/lib/slurm', '/usr/lib']
#extra_link_args = [ '/usr/lib/slurm/auth_none.so']
extra_objects = [ '/usr/lib/slurm/auth_none.so']

classifiers = """\
Development Status :: 4 - Beta
Intended Audience :: Developers
License :: OSI Approved :: GNU General Public License (GPL)
Natural Language :: English
Operating System :: POSIX :: Linux
rogramming Language :: Python
Topic :: Software Development :: Libraries :: Python Modules
"""

doclines = __doc__.split("\n")

setup(
    name = "pyslurm",
    version = "0.0.1",
    description = doclines[0],
    long_description = "\n".join(doclines[2:]),
    author = "Mark Roberts",
    author_email = "mark at gingergeeks co uk",
    url = "http://www.gingergeeks.co.uk/pyslurm/",
    classifiers = filter(None, classifiers.split("\n")),
    platforms = ["Linux"],
    keywords = ["Batch Scheduler", "slurm"],
    packages = ["pyslurm"],
    ext_modules = [
        Extension( "pyslurm.pyslurm",["pyslurm/pyslurm.pyx"],
                   library_dirs = library_dirs,
                   libraries = libraries,
                   runtime_library_dirs = runtime_library_dirs,
                   extra_objects = extra_objects,
                   include_dirs = include_dirs)
    ],
    cmdclass = {"build_ext": build_ext}
)

