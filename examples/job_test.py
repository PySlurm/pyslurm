#!/usr/bin/env python
"""
Class to access/modify Slurm Job Information.
"""

import pyslurm

try:
    a = pyslurm.job()

    jobs = a.get()
    print(jobs)
except ValueError as value_error:
    print(f"Job list error - {value_error.args[0]}")
