#!/usr/bin/env python
"""
Manipulate Slurm configuration
"""
from __future__ import print_function

import sys

import pyslurm

try:
    a = pyslurm.config()
    ctl_dict = a.get()
except ValueError as value_error:
    print("Error - {0}".format(value_error.args[0]))
    sys.exit(1)

date_fields = ["boot_time", "last_update"]
for key in sorted(ctl_dict.items()):

    if key in date_fields:

        if ctl_dict[key] == 0:
            print("\t{0:<35} : N/A".format(key))
        else:
            ddate = pyslurm.epoch2date(ctl_dict[key])
            print("\t{0:<35} : {1}".format(key, ddate))

    elif "debug_flags" in key:
        print("\t{0:<35s} : {1}".format(key[0], pyslurm.get_debug_flags(key[1])))
    else:
        if "key_pairs" not in key:
            print("\t{0:<35} : {1}".format(key[0], key[1]))

if "key_pairs" in ctl_dict:
    print("\nAdditional Information :\n------------------------\n")
    for key in sorted(ctl_dict["key_pairs"].items()):
        print("\t{0:<35} : {1}".format(key, ctl_dict["key_pairs"][key]))
