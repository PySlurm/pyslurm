#!/usr/bin/env python

import time
import pyslurm

def reservation_display(reservation):
    if reservation:
        for key,value in reservation.items():
           print("\t{}={}".format(key, value))

if __name__ == "__main__":
    try:
        end = time.time()
        start = end - (30*24*60*60)
        print("start={}, end={}".format(start, end))
        reservations = pyslurm.slurmdb_reservations()
        reservations.set_reservation_condition(start, end)
        reservations_dict = reservations.get()
        if len(reservations_dict):
            for key, value in reservations_dict.items():
                print("{} Reservation: {}".format('{', key))
                reservation_display(value)
                print("}")
        else:
            print("No reservation found")
    except ValueError as e:
        print("Error:{}".format(e.args[0]))

