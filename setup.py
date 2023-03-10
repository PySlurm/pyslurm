"""
The Pyslurm Setup - build options
"""

import os
import logging
import sys
import textwrap
import pathlib
from setuptools import setup, Extension
from distutils.dir_util import remove_tree
from distutils.version import LooseVersion

logger = logging.getLogger(__name__)
logging.basicConfig(format="%(levelname)s: %(message)s", level=logging.DEBUG)

# Keep in sync with pyproject.toml
CYTHON_VERSION_MIN = "0.29.30"

SLURM_RELEASE = "21.8"
PYSLURM_PATCH_RELEASE = "0"
SLURM_SHARED_LIB = "libslurm.so"
CURRENT_DIR = pathlib.Path(__file__).parent

metadata = dict(
    name="pyslurm",
    version=SLURM_RELEASE + "." + PYSLURM_PATCH_RELEASE,
    license="GPLv2",
    description="Python Interface for Slurm",
    long_description=(CURRENT_DIR / "README.md").read_text(),
    author="Mark Roberts, Giovanni Torres, et al.",
    author_email="pyslurm@googlegroups.com",
    url="https://github.com/PySlurm/pyslurm",
    platforms=["Linux"],
    keywords=["HPC", "Batch Scheduler", "Resource Manager", "Slurm", "Cython"],
    packages=["pyslurm"],
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
        "Topic :: Software Development :: Libraries",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: System :: Distributed Computing",
    ],
)

class PySlurmConfig():

    def __init__(self):
        # Assume some defaults here
        self.slurm_lib = "/usr/lib64"
        self.slurm_inc = "/usr/include"
        self.slurm_inc_full = "/usr/include/slurm"

config = PySlurmConfig()

def warn(log_string):
    """Warn logger"""
    logger.error(log_string)


def info(log_string):
    """Info logger"""
    logger.info(log_string)


if sys.version_info[:2] < (3, 6):
    raise RuntimeError("Python 3.6 or higher is required to run PySlurm.")


def usage():
    """Display usage flags"""
    print(
        textwrap.dedent(
        """
        PySlurm Help
        ------------
            --slurm-lib=PATH    Where to look for libslurm.so (default=/usr/lib64)
                                You can also instead use the environment
                                variable SLURM_LIB_DIR.
                                
            --slurm-inc=PATH    Where to look for slurm.h, slurm_errno.h
                                and slurmdb.h (default=/usr/include)
                                You can also instead use the environment
                                variable SLURM_INCLUDE_DIR.

        For help with building or installing PySlurm, please ask on the PySlurm
        Google group at https://groups.google.com/forum/#!forum/pyslurm.

        If you are sure that you have run into a bug, please report it at
        https://github.com/PySlurm/pyslurm/issues.
        """
        )
    )


def inc_vers2str(hex_inc_version):
    """
    Return a slurm version number string decoded from
    the bit shifted components of the slurm version hex
    string supplied in slurm.h
    """
    a = int(hex_inc_version, 16)
    b = (a >> 16 & 0xFF, a >> 8 & 0xFF, a & 0xFF)
    # Only really need the major release
    return f"{b[0]:02d}.{b[1]:02d}"


def read_inc_version(fname):
    """
    Read the supplied include file and extract the
    slurm version number in the define line e.g
    #define SLURM_VERSION_NUMBER 0x020600
    """
    hex_version = ""
    with open(fname, "r", encoding="latin-1") as f:
        for line in f:
            if line.find("#define SLURM_VERSION_NUMBER") == 0:
                hex_version = line.split(" ")[2].strip()
                info("Detected Slurm version - "f"{inc_vers2str(hex_version)}")

    if not hex_version:
        raise RuntimeError("Unable to detect Slurm version")

    return hex_version


def find_files_with_extension(path, extensions):
    """
    Recursively find all files with specific extensions.
    """
    files = [p
             for p in pathlib.Path(path).glob("**/*")
             if p.suffix in extensions]

    return files


def cleanup_build():
    """
    Cleanup build directory and temporary files
    """
    info("Checking for objects to clean")

    if os.path.isdir("build"):
        info("Removing build/")
        remove_tree("build", verbose=1)

    files = find_files_with_extension("pyslurm", {".c", ".pyc", ".so"})

    for file in files:
        if file.is_file():
            info(f"Removing: {file}")
            file.unlink()
        else:
            raise RuntimeError(f"{file} is not a file !")

    info("cleanup done")


