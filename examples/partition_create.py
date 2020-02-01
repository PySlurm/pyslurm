#!/usr/bin/env python
"""
Create a slurm partition.
"""
from __future__ import print_function

import pyslurm

a = pyslurm.partition()
partition_dict = pyslurm.create_partition_dict()
partition_dict["Name"] = "part_test"

try:
    a.create(partition_dict)
except ValueError as e:
    print("Partition create failed - {0}".format(e.args[0]))
else:
    print("Partition {0} successfully created".format(partition_dict["Name"]))

    a.get()
    print()
    print("Partition IDs - {0}".format(a.ids()))
