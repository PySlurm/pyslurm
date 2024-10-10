"""pyslurm package

pyslurm is a wrapper around the Slurm C-API.
"""
from __future__ import absolute_import

import os
import sys

sys.setdlopenflags(sys.getdlopenflags() | os.RTLD_GLOBAL | os.RTLD_DEEPBIND )

# Initialize slurm api
from pyslurm.api import slurm_init, slurm_fini
slurm_init()

from .pyslurm import *
from .__version__ import __version__

from pyslurm import db
from pyslurm import utils
from pyslurm import constants

from pyslurm.core.job import (
    Job,
    Jobs,
    JobStep,
    JobSteps,
    JobSubmitDescription,
)
from pyslurm.core.node import Node, Nodes
from pyslurm.core.partition import Partition, Partitions
from pyslurm.core import error
from pyslurm.core.error import (
    PyslurmError,
    RPCError,
)
from pyslurm.core import slurmctld


def version():
    return __version__
