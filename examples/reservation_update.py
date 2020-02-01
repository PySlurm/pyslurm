#!/usr/bin/env python
"""
Update Slurm reservations
"""
from __future__ import print_function

import pyslurm

try:
    a = pyslurm.reservation()
    res_dict = pyslurm.create_reservation_dict()

    res_dict["name"] = "res_test"
    res_dict["duration"] = 8000

    a.update(res_dict)

except ValueError as value_error:
    print("Error - {0}".format(value_error.args[0]))
else:
    print("Reservation {0} updated".format(res_dict["name"]))
