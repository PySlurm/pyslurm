#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function

import os
import logging
import sys
import textwrap
from setuptools import setup
from distutils.dir_util import remove_tree
from distutils.core import Extension
from distutils.version import LooseVersion

logger = logging.getLogger(__name__)
logging.basicConfig(
    format="%(levelname)s: %(message)s",
    level=logging.DEBUG
)

CYTHON_VERSION_MIN = "0.19"
SLURM_VERSION = "19.05"

def fatal(logstring, code=1):
    logger.error(logstring)
    sys.exit(code)

def warn(logstring):
    logger.error(logstring)

def info(logstring):
    logger.info(logstring)

try:
    from Cython.Distutils import build_ext
    from Cython.Compiler.Version import version as cython_version

    if LooseVersion(cython_version) < LooseVersion(CYTHON_VERSION_MIN):
        info("Cython version %s installed" % cython_version)
        fatal("Please use Cython version >= %s" % CYTHON_VERSION_MIN)
except:
    fatal("Cython (https://cython.org) is required to build PySlurm")
    fatal("Please use Cython version >= %s" % CYTHON_VERSION_MIN)

if sys.version_info[:2] < (2, 7) or (3, 0) <= sys.version_info[:2] < (3, 4):
    fatal("Python == 2.7 or >= 3.4 is required to run PySlurm.")


