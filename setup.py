#!/usr/bin/env python
from __future__ import print_function

import os
import logging
import sys
import textwrap
from setuptools import setup
from distutils.dir_util import remove_tree
from distutils.core import Extension
from distutils.version import LooseVersion

PYSLURM_VERSION = "17.11.0.7"
CYTHON_VERSION_MIN = "0.15"

# Slurm min/max supported (hex) versions
__min_slurm_hex_version__ = "0x110b00"
__max_slurm_hex_version__ = "0x110b05"

# Configure console logging
logger = logging.getLogger(__name__)
logging.basicConfig(
    format="%(levelname)s: %(message)s",
    level=logging.DEBUG
)

# Console logging helper functions
def fatal(logstring, code=1):
    logger.error(logstring)
    sys.exit(code)


def warn(logstring):
    logger.error(logstring)


def info(logstring):
    logger.info(logstring)


if sys.version_info[:2] < (2, 6) or (3, 0) <= sys.version_info[:2] < (3, 4):
    fatal("Python >= 2.6 or >= 3.4 is required to run PySlurm.")

try:
    from Cython.Distutils import build_ext
    from Cython.Compiler.Version import version as cython_version

    if LooseVersion(cython_version) < LooseVersion(CYTHON_VERSION_MIN):
        info("Cython version %s installed" % cython_version)
        fatal("Please use Cython version >= %s" % CYTHON_VERSION_MIN)
except:
    fatal("Cython (http://cython.org) is required to build PySlurm")
    fatal("Please use Cython version >= %s" % CYTHON_VERSION_MIN)

# Set default Slurm directory to /usr
DEFAULT_SLURM = "/usr"
SLURM_DIR = ""
SLURM_LIB = ""
SLURM_INC = ""

# Set default Bluegene/Q emulation to 0
BGQ = 0

def usage():
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


def makeExtension(extName):
    """Generate an Extension object from its dotted name"""
    extPath = extName.replace(".", os.path.sep) + ".pyx"
    return Extension(
        extName,
        [extPath],
        include_dirs = ['%s' % SLURM_INC, '.'],
        library_dirs = ['%s' % SLURM_LIB, '%s/slurm' % SLURM_LIB],
        libraries = ['slurmdb', 'slurm'],
        runtime_library_dirs = ['%s/' % SLURM_LIB, '%s/slurm' % SLURM_LIB],
        extra_objects = [],
        extra_compile_args = [],
        extra_link_args = [],
    )


def read_inc_version(fname):
    """Read the supplied include file and extract slurm version number
    in the line #define SLURM_VERSION_NUMBER 0x020600 """
    hex = ''
    f = open(fname, "r")
    for line in f:
        if line.find("#define SLURM_VERSION_NUMBER") == 0:
            hex = line.split(" ")[2].strip()
            info("Build - Detected Slurm version - %s (%s)" % (
                hex, inc_vers2str(hex)
            ))
    f.close()
    return hex


def inc_vers2str(hex_inc_version):
    """Return a slurm version number string decoded from the bit shifted
       components of the slurm version hex string supplied in slurm.h."""
    a = int(hex_inc_version, 16)
    b = (a >> 16 & 0xff, a >> 8 & 0xff, a & 0xff)
    return '{0:02d}.{1:02d}.{2:02d}'.format(*b)


def check_libPath(slurm_path):
    if not slurm_path:
        slurm_path = DEFAULT_SLURM

    slurm_path = os.path.normpath(slurm_path)

    # if base dir given then check this
    if os.path.basename(slurm_path) in ['lib','lib64']:
        if os.path.exists("%s/libslurm.so" % slurm_path):
            info("Build - Found Slurm shared library in %s" % slurm_path)
            return slurm_path
        else:
            info("Build - Cannot locate Slurm shared library in %s" % slurm_path)
            return ''

    # if base dir given then search lib64 and then lib
    for libpath in ['lib64', 'lib']:
        slurmlibPath = "%s/%s" % (slurm_path, libpath)

        if os.path.exists("%s/libslurm.so" % slurmlibPath):
            info("Build - Found Slurm shared library in %s" % slurmlibPath)
            return slurmlibPath

    info("Build - Could not locate Slurm shared library in %s" % slurm_path)
    return ''


