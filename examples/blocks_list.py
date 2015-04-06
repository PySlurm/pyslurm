#!/usr/bin/env python

import pyslurm
from time import gmtime, strftime

def display(block_dict):

	if block_dict:

     
		date_fields = [ ]
      
		print "-" * 80
      
		for key, value in block_dict.iteritems():

			print "%s :" % (key)
			for part_key in sorted(value.iterkeys()):

				if part_key in date_fields:
					ddate = value[part_key]
					if ddate == 0:
						print "\t%-17s : N/A" % (part_key)
					elif ('reason_uid' in part_key) and (value['reason'] is None):
						print "\t%-17s :" % part_key
					else:
						ddate = pyslurm.epoch2date(ddate)
						print "\t%-17s : %s" % (part_key, ddate)
				elif part_key == 'connection_type':
					print "\t%-17s : %s" % (part_key, pyslurm.get_connection_type(value[part_key]))
				elif part_key == 'state':
					print "\t%-17s : %s" % (part_key, value[part_key])
				else: 
					print "\t%-17s : %s" % (part_key, value[part_key])

			print "-" * 80


if __name__ == "__main__":

	a = pyslurm.block()
	try:
		a.load()
		block_dict = a.get()
	except ValueError as e:
		print 'Block query failed - %s' % (e)
	else:
		if len(block_dict) > 0:

			display(block_dict)
			print
			print "Block IDs - %s" % a.ids()
			print

		else:
			print "No Blocks found !"
