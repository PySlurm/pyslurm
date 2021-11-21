"""
The Pyslurm Setup - build options
"""

import os
import logging
import sys
import textwrap
from setuptools import setup
from distutils.dir_util import remove_tree
from distutils.core import Extension
from distutils.version import LooseVersion


logger = logging.getLogger(__name__)
logging.basicConfig(format="%(levelname)s: %(message)s", level=logging.DEBUG)

CYTHON_VERSION_MIN = "0.19"
SLURM_VERSION = "20.11"


def fatal(log_string, code=1):
    """Fatal logger"""
    logger.error(log_string)
    sys.exit(code)


def warn(log_string):
    """Warn logger"""
    logger.error(log_string)


def info(log_string):
    """Info logger"""
    logger.info(log_string)


try:
    from Cython.Distutils import build_ext
    from Cython.Compiler.Version import version as cython_version

    if LooseVersion(cython_version) < LooseVersion(CYTHON_VERSION_MIN):
        info(f"Cython version %s installed {cython_version}")
        fatal(f"Please use Cython version >= {CYTHON_VERSION_MIN}")
except ImportError:
    fatal("Cython (https://cython.org) is required to build PySlurm")
    fatal(f"Please use Cython version >= {CYTHON_VERSION_MIN}")


if sys.version_info[:2] < (3, 6):
    fatal("Python 3.6 or higher is required to run PySlurm.")


