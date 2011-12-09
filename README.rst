====================================
 PySLURM: SLURM interface for Python
====================================

:Authors: Mark Roberts <mark@gingergeeks.co.uk> and Stephan Gorget <phantez@gmail.com>

Overview
========

Currently `PySLURM` is under development to move from it's thin layer on top of the SLURM C API to an object orientated interface.

The current branch is based on the SLURM 2.2.7 API but versions 2.3 and 2.4 have also been tested.

Prerequistes
=============

This version has been tested with SLURM 2.2.7, Cython 0.15.1 and Python 2.7.2

* [SLURM] http://www.schedmd.com
* [Python] http://www.python.org
* [Cython] http://www.cython.org

Installation
============

You will need to instruct the setup.py script where either the SLURM install root 
directory or where the SLURM libraries and SLURM include files are :

Slurm root directory (Common installation directory):

	python setup.py build --slurm=PATH_TO_SLURM_DIR

	python setup.py install

Separate Slurm library and include directory paths:

	python setup.py build --slurm-lib=PATH_TO_SLURM_LIB --slurm-inc=PATH_TO_SLURM_INC

	python setup.py install

If you still have issues then you could code this directly into the setup.py

Documentation
=============

Prebuilt documentation for the module can be reviewed `online
<http://www.gingergeeks.co.uk/pyslurm>`_, and the source code 
is available on `GitHub <http://github.com/gingergeeks/pyslurm>`_.

