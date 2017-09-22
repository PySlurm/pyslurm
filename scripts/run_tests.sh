#!/bin/bash
set -e

#
# Run nose tests
#

# Get out of pyslurm directory to run tests
cd ..

# Run tests
python$PYTHON $(which nosetests) -v pyslurm/tests
