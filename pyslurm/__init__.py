"""pyslurm package

pyslurm is a wrapper around the Slurm C-API.
"""
from __future__ import absolute_import

import ctypes
import sys

sys.setdlopenflags(sys.getdlopenflags() | ctypes.RTLD_GLOBAL)

from .pyslurm import *
from .__version__ import __version__

from pyslurm.core.job import (
    Job,
    Jobs,
    JobStep,
    JobSteps,
    JobSubmitDescription,
)

from pyslurm import db
from pyslurm.core.node import Node, Nodes

from pyslurm.core import error
from pyslurm.core.error import (
    RPCError,
)

# Utility time functions
from pyslurm.core.common.ctime import (
    timestr_to_secs,
    timestr_to_mins,
    secs_to_timestr,
    mins_to_timestr,
    date_to_timestamp,
    timestamp_to_date,
)

# General utility functions
from pyslurm.core.common import (
    uid_to_name,
    gid_to_name,
    user_to_uid,
    group_to_gid,
    expand_range_str,
    humanize,
    dehumanize,
    nodelist_from_range_str,
    nodelist_to_range_str,
)

from pyslurm.core import slurmctld

# Initialize slurm api
from pyslurm.api import slurm_init, slurm_fini
slurm_init()


def version():
    return __version__
