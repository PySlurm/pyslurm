# -*- coding: utf-8 -*-

import os
import imp
import logging
import platform
import shutil
import sys

from stat import *
from string import *

from setuptools import setup, find_packages
from distutils.extension import Extension
from distutils.command import clean
from distutils.sysconfig import get_python_lib

logger = logging.getLogger()
#logger.addHandler(logging.StreamHandler(sys.stderr))
logging.basicConfig(level=20)

# PySlurm Version

#VERSION = imp.load_source("/tmp", "pyslurm/__init__.py").__version__
__version__ = "17.11.0.3"
__min_slurm_hex_version__ = "0x110b00"
__max_slurm_hex_version__ = "0x110b03"

def fatal(logstring, code=1):
    logger.error("Fatal: " + logstring)
    sys.exit(code)

def warn(logstring):
    logger.error("Warning: " + logstring)

def info(logstring):
    logger.info("Info: " + logstring)

def usage():
    info("Need to provide either SLURM dir location for build")
    info("Please use --slurm=PATH or --slurm-lib=PATH and --slurm-inc=PATH")
    info("i.e If slurm is installed in /usr use :")
    info("\t--slurm=/usr or --slurm-lib=/usr/lib64 and --slurm-inc=/usr/include")
    info("For now if using BlueGene Cluster set the type with --bgq")
    sys.exit(1)

def scandir(dir, files=[]):
    """
    Scan the directory for extension files, converting
    them to extension names in dotted notation.
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
        include_dirs = ['%s' % SLURM_INC, '.'],   # adding the '.' to include_dirs is CRUCIAL!!
        library_dirs = ['%s' % SLURM_LIB, '%s/slurm' % SLURM_LIB],
        libraries = ['slurmdb', 'slurm'],
        runtime_library_dirs = ['%s/' % SLURM_LIB, '%s/slurm' % SLURM_LIB],
        extra_objects = [],
        extra_compile_args = [],
        extra_link_args = [],
    )

def read(fname):
    """Read the README.rst file for long description"""

    return open(os.path.join(os.path.dirname(__file__), fname)).read()

def read_inc_version(fname):
    """Read the supplied include file and extract slurm version number
    in the line #define SLURM_VERSION_NUMBER 0x020600 """

    hex = ''
    f = open(fname, "r")
    for line in f:
        if line.find("#define SLURM_VERSION_NUMBER") == 0:
            hex = line.split(" ")[2].strip()
            info("Build - Detected Slurm include file version - %s (%s)" % (hex, inc_vers2str(hex)))
    f.close()

    return hex

def inc_vers2str(hex_inc_version):
    """Return a slurm version number string decoded from the bit shifted components of the
    slurm version hex string supplied in slurm.h."""

    a = int(hex_inc_version,16)
    b = ( a >> 16 & 0xff, a >> 8 & 0xff, a & 0xff)
    return '{0:02d}.{1:02d}.{2:02d}'.format(*b)

def clean():
    """
    Cleanup build directory and temporary files.

    I wonder if disutils.dir_util.remove_tree should be used instead?
    """

    info("Clean - checking for objects to clean")
    if os.path.isdir("build/"):
        info("Clean - removing pyslurm build temp directory ...")
        try:
            shutil.rmtree("build/")
        except:
            fatal("Clean - failed to remove pyslurm build/ directory !")
            sys.exit(-1)

    files = ["pyslurm/__init__.pyc", "pyslurm/pyslurm.c", "pyslurm/bluegene.pxi", "pyslurm/pyslurm.so", "pyslurm/slurm_version.pxi" ]

    for file in files:

        if os.path.exists(file):

            if os.path.isfile(file):
                try:
                    info("Clean - removing %s temp file" % file)
                    os.unlink(file)
                except:
                    fatal("Clean - failed to remove %s temp file" % file)
                    sys.exit(-1)
            else:
                fatal("Clean - %s temp file not a file !" % file)
                sys.exit(-1)

    info("Clean - completed")


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

#
# Main section
#

