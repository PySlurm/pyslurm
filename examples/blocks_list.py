#!/usr/bin/env python

from __future__ import print_function

import pyslurm
from time import gmtime, strftime

def display(block_dict):

    if block_dict:

        date_fields = [ ]

        print('{0:*^80}'.format(''))

        for key, value in block_dict.items():

            print("{0} :".format(key))
            for part_key in sorted(value.items()):

                if part_key in date_fields:
                    ddate = value[part_key]
                    if ddate == 0:
                        print("\t{0:<17} : N/A".format(part_key))
                    elif ('reason_uid' in part_key) and (value['reason'] is None):
                        print("\t{0:<17} :".format(part_key))
                    else:
                        ddate = pyslurm.epoch2date(ddate)
                        print("\t{0:<17} : {1}".format(part_key, ddate))
                elif part_key == 'connection_type':
                    print("\t{0:<17} : {1}".format(part_key, pyslurm.get_connection_type(value[part_key])))
                elif part_key == 'state':
                    print("\t{0:<17} : {1}".format(part_key, value[part_key]))
                else:
                    print("\t{0:<17} : {1}".format(part_key, value[part_key]))

            print('{0:*^80}'.format(''))


if __name__ == "__main__":

    a = pyslurm.block()
    try:
        a.load()
        block_dict = a.get()
    except ValueError as e:
        print("Block query failed - {0}".format(e.args[0]))
    else:
        if len(block_dict) > 0:

            display(block_dict)
            print()
            print("Block IDs - {0}".format(a.ids()))
            print()

        else:
            print("No Blocks found !")
