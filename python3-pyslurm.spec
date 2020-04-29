Name:		python3-pyslurm
Version:	20.02.0
Release:	1%{?dist}
Summary:	python3-pyslurm

Group:		Development/Libraries
License:	GPLv2
URL:		https://github.com/PySlurm/pyslurm

BuildRequires:	slurm-devel, python3, python3-devel, python3-pip
Requires:	slurm

%description
PySLURM is a Python/Cython extension module to the Simple Linux Unified Resource Manager (SLURM) API

%prep
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
rm -rf pyslurm
git clone https://github.com/bikerdanny/pyslurm.git
cd pyslurm
git checkout 20.02.1
cd /usr/include
pip3 install autopxd2
autopxd --include-dir /usr/include slurm/slurm.h %{_builddir}/pyslurm/pyslurm/slurm.h.pxd
autopxd --include-dir /usr/include slurm/slurmdb.h %{_builddir}/pyslurm/pyslurm/slurmdb.h.pxd
autopxd --include-dir /usr/include slurm/slurm_errno.h %{_builddir}/pyslurm/pyslurm/slurm_errno.h.pxd
cd %{_builddir}/pyslurm/pyslurm
patch -p0 < slurm.h.pxd.patch
patch -p0 < slurmdb.h.pxd.patch
sed -i "s/slurm_addr_t control_addr/#slurm_addr_t control_addr/g" slurmdb.h.pxd
sed -i "s/pthread_mutex_t lock/#pthread_mutex_t lock/g" slurmdb.h.pxd
patch -p0 < slurm_errno.h.pxd.patch
pip3 install j2cli
j2 slurm.j2 > slurm.pxd
pip3 install Cython

%build
cd %{_builddir}/pyslurm
python3 setup.py build

%install
cd %{_builddir}/pyslurm
python3 setup.py install --skip-build --root %{buildroot}

%files
%{python3_sitearch}/*

%changelog

