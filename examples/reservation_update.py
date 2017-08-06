#!/usr/bin/env python

from __future__ import print_function

import pyslurm

try:
    a = pyslurm.reservation()
    res_dict = pyslurm.create_reservation_dict()

    res_dict["name"] = "res_test"
    res_dict["duration"] = 8000

    a.update(res_dict)

except ValueError as e:
    printl("Error - {0}".format(e.args[0]))
else:
    print("Reservation {0} updated".format(res_dict["name"]))
