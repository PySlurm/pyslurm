#!/usr/bin/env python

import pyslurm

a = pyslurm.trigger()
trig_dict = a.get()

if len(trig_dict) > 0:

	print "-" * 80
	for key, value in trig_dict.iteritems():
		print "Trigger ID                : %s" % (key)
		for part_key in sorted(value.iterkeys()):
				print "%-25s : %s" % (part_key, value[part_key])

		print "-" * 80
else:
	print "No triggers found !"

