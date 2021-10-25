from glob import glob
import os
import os.path as osp

# make sure to import setuptools before Cython
from setuptools import setup, find_packages, Extension
import Cython.Build
from Cython.Build import cythonize

# constants
DEFAULT_SLURM_DIR = "/usr"

SLURM_DIR_ENV_VAR_NAME = "SLURM_DIR"
SLURM_LIB_ENV_VAR_NAME = "SLURM_LIB"
SLURM_INCLUDE_ENV_VAR_NAME = "SLURM_INCLUDE"

# 'slurmfull' is in e.g. /usr/slurm/libslurmfull.a so make sure that
# this is found on the lib paths
SLURM_LIBRARIES = [
    "slurmfull",
]


def get_slurm_dir():

    val = os.environ.get(SLURM_DIR_ENV_VAR_NAME, False)

    if not val:
        return DEFAULT_SLURM_DIR

    else:
        return val


def resolve_slurm_libs_incs():

    # # get the slurm dir using default if needed
    # slurm_dir = get_slurm_dir()

    # resolve the values from the environment variables
    slurm_lib = os.environ.get(SLURM_LIB_ENV_VAR_NAME, False)
    slurm_include = os.environ.get(SLURM_INCLUDE_ENV_VAR_NAME, False)

    if slurm_lib is False:
        slurm_lib = "{}/lib".format(DEFAULT_SLURM_DIR)

    if slurm_include is False:
        slurm_include = "{}/include".format(DEFAULT_SLURM_DIR)

    # we want to search both the e.g. /usr/lib and in /usr/lib/slurm
    slurm_libs = [slurm_lib,
                  "{}/slurm".format(slurm_lib),
                  ]

    slurm_includes = [slurm_include,
                      '.',
                  # "{}/slurm".format(slurm_include),
                  ]

    return slurm_libs, slurm_includes

def path_to_modname(path):

    return osp.splitext(path)[0].replace(osp.sep, '.')

def resolve_extension_kwargs():

    # Compile & link time stuff

    # get the directories to search for the libs and include files by
    # resolving the env variables, defaults, command line arguments
    # etc.
    library_dirs, include_dirs = resolve_slurm_libs_incs()

    # runtime libraries
    runtime_library_dirs = library_dirs


    return {
        "include_dirs" : include_dirs,
        "library_dirs" : library_dirs,
        "libraries" : SLURM_LIBRARIES,
        "runtime_library_dirs" : runtime_library_dirs,
    }

ext_kwargs = resolve_extension_kwargs()

cython_paths = glob("pyslurm/**/*.pyx", recursive=True)
cython_modnames = [path_to_modname(cython_path) for cython_path in cython_paths]

print("Cython paths:", cython_paths)

print("Extension Kwargs:", ext_kwargs)

extensions = [
    Extension(
        cython_modname,
        [cython_path],
        **ext_kwargs,
    )
    for cython_path, cython_modname
    in zip(cython_paths, cython_modnames)
]

extensions = cythonize(extensions)

# TODO: more robust standardized way to get the version
here = os.path.abspath(os.path.dirname(__file__))

with open(os.path.join(here, "README.rst")) as f:
    long_description = f.read()


with open(os.path.join(here, "pyslurm", "__version__.py"), "r") as f:
    about = {}
    exec(f.read(), about)

setup(
    name="pyslurm",
    version=about["__version__"],
    license="GPLv2",
    description=("Python Interface for Slurm"),
    long_description=long_description,
    author="Mark Roberts, Giovanni Torres, et al.",
    author_email="pyslurm@googlegroups.com",
    url="https://github.com/PySlurm/pyslurm",
    platforms=["Linux"],
    keywords=["HPC", "Batch Scheduler", "Resource Manager", "Slurm", "Cython"],
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'License :: OSI Approved :: GNU General Public License v2 (GPLv2)',
        'Natural Language :: English',
        'Operating System :: POSIX :: Linux',
        'Programming Language :: Cython',
        'Programming Language :: Python',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Topic :: Software Development :: Libraries',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'Topic :: System :: Distributed Computing',
    ],

    ## Packaging mechanism info

    packages=["pyslurm"],

    # this is deprecated in favor of the pyproject.toml
    # setup_requires = ['cython'],

    # this shouldn't be true
    # install_requires=["Cython"],
    ext_modules=extensions,
    # cmdclass = {'build_ext' : Cython.Build.build_ext},

    # this is needed for the pxd files
    zip_safe=False,

)

