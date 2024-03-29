#!/usr/bin/env python
"""
Cancel a scheduled job
"""

import pyslurm

try:
    rc = pyslurm.slurm_kill_job(51, 9, 0)
except ValueError as value_error:
    print(b"Cancel job error - {value_error.args[0]}")
else:
    print("Success - cancelled job")