class Pyslurm:
    def __init__(self):
        self.here = os.path.abspath(os.path.dirname(__file__))
        self.about = {}
        self.default_slurm_dir = "/usr"
        self.slurm_lib = None
        self.slurm_inc = None
        self.slurm_dir = None
        self.bgq = 0

        with open(os.path.join(self.here, "pyslurm", "__version__.py"), "r") as f:
            exec(f.read(), self.about)

    def usage(self):
        print(textwrap.dedent("""
            PySlurm Help
            ------------
                --slurm=PATH        Where to look for Slurm, PATH points to
                                    the Slurm installation root (default=/usr)
                --slurm-lib=PATH    Where to look for libslurm.so (default=/usr/lib64/slurm)
                --slurm-inc=PATH    Where to look for slurm.h, slurm_errno.h
                                    and slurmdb.h (default=/usr/include)
                --bgq               Enable support for BG/Q mode

            For help with building or installing PySlurm, please ask on the PySlurm
            Google group at https://groups.google.com/forum/#!forum/pyslurm.

            If you are sure that you have run into a bug, please report it at
            https://github.com/PySlurm/pyslurm/issues.
            """))

    @staticmethod
    def scandir(dir, files=[]):
        """
        Scan the directory for extension files, converting them to extension names
        in dotted notation.
        """
        for file in os.listdir(dir):
            path = os.path.join(dir, file)

            if os.path.isfile(path) and path.endswith(".pyx"):
                files.append(path.replace(os.path.sep, ".")[:-4])
            elif os.path.isdir(path):
                scandir(path, files)

        return files


    def makeExtension(self, extName):
        """Generate an Extension object from its dotted name"""
        extPath = extName.replace(".", os.path.sep) + ".pyx"
        runtime_library_dirs = [self.slurm_lib, '{0}/slurm'.format(self.slurm_lib)]
        return Extension(
            extName,
            [extPath],
            include_dirs = [self.slurm_inc, '.'],
            library_dirs = runtime_library_dirs,
            libraries = ['slurmfull'],
            runtime_library_dirs = runtime_library_dirs,
            extra_objects = [],
            extra_compile_args = [],
            extra_link_args = [],
        )

    @staticmethod
    def inc_vers2str(hex_inc_version):
        """Return a slurm version number string decoded from the bit shifted
        components of the slurm version hex string supplied in slurm.h."""
        a = int(hex_inc_version, 16)
        b = (a >> 16 & 0xff, a >> 8 & 0xff, a & 0xff)
        return '{0:02d}.{1:02d}.{2:02d}'.format(*b)

    def read_inc_version(self, fname):
        """Read the supplied include file and extract slurm version number
        in the line #define SLURM_VERSION_NUMBER 0x020600 """
        hex = ''

        with open(fname, "r") as f:
            for line in f:
                if line.find("#define SLURM_VERSION_NUMBER") == 0:
                    hex = line.split(" ")[2].strip()
                    info("Build - Detected Slurm version - %s (%s)" % (
                        hex, self.inc_vers2str(hex)
                    ))
        return hex

    def check_libPath(self, slurm_path):
        if not slurm_path:
            slurm_path = self.default_slurm_dir

        slurm_path = os.path.normpath(slurm_path)

        # if base dir given then search lib64 and then lib
        for libpath in ['lib64', 'lib']:
            slurmlibPath = os.path.join(slurm_path, libpath)

            if os.path.exists("{0}/libslurm.so".format(slurmlibPath)):
                info("Build - Found Slurm shared library in %s" % slurmlibPath)
                return slurmlibPath

        # if base dir given then check this
        if os.path.exists("{0}/libslurm.so".format(slurm_path)):
            info("Build - Found Slurm shared library in %s" % slurm_path)
            return slurm_path
        else:
            info("Build - Cannot locate Slurm shared library in %s" % slurm_path)
            return None

        info("Build - Could not locate Slurm shared library in %s" % slurm_path)
        return ''

    def create_bluegene_include(self):
        """Create pyslurm/bluegene.pxi include file."""
        info("Build - Generating pyslurm/bluegene.pxi file")
        try:
            with open("pyslurm/bluegene.pxi", "w") as f:
                f.write("DEF BG=1\n")
                f.write("DEF BGQ={0}\n".format(self.bgq))
        except:
            fatal("Build - Unable to write Blue Gene type to pyslurm/bluegene.pxi")

    def clean(self):
        """
        Cleanup build directory and temporary files.
        """
        info("Clean - checking for objects to clean")

        if os.path.isdir("build"):
            info("Clean - removing build/")
            remove_tree("build", verbose=1)

        files = [
            "pyslurm/__init__.pyc",
            "pyslurm/bluegene.pxi",
            "pyslurm/pyslurm.c",
            "pyslurm/pyslurm.so",
        ]

        for file in files:
            if os.path.exists(file):
                if os.path.isfile(file):
                    try:
                        info("Clean - removing %s" % file)
                        os.unlink(file)
                    except:
                        fatal("Clean - failed to remove %s" % file)
                else:
                    fatal("Clean - %s is not a file !" % file)

        info("Clean - completed")


    def build(self):
        info("")
        info("Building PySlurm (%s)" % self.about["__version__"])
        info("------------------------------")
        info("")
        info("Cython version %s installed" % cython_version)
        info("")

        # Clean up temporary build objects first
        self.clean()

        args = sys.argv[1:]
        for arg in args:
            if arg.find('--slurm=') == 0:
                self.slurm_dir = arg.split('=')[1]
                sys.argv.remove(arg)
            if arg.find('--slurm-lib=') == 0:
                self.slurm_lib = arg.split('=')[1]
                sys.argv.remove(arg)
            if arg.find('--slurm-inc=') == 0:
                self.slurm_inc = arg.split('=')[1]
                sys.argv.remove(arg)

        # Slurm installation directory
        if self.slurm_dir and (self.slurm_lib or self.slurm_inc):
            self.usage()
        elif self.slurm_dir and not (self.slurm_lib or self.slurm_inc):
            self.slurm_lib = self.slurm_dir
            self.slurm_inc = "{0}/include".format(self.slurm_dir)
        elif not self.slurm_dir and not self.slurm_lib and not self.slurm_inc:
            self.slurm_lib = self.default_slurm_dir
            self.slurm_inc = "{0}/include".format(self.default_slurm_dir)
        elif not self.slurm_dir and (not self.slurm_lib or not self.slurm_inc):
            self.usage()

        # Test for slurm.h maybe from derived paths
        if os.path.exists("{0}/slurm/slurm.h".format(self.slurm_inc)):
            info("Build - Found Slurm header in %s" % self.slurm_inc)
        elif os.path.exists("{0}/slurm.h".format(self.slurm_inc)):
            info("Build - Found Slurm header in %s" % self.slurm_inc)
        else:
            fatal("Build - Cannot locate the Slurm include in %s" % self.slurm_inc)

        # Test for Slurm MAJOR.MINOR version match (ignoring .MICRO)
        try:
            SLURM_INC_VER = self.read_inc_version("{0}/slurm/slurm.h".format(self.slurm_inc))
        except IOError:
            SLURM_INC_VER = self.read_inc_version("{0}/slurm.h".format(self.slurm_inc))

        MAJOR = (int(SLURM_INC_VER, 16) >> 16) & 0xff
        MINOR = (int(SLURM_INC_VER, 16) >>  8) & 0xff

        if LooseVersion(str(MAJOR) + "." + str(MINOR)) != LooseVersion(SLURM_VERSION):
            fatal("Build - Incorrect slurm version detected, requires Slurm %s" % (SLURM_VERSION))

        # Test for libslurm in lib64 and then lib
        self.slurm_lib = self.check_libPath(self.slurm_lib)
        if not self.slurm_lib:
            self.self.usage()

        # BlueGene
        self.create_bluegene_include()

    def parse_setuppy_commands(self):
        args = sys.argv[1:]

        if len(args) == 0:
            self.self.usage()
        else:
            if "--bgq" in args:
                self.bgq = 1

            # Prepend PySlurm help text when passing --help | -h
            if "--help" in args or "-h" in args:
                self.usage()
                print(textwrap.dedent("""
                    Distutils Help
                    --------------
                    """))

            # Clean up temporary build objects when cleaning
            elif "clean" in args:
                self.clean()

            # Generate bluegene.pxi when creating source distribution
            elif "sdist" in args:
                self.create_bluegene_include()

            # --slurm=[ROOT_PATH]
            # --slurm-lib=[LIB_PATH] --slurm-inc=[INC_PATH]
            elif "build" in args or "build_ext" in args:
                self.build()

    def setup_package(self):
        self.parse_setuppy_commands()

        # Get the list of extensions
        extNames = self.scandir("pyslurm/")

        # Build up the set of Extension objects
        extensions = [self.makeExtension(name) for name in extNames]

        with open(os.path.join(self.here, "README.rst")) as f:
            long_description = f.read()

        setup(
            name="pyslurm",
            version=self.about["__version__"],
            license="GPLv2",
            description=("Python Interface for Slurm"),
            long_description=long_description,
            author="Mark Roberts, Giovanni Torres, et al.",
            author_email="pyslurm@googlegroups.com",
            url="https://github.com/PySlurm/pyslurm",
            platforms=["Linux"],
            keywords=["HPC", "Batch Scheduler", "Resource Manager", "Slurm", "Cython"],
            packages=["pyslurm"],
            install_requires=["Cython"],
            ext_modules=extensions,
            cmdclass={"build_ext": build_ext },
            classifiers=[
                'Development Status :: 5 - Production/Stable',
                'Environment :: Console',
                'Intended Audience :: Developers',
                'Intended Audience :: System Administrators',
                'License :: OSI Approved :: GNU General Public License v2 (GPLv2)',
                'Natural Language :: English',
                'Operating System :: POSIX :: Linux',
                'Programming Language :: Cython',
                'Programming Language :: Python',
                'Programming Language :: Python :: 2',
                'Programming Language :: Python :: 2.7',
                'Programming Language :: Python :: 3',
                'Programming Language :: Python :: 3.4',
                'Programming Language :: Python :: 3.5',
                'Programming Language :: Python :: 3.6',
                'Topic :: Software Development :: Libraries',
                'Topic :: Software Development :: Libraries :: Python Modules',
                'Topic :: System :: Distributed Computing',
            ]
        )


if __name__ == "__main__":
    Pyslurm().setup_package()
