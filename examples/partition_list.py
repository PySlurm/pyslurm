#!/usr/bin/env python

def display(part_dict):

	if len(part_dict) > 0:

		for key, value in part_dict.iteritems():

			print "%s :" % key

			for part_key in sorted(value.iterkeys()):

				valStr = value[part_key]

				if 'default_time' in part_key:

					if isinstance(value[part_key], int):
						valStr = "%s minutes" % (value[part_key]/60)
					else:
						valStr = value[part_key]

				elif part_key in [ 'max_nodes', 'max_time']:

					if value[part_key] == 0xffffffff:
						valStr = "Unlimited"

				print "\t%-20s : %s" % (part_key, valStr)

			print "-" * 80

if __name__ == "__main__":

	import pyslurm
	import time

	try:
		a = pyslurm.partition()
		part_dict = a.get()
	except ValueError as e:
		print 'Partition error - %s' % (e)
	else:
		if len(part_dict) > 0:

			display(part_dict)

			print
			print "Partition IDs - %s" % a.ids()
			print
		else:
			print "No partitions found !"
