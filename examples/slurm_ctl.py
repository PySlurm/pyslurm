#!/usr/bin/env python
"""
Manipulate Slurm configuration
"""

import sys

import pyslurm

try:
    a = pyslurm.config()
    ctl_dict = a.get()
except ValueError as value_error:
    print(f"Error - {0}")
    sys.exit(1)

date_fields = ["boot_time", "last_update"]
for key in sorted(ctl_dict.items()):

    if key in date_fields:

        if ctl_dict[key] == 0:
            print(f"\t{key:<35} : N/A")
        else:
            ddate = pyslurm.epoch2date(ctl_dict[key])
            print("\t{key:<35} : {ddate}")

    elif "debug_flags" in key:
        print(f"\t{key[0]:<35s} : {pyslurm.get_debug_flags(key[1])}")
    else:
        if "key_pairs" not in key:
            print(f"\t{key[0]:<35} : {key[1]}")

if "key_pairs" in ctl_dict:
    print("\nAdditional Information :\n------------------------\n")
    for key in sorted(ctl_dict["key_pairs"].items()):
        print(f"\t{key:<35} : {ctl_dict}")
