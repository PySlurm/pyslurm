#!/bin/bash
set -e

#
# Build the project locally.
#

# Install Python
if [ $PYTHON == "3.4" ]
then
    yum makecache fast && yum -y install python34{,-devel,-pip}
fi

# Install nose
pip$PYTHON install nose Cython==$CYTHON

cd pyslurm
python$PYTHON setup.py build
python$PYTHON setup.py install
