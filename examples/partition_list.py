#!/usr/bin/env python
"""
List Slurm partitions
"""
from __future__ import print_function


def display(part_dict):
    """Format output"""
    if part_dict:

        for key, value in part_dict.items():

            print("{0} :".format(key))

            for part_key in sorted(value.keys()):

                valStr = value[part_key]

                if "default_time" in part_key:

                    if isinstance(value[part_key], int):
                        valStr = "{0} minutes".format(value[part_key] / 60)
                    else:
                        valStr = value[part_key]

                elif part_key in ["max_nodes", "max_time", "max_cpus_per_node"]:

                    if value[part_key] == "UNLIMITED":
                        valStr = "Unlimited"

                print("\t{0:<20} : {1}".format(part_key, valStr))

            print("{0:*^80}".format(""))


if __name__ == "__main__":

    import pyslurm

    try:
        a = pyslurm.partition()
        part_dict = a.get()
    except ValueError as e:
        print("Partition error - {0}".format(e.args[0]))
    else:
        if part_dict:
            display(part_dict)
            print()
            print("Partition IDs - {0}".format(a.ids()))
            print()
        else:
            print("No partitions found !")
