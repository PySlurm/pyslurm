#!/usr/bin/env python
"""
List Slurm partitions
"""


def display(part_dict):
    """Format output"""
    if part_dict:

        for key, value in part_dict.items():

            print(f"{key} :")

            for part_key in sorted(value.keys()):

                val_str = value[part_key]

                if "default_time" in part_key:

                    if isinstance(val_str, int):
                        val_str = f"{val_str/60} minutes"

                elif part_key in ["max_nodes", "max_time", "max_cpus_per_node"]:

                    if value[part_key] == "UNLIMITED":
                        val_str = "Unlimited"

                print(f"\t{part_key:20} : {val_str}")

            print(f"{'':*^80}")


if __name__ == "__main__":

    import pyslurm

    try:
        a = pyslurm.partition()
        new_part_dict = a.get()
    except ValueError as e:
        print(f"Partition error - {e.args[0]}")
    else:
        if new_part_dict:
            display(new_part_dict)
            print()
            print(f"Partition IDs - {a.ids()}")
            print()
        else:
            print("No partitions found !")
