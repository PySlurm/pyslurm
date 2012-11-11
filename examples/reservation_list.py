#!/usr/bin/env python

import pyslurm
import datetime
import time

def display(res_dict):

	if len(res_dict) > 0:

		
		nowTuple = datetime.datetime.now()
		nowEpoch = time.mktime(nowTuple.timetuple())

		date_fields = ['end_time', 'start_time']

		for key, value in res_dict.iteritems():

			print "Res ID : %s" % (key)
			for res_key in sorted(value.iterkeys()):

				if res_key in date_fields:

					if value[res_key] == 0:
						print "\t%-20s : N/A" % (res_key)
					else:
						ddate = pyslurm.epoch2date(value[res_key])
						print "\t%-20s : %s" % (res_key, ddate)
				elif res_key == 'flags':
					print "\t%-20s : (%s, %s)" % (res_key, value[res_key], pyslurm.get_res_state(value[res_key]))
				else:
					print "\t%-20s : %s" % (res_key, value[res_key])
			state = 'INACTIVE'
			if value['start_time'] < nowEpoch and value['end_time'] > nowEpoch:
				state = 'ACTIVE'
			print "\t%-20s : %s" % ('state', state)

		print "-" * 80
		

if __name__ == "__main__":

	a = pyslurm.reservation()
	res_dict = a.get()

	if len(res_dict) > 0:

		display(res_dict)

		print "Res IDs - %s" % a.ids()

	else:
		print "No reservations found !"

