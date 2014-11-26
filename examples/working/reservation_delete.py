#!/usr/bin/env python

import pyslurm

rc = pyslurm.slurm_delete_reservation("root_1")
if rc != 0:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
