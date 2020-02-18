#!/usr/bin/env python
"""
Retrieve a jobs checkpoint status
"""
from __future__ import print_function

import pyslurm

try:
    time = pyslurm.slurm_checkpoint_able(2, 0)
except ValueError as value_error:
    print("Checkpointable job failed - {0}".format(value_error.args[0]))
else:
    print("Job can be checkpointed at {0}".format(time))
