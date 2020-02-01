#!/usr/bin/env python
"""
Class to access/modify Slurm Job Information.
"""
from __future__ import print_function

import pyslurm

try:
    a = pyslurm.job()

    jobs = a.get()
    print(jobs)
except ValueError as value_error:
    print("Job list error - {0}".format(value_error.args[0]))
