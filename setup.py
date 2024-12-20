#!/usr/bin/env python3
"""The Pyslurm Setup - build options"""

import os
import sys
from pathlib import Path
from setuptools import setup, Extension, find_packages

try:
    from packaging.version import Version
except ImportError:
    from setuptools._vendor.packaging.version import Version

TOPDIR = Path(__file__).parent


def get_version():
    with (TOPDIR / "pyslurm/version.py").open() as f:
        for line in f.read().splitlines():
            if not line.startswith("__version__"):
                continue

            V = Version(line.split('"')[1])
            if not hasattr(V, "major") or not hasattr(V, "minor"):
                (V.major, V.minor) = V._version.release[0:2]

            return V
    raise RuntimeError("Cannot get version string.")


CYTHON_VERSION_MIN = "0.29.37" # Keep in sync with pyproject.toml
SLURM_LIB = "libslurmfull"
VERSION = get_version()
SLURM_VERSION = f"{VERSION.major}.{VERSION.minor}"
DOCUMENTATION_URL = f"https://pyslurm.github.io/{SLURM_VERSION}"
GITHUB_URL = "https://github.com/PySlurm/pyslurm"


def homepage(*args):
    return "/".join([DOCUMENTATION_URL] + list(args))


def github(*args):
    return "/".join([GITHUB_URL] + list(args))


metadata = dict(
    name="pyslurm",
    version=str(VERSION),
    license="GPLv2",
    description="Python Interface for Slurm",
    long_description=(TOPDIR / "README.md").read_text(encoding="utf-8"),
    long_description_content_type="text/markdown",
    author="Mark Roberts, Giovanni Torres, Toni Harzendorf, et al.",
    maintainer="Toni Harzendorf",
    maintainer_email="toni.harzendorf@gmail.com",
    platforms=["Linux"],
    url=homepage(),
    keywords=[
        "HPC",
        "Batch Scheduler",
        "Resource Manager",
        "Slurm",
        "Cython",
    ],
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "Intended Audience :: System Administrators",
        "License :: OSI Approved :: GNU General Public License v2 (GPLv2)",
        "Natural Language :: English",
        "Operating System :: POSIX :: Linux",
        "Programming Language :: Cython",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Software Development :: Libraries",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: System :: Distributed Computing",
    ],
    project_urls={
        "Homepage"      : github(),
        "Repository"    : github(),
        "Issues"        : github("issues"),
        "Discussions"   : github("discussions"),
        "Documentation" : homepage("reference"),
        "Changelog"     : homepage("changelog")
    },
    python_requires=">=3.6",
    packages=find_packages(
        include=['pyslurm*'],
    ),
    include_package_data=True,
)

class SlurmConfig():

    def __init__(self):
        # Assume some defaults here
        self._lib_dir = Path("/usr/lib64")
        self._lib = None
        self._lib_dir_search_paths = []
        self.inc_dir = Path("/usr/include")
        self._version = None

    def _find_hdr(self, name):
        hdr = self.inc_full_dir / name
        if not hdr.exists():
            raise RuntimeError(f"Cannot locate {name} in {self.inc_full_dir}")
        return hdr

    def _search_lib(self, lib_dir):
        if self._lib:
            return

        lib = lib_dir / f"{SLURM_LIB}.so"
        if not lib.exists():
            self._lib_dir_search_paths.append(str(lib_dir))
        else:
            print(f"Found slurm library: {lib}")
            self._lib = lib
            self._lib_dir = lib_dir

    @property
    def lib_dir(self):
        return self._lib_dir

    @lib_dir.setter
    def lib_dir(self, path):
        self._search_lib(path)
        self._search_lib(path / "slurm")
        self._search_lib(path / "slurm-wlm")

        if not self._lib:
            searched = "\n- ".join(self._lib_dir_search_paths)
            raise RuntimeError("Cannot locate Slurm library. Searched paths: "
                               f"\n- {searched}")

    @property
    def inc_full_dir(self):
        return self.inc_dir / "slurm"

    @property
    def slurm_h(self):
        return self._find_hdr("slurm.h")

    @property
    def slurm_version_h(self):
        return self._find_hdr("slurm_version.h")

    @property
    def version(self):
        vers = int(self._version, 16)
        major = vers >> 16 & 0xFF
        minor = vers >> 8 & 0xFF
        return f"{major}.{minor}"

    def check_version(self):
        with open(self.slurm_version_h, "r", encoding="latin-1") as f:
            for line in f:
                if line.find("#define SLURM_VERSION_NUMBER") == 0:
                    self._version = line.split(" ")[2].strip()
                    print("Detected Slurm version - "f"{self.version}")

        if not self._version:
            raise RuntimeError("Unable to detect Slurm version")

        if Version(self.version) != Version(SLURM_VERSION):
            raise RuntimeError(
                "Slurm version mismatch: "
                f"requires Slurm {SLURM_VERSION}, found {self.version}"
            )


