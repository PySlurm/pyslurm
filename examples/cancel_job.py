#!/usr/bin/env python

import pyslurm

try:
	rc = pyslurm.slurm_kill_job(51, 9, 0)
except ValueError as e:
	print 'Cancel job error - %s' % e
else:
	print "Success - cancelled job"
