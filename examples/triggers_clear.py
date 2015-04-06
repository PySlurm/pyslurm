#!/usr/bin/env python

import pyslurm

TrigID = 5
a = pyslurm.trigger()

try:
	a.clear(TrigID)
except ValueError as e:
        print "Unable to clear trigger : %s" % (e)
else:
	print "TriggerID (%s) cleared" % TrigID

