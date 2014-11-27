#!/usr/bin/env python

import pyslurm

import sys
if len(sys.argv) != 2:
	print "Error. Wrong number of parameters"
	sys.exit(1)
jobID=int(sys.argv[1])


rc, Time = pyslurm.slurm_checkpoint_able(jobID,0)
if rc != 0:
	print "Error : %s" % pyslurm.slurm_strerror(rc)
else:
	print "Job can be checkpointed"

