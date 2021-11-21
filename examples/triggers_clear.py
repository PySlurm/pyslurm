#!/usr/bin/env python
"""
Remove trigger by trigger ID
"""

import pyslurm

TRIGID = 5
a = pyslurm.trigger()

try:
    a.clear(TRIGID)
except ValueError as value_error:
    print(f"Unable to clear trigger : {value_error.args[0]}")
else:
    print(f"TriggerID ({TRIGID}) cleared")
