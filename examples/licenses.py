#!/usr/bin/env python

def display(lic_dict):

	if lic_dict:

		print licenses.ids()
		print "State last updated : %s" % slurm.epoch2date(licenses.lastUpdate())
		print "-" * 80
		for key, value in lic_dict.iteritems():

			print "%s :" % (key)
			for part_key in sorted(value.iterkeys()):

				print "\t%-17s : %s" % (part_key, value[part_key])

			print "-" * 80
	else:
		
		print "No Licenses found !"


if __name__ == "__main__":

	import pyslurm as slurm
	import sys
	import time

	try:

		licenses = slurm.licenses()
		lic = licenses.get()
		old = licenses.lastUpdate()

		new = old
		display(lic)

		while 1:
			time.sleep(1)
			lic = licenses.get()
			new = licenses.lastUpdate()
			if new > old:
				old  = new
				print "*****************"
				display(lic)
				print "*****************"

	except ValueError as e:
		print "License error : %s" % (e)
		sys.exit(-1)
	except KeyboardInterrupt:
		print "Exiting...."
		sys.exit()
