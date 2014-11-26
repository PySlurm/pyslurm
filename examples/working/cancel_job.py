#!/usr/bin/env python
import pyslurm

import sys
if len(sys.argv) != 2:
	print "Error. Wrong number of parameters"
	sys.exit(1)
jobID=int(sys.argv[1])
	
rc = pyslurm.slurm_kill_job(jobID, 9, 0)
if rc == -1:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
	sys.exit(1)
else:
	print "Success - cancelled job" 

