#!/usr/bin/env python
"""
Update a given Slurm partitions
"""

import pyslurm

part_dict = pyslurm.create_partition_dict()

part_dict["Name"] = "part_test"
part_dict["State"] = "DOWN"
part_dict["Reason"] = "API test"

try:
    a = pyslurm.slurm_update_partition(part_dict)
except ValueError as e:
    print(f"Partition update failed - {e.args[0]}")
else:
    print("Partition update successful !")
