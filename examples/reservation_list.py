#!/usr/bin/env python

from __future__ import print_function

import pyslurm
import datetime
import time

def display(res_dict):

    if len(res_dict) > 0:

        date_fields = ['end_time', 'start_time']

        for key, value in res_dict.items():

            print("{0} :".format(key))
            for res_key in sorted(value.keys()):

                if res_key in date_fields:

                    if value[res_key] == 0:
                        print("\t{0:<20} : N/A".format(res_key))
                    else:
                        ddate = pyslurm.epoch2date(value[res_key])
                        print("\t{0:<20} : {1}".format(res_key, ddate))
                else:
                        print("\t{0:<20} : {1}".format(res_key, value[res_key]))

        print('{0:*^80}'.format(''))

        now = int(time.time())
        resvState = "INACTIVE"

        if value['start_time'] <= now and value['end_time'] >= now:
            resvState = "ACTIVE"

        print("\t%-20s : %s\n" % ("state", resvState))

if __name__ == "__main__":

    try:
        a = pyslurm.reservation()
        res_dict = a.get()

        if len(res_dict) > 0:
            display(res_dict)
            print("Res IDs - {0}".format(a.ids()))
        else:
            print("No reservations found !")
    except ValueError as e:
        print("Error - {0}".format(e.args[0]))
