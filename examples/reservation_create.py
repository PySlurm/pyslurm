#!/usr/bin/env python
"""
Create a Slurm reservation
"""
from __future__ import print_function

import sys
import time

import pyslurm

epoch_now = int(time.time())

a = pyslurm.reservation()
res_dict = pyslurm.create_reservation_dict()
res_dict["node_cnt"] = 1
res_dict["users"] = "root"
res_dict["start_time"] = epoch_now
res_dict["duration"] = 600
res_dict["name"] = "res_test"

try:
    resid = a.create(res_dict)
except ValueError as value_error:
    print("Reservation creation failed - {0}".format(value_error.args[0]))
else:
    print("Success - Created reservation {0}\n".format(resid))

    res_dict = a.get()
    if res_dict.get(resid):

        date_fields = ["end_time", "start_time"]

        value = res_dict[resid]
        print("Res ID : {0}".format(resid))
        for res_key in sorted(value.keys()):

            if res_key in date_fields:

                if value[res_key] == 0:
                    print("\t{0:<20} : N/A".format(res_key))
                else:
                    ddate = pyslurm.epoch2date(value[res_key])
                    print("\t{0:<20} : {1}".format(res_key, ddate))
            else:
                print("\t{0:<20} : {1}".format(res_key, value[res_key]))

        print("{0:-^80}".format(""))

    else:
        print("No reservation {0} found !".format(resid))
        sys.exit(-1)

    print()
    print("{0:-^80}".format(" All Reservations "))
    a.print_reservation_info_msg()
    print("{0:-^80}".format(""))
