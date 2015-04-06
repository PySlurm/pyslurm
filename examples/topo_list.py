#!/usr/bin/env python

import pyslurm
from time import gmtime, strftime

try:
	a = pyslurm.topology()
	b = a.get()
except ValueError as e:
	print 'Topology error - %s' % (e)
else:
	if not b:
		print "No toplogy found"
	else:
		print b
