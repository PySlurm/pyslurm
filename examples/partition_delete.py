#!/usr/bin/env python

import pyslurm

try:
	pyslurm.slurm_delete_partition("mark")
except ValueError as e:
        print 'Partition delete failed - %s' % (e)
else:
        print "Partition deleted"
