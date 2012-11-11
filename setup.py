# -*- coding: utf-8 -*-

import os
import imp
import sys
import platform

from string import *
from stat import *

from distutils.core import setup
from distutils.extension import Extension
from distutils.command import clean
from distutils.sysconfig import get_python_lib

import logging

logger = logging.getLogger()
#logger.addHandler(logging.StreamHandler(sys.stderr))
logging.basicConfig(level=20)

# PySlurm Version

#VERSION = imp.load_source("/tmp", "pyslurm/__init__.py").__version__
__version__ = "2.4.0-1"

def fatal(logstring, code=1):
	logger.error("Fatal: " + logstring)
	sys.exit(code)

def warn(logstring):
	logger.error("Warning: " + logstring)

def info(logstring):
	logger.info("Info: " + logstring)

def usage():
	warn("Need to provide either SLURM dir location for --build")
	warn("Please use --slurm=PATH or --slurm-lib=PATH and --slurm-inc=PATH")
	warn("Please set BlueGene type with --bgl --bgp or --bgq")
	sys.exit(1)

def scandir(dir, files=[]):

	"""
	Scan the directory for extension files, converting
	them to extension names in dotted notation
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
		include_dirs = ['%s/include' % SLURM_INC, '.'],   # adding the '.' to include_dirs is CRUCIAL!!
		library_dirs = ['%s/lib' % SLURM_LIB], 
		libraries = ['slurm'],
		runtime_library_dirs = ['%s/lib' % SLURM_LIB],
		extra_objects = [],
		extra_compile_args = [],
		extra_link_args = [],
	)

def read(fname):

	"""Read the README.rst file for long description"""

	return open(os.path.join(os.path.dirname(__file__), fname)).read()

#
# Main section
#

info("")
info("Building PySlurm (%s)" % __version__)
info("------------------------------")
info("")

if sys.version_info[:2] < (2, 6):
	fatal("PySLURM %s requires Python version 2.6 or later (%d.%d detected)." % (__version__, sys.version_info[:2]))

compiler_dir = os.path.join(get_python_lib(prefix=''), 'src/pyslurm/')

try:
	from Cython.Distutils import build_ext
	from Cython.Compiler.Version import version as CyVersion

	info("Cython version %s installed\n" % CyVersion)

	if CyVersion < "0.15":
		fatal("Please use Cython version >= 0.15")
except:
	fatal("Cython (www.cython.org) is required to build PySlurm")

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
if args[1] == 'build':

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

		BGL = BGP = BGQ = 0
		if arg.find('--bgl') == 0:
			BGL=1
			sys.argv.remove(arg)
		if arg.find('--bgp') == 0:
			BGP=1
			sys.argv.remove(arg)
		if arg.find('--bgq') == 0:
			BGQ=1
			sys.argv.remove(arg)

	# BlueGene Types

	if (BGL + BGP + BGQ) > 1:
		fatal("Please specifiy one BG Type either --bgl or --bgp or --bgq")
	else:
		try:
			f = open("pyslurm/bluegene.pxi", "w")
			f.write("DEF BG=1\n")
			f.write("DEF BGL=%d\n" % BGL)
			f.write("DEF BGP=%d\n" % BGP)
			f.write("DEF BGQ=%d\n" % BGQ)
			f.close()
		except:
			fatal("Unable to write Blue Gene type to pyslurm/bluegene.pxd")
		
	# Slurm installation directory

	if SLURM_DIR and (SLURM_LIB or SLURM_INC):
		usage()
	elif SLURM_DIR and not (SLURM_LIB or SLURM_INC):
		SLURM_LIB = SLURM_DIR
		SLURM_INC = SLURM_DIR
	elif not SLURM_DIR and not SLURM_LIB and not SLURM_INC:
		SLURM_LIB = DEFAULT_SLURM
		SLURM_INC = DEFAULT_SLURM
	elif not SLURM_DIR and not (SLURM_LIB or not SLURM_INC):
		usage()

	# Test for slurm lib and slurm.h maybe from derived paths ?

	if not os.path.exists("%s/include/slurm/slurm.h" % SLURM_INC):
		warn("Cannot locate the Slurm include in %s" % SLURM_INC)
		usage()
	if not os.path.exists("%s/lib/libslurm.so" % SLURM_LIB):
		warn("Cannot locate the Slurm shared library in %s" % SLURM_LIB)
		usage()

# Get the list of extensions

extNames = scandir("pyslurm/")

# Build up the set of Extension objects

extensions = [makeExtension(name) for name in extNames]

setup(
	name = "pyslurm",
	version = __version__,
	license="GPL",
	description = ("SLURM Interface for Python"),
	long_description=read("README.rst"),
	author = "Mark Roberts",
	author_email = "mark@gingergeeks co uk",
	url = "http://www.gingergeeks.co.uk/pyslurm/",
	platforms = ["Linux"],
	keywords = ["Batch Scheduler", "Resource Manager", "SLURM", "Cython"],
	packages = ["pyslurm"],
	ext_modules = extensions,
	cmdclass = {"build_ext": build_ext },
	classifiers = [
		'Development Status :: 4 - Beta',
		'Environment :: Console',
		'License :: OSI Approved :: GPL',
		'Intended Audience :: Developers',
		'Natural Language :: English',
		'Operating System :: Linux',
		'Programming Language :: Python',
		'Programming Language :: Python :: 2.6',
		'Programming Language :: Python :: 2.7',
		'Programming Language :: Python :: 3.1',
		'Programming Language :: Python :: 3.2',
		'Topic :: Software Development :: Libraries',
		'Topic :: Software Development :: Libraries :: Python Modules',
	]
)
