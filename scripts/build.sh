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
if [ "$PYTHON" == "3.4" ]
then
    yum makecache fast && yum -y install python34{,-devel,-pip}
fi

if [ "$PYTHON" == "3.5" ]
then
    centos_install_ius
    yum makecache fast && yum -y install python35u{,-devel,-pip}
fi

if [ "$PYTHON" == "3.6" ]
then
    centos_install_ius
    yum makecache fast && yum -y install python36u{,-devel,-pip}
fi

# Install nose
pip$PYTHON install nose Cython==$CYTHON Sphinx

cd pyslurm
python$PYTHON setup.py build
python$PYTHON setup.py install
