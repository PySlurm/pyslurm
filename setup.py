#!/usr/bin/env python
# encoding: utf-8

u'''

	PySlurm: Python/Cython interface for SLURM

'''

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


# PySlurm Version

VERSION = imp.load_source('/tmp', 'pyslurm/__init__.py').__version__

print ""
print "Building PySlurm (%s)" % VERSION 
print "------------------------------"
print ""

if sys.version_info[:2] < (2, 5):
	print("PySLURM %s requires Python version 2.5 or later (%d.%d detected)." % (VERSION, sys.version_info[:2]))
	sys.exit(-1)

compiler_dir = os.path.join(get_python_lib(prefix=''), 'src/pyslurm/')

try:
	from Cython.Distutils import build_ext
	from Cython.Compiler.Version import version as CyVersion

	print "Info - Cython version %s installed\n" % CyVersion

	if CyVersion < "0.15":
		print "Alert - Please use Cython version >= 0.15"
		raise
except:
	print "Error - Cython (www.cython.org) is required to build PySlurm"
	sys.exit(-1)

# Handle flags but only on build section
#
#    --slurm=[ROOT_PATH] | --slurm-lib=[LIB_PATH] && --slurm-inc=[INC_PATH]

SLURM_DIR = SLURM_LIB = SLURM_INC = ''
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

	# Slurm installation directory

	if SLURM_DIR and (SLURM_LIB or SLURM_INC):
		usage()

	if SLURM_DIR and not (SLURM_LIB or SLURM_INC):
		SLURM_LIB = SLURM_DIR
		SLURM_INC = SLURM_DIR
	elif SLURM_LIB and not SLURM_INC:
		usage()
	elif SLURM_INC and not SLURM_LIB:
		usage()
	else:
		usage()
	

def usage():
		print "Error - Need to provide either SLURM dir location, please use --slurm=PATH"
		print "        or --slurm-lib=PATH and --slurm-inc=PATH"
		sys.exit(-1)

def scandir(dir, files=[]):

	u'''
	Scan the directory for extension files, converting
	them to extension names in dotted notation
	'''

	for file in os.listdir(dir):
		path = os.path.join(dir, file)
		if os.path.isfile(path) and path.endswith(".pyx"):
			files.append(path.replace(os.path.sep, ".")[:-4])
		elif os.path.isdir(path):
			scandir(path, files)
	return files

def makeExtension(extName):

	u'''
	Generate an Extension object from its dotted name
	'''

	extPath = extName.replace(".", os.path.sep) + ".pyx"
	return Extension(
		extName,
		[extPath],
		include_dirs = [ '%s/include' % SLURM_INC, '.' ],   # adding the '.' to include_dirs is CRUCIAL!!
		library_dirs = [ '%s/lib' % SLURM_LIB], 
		libraries = [ 'slurm' ],
		runtime_library_dirs = [ '%s/lib' % SLURM_LIB],
		extra_objects = [],
		extra_compile_args = [],
		extra_link_args = [],
	)

# Read the README file for long description

def read(fname):

	u'''
	Read the README.rst file for long description
	'''

	return open(os.path.join(os.path.dirname(__file__), fname)).read()

# Get the list of extensions

extNames = scandir("pyslurm/")

# Build up the set of Extension objects

extensions = [ makeExtension(name) for name in extNames ]

setup(
	name = "pyslurm",
	version = VERSION,
	license="GPL",
	description = ("SLURM Interface for Python"),
	long_description=read('README.rst'),
	author = "Mark Roberts",
	author_email = "mark@gingergeeks co uk",
	url = "http://www.gingergeeks.co.uk/pyslurm/",
	platforms = [ "Linux" ],
	keywords = [ "Batch Scheduler", "Resource Manager", "SLURM", "Cython" ],
	packages = [ "pyslurm" ],
	ext_modules = extensions,
	cmdclass = { "build_ext": build_ext },
	classifiers = [
		'Development Status :: 4 - Beta',
		'Environment :: Console',
		'License :: OSI Approved :: GPL',
		'Intended Audience :: Developers',
		'Natural Language :: English',
		'Operating System :: Linux',
		'Programming Language :: Python',
		'Programming Language :: Python :: 2',
		'Programming Language :: Python :: 2.5',
		'Programming Language :: Python :: 2.6',
		'Programming Language :: Python :: 2.7',
		'Topic :: Software Development :: Libraries',
		'Topic :: Software Development :: Libraries :: Python Modules',
	]
)

