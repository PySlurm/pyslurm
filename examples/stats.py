#!/usr/bin/env python

def display(stats_dict):

	if stats_dict:

		print "-" * 80
		for key, value in stats_dict.iteritems():
			if key in ['bf_when_last_cycle', 'req_time', 'req_time_start']:
				ddate = value
				if ddate == 0:
					print "%-25s : N/A" % (key)
				else:
					ddate = pyslurm.epoch2date(ddate)
					print "%-25s : %-17s" % (key, ddate)
			elif key in ['rpc_user_stats', 'rpc_type_stats']:
				label = 'rpc_user_id'
				if key == 'rpc_type_stats':
					label = 'rpc_type_id'
				print "%-25s :" % (key)
				for rpc_key, rpc_val in value.iteritems():
					print "\t%-12s : %-15s" % (label, rpc_key)
					for rpc_val_key, rpc_value in rpc_val.iteritems():
						print "\t\t%-12s : %-15s" % (rpc_val_key, rpc_value)
			else:
				print "%-25s : %-17s" % (key, value)

		print "-" * 80
	else:
		
		print "No Stats found !"


if __name__ == "__main__":

	import pyslurm
	import time

	stats = pyslurm.statistics()
        s = stats.get()
        display(s)

