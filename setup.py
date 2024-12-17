#!/usr/bin/env python3
"""The Pyslurm Setup - build options"""

import os
import sys
import textwrap
import shutil
from pathlib import Path
from setuptools import setup, Extension

try:
    from packaging.version import Version
except ImportError:
    from setuptools._vendor.packaging.version import Version


CYTHON_VERSION_MIN = "0.29.37" # Keep in sync with pyproject.toml
SLURM_LIB = "libslurmfull"
TOPDIR = Path(__file__).parent
PYTHON_MIN_REQUIRED = (3, 6)


def get_version():
    with (TOPDIR / "pyslurm/__version__.py").open() as f:
        for line in f.read().splitlines():
            if line.startswith("__version__"):
               return Version(line.split('"')[1])
    raise RuntimeError("Cannot get version string.")


VERSION = get_version()
SLURM_VERSION = f"{VERSION.major}.{VERSION.minor}"


def homepage(*args):
    url = f"https://pyslurm.github.io/{SLURM_VERSION}"
    return "/".join([url] + list(args))


def github(*args):
    url = "https://github.com/PySlurm/pyslurm"
    return "/".join([url] + list(args))


metadata = dict(
    name="pyslurm",
    version=str(VERSION),
    license="GPLv2",
    description="Python Interface for Slurm",
    long_description=(TOPDIR / "README.md").read_text(encoding="utf-8"),
    long_description_content_type="text/markdown",
    author="Mark Roberts, Giovanni Torres, et al.",
    author_email="pyslurm@googlegroups.com",
    url=homepage(),
    platforms=["Linux"],
    keywords=[
        "HPC"
        "Batch Scheduler"
        "Resource Manager"
        "Slurm"
        "Cython"
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
        "Source Code"   : github(),
        "Bug Tracker"   : github("issues"),
        "Discussions"   : github("discussions"),
        "Documentation" : homepage("reference"),
        "Changelog"     : homepage("changelog")
    },
    python_requires=f">={'.'.join(str(i) for i in PYTHON_MIN_REQUIRED)}",
)

if sys.version_info[:2] < PYTHON_MIN_REQUIRED:
    raise RuntimeError(f"Python {PYTHON_MIN_REQUIRED} or higher is required.")


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


def usage():
    print(
        textwrap.dedent(
        f"""
        PySlurm Help
        ------------
            --slurm-lib=PATH    Where to look for the Slurm library (default=/usr/lib64)
                                You can also instead use the environment
                                variable SLURM_LIB_DIR.

            --slurm-inc=PATH    Where to look for slurm.h, slurm_errno.h
                                and slurmdb.h (default=/usr/include)
                                You can also instead use the environment
                                variable SLURM_INCLUDE_DIR.

        Homepage: {homepage()}
        """
        )
    )


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
    # Check first if necessary paths to Slurm header and lib were provided via
    # env var
    lib_dir = os.getenv("SLURM_LIB_DIR", slurm.lib_dir)
    inc_dir = os.getenv("SLURM_INCLUDE_DIR", slurm.inc_dir)

    # If these are provided, they take precedence over the env vars
    args = sys.argv[1:]
    for arg in args:
        if arg.find("--slurm-lib=") == 0:
            lib_dir = arg.split("=")[1]
            sys.argv.remove(arg)
        if arg.find("--slurm-inc=") == 0:
            inc_dir = arg.split("=")[1]
            sys.argv.remove(arg)

    slurm.inc_dir = Path(inc_dir)
    slurm.lib_dir = Path(lib_dir)


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
    metadata["ext_modules"] = cythonize(get_extensions())


def parse_setuppy_commands():
    args = sys.argv[1:]
    if not args:
        return False

    # Prepend PySlurm help text when passing --help | -h
    if "--help" in args or "-h" in args:
        usage()
        print(
            textwrap.dedent(
            """
            Setuptools Help
            --------------
            """
            )
        )
        return False

    # Clean up all build objects
    if "clean" in args:
        cleanup_build()
        return False

    build_cmd = ('build', 'build_ext', 'build_py', 'build_clib',
        'build_scripts', 'bdist_wheel', 'build_src', 'bdist_egg', 'develop')

    for cmd in build_cmd:
        if cmd in args:
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
