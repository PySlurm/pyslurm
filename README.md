# PySlurm

[![PySlurm](https://github.com/PySlurm/pyslurm/actions/workflows/pyslurm.yml/badge.svg?branch=main)](https://github.com/PySlurm/pyslurm/actions/workflows/pyslurm.yml)

## Overview

PySlurm is the Python client library for the [Slurm](https://slurm.schedmd.com) HPC Scheduler.

## Prerequisites

* [Slurm](https://slurm.schedmd.com) - Slurm shared library and header files
* [Python](https://www.python.org) - >= 3.6
* [Cython](https://cython.org) - >= 0.29.30 but < 3.0

This PySlurm branch is for the Slurm Major-Release 23.02

## Installation

By default, it is searched inside `/usr/include` for the Header files and in
`/usr/lib64` for Slurms shared-library (`libslurm.so`) during Installation.
For Slurm installations in different locations, you will need to provide
the corresponding paths to the necessary files.

You can specify these Paths with environment variables (recommended), for example:

```shell
export SLURM_INCLUDE_DIR=/opt/slurm/23.02/include
export SLURM_LIB_DIR=/opt/slurm/23.02/lib
```

Then you can proceed to install PySlurm, for example by cloning the Repository:

```shell
git clone https://github.com/PySlurm/pyslurm.git && cd pyslurm
scripts/build.sh

# Or simply with pip
pip install .
```

Also see `python setup.py --help`

## Release Versioning

PySlurm's versioning scheme follows the official Slurm versioning. The first
two numbers (MAJOR.MINOR) always correspond to Slurms Major-Release, for example
`23.02`. The last number (MICRO) is however not tied in any way to Slurms
MICRO version. For example, any PySlurm 23.02.X version should work with any
Slurm 23.02.X release.

## Documentation

The API documentation is hosted at <https://pyslurm.github.io>.

To build the docs locally, use [Sphinx](http://www.sphinx-doc.org) to generate
the documentation from the reStructuredText based docstrings found in the
pyslurm module once it is built:

```shell
cd doc
make clean
make html
```

## Testing

PySlurm requires an installation of Slurm.

### Using a Test Container

To run tests locally without an existing Slurm cluster, `docker` and
`docker-compose` is required.

Clone the project:

```shell
git clone https://github.com/PySlurm/pyslurm.git
cd pyslurm
```

Start the Slurm container in the background:

```shell
docker-compose up -d
```

The cluster takes a few seconds to start all the required Slurm services. Tail
the logs:

```shell
docker-compose logs -f
```

When the cluster is ready, you will see the following log message:

```text
Cluster is now available
```

Press CTRL+C to stop tailing the logs. Slurm is now running in a container in
detached mode. `docker-compose` also bind mounds the git directory inside the
container at `/pyslurm` so that the container has access to the test cases.

Install test dependencies:

```shell
pipenv sync --dev
```

Execute the tests inside the container:

```shell
pipenv run pytest -sv scripts/run_tests_in_container.py
```

When testing is complete, stop the running Slurm container:

```shell
docker-compose down
```

### Testing on an Existing Slurm Cluster

You may also choose to clone the project and run tests on a node where Slurm is
already compiled and installed:

```shell
git clone https://github.com/PySlurm/pyslurm.git
cd pyslurm
pip install .
./scripts/configure.sh
pipenv sync --dev
pipenv run pytest -sv
```

## Contributors

PySlurm is made by [contributors like
you](https://github.com/PySlurm/pyslurm/graphs/contributors).

## Help

Ask questions on the [PySlurm Google
Group](https://groups.google.com/forum/#!forum/pyslurm)