class Pyslurm:
    """Main setup class"""

    def __init__(self):
        self.here = os.path.abspath(os.path.dirname(__file__))
        self.about = {}
        self.default_slurm_dir = "/usr"
        self.slurm_lib = None
        self.slurm_inc = None
        self.slurm_dir = None
        self.bgq = 0

        # TODO - This needs an recode
        file_path = os.path.join(self.here, "pyslurm", "__version__.py")
        with open(file_path, "r", encoding="latin-1") as file_object:
            for line in file_object:
                (key, val) = line.strip("\n").split(' = ')
                self.about[key] = val.strip('"')

    @staticmethod
    def usage():
        """Display usage flags"""
        print(
            textwrap.dedent(
                """
            PySlurm Help
            ------------
                --slurm=PATH        Where to look for Slurm, PATH points to
                                    the Slurm installation root (default=/usr)
                --slurm-lib=PATH    Where to look for libslurm.so (default=/usr/lib64/slurm)
                --slurm-inc=PATH    Where to look for slurm.h, slurm_errno.h
                                    and slurmdb.h (default=/usr/include)
                --bgq               Enable support for BG/Q mode

            For help with building or installing PySlurm, please ask on the PySlurm
            Google group at https://groups.google.com/forum/#!forum/pyslurm.

            If you are sure that you have run into a bug, please report it at
            https://github.com/PySlurm/pyslurm/issues.
            """
            )
        )

    @staticmethod
    def scandir(filedir, files=None):
        """
        Scan the directory for extension files, converting
        them to extension names in dotted notation
        """
        if files is None:
            files = []

        for file in os.listdir(filedir):

            path = os.path.join(filedir, file)

            if os.path.isfile(path) and path.endswith(".pyx"):
                files.append(path.replace(os.path.sep, ".")[:-4])
            elif os.path.isdir(path):
                Pyslurm.scandir(path, files)

        return files

    def make_extension(self, extension_name):
        """Generate an Extension object from its dotted name"""
        extension_path = extension_name.replace(".", os.path.sep) + ".pyx"
        runtime_library_dirs = [self.slurm_lib, f"{self.slurm_lib}/slurm"]
        return Extension(
            extension_name,
            [extension_path],
            include_dirs=[self.slurm_inc, "."],
            library_dirs=runtime_library_dirs,
            libraries=["slurmfull"],
            runtime_library_dirs=runtime_library_dirs,
            extra_objects=[],
            extra_compile_args=[],
            extra_link_args=[],
        )

    @staticmethod
    def inc_vers2str(hex_inc_version):
        """
        Return a slurm version number string decoded from
        the bit shifted components of the slurm version hex
        string supplied in slurm.h
        """
        a = int(hex_inc_version, 16)
        b = (a >> 16 & 0xFF, a >> 8 & 0xFF, a & 0xFF)
        return f"{b[0]:02d}.{b[1]:02d}.{b[2]:02d}"

    def read_inc_version(self, fname):
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
                    info(
                        "Build - Detected Slurm version - "
                        f"{hex_version} {self.inc_vers2str(hex_version)}"
                    )

        if not hex_version:
            fatal("Build - Unable to detect Slurm version")

        return hex_version

    def check_lib_path(self, slurm_path):
        """Check the Slurm library path"""
        if not slurm_path:
            slurm_path = self.default_slurm_dir

        slurm_path = os.path.normpath(slurm_path)
        # if base dir given then search lib64 and then lib
        for lib_path in ["lib64", "lib"]:
            slurm_lib_path = os.path.join(slurm_path, lib_path)

            if os.path.exists(f"{slurm_lib_path}/libslurm.so"):
                info(f"Build - Found Slurm shared library in {slurm_lib_path}")
                return slurm_lib_path

        # if base dir given then check this
        if os.path.exists(f"{slurm_path}/libslurm.so"):
            info(f"Build - Found Slurm shared library in {slurm_path}")
            return slurm_path
        else:
            fatal(f"Build - Cannot locate Slurm shared library in {slurm_path}")
            return None

    def create_bluegene_include(self):
        """
        Create pyslurm/bluegene.pxi include file.
        """
        info("Build - Generating pyslurm/bluegene.pxi file")
        try:
            with open("pyslurm/bluegene.pxi", "w", encoding="latin-1") as f:
                f.write("DEF BG=1\n")
                f.write(f"DEF BGQ={self.bgq}\n")
        except IOError:
            fatal("Build - Unable to write Blue Gene type to pyslurm/bluegene.pxi")

    @staticmethod
    def clean():
        """Cleanup build directory and temporary files"""
        info("Clean - checking for objects to clean")

        if os.path.isdir("build"):
            info("Clean - removing build/")
            remove_tree("build", verbose=1)

        files = [
            "pyslurm/__init__.pyc",
            "pyslurm/bluegene.pxi",
            "pyslurm/pyslurm.c",
            "pyslurm/pyslurm.so",
        ]

        for file in files:
            if os.path.exists(file):
                if os.path.isfile(file):
                    try:
                        info(f"Clean - removing {file}")
                        os.unlink(file)
                    except OSError:
                        fatal(f"Clean - failed to remove {file}")
                else:
                    fatal(f"Clean - {file} is not a file !")

        info("Clean - completed")

    def build(self):
        """Build the PySlurm package"""
        info("")
        info(f'Building PySlurm ({self.about["__version__"]})')
        info("------------------------------")
        info("")
        info(f"Cython version {cython_version} installed")
        info("")

        # Clean up temporary build objects first
        self.clean()

        args = sys.argv[1:]
        for arg in args:
            if arg.find("--slurm=") == 0:
                self.slurm_dir = arg.split("=")[1]
                sys.argv.remove(arg)
            if arg.find("--slurm-lib=") == 0:
                self.slurm_lib = arg.split("=")[1]
                sys.argv.remove(arg)
            if arg.find("--slurm-inc=") == 0:
                self.slurm_inc = arg.split("=")[1]
                sys.argv.remove(arg)

        # Slurm installation directory
        if self.slurm_dir and (self.slurm_lib or self.slurm_inc):
            self.usage()
        elif self.slurm_dir and not (self.slurm_lib or self.slurm_inc):
            self.slurm_lib = self.slurm_dir
            self.slurm_inc = f"{self.slurm_dir}/include"
        elif not self.slurm_dir and not self.slurm_lib and not self.slurm_inc:
            self.slurm_lib = self.default_slurm_dir
            self.slurm_inc = f"{self.default_slurm_dir}/include"
        elif not self.slurm_dir and (not self.slurm_lib or not self.slurm_inc):
            self.usage()

        # Test for slurm.h maybe from derived paths
        if os.path.exists(f"{self.slurm_inc}/slurm/slurm.h"):
            info(f"Build - Found Slurm header in {self.slurm_inc}/slurm")
        elif os.path.exists(f"{self.slurm_inc}/slurm.h"):
            info(f"Build - Found Slurm header in {self.slurm_inc}")
        else:
            fatal(f"Build - Cannot locate the Slurm include in {self.slurm_inc}")

        # Test for Slurm MAJOR.MINOR version match (ignoring .MICRO)
        try:
            slurm_inc_ver = self.read_inc_version(f"{self.slurm_inc}/slurm/slurm.h")
        except IOError:
            slurm_inc_ver = self.read_inc_version(f"{self.slurm_inc}/slurm.h")

        major = (int(slurm_inc_ver, 16) >> 16) & 0xFF
        minor = (int(slurm_inc_ver, 16) >> 8) & 0xFF

        if LooseVersion(str(major) + "." + str(minor)) != LooseVersion(SLURM_VERSION):
            fatal(
                f"Build - Incorrect slurm version detected, requires Slurm {SLURM_VERSION}"
            )

        # Test for libslurm in lib64 and then lib
        self.slurm_lib = self.check_lib_path(self.slurm_lib)
        if not self.slurm_lib:
            self.usage()

        # BlueGene
        self.create_bluegene_include()

    def parse_setuppy_commands(self):
        """Parse the given setup commands"""
        args = sys.argv[1:]

        if len(args) == 0:
            self.usage()
        else:
            if "--bgq" in args:
                self.bgq = 1

            # Prepend PySlurm help text when passing --help | -h
            if "--help" in args or "-h" in args:
                self.usage()
                print(
                    textwrap.dedent(
                        """
                    Distutils Help
                    --------------
                    """
                    )
                )

            # Clean up temporary build objects when cleaning
            elif "clean" in args:
                self.clean()

            # Generate bluegene.pxi when creating source distribution
            elif "sdist" in args:
                self.create_bluegene_include()

            # --slurm=[ROOT_PATH]
            # --slurm-lib=[LIB_PATH] --slurm-inc=[INC_PATH]
            elif "build" in args or "build_ext" in args:
                self.build()

    def setup_package(self):
        """Define the PySlurm package"""
        self.parse_setuppy_commands()

        # Get the list of extensions
        ext_names = self.scandir("pyslurm/")

        # Build up the set of Extension objects
        extensions = [self.make_extension(name) for name in ext_names]

        with open(
            os.path.join(self.here, "README.md"),
            "r",
            encoding="latin-1",
        ) as f:
            long_description = f.read()

        setup(
            name="pyslurm",
            version=self.about["__version__"],
            license="GPLv2",
            description="Python Interface for Slurm",
            long_description=long_description,
            author="Mark Roberts, Giovanni Torres, et al.",
            author_email="pyslurm@googlegroups.com",
            url="https://github.com/PySlurm/pyslurm",
            platforms=["Linux"],
            keywords=["HPC", "Batch Scheduler", "Resource Manager", "Slurm", "Cython"],
            packages=["pyslurm"],
            install_requires=["Cython"],
            ext_modules=extensions,
            cmdclass={"build_ext": build_ext},
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


if __name__ == "__main__":
    Pyslurm().setup_package()
