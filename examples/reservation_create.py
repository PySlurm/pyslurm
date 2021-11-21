#!/usr/bin/env python
"""
Create a Slurm reservation
"""

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
    print(f"Reservation creation failed - {value_error.args[0]}")
else:
    print(f"Success - Created reservation {format(resid)}\n")

    res_dict = a.get()
    if res_dict.get(resid):

        date_fields = ["end_time", "start_time"]

        value = res_dict[resid]
        print(f"Res ID : {resid}")
        for res_key in sorted(value.keys()):

            if res_key in date_fields:

                if value[res_key] == 0:
                    print(f"\t{res_key:<20} : N/A")
                else:
                    ddate = pyslurm.epoch2date(value[res_key])
                    print(f"\t{res_key:<20} : {ddate}")
            else:
                print(f"\t{res_key:<20} : {value[res_key]}")

        print(f"{'':-^80}")

    else:
        print(f"No reservation {resid} found !")
        sys.exit(-1)

    print()
    print(f"{' All Reservations ':-^80}")
    a.print_reservation_info_msg()
    print(f"{'':-^80}")
