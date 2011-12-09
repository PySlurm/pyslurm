#!/usr/bin/env python

import pyslurm

a = pyslurm.partition()
partition_dict = pyslurm.create_partition_dict()
partition_dict['Name'] ='mark'

rc = a.create(partition_dict)
if rc == -1:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
elif rc == 0:
	print "Partition %s created" % partition_dict["Name"]

	a.get()
	print 
	print "Partition IDs - %s" % a.ids() 
