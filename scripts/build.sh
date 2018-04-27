#!/bin/bash
set -e

#
# Build the project.
#

# Vars and functions for installing Python 3.5 and 3.6 via IUS repo.
RELEASE_RPM=$(rpm -qf /etc/redhat-release)
RELEASE=$(rpm -q --qf '%{VERSION}' ${RELEASE_RPM})

import_ius_key(){
	rpm --import /etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY
}

centos_install_ius(){
	case ${RELEASE} in
		6*) yum -y install https://centos6.iuscommunity.org/ius-release.rpm;;
		7*) yum -y install https://centos7.iuscommunity.org/ius-release.rpm;;
	esac
	import_ius_key
}

# Install Python
if [ "$PYTHON" == "3.4" ]; then
    yum makecache fast && yum -y install python34{,-devel,-pip}
fi

if [ "$PYTHON" == "3.5" ]; then
    set +e
    command -v python3.5 &>> /dev/null
    if [ "$?" -eq 1 ]; then
        centos_install_ius
        yum makecache fast && yum -y install python35u{,-devel,-pip}
    fi
    set -e
fi

if [ "$PYTHON" == "3.6" ]; then
    set +e
    command -v python3.6 &>> /dev/null
    if [ "$?" -eq 1 ]; then
        centos_install_ius
        yum makecache fast && yum -y install python36u{,-devel,-pip}
    fi
    set -e
fi

# Install importlib dependency for setuptools in Python 2.6.  This needs to get
# done before upgrading pip, as that will also upgrade setuptools, which
# requires importlib.
if [ "$PYTHON" == "2.6" ]
then
    pip uninstall -y setuptools
    pip install setuptools==36.8.0
    pip install importlib
fi

# Upgrade pip
pip install --upgrade pip==9.0.3

# Install nose
pip$PYTHON install nose Cython==$CYTHON

cd pyslurm
echo "Building PySlurm..."
python$PYTHON setup.py build

echo "Installing PySlurm..."
python$PYTHON setup.py install
