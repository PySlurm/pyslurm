Name:            python-pyslurm
Version:         25.11.2
%define rel      1
Release:         %{rel}%{?dist}
Summary:         Python interface to Slurm
License:         GPL-2.0-only
URL:             https://github.com/PySlurm/pyslurm
Source:          pyslurm-%{version}.tar.gz

BuildRequires:   python3-devel
BuildRequires:   pyproject-rpm-macros
BuildRequires:   slurm-devel >= 25.11.0

%description
pyslurm is a Python interface to Slurm

%package -n python3-pyslurm
Summary:        %{summary}
Requires:       python3

%description -n python3-pyslurm
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

%files -n python3-pyslurm -f %{pyproject_files}
%license COPYING.txt
%doc README.md

%changelog
* Sat Apr 12 2026 Giovanni Torres <giovtorres@users.noreply.github.com> - 25.11.2-1                                                                                                                                    
- Fix Python 3.6 package metadata (UNKNOWN-0.0.0) by reading version from setup.py

* Sun Mar 22 2026 Giovanni Torres <giovtorres@users.noreply.github.com> - 25.11.0-1
- Initial package
