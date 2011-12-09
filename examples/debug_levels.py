#!/usr/bin/env python

import pyslurm

SLURM_DEBUG=1
SCHED_DEBUG=0

rc = pyslurm.slurm_set_debug_level(SLURM_DEBUG)
if rc == -1:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
elif rc == 0:
	print "Slurmd debug level updated to %s" % SLURM_DEBUG 

rc = pyslurm.slurm_set_schedlog_level(SCHED_DEBUG)
if rc == -1:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
elif rc == 0:
	print "Schedlog log level updated to %s" % SCHED_DEBUG 


