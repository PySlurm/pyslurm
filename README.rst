====================================
 PySLURM: SLURM interface for Python
====================================

:Authors: Mark Roberts <mark@gingergeeks.co.uk> and Stephan Gorget <phantez@gmail.com>

Overview
========

Currently `PySLURM` is a thin layer on top of the SLURM 2.2.7 C API but is being developed to be a full object orientated interface.

Prerequistes
=============

This version has been tested with SLURM 2.2.7, Cython 0.15.1 and Python 2.7.2

* [SLURM] http://www.schedmd.com
* [Python] http://www.python.org
* [Cython] http://www.cython.org

Installation
============

You will need to instruct the setup.py script where the SLURM install root is :

	python setup.py build --slurm=PATH_TO_SLURM_DIR
	python setup.py install

If you still have issues then you can code this directly into the setup.py

Documentation
=============

Prebuilt documentation for the module can be reviewed `online
<http://www.gingergeeks.co.uk/pyslurm>`_, and the source code 
is available on `GitHub <http://github.com/gingergeeks/pyslurm>`_.

