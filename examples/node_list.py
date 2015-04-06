#!/usr/bin/env python

def display(node_dict):

	if node_dict:

		date_fields = [ 'boot_time', 'slurmd_start_time', 'last_update', 'reason_time' ]

		print "-" * 80
		for key, value in node_dict.iteritems():

			print "%s :" % (key)
			for part_key in sorted(value.iterkeys()):

				if part_key in date_fields:

					ddate = value[part_key]
					if ddate == 0:
						print "\t%-17s :" % (part_key)
					else:
						ddate = pyslurm.epoch2date(ddate)
						print "\t%-17s : %s" % (part_key, ddate)

				elif ('reason_uid' in part_key and value['reason'] is None):
					print "\t%-17s :" % part_key
				elif ('cpu_load' in part_key):
					if value[part_key] == pyslurm.NO_VAL:
						print "\t%-17s :" % (part_key)
					else:
						print "\t%-17s : %.2f" % (part_key, value[part_key]/100)
				else: 
					print "\t%-17s : %s" % (part_key, value[part_key])

			print "-" * 80


if __name__ == "__main__":

	import pyslurm

	try:

		Nodes = pyslurm.node()
		node_dict = Nodes.get()

		if len(node_dict) > 0:

			display(node_dict)

			print
			print "Node IDs - %s" % Nodes.ids()

		else:
	
			print "No Nodes found !"

        except ValueError as e:
                print 'Error - %s' % (e)	
