#!/usr/bin/env python

import pyslurm

SLURM_DEBUG=1
SCHED_DEBUG=0

print "Setting Slurmd debug level to %s..." % SLURM_DEBUG
rc = pyslurm.slurm_set_debug_level(SLURM_DEBUG)
if rc == -1:
	print "\tError : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
elif rc == 0:
	print "\tSuccess"

print "Setting Sched log level to %s..." % SCHED_DEBUG
rc = pyslurm.slurm_set_schedlog_level(SCHED_DEBUG)
if rc == -1:
	print "\tError : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
elif rc == 0:
	print "\tSuccess"


