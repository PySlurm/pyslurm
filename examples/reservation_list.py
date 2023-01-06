#!/usr/bin/env python
"""
List Slurm reservations
"""

import time

import pyslurm


def display(res_dict):
    """Format output"""
    if res_dict:

        date_fields = ["end_time", "start_time"]

        for res_key, res_value in res_dict.items():

            print(f"{res_key} :")
            for reservation in sorted(res_value.keys()):

                if reservation in date_fields:

                    if res_value[reservation] == 0:
                        print(f"\t{reservation:<20} : N/A")
                    else:
                        ddate = pyslurm.epoch2date(res_value[reservation])
                        print(f"\t{reservation:<20} : {ddate}")
                else:
                    print(f"\t{reservation:<20} : {res_value[reservation]}")

        print(f"{'':*^80}")

        now = int(time.time())
        resv_state = "INACTIVE"
        if res_value["start_time"] <= now <= res_value["end_time"]:
            resv_state = "ACTIVE"

        print(f"\t{'state':<20s} : {resv_state}\n")


if __name__ == "__main__":

    try:
        a = pyslurm.reservation()
        new_res_dict = a.get()

        if len(new_res_dict) > 0:
            display(new_res_dict)
            print(f"Res IDs - {a.ids()}")
        else:
            print("No reservations found !")
    except ValueError as value_error:
        print(f"Error - {value_error.args[0]}")
