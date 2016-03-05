#!/usr/bin/env python

from __future__ import print_function

import pyslurm

TrigID = 5
a = pyslurm.trigger()

try:
    a.clear(TrigID)
except ValueError as e:
    print("Unable to clear trigger : {0}".format(e.args[0]))
else:
    print("TriggerID ({0}) cleared".format(TrigID))

