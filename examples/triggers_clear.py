#!/usr/bin/env python
"""
Remove trigger by trigger ID
"""

import pyslurm

TrigID = 5
a = pyslurm.trigger()

try:
    a.clear(TrigID)
except ValueError as value_error:
    print("Unable to clear trigger : {0}".format(value_error.args[0]))
else:
    print("TriggerID ({0}) cleared".format(TrigID))
