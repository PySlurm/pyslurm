#!/bin/bash
set -e

###################################
# Build PySlurm
###################################

cd pyslurm
echo "---> Building PySlurm..."
python$PYTHON setup.py build

echo "---> Installing PySlurm..."
python$PYTHON setup.py install
