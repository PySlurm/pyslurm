"""

pyslurm: Python interface to slurm

"""

from distutils.core import setup
from distutils.extension import Extension
from distutils.command import clean
from distutils.sysconfig import get_python_lib
from Pyrex.Distutils import build_ext

import os, re
import sys, platform, popen2
from string import *
from stat import *

# Mininmum of Python 2.2.3 required because that's what I've tested

if not hasattr(sys, 'version_info') or sys.version_info < (2,2,3,'final'):
   raise SystemExit, "Python 2.2.3 or later required to build slurpy."

include_dirs = ['/opt/include/slurm', '/opt/include', '/usr/include']
library_dirs = ['/opt/lib']
libraries = ['slurm']
runtime_library_dirs = ['/opt/lib/slurm']
extra_compile_args = ['']
extra_objects = ['']

compiler_dir = os.path.join(get_python_lib(prefix=''), 'pyslurm/')

# Trove classifiers

classifiers = """\
Development Status :: 4 - Beta
Intended Audience :: Developers
License :: OSI Approved :: GNU General Public License (GPL)
Natural Language :: English
Operating System :: POSIX :: Linux
rogramming Language :: Python
Topic :: Software Development :: Libraries :: Python Modules
"""

# Disutils fix for Python versions < 2.3 that didn't
# support classifiers as listed at
# http://www.python.org/~jeremy/weblog/030924.html

if sys.version_info < (2, 3):
    _setup = setup
    def setup(**kwargs):
       if kwargs.has_key("classifiers"):
          del kwargs["classifiers"]
       _setup(**kwargs)

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
        Extension( "pyslurm/pyslurm",["pyslurm/pyslurm.pyx"],
                   library_dirs = library_dirs,
                   libraries = libraries,
                   runtime_library_dirs = runtime_library_dirs,
                   include_dirs = include_dirs)
    ],
    cmdclass = {"build_ext": build_ext}
)

