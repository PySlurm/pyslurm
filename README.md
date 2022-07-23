# PySlurm

[![PySlurm](https://github.com/PySlurm/pyslurm/actions/workflows/pyslurm.yml/badge.svg?branch=main)](https://github.com/PySlurm/pyslurm/actions/workflows/pyslurm.yml)

## Overview

PySlurm is the Python client library for the [Slurm](https://slurm.schedmd.com) HPC Scheduler.

## Prerequisites

* [Slurm](https://slurm.schedmd.com)
* [Python](https://www.python.org)
* [Cython](https://cython.org)

This PySlurm branch has been tested with:

* Cython (latest stable)
* Python 3.6, 3.7, 3.8, and 3.9
* Slurm 22.05

## Installation

You will need to instruct the setup.py script where either the Slurm install
root directory or where the Slurm libraries and Slurm header files are.

### Slurm installed using system defaults (/usr)

```shell
python setup.py build
python setup.py install
```

### Custom installation location

```shell
python setup.py build --slurm=PATH_TO_SLURM_DIR
python setup.py install
```

### Custom Slurm library and include directories

```shell
python setup.py build --slurm-lib=PATH_TO_SLURM_LIB --slurm-inc=PATH_TO_SLURM_INC
python setup.py install
```

### Indicate Blue Gene type Q on build line

```shell
python setup.py build --bgq
```

### Cleanup build artifacts

The build will automatically call a cleanup procedure to remove temporary build
files but this can be called directly if needed as well with :

```shell
python setup.py clean
```

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
python3.9 setup.py build
python3.9 setup.py install
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
