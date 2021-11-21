#!/usr/bin/env python
"""
How to set Slurm debug level
"""

import pyslurm

SLURM_DEBUG = 1
SCHED_DEBUG = 0

try:
    print(f"Setting Slurmd debug level to {SLURM_DEBUG}")
    rc = pyslurm.slurm_set_debug_level(SLURM_DEBUG)
    if rc == 0:
        print(f"\tSuccess...Slurmd debug level updated to {SLURM_DEBUG}")
except ValueError as value_error:
    print(f"\tError - {value_error.args[0]}")

try:
    print(f"Setting Schedlog debug level to {SCHED_DEBUG}")
    rc = pyslurm.slurm_set_schedlog_level(SCHED_DEBUG)
    if rc == 0:
        print(f"\tSuccess...Schedlog log level updated to {SCHED_DEBUG}")
except ValueError as value_error:
    print(f"\tError - {value_error.args[0]}")
