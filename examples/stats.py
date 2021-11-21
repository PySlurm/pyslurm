#!/usr/bin/env python
"""
Display Slurm statistics
"""

import pyslurm


def display(stats_dict):
    """Format output"""
    if stats_dict:
        print(f"{' Slurm Controller Statistics ':*^80}")
        for key, value in stats_dict.items():
            if key in ["bf_when_last_cycle", "req_time", "req_time_start"]:
                ddate = value
                if ddate == 0:
                    print(f"{key:<25} : N/A")
                else:
                    ddate = pyslurm.epoch2date(ddate)
                    print(f"{key:<25} : {ddate:<17}")
            elif key in ["rpc_user_stats", "rpc_type_stats"]:
                label = "rpc_user_id"
                if key == "rpc_type_stats":
                    label = "rpc_type_id"
                print("{key:<25} :")
                for rpc_key, rpc_val in value.items():
                    print(f"\t{label:<12} : {rpc_key:<15}")
                    for rpc_val_key, rpc_value in rpc_val.items():
                        print(f"\t\t{rpc_val_key:<12} : {rpc_value:<15}")
            else:
                print(f"{key:<25} : {value:<17}")

        print("{'':*^80}")
    else:
        print("No Stats found !")


if __name__ == "__main__":
    try:
        stats = pyslurm.statistics()
        s = stats.get()
        display(s)
    except ValueError as value_error:
        print(f"Error - {value_error.args[0]}")
