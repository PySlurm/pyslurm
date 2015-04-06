#!/usr/bin/env python

import pyslurm

SLURM_DEBUG=1
SCHED_DEBUG=0

try:
	print "Setting Slurmd debug level to %s" % SLURM_DEBUG
	rc = pyslurm.slurm_set_debug_level(SLURM_DEBUG)
	if rc == 0:
		print "\tSuccess...Slurmd debug level updated to %s" % SLURM_DEBUG 
except ValueError as e:
	print '\tError - %s' % (e)

try:
	print "Setting Schedlog debug level to %s" % SCHED_DEBUG
	rc = pyslurm.slurm_set_schedlog_level(SCHED_DEBUG)
	if rc == 0:
		print "\tSuccess...Schedlog log level updated to %s" % SCHED_DEBUG 
except ValueError as e:
	print '\tError - %s' % (e)