def make_extensions():
    """
    Generate Extension objects from .pyx files
    """
    extensions = []
    pyx_files = find_files_with_extension("pyslurm", {".pyx"})
    ext_meta = { 
        "include_dirs": [config.slurm_inc, "."],
        "library_dirs": [config.slurm_lib],
        "libraries": ["slurm"],
        "runtime_library_dirs": [config.slurm_lib],
    }

    for pyx in pyx_files:
        ext = Extension(
                str(pyx.with_suffix("")).replace(os.path.sep, "."),
                [str(pyx)],
                **ext_meta
        )
        extensions.append(ext)

    return extensions


def parse_slurm_args():
    args = sys.argv[1:]

    # Check first if necessary paths to Slurm
    # header and lib were provided via env var
    slurm_lib = os.getenv("SLURM_LIB_DIR")
    slurm_inc = os.getenv("SLURM_INCLUDE_DIR")

    # If these are provided, they take precedence
    # over the env vars
    for arg in args:
        if arg.find("--slurm-lib=") == 0:
            slurm_lib = arg.split("=")[1]
            sys.argv.remove(arg)
        if arg.find("--slurm-inc=") == 0:
            slurm_inc = arg.split("=")[1]
            sys.argv.remove(arg)

    if "--bgq" in args:
        config.bgq = 1

    if slurm_lib:
        config.slurm_lib = slurm_lib
    if slurm_inc:
        config.slurm_inc = slurm_inc
        config.slurm_inc_full = os.path.join(slurm_inc, "slurm")


def slurm_sanity_checks():
    """
    Check if Slurm headers and Lib exist.
    """
    if os.path.exists(f"{config.slurm_lib}/{SLURM_SHARED_LIB}"):
        info(f"Found Slurm shared library in {config.slurm_lib}")
    else:
        raise RuntimeError(f"Cannot locate Slurm shared library in {config.slurm_lib}")
    
    if os.path.exists(f"{config.slurm_inc_full}/slurm.h"):
        info(f"Found Slurm header in {config.slurm_inc_full}")
    else:
        raise RuntimeError(f"Cannot locate the Slurm include in {config.slurm_inc_full}")

    # Test for Slurm MAJOR.MINOR version match (ignoring .MICRO)
    slurm_inc_ver = read_inc_version(f"{config.slurm_inc_full}/slurm_version.h")

    major = (int(slurm_inc_ver, 16) >> 16) & 0xFF
    minor = (int(slurm_inc_ver, 16) >> 8) & 0xFF
    detected_version = str(major) + "." + str(minor)

    if LooseVersion(detected_version) != LooseVersion(SLURM_RELEASE):
        raise RuntimeError(
            f"Incorrect slurm version detected, requires Slurm {SLURM_RELEASE}"
        )


def cythongen():
    """
    Build the PySlurm package
    """
    info("Building PySlurm from source...")
    try:
        from Cython.Distutils import build_ext
        from Cython.Build import cythonize
        from Cython.Compiler.Version import version as cython_version
    except ImportError as e:
        msg = "Cython (https://cython.org) is required to build PySlurm."
        raise RuntimeError(msg) from e
    else:    
        if LooseVersion(cython_version) < LooseVersion(CYTHON_VERSION_MIN):
            msg = f"Please use Cython version >= {CYTHON_VERSION_MIN}"
            raise RuntimeError(msg)


    # Clean up temporary build objects first
    cleanup_build()

    # Build all extensions
    metadata["ext_modules"] = cythonize(make_extensions()) 
    

def parse_setuppy_commands():
    """
    Parse the given setup commands
    """
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
    """
    Define the PySlurm package
    """
    build_it = parse_setuppy_commands()

    if build_it:
        parse_slurm_args()
        slurm_sanity_checks()
        cythongen()

    if "install" in sys.argv:
        parse_slurm_args()
        slurm_sanity_checks()
        metadata["ext_modules"] = make_extensions()

    setup(**metadata)


if __name__ == "__main__":
    setup_package()
