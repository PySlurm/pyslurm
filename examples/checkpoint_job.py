#!/usr/bin/env python
"""
Retrieve a jobs checkpoint status
"""

import pyslurm

try:
    time = pyslurm.slurm_checkpoint_able(2, 0)
except ValueError as value_error:
    print(f"Checkpointable job failed - {value_error.args[0]}")
else:
    print(f"Job can be checkpointed at {format(time)}")