slurm = SlurmConfig()


def find_files_with_extension(path, extensions):
    files = [p
             for p in Path(path).glob("**/*")
             if p.suffix in extensions]
    return files


def cleanup_build():
    files = find_files_with_extension("pyslurm", {".c", ".pyc", ".so"})
    for file in files:
        if file.is_file():
            file.unlink()
        else:
            raise RuntimeError(f"{file} is not a file!")


def get_extensions():
    extensions = []
    pyx_files = find_files_with_extension("pyslurm", {".pyx"})
    ext_meta = {
        "include_dirs": [str(slurm.inc_dir), "."],
        "library_dirs": [str(slurm.lib_dir)],
        "libraries": [SLURM_LIB[3:]],
        "runtime_library_dirs": [str(slurm.lib_dir)],
    }
    for pyx in pyx_files:
        mod_name = str(pyx.with_suffix("")).replace(os.path.sep, ".")
        ext = Extension(mod_name, [str(pyx)], **ext_meta)
        extensions.append(ext)

    return extensions


def parse_slurm_args():
    slurm.lib_dir = Path(os.getenv("SLURM_LIB_DIR", slurm.lib_dir))
    slurm.lib_dir = Path(os.getenv("SLURM_INCLUDE_DIR", slurm.inc_dir))


def cythongen():
    print("Cythonizing sources...")
    try:
        from Cython.Distutils import build_ext
        from Cython.Build import cythonize
        from Cython.Compiler.Version import version as cython_version
    except ImportError as e:
        msg = "Cython (https://cython.org) is required to build PySlurm."
        raise RuntimeError(msg) from e
    else:
        if Version(cython_version) < Version(CYTHON_VERSION_MIN):
            msg = f"Please use Cython version >= {CYTHON_VERSION_MIN}"
            raise RuntimeError(msg)

    cleanup_build()
    nthreads = os.getenv("PYSLURM_BUILD_JOBS", 1)
    metadata["ext_modules"] = cythonize(get_extensions(), nthreads=int(nthreads))


def parse_setuppy_commands():
    args = sys.argv[1:]
    if not args:
        return False

    if "clean" in args:
        cleanup_build()
        return False

    build_cmd = ('build', 'build_ext', 'build_py', 'build_clib',
                 'build_scripts', 'bdist_wheel', 'build_src', 'bdist_egg',
                 'develop', 'editable_wheel')

    for cmd in build_cmd:
        if cmd == args[0]:
            return True

    return False


def setup_package():
    build_it = parse_setuppy_commands()

    if build_it:
        parse_slurm_args()
        slurm.check_version()
        cythongen()

    if "install" in sys.argv:
        parse_slurm_args()
        slurm.check_version()
        metadata["ext_modules"] = get_extensions()

    setup(**metadata)


if __name__ == "__main__":
    setup_package()
