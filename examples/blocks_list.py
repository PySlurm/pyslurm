#!/usr/bin/env python
"""
Retrieve list of blocked items
"""

import pyslurm


def display(block_dict):
    """Format output"""
    if block_dict:

        date_fields = []

        print(f"{'':*^80}")

        for key, value in block_dict.items():

            print(f"{key} :")
            for part_key in sorted(value.items()):

                if part_key in date_fields:
                    ddate = value[part_key]
                    if ddate == 0:
                        print(f"\t{part_key:<17} : N/A")
                    elif ("reason_uid" in part_key) and (value["reason"] is None):
                        print(f"\t{part_key:<17} :")
                    else:
                        ddate = pyslurm.epoch2date(ddate)
                        print(f"\t{part_key:<17} : {ddate}")
                elif part_key == "connection_type":
                    print(
                        f"\t{part_key:<17} : {pyslurm.get_connection_type(value[part_key])}"
                    )
                elif part_key == "state":
                    print(f"\t{part_key:<17} : {value[part_key]}")
                else:
                    print(f"\t{part_key:<17} : {value[part_key]}")

            print(f"{'':*^80}")


if __name__ == "__main__":

    a = pyslurm.block()
    try:
        a.load()
        new_block_dict = a.get()
    except ValueError as value_error:
        print(f"Block query failed - {value_error.args[0]}")
    else:
        if new_block_dict:
            display(new_block_dict)
            print(f"\nBlock IDs - {a.ids()}\n")
        else:
            print("No Blocks found !")
