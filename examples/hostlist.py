#!/usr/bin/env python
"""
Retrieve Slurm hosts
"""

import pyslurm

b = pyslurm.hostlist()

HOSTS = "dummy0,dummy1,dummy1,dummy3,dummy4"
print(f"Creating hostlist ...... with {HOSTS}")
if b.create(HOSTS):
    print()
    print(f"\tHost list count is {b.count()}")
    NODE = "dummy3"
    pos = b.find(NODE)
    if pos == -1:
        print(f"Failed to find {NODE} in list")
    else:
        print(f"\tHost {NODE} found at position {pos}")
    print("\tCalling uniq on current host list")
    b.uniq()

    print(f"\tNew host list is {b.get()}")
    print(f"\tNew host list count is {b.count()}")
    pos = b.find(NODE)
    if pos == -1:
        print(f"Failed to find {NODE}")
    else:
        print(f"\tHost {NODE} found at position {pos}")

    print(f"\tRanged host list is {b.get()}")
    print()

    NODE = "dummy18"
    print(f"\tPushing new entry {NODE}")
    if b.push(NODE):
        print("\t\tSuccess !")
        print(f"\tNew ranged list is {b.get()}")
    else:
        print("\t\tFailed !")
    print()

    print("\tDropping first host from list")
    name = b.pop()
    if name:
        print(f"\t\tDropped host {name} from list")
        print(f"\t\tNew host count is {b.count()}")
        print(f"\t\tNew host list is {b.get()}")
    else:
        print("\t\tFailed !")

    print("Destroying host list")
    b.destroy()
    print(f"\tHost listcount is {b.count()}")

else:
    print("\tFailed to create initial list !")
