#!/bin/bash
set -e

#
# Run nose tests
#

# Get out of pyslurm directory to run tests
cd ..

# Run tests
if [ $PYTHON == "2.6"]
then
    nosetests -v pyslurm/tests
else
    nosetests-$PYTHON -v pyslurm/tests
fi
