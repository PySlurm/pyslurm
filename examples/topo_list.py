#!/usr/bin/env python

from __future__ import print_function

import pyslurm
from time import gmtime, strftime

try:
    a = pyslurm.topology()
    b = a.get()
except ValueError as e:
    print("Topology error - {0}".format(e.args[0]))
else:
    if not b:
        print("No topology found")
    else:
        print(b)
