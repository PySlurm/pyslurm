#!/usr/bin/env python

import pyslurm

part_dict = pyslurm.create_partition_dict()

part_dict['Name'] = 'compute'
part_dict['State'] = 'DOWN'
part_dict['Reason'] = 'API test'

try:
	a = pyslurm.slurm_update_partition(part_dict)
except ValueError as e:
        print 'Partition update failed - %s' % (e)
else:
	print "Partition update successful !"rint "Successful !"
