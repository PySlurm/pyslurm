%define python3_pkgversion 3.11

Name:            python-pyslurm
Version:         24.5.0
%define rel      1
Release:         %{rel}%{?dist}
Summary:         Python interface to Slurm
License:         GPLv2+
URL:             https://github.com/PySlurm/pyslurm
Source:          pyslurm-%{version}.tar.gz

BuildRequires:   python%{python3_pkgversion}-devel
BuildRequires:   python%{python3_pkgversion}-setuptools
BuildRequires:   python%{python3_pkgversion}-wheel
BuildRequires:   python%{python3_pkgversion}-Cython
BuildRequires:   python%{python3_pkgversion}-packaging
BuildRequires:   python-rpm-macros
BuildRequires:   slurm-devel >= 24.05.0
BuildRequires:   slurm >= 24.05.0
Requires:        python%{python3_pkgversion}

%description
pyslurm is a Python interface to Slurm

%package -n python%{python3_pkgversion}-pyslurm
Summary:        %{summary}

%description -n python%{python3_pkgversion}-pyslurm
pyslurm is a Python interface to Slurm

%prep
%autosetup -p1 -n pyslurm-%{version}

%generate_buildrequires
%pyproject_buildrequires -R

%build
%pyproject_wheel

%install
%pyproject_install
%pyproject_save_files pyslurm

%files -f %{pyproject_files}
%license COPYING.txt
%doc README.md
