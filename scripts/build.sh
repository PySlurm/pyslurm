#!/bin/bash
set -e

###################################
# Install Python and Build PySlurm
###################################

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

# NOTE: Python is already pre-installed in the later containers

# Install Python versions from YUM repositories
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

if [ "$PYTHON" == "2.6" ]
then
    echo "---> Upgrading setuptools to 36.8.0..."
    pip install --upgrade setuptools==36.8.0
fi

# Upgrade pip
echo "---> Upgrading pip to 9.0.3..."
pip install --upgrade pip==9.0.3

# Install nose
echo "---> Installing nose and Cython pip packages..."
pip$PYTHON install nose Cython==$CYTHON

cd pyslurm
echo "---> Building PySlurm..."
python$PYTHON setup.py build

echo "---> Installing PySlurm..."
python$PYTHON setup.py install
