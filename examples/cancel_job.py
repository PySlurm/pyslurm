#!/usr/bin/env python
"""
Cancel a scheduled job
"""
from __future__ import print_function

import pyslurm

try:
    rc = pyslurm.slurm_kill_job(51, 9, 0)
except ValueError as value_error:
    print("Cancel job error - {0}".format(value_error.args[0]))
else:
    print("Success - cancelled job")
