#!/usr/bin/env python
"""PySlurm: Python bindings for the Slurm C API.

more description here.
"""
from __future__ import division, print_function

import sys

from distutils.core import setup, Extension
from distutils.version import LooseVersion
from os import path

VENDOR = "PySlurm"
CYTHON_VERSION_MIN = "0.15"

if sys.version_info[:2] < (2, 6) or (3, 0) <= sys.version_info[:2] < (3, 3):
    raise RuntimeError("Python >= 2.6 or >= 3.3 is required to run %s." %
                       VENDOR)

try:
    from Cython.Build import cythonize
    from Cython.Compiler.Version import version as cython_version

    if LooseVersion(cython_version) < LooseVersion(CYTHON_VERSION_MIN):
        raise Exception("Building %s requires Cython >= %s" % (
                        VENDOR, CYTHON_VERSION_MIN))
except ImportError:
    raise OSError("Cython >= %s is required to build %s." %
                  (CYTHON_VERSION_MIN, VENDOR))

extensions = [
    Extension(
        "pyslurm/node",
        ["pyslurm/node.pyx"],
        include_dirs=["/usr/local/slurm/include"],
        libraries=["slurm"],
        library_dirs=["/usr/local/slurm/lib"]
    ),
    Extension(
        "pyslurm/job",
        ["pyslurm/job.pyx"],
        include_dirs=["/usr/local/slurm/include"],
        libraries=["slurm"],
        library_dirs=["/usr/local/slurm/lib"]
    ),
    Extension(
        "pyslurm/statistics",
        ["pyslurm/statistics.pyx"],
        include_dirs=["/usr/local/slurm/include"],
        libraries=["slurm"],
        library_dirs=["/usr/local/slurm/lib"]
    ),
    Extension(
        "pyslurm/misc",
        ["pyslurm/misc.pyx"],
        include_dirs=["/usr/local/slurm/include"],
        libraries=["slurm"],
        library_dirs=["/usr/local/slurm/lib"]
    )
]

here = path.abspath(path.dirname(__file__))

with open(path.join(here, "README.rst")) as f:
    long_description = f.read()

setup (
    name="pyslurm",
    version="15.08.10",
    description="Python Bindings for Slurm",
    long_description=long_description,
    author = "Mark Roberts",
    author_email = "mark@gingergeeks co uk",
    license= "GPL",
    classifiers = [
        "Development Status :: 4 - Beta",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "Intended Audience :: System Administrators",
        "License :: OSI Approved :: GNU General Public License (GPL)",
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
#    maintainer = "PySlurm Developers",
#    maintainer_email = "pyslurm@googlegroups.com",
    url = "http://github.com/PySlurm/pyslurm",
    ext_modules = cythonize(extensions),
#    cmdclass = {"build_ext": build_ext },
)



#if __name__ == "__main__":
#    setup_package()