def create_bluegene_include():
    """Create pyslurm/bluegene.pxi include file."""
    info("Build - Generating pyslurm/bluegene.pxi file")
    global BGQ
    try:
        with open("pyslurm/bluegene.pxi", "w") as f:
            f.write("DEF BG=1\n")
            f.write("DEF BGQ=%d\n" % BGQ)
    except:
        fatal("Build - Unable to write Blue Gene type to pyslurm/bluegene.pxi")
        sys.exit(-1)


def clean():
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
                    sys.exit(-1)
            else:
                fatal("Clean - %s is not a file !" % file)
                sys.exit(-1)

    info("Clean - completed")


def build():
    info("")
    info("Building PySlurm (%s)" % PYSLURM_VERSION)
    info("------------------------------")
    info("")
    info("Cython version %s installed" % cython_version)
    info("")

    # Clean up temporary build objects first
    clean()

    global DEFAULT_SLURM
    global SLURM_DIR
    global SLURM_LIB
    global SLURM_INC

    args = sys.argv[1:]
    for arg in args:
        if arg.find('--slurm=') == 0:
            SLURM_DIR = arg.split('=')[1]
            sys.argv.remove(arg)
        if arg.find('--slurm-lib=') == 0:
            SLURM_LIB = arg.split('=')[1]
            sys.argv.remove(arg)
        if arg.find('--slurm-inc=') == 0:
            SLURM_INC = arg.split('=')[1]
            sys.argv.remove(arg)

    # Slurm installation directory
    if SLURM_DIR and (SLURM_LIB or SLURM_INC):
        usage()
    elif SLURM_DIR and not (SLURM_LIB or SLURM_INC):
        SLURM_LIB = "%s" % SLURM_DIR
        SLURM_INC = "%s/include" % SLURM_DIR
    elif not SLURM_DIR and not SLURM_LIB and not SLURM_INC:
        SLURM_LIB = "%s" %  DEFAULT_SLURM
        SLURM_INC = "%s/include" %  DEFAULT_SLURM
    elif not SLURM_DIR and (not SLURM_LIB or not SLURM_INC):
        usage()

    # Test for slurm.h maybe from derived paths 
    if not os.path.exists("%s/slurm/slurm.h" % SLURM_INC):
        info("Build - Cannot locate the Slurm include in %s" % SLURM_INC)
        usage()
    else:
        info("Build - Found Slurm header in %s" % SLURM_INC)

    # Test for supported min and max Slurm versions 
    SLURM_INC_VER = read_inc_version("%s/slurm/slurm.h" % SLURM_INC)

    if (int(SLURM_INC_VER,16) < int(__min_slurm_hex_version__,16)) or \
        (int(SLURM_INC_VER,16) > int(__max_slurm_hex_version__,16)):

        fatal("Build - Incorrect slurm version detected, require Slurm-%s to slurm-%s" % (
            inc_vers2str(__min_slurm_hex_version__), inc_vers2str(__max_slurm_hex_version__)
        ))
        sys.exit(-1)

    # Test for libslurm in lib64 and then lib
    SLURM_LIB = check_libPath(SLURM_LIB)
    if not SLURM_LIB:
        usage()

    # BlueGene
    create_bluegene_include()


def parse_setuppy_commands():
    args = sys.argv[1:]

    if len(args) == 0:
        usage()
    else:
        # Set BGQ if --bgq argument provided
        if "--bgq" in args:
            BGQ = 1

        # Prepend PySlurm help text when passing --help | -h
        if "--help" in args or "-h" in args:
            usage()
            print(textwrap.dedent("""
                Distutils Help
                --------------
                """))

        # Clean up temporary build objects when cleaning
        elif "clean" in args:
            clean()

        # Generate bluegene.pxi when creating source distribution
        elif "sdist" in args:
            create_bluegene_include()

        # --slurm=[ROOT_PATH]
        # --slurm-lib=[LIB_PATH] --slurm-inc=[INC_PATH]
        elif "build" in args or "build_ext" in args:
            build()

def setup_package():
    parse_setuppy_commands()

    # Get the list of extensions
    extNames = scandir("pyslurm/")

    # Build up the set of Extension objects
    extensions = [makeExtension(name) for name in extNames]

    here = os.path.abspath(os.path.dirname(__file__))
    with open(os.path.join(here, "README.rst")) as f:
        long_description = f.read()

    setup(
        name="pyslurm",
        version=PYSLURM_VERSION,
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
            'Programming Language :: Python :: 2.6',
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
    setup_package()
