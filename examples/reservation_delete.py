#!/usr/bin/env python

import pyslurm

try:
	rc = pyslurm.slurm_delete_reservation("root_1")
except ValueError as e:
        print 'Reservation delete failed - %s' % (e)
else:
	print 'Reservation deleted'
