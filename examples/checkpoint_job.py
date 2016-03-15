#!/usr/bin/env python

from __future__ import print_function

import pyslurm

try:
    time = pyslurm.slurm_checkpoint_able(2,0)
except ValueError as e:
    print("Checkpointable job failed - {0}".format(e.args[0]))
else:
    print("Job can be checkpointed at {0}".format(time))
