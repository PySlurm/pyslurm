#!/usr/bin/env python

from __future__ import print_function

import pyslurm

try:
    rc = pyslurm.slurm_kill_job(51, 9, 0)
except ValueError as e:
    print("Cancel job error - {0}".format(e.args[0]))
else:
    print("Success - cancelled job")
