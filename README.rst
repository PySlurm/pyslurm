***********************************
PySlurm: Slurm Interface for Python
***********************************

.. image:: https://github.com/PySlurm/pyslurm/actions/workflows/pyslurm.yml/badge.svg
    :target: https://github.com/PySlurm/pyslurm/actions/workflows/pyslurm.yml

Overview
========

Currently PySlurm is under development to move from it's thin layer on top of
the Slurm C API to an object orientated interface.

This release is based on Slurm 20.11.

Prerequisites
*************

* `Slurm <https://www.schedmd.com>`_
* `Python <https://www.python.org>`_
* `Cython <https://cython.org>`_

This PySlurm branch has been tested with:

* Cython 0.19.2, and the latest stable
* Python 2.7, 3.4, 3.5 and 3.6
* Slurm 20.11


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


Testing
*******

PySlurm requires an installation of Slurm.

Using a Test Container
----------------------

To run tests locally without an existing Slurm cluster, `docker` and
`docker-compose` is required.

Clone the project::

    git clone https://github.com/PySlurm/pyslurm.git
    cd pyslurm

Start the Slurm container in the background::

    docker-compose up -d

The cluster takes a few seconds to start all the required Slurm services. Tail the logs::

    docker logs -f slurmctl

When the cluster is ready, you will see the following log message::

    Cluster is now available

Press CTRL+C to stop tailing the logs. Slurm is now running in a container in detached mode. `docker-compose` also bind mounds the git directory
inside the container at `/pyslurm` so that the container has access to the test cases.

Install test dependencies::

    pipenv sync --dev

Execute the tests inside the container::

    pipenv run pytest -sv scripts/run_tests_in_container.py

When testing is complete, stop the running Slurm container::

    docker-compose down

Testing on an Existing Slurm Cluster
------------------------------------

You may also choose to clone the project and run tests on a node where Slurm is already compiled and installed::

    git clone https://github.com/PySlurm/pyslurm.git
    cd pyslurm
    python3.9 setup.py build
    python3.9 setup.py install
    ./scripts/configure.sh
    pipenv sync --dev
    pipenv run pytest -sv

Authors
*******

* `Mark Roberts <https://github.com/gingergeeks>`_
* `Giovanni Torres <https://github.com/giovtorres>`_

Help
****

Ask questions on the `pyslurm group <https://groups.google.com/forum/#!forum/pyslurm>`_.
