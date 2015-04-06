#!/usr/bin/env python

import pyslurm

a = pyslurm.partition()
partition_dict = pyslurm.create_partition_dict()
partition_dict['Name'] ='mark'

try:
	a.create(partition_dict)
except ValueError as e:
        print 'Partition create failed - %s' % (e)
else:
        print "Partition %s successfully created" % partition_dict['Name']

	a.get()
	print 
	print "Partition IDs - %s" % a.ids() 
