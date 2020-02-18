#!/usr/bin/env python
"""
Retrieve Slurm hosts
"""
from __future__ import print_function

import pyslurm

b = pyslurm.hostlist()

hosts = "dummy0,dummy1,dummy1,dummy3,dummy4"
print("Creating hostlist ...... with {0}".format(hosts))
if b.create(hosts):
    print()
    print("\tHost list count is {0}".format(b.count()))
    node = "dummy3"
    pos = b.find(node)
    if pos == -1:
        print("Failed to find {0} in list".format(node))
    else:
        print("\tHost {0} found at position {1}".format(node, pos))
    print("\tCalling uniq on current host list")
    b.uniq()

    print("\tNew host list is {0}".format(b.get()))
    print("\tNew host list count is {0}".format(b.count()))
    pos = b.find(node)
    if pos == -1:
        print("Failed to find {0} in list".format(node))
    else:
        print("\tHost {0} found at position {1}".format(node, pos))

    print("\tRanged host list is {0}".format(b.get()))
    print()

    node = "dummy18"
    print("\tPushing new entry {0}".format(node))
    if b.push(node):
        print("\t\tSuccess !")
        print("\tNew ranged list is {0}".format(b.get()))
    else:
        print("\t\tFailed !")
    print()

    print("\tDropping first host from list")
    name = b.pop()
    if name:
        print("\t\tDropped host {0} from list".format(name))
        print("\t\tNew host count is {0}".format(b.count()))
        print("\t\tNew host list is {0}".format(b.get()))
    else:
        print("\t\tFailed !")

    print("Destroying host list")
    b.destroy()
    print("\tHost listcount is {0}".format(b.count()))

else:
    print("\tFailed to create initial list !")
