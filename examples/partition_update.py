#!/usr/bin/env python

import pyslurm

part_dict = pyslurm.create_partition_dict()

part_dict['Name'] = 'compute'
part_dict['State'] = 'DOWN'
part_dict['Reason'] = 'API test'

a = pyslurm.slurm_update_partition(part_dict)
if a == -1:
	print "Failed %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
else:
	print "Successful !"
