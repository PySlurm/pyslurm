Name:           python-pyslurm
Version:        24.5.0
Release:        1%{?dist}
Summary:        Python interface to Slurm

License:        GPLv2+
URL:            https://github.com/PySlurm/pyslurm

# https://docs.fedoraproject.org/en-US/packaging-guidelines/SourceURL/#_troublesome_urls
Source:         %{url}/archive/refs/tags/v%{version}.tar.gz

BuildArch:       noarch
BuildRequires:   python%{python3_pkgversion}-devel
BuildRequires:   slurm-devel >= 24.05.0
BuildRequires:   slurm >= 24.05.0
# BuildRequires:   python%{python3_pkgversion}-setuptools
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

%changelog
%autochangelog
