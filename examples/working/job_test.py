#!/usr/bin/env python

import pyslurm

a = pyslurm.job()

#print pyslurm.slurm_job_cpus_allocated_on_node("shivling")
a.__cpus_allocated_on_node("shivling")

jobs =  a.get()
print jobs
