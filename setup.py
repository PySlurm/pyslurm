#!/usr/bin/env python
"""PySlurm: Python bindings for the Slurm C API.

more description here.
"""
from __future__ import print_function

import sys
import textwrap

from distutils.core import setup, Extension
from distutils.version import LooseVersion
from os import path

VENDOR = "PySlurm"
CYTHON_VERSION_MIN = "0.15"

if sys.version_info[:2] < (2, 6) or (3, 0) <= sys.version_info[:2] < (3, 3):
    raise RuntimeError(
        "Python >= 2.6 or >= 3.3 is required to run %s." % VENDOR
    )

try:
    from Cython.Build import cythonize
    from Cython.Compiler.Version import version as cython_version

    if LooseVersion(cython_version) < LooseVersion(CYTHON_VERSION_MIN):
        raise Exception(
            "Building %s requires Cython >= %s" % (VENDOR, CYTHON_VERSION_MIN)
        )
except ImportError:
    raise OSError(
        "Cython >= %s is required to build %s." % (CYTHON_VERSION_MIN, VENDOR)
    )

# FIXME: change default paths
# Default Slurm Paths
SLURM_INCLUDE_PATH = "/usr/local/slurm/include"
SLURM_LIBRARY_PATH = "/usr/local/slurm/lib"

# PySlurm path options to setup.py
pyslurm_build_commands = [
    "--with-slurm",
    "--with-slurm-libdir",
    "--with-slurm-includes"
]

def parse_setuppy_commands():
    if "--help" in sys.argv[1:] or "-h" in sys.argv[1]:
        print(textwrap.dedent("""
            PySlurm Help
            ------------

            --with-slurm=PATH           Where to look for Slurm, PATH points to
                                        the installation root
            --with-slurm-libdir=PATH    Where to look for libslurm.so
            --with-slurm-includes=PATH  Where to look for slurm.h, slurm_errno.h
                                        and slurmdb.h

            For help with building or installing PySlurm, please ask on the PySlurm
            Google group at https://groups.google.com/forum/#!forum/pyslurm.

            If you are sure that you have run into a bug, please report it at
            https://github.com/PySlurm/pyslurm/issues.

            Distutils Help
            --------------
            """))
        return

    if len(sys.argv) < 2:
        # User did not give argument.
        # Slurm headers and libraries should be within the linker's PATH.
        pass

#    if ("--with-slurm-libdir" in sys.argv[1:]) and (
#        "--with-slurm-includes" in sys.argv[1:]):



extensions = [
    Extension(
        "pyslurm/*",
        ["pyslurm/*.pyx"],
        include_dirs=[SLURM_INCLUDE_PATH],
        libraries=["slurmdb", "slurm"],
        library_dirs=[SLURM_LIBRARY_PATH]
    )
]

here = path.abspath(path.dirname(__file__))

with open(path.join(here, "README.rst")) as f:
    long_description = f.read()

def setup_package():
    parse_setuppy_commands()

    setup (
        name="pyslurm",
        version="16.05.6",
        description="Python Bindings for Slurm",
        long_description=long_description,
        maintainer = "PySlurm Developers",
        maintainer_email = "pyslurm@googlegroups.com",
        license= "GPL",
        url = "http://github.com/PySlurm/pyslurm",
        author = "Mark Roberts",
        classifiers = [
            "Development Status :: 4 - Beta",
            "Environment :: Console",
            "Intended Audience :: Developers",
            "Intended Audience :: System Administrators",
            "License :: OSI Approved :: GNU General Public License v2 (GPLv2)",
            "Natural Language :: English",
            "Operating System :: POSIX :: Linux",
            "Programming Language :: Cython",
            "Programming Language :: Python",
            "Programming Language :: Python :: 2.6",
            "Programming Language :: Python :: 2.7",
            "Programming Language :: Python :: 3.3",
            "Programming Language :: Python :: 3.4",
            "Programming Language :: Python :: 3.5",
            "Topic :: Software Development :: Libraries",
            "Topic :: Software Development :: Libraries :: Python Modules",
            "Topic :: System :: Distributed Computing"
        ],
        keywords = ["HPC", "Batch Scheduler", "Resource Manager", "Slurm", "Cython"],
        packages = ["pyslurm"],
        platforms = ["Linux"],
        ext_modules = cythonize(extensions),
    #    cmdclass = {"build_ext": build_ext },
    )
#    Entry-points:
#    [console_scripts]
#    nosetests = nose:run_exit
#    [distutils.commands]
#    nosetests = nose.commands:nosetests


if __name__ == "__main__":
    setup_package()
