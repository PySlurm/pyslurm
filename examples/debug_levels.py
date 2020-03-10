#!/usr/bin/env python
"""
How to set Slurm debug level
"""
from __future__ import print_function

import pyslurm

SLURM_DEBUG = 1
SCHED_DEBUG = 0

try:
    print("Setting Slurmd debug level to {0}".format(SLURM_DEBUG))
    rc = pyslurm.slurm_set_debug_level(SLURM_DEBUG)
    if rc == 0:
        print("\tSuccess...Slurmd debug level updated to {0}".format(SLURM_DEBUG))
except ValueError as value_error:
    print("\tError - {0}".format(value_error.args[0]))

try:
    print("Setting Schedlog debug level to {0}".format(SCHED_DEBUG))
    rc = pyslurm.slurm_set_schedlog_level(SCHED_DEBUG)
    if rc == 0:
        print("\tSuccess...Schedlog log level updated to {0}".format(SCHED_DEBUG))
except ValueError as value_error:
    print("\tError - {0}".format(value_error.args[0]))
