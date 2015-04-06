#!/usr/bin/env python

import pyslurm

try:
	a = pyslurm.reservation()
	res_dict = pyslurm.create_reservation_dict()

	res_dict["name"] = "root_10"
	res_dict["duration"] = 8000

	a.update(res_dict)

except ValueError as e:
	print 'Error - %s' % (e)
else:
	print "Reservation %s updated" % res_dict["name"]
