#!/usr/bin/env python

def display(part_dict):

	if len(part_dict) > 0:

		for key, value in part_dict.iteritems():

			print "%s :" % key

			for part_key in sorted(value.iterkeys()):

				valStr = value[part_key]

				if 'default_time' in part_key:

					if value[part_key] == 0xffffffff:
						valStr = (value[part_key], "infinite")	
					elif value[part_key] == 0xfffffffe:
						valStr = (value[part_key], "no_value")
					else:
						valStr = (value[part_key], "%s minutes" % (value[part_key]/60) )

				elif part_key in [ 'max_nodes', 'max_time']:

					if value[part_key] == 0xffffffff:
						valStr = "Unlimited"
				elif part_key == 'state_up':
					valStr = pyslurm.get_partition_state(value[part_key])
				elif part_key == 'flags':
					valStr = pyslurm.get_partition_mode(value[part_key])
				elif part_key == 'last_update':
					valStr = pyslurm.epoch2date(value[part_key])

				print "\t%-20s : %s" % (part_key, valStr)

			print "-" * 80

if __name__ == "__main__":

	import pyslurm
	import time

	a = pyslurm.partition()
	part_dict = a.get()

	if len(part_dict) > 0:

		display(part_dict)

		print
		print "Partition IDs - %s" % a.ids()
		print
	else:
	
		print "No partitions found !"