info("")
info("Building PySlurm (%s)" % __version__)
info("------------------------------")
info("")

if sys.version_info[:2] < (2, 6):
    fatal("PySlurm %s requires Python version 2.6 or later (%d.%d detected)." % (__version__, sys.version_info[:2]))

compiler_dir = os.path.join(get_python_lib(prefix=''), 'src/pyslurm/')

CyVersion_min = "0.15"
try:
    from Cython.Distutils import build_ext
    from Cython.Compiler.Version import version as CyVersion

    info("Cython version %s installed\n" % CyVersion)

    if CyVersion < CyVersion_min:
        fatal("Please use Cython version >= %s" % CyVersion_min)
except:
    fatal("Cython (www.cython.org) is required to build PySlurm")
    fatal("Please use Cython version >= %s" % CyVersion_min)

#
# Set default Slurm directory to /usr
#

DEFAULT_SLURM = '/usr'
SLURM_DIR = SLURM_LIB = SLURM_INC = ''

#
# Handle flags but only on build section
#
#    --slurm=[ROOT_PATH] | --slurm-lib=[LIB_PATH] && --slurm-inc=[INC_PATH]
#

args = sys.argv[:]
if args[1] == 'clean':

    #
    # Call clean up of temporary build objects
    #

    clean()

if args[1] == 'build' or args[1] == 'build_ext':

    #
    # Call clean up of temporary build objects
    #

    clean()

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

        BGQ = 0
        if arg.find('--bgq') == 0:
            BGQ=1
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

    # Test for supported min and max Slurm versions 

    SLURM_INC_VER = read_inc_version("%s/slurm/slurm.h" % SLURM_INC)
    if (int(SLURM_INC_VER,16) < int(__min_slurm_hex_version__,16)) or (int(SLURM_INC_VER,16) > int(__max_slurm_hex_version__,16)):
        fatal("Build - Incorrect slurm version detected, require Slurm-%s to slurm-%s" % (inc_vers2str(__min_slurm_hex_version__), inc_vers2str(__max_slurm_hex_version__)))
        sys.exit(-1)

    # Test for libslurm in lib64 and then lib

    SLURM_LIB = check_libPath(SLURM_LIB)
    if not SLURM_LIB:
        usage()

    # Slurm version 

    info("Build - Writing Slurm version to pyslurm/slurm_version.pxi")
    try:
        f = open("pyslurm/slurm_version.pxi", "w")
        f.write("SLURM_VERSION_NUMBER = %s\n" % SLURM_INC_VER)
        f.close()
    except:
        fatal("Build - Unable to write Slurm version to pyslurm/slurm_version.pxi")
        sys.exit(-1)

    # BlueGene

    info("Build - Generating pyslurm/bluegene.pxi file")
    try:
        f = open("pyslurm/bluegene.pxi", "w")
        f.write("DEF BG=1\n")
        f.write("DEF BGQ=%d\n" % BGQ)
        f.close()
    except:
        fatal("Build - Unable to write Blue Gene type to pyslurm/bluegene.pxd")
        sys.exit(-1)

# Get the list of extensions

extNames = scandir("pyslurm/")

# Build up the set of Extension objects

extensions = [makeExtension(name) for name in extNames]

setup(
    name = "pyslurm",
    version = __version__,
    license="GPLv2",
    description = ("Python Interface for Slurm"),
    long_description=read("README.rst"),
    author = "Mark Roberts, Giovanni Torres, et al.",
    author_email = "pyslurm@googlegroups.com",
    url = "https://github.com/PySlurm/pyslurm",
    platforms = ["Linux"],
    keywords = ["Batch Scheduler", "Resource Manager", "Slurm", "Cython"],
    packages = ["pyslurm"],
    install_requires = ["Cython"],
    ext_modules = extensions,
    cmdclass = {"build_ext": build_ext },
    classifiers = [
        'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'License :: OSI Approved :: GNU General Public License v2 (GPLv2)',
        'Intended Audience :: Developers',
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
        'Topic :: Software Development :: Libraries :: Python Modules',
    ]
)
