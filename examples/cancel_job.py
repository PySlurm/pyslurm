#!/usr/bin/env python

import pyslurm

rc = pyslurm.slurm_kill_job(51, 9, 0)
if rc == -1:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
else:
	print "Success - cancelled job" 

