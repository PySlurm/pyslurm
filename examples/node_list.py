#!/usr/bin/env python
"""
List Slurm nodes
"""


def display(node_dict):
    """Format output"""
    if node_dict:

        date_fields = ["boot_time", "slurmd_start_time", "last_update", "reason_time"]

        print("{'':*^80}")
        for key, value in node_dict.items():

            print(f"{key} :")
            for part_key in sorted(value.items()):

                if part_key in date_fields:
                    ddate = value[part_key]
                    if ddate == 0:
                        print(f"\t{part_key:<17} : N/A")
                    else:
                        ddate = pyslurm.epoch2date(ddate)
                        print(f"\t{part_key:<17} : {ddate}")
                elif "reason_uid" in part_key and value["reason"] is None:
                    print(f"\t{part_key[0]:<17} : ")
                else:
                    print(f"\t{part_key[0]:<17} : {part_key[1]}")

            print(f"{'':*^80}")


if __name__ == "__main__":

    import pyslurm

    try:
        Nodes = pyslurm.node()
        new_node_dict = Nodes.get()

        if new_node_dict:
            display(new_node_dict)
            print()
            print(f"Node IDs - {Nodes.ids()}")
        else:
            print("No Nodes found !")

    except ValueError as e:
        print(f"Error - {e.args[0]}")
