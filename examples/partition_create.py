#!/usr/bin/env python
"""
Create a slurm partition.
"""

import pyslurm

a = pyslurm.partition()
partition_dict = pyslurm.create_partition_dict()
partition_dict["Name"] = "part_test"

try:
    a.create(partition_dict)
except ValueError as e:
    print(f"Partition create failed - {e.args[0]}")
else:
    print(f"Partition {partition_dict['Name']} successfully created")

    a.get()
    print()
    print(f"Partition IDs - {a.ids()}")
