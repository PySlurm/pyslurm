***********************************
PySlurm: Slurm Interface for Python
***********************************

.. image:: https://travis-ci.org/PySlurm/pyslurm.svg?branch=19.05.0
    :target: https://travis-ci.org/PySlurm/pyslurm

Overview
========

Currently PySlurm is under development to move from it's thin layer on top of
the Slurm C API to an object orientated interface.

This release is based on Slurm 19.05.

Prerequisites
*************

* `Slurm <https://www.schedmd.com>`_
* `Python <https://www.python.org>`_
* `Cython <https://cython.org>`_

This PySlurm branch has been tested with:

* Cython 0.19.2, and the latest stable
* Python 2.7, 3.4, 3.5 and 3.6
* Slurm 19.05.0


Installation
************

You will need to instruct the setup.py script where either the Slurm install
root directory or where the Slurm libraries and Slurm include files are:

#. Slurm default directory (/usr):

    * python setup.py build

    * python setup.py install

#. Indicate Blue Gene type Q on build line:

    * --bgq

#. Slurm root directory (Alternate installation directory):

    * python setup.py build --slurm=PATH_TO_SLURM_DIR

    * python setup.py install

#. Separate Slurm library and include directory paths:

    * python setup.py build --slurm-lib=PATH_TO_SLURM_LIB --slurm-inc=PATH_TO_SLURM_INC

    * python setup.py install

#. The build will automatically call a cleanup procedure to remove temporary build files but this can be called directly if needed as well with :

    * python setup.py clean

Documentation
*************

The API documentation is hosted at https://pyslurm.github.io.

To build the docs locally, use `Sphinx <http://www.sphinx-doc.org>`_ to
generate the documentation from the reStructuredText based docstrings found in
the pyslurm module once it is built:

.. code-block:: console

    cd doc
    make clean
    make html


Authors
*******

* `Mark Roberts <https://github.com/gingergeeks>`_
* `Giovanni Torres <https://github.com/giovtorres>`_

Help
****

Ask questions on the `pyslurm group <https://groups.google.com/forum/#!forum/pyslurm>`_.
