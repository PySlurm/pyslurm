#!/usr/bin/env python
"""
Display Slurm cluster topology
"""

import pyslurm

try:
    a = pyslurm.topology()
    b = a.get()
except ValueError as value_error:
    print(f"Topology error - {value_error.args[0]}")
else:
    if not b:
        print("No topology found")
    else:
        print(b)
