#!/usr/bin/env python
"""
Display Slurm statistics
"""
from __future__ import print_function

import pyslurm


def display(stats_dict):
    """Format output"""
    if stats_dict:
        print("{0:*^80}".format(" Slurm Controller Statistics "))
        for key, value in stats_dict.items():
            if key in ["bf_when_last_cycle", "req_time", "req_time_start"]:
                ddate = value
                if ddate == 0:
                    print("{0:<25} : N/A".format(key))
                else:
                    ddate = pyslurm.epoch2date(ddate)
                    print("{0:<25} : {1:<17}".format(key, ddate))
            elif key in ["rpc_user_stats", "rpc_type_stats"]:
                label = "rpc_user_id"
                if key == "rpc_type_stats":
                    label = "rpc_type_id"
                print("{0:<25} :".format(key))
                for rpc_key, rpc_val in value.items():
                    print("\t{0:<12} : {1:<15}".format(label, rpc_key))
                    for rpc_val_key, rpc_value in rpc_val.items():
                        print("\t\t{0:<12} : {1:<15}".format(rpc_val_key, rpc_value))
            else:
                print("{0:<25} : {1:<17}".format(key, value))

        print("{0:*^80}".format(""))
    else:
        print("No Stats found !")


if __name__ == "__main__":
    try:
        stats = pyslurm.statistics()
        s = stats.get()
        display(s)
    except ValueError as value_error:
        print("Error - {0}".format(value_error.args[0]))
