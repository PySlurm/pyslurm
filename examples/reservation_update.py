#!/usr/bin/env python
"""
Update Slurm reservations
"""

import pyslurm

try:
    a = pyslurm.reservation()
    res_dict = pyslurm.create_reservation_dict()

    res_dict["name"] = "res_test"
    res_dict["duration"] = 8000

    a.update(res_dict)

except ValueError as value_error:
    print(f"Error - {value_error.args[0]}")
else:
    print(f"Reservation {res_dict['name']} updated")
