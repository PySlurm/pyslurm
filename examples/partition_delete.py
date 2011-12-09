#!/usr/bin/env python

import pyslurm

rc = pyslurm.slurm_delete_partition(2)
if rc == -1:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
elif rc == 0:
	print "Partition deleted"

