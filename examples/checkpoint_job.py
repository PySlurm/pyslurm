#!/usr/bin/env python

import pyslurm

try:
	time = pyslurm.slurm_checkpoint_able(2,0)
except ValueError as e:
        print 'Checkpointable job failed - %s' % (e)
else:
	print "Job can be checkpointed at %" % time
