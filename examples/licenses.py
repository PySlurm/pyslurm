#!/usr/bin/env python

from __future__ import print_function

def display(lic_dict):

    if lic_dict:
        print("State last updated : {0}".format(slurm.epoch2date(licenses.lastUpdate())))
        print('{0:*^80}'.format(''))

        for key, value in lic_dict.items():

            print("{0} :".format(key))
            for part_key in sorted(value.keys()):

                print("\t{0:<17} : {1}".format(part_key, value[part_key]))

            print('{0:*^80}'.format(''))
    else:
        print("No Licenses found !")

if __name__ == "__main__":

    import pyslurm as slurm
    import sys
    import time

    try:
        licenses = slurm.licenses()
        lic = licenses.get()
        old = licenses.lastUpdate()

        new = old
        display(lic)

        while 1:
            time.sleep(1)
            lic = licenses.get()
            new = licenses.lastUpdate()
            if new > old:
                old  = new
                print('{0:*^80}'.format(''))
                display(lic)
                print('{0:*^80}'.format(''))
    except ValueError as e:
        print("License error : {0}".format(e.args[0]))
        sys.exit(-1)
    except KeyboardInterrupt:
        print("Exiting....")
        sys.exit()
