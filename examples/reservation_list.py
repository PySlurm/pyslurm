#!/usr/bin/env python

import pyslurm
import datetime

def display(res_dict):

	if len(res_dict) > 0:

		date_fields = ['end_time', 'start_time']

		for key, value in res_dict.iteritems():

			for res_key in sorted(value.iterkeys()):

				if res_key in date_fields:

					if value[res_key] == 0:
						print "\t%-20s : N/A" % (res_key)
					else:
						ddate = pyslurm.epoch2date(value[res_key])
						print "\t%-20s : %s" % (res_key, ddate)
				else:
						print "\t%-20s : %s" % (res_key, value[res_key])

		print "-" * 80
		

if __name__ == "__main__":

	try:
		a = pyslurm.reservation()
		res_dict = a.get()

		if len(res_dict) > 0:
			display(res_dict)
			print "Res IDs - %s" % a.ids()
		else:
			print "No reservations found !"
	except ValueError as e:
		print 'Error - %s' % (e)
