#!/usr/bin/env python
"""
Delete Slurm reservations
"""
from __future__ import print_function

import pyslurm

resName = "res_test"
try:
    rc = pyslurm.slurm_delete_reservation(resName)
except ValueError as value_error:
    print("Reservation ({0}) delete failed - {1}".format(resName, value_error.args[0]))
else:
    print("Reservation {0} deleted".format(resName))
