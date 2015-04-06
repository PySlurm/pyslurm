#!/usr/bin/env python

import pyslurm

try:
	a = pyslurm.trigger()
	trig_dict = a.get()
except ValueError as e:
        print 'Trigger error - %s' % (e)
else:
	if len(trig_dict) > 0:

		print "-" * 80
		for key, value in trig_dict.iteritems():
			print "Trigger ID                : %s" % (key)
			for part_key in sorted(value.iterkeys()):

				if 'res_type' in part_key:
					print "%-25s : %s" % (part_key, pyslurm.get_trigger_res_type(value[part_key]))
				elif 'trig_type' in part_key:
					print "%-25s : %s" % (part_key, pyslurm.get_trigger_type(value[part_key]))
				else:
					print "%-25s : %s" % (part_key, value[part_key])
			print "-" * 80
	else:
		print "No triggers found !"
