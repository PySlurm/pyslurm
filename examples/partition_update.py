#!/usr/bin/env python
"""
Update a given Slurm partitions
"""
from __future__ import print_function

import pyslurm

part_dict = pyslurm.create_partition_dict()

part_dict["Name"] = "part_test"
part_dict["State"] = "DOWN"
part_dict["Reason"] = "API test"

try:
    a = pyslurm.slurm_update_partition(part_dict)
except ValueError as e:
    print("Partition update failed - {0}".format(e.args[0]))
else:
    print("Partition update successful !")
