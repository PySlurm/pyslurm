#!/usr/bin/env python

import pyslurm

try:
	a = pyslurm.job()
	#print pyslurm.slurm_job_cpus_allocated_on_node("shivling")

	jobs =  a.get()
	print jobs
except ValueError as e:
	print 'Job list error - %s' % (e)
