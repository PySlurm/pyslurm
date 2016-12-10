"""
PySlurm: Python bindings for the Slurm C API
============================================

PySlurm is a Cython wrapper around Slurm C API functions.

More information about Slurm can be found at http://slurm.schedmd.com.

Extensions
----------

::

    config       ---  Slurm Control Configuration Read/Print/Update Functions
    hostlist     ---  Slurm Hostlist Functions
    job          ---  Slurm Job Control Configuration Read/Print/Update Functions
    jobstep      ---  Slurm Job Step Configuration Read/Print/Update Functions
    license      ---  Slurm License Read Functions
    node         ---  Slurm Node Configuration Read/Print Functions
    partition    ---  Slurm Partition Configuration Read/Print/Update Functions
    powercap     ---  Slurm Powercapping Read/Print/Update Functions
    reservation  ---  Slurm Reservation Configuration Read/Print/Update Functions
    statistics   ---  Slurm Scheduler Diagnostic Functions
    topology     ---  Slurm Switch Topology Configuration Read/Print Functions

"""
import sys
import ctypes

__version__ = "dev-16.05-props"

sys.setdlopenflags(sys.getdlopenflags() | ctypes.RTLD_GLOBAL)

from . import account
from . import config
from . import job
from . import jobstep
from . import hostlist
from . import license
from . import misc
from . import node
from . import partition
from . import powercap
from . import reservation
from . import statistics
from . import topology
