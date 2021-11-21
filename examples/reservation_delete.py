#!/usr/bin/env python
"""
Delete Slurm reservations
"""

import pyslurm

RESNAME = "res_test"
try:
    rc = pyslurm.slurm_delete_reservation(RESNAME)
except ValueError as value_error:
    print(f"Reservation ({RESNAME}) delete failed - {value_error.args[0]}")
else:
    print(f"Reservation {RESNAME} deleted")
