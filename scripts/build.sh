#!/bin/bash
set -e

#
# Build the project locally.
#

# Install Python
if [ "$PYTHON" == "3.4" ]
then
    yum makecache fast && yum -y install python34{,-devel,-pip}
fi
if [ "$PYTHON" == "3.5" ]
then
    yum makecache fast && yum -y install python35{,-devel,-pip}
fi
if [ "$PYTHON" == "3.6" ]
then
    yum makecache fast && yum -y install python36{,-devel,-pip}
fi

python -V

# Install nose
pip$PYTHON install nose Cython==$CYTHON Sphinx

cd pyslurm
python$PYTHON setup.py build
python$PYTHON setup.py install
