#!/usr/bin/env python

import pyslurm

import sys
if len(sys.argv) != 2:
	print "Error. Wrong number of parameters"
	sys.exit(1)
trigID=int(sys.argv[1])

a = pyslurm.trigger()
rc = a.clear(trigID)

if rc != 0:
	rc = pyslurm.slurm_get_errno()
	print "Unable to clear trigger : %s" % pyslurm.slurm_strerror(rc)
else:
	print "TriggerID (%s) cleared" % trigID 

