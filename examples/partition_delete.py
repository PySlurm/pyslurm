#!/usr/bin/env python
"""
Delete a given slurm partition
"""

import pyslurm

PARTITION = "part_test"

try:
    pyslurm.slurm_delete_partition(PARTITION)
except ValueError as e:
    print(f"Partition ({PARTITION}) delete failed - {e.args[0]}")
else:
    print(f"Partition ({PARTITION}) deleted")
