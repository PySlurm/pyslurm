#!/usr/bin/env python

import pyslurm
import sys

try:
	a = pyslurm.config()
	ctl_dict = a.get()
except ValueError as e:
	print 'Error - %s' % (e)
	sys.exit(-1)

# Process the sorted SLURM configuration dictionary

date_fields = [ 'boot_time', 'last_update' ]
for key in sorted(ctl_dict.iterkeys()):

	if key in date_fields:

		if ctl_dict[key] == 0:
			print "\t%-35s : N/A" % (key)
		else:
			ddate = pyslurm.epoch2date(ctl_dict[key])
			print "\t%-35s : %s" % (key, ddate)

	elif 'debug_flags' in key:
		print "\t%-35s : %s" % (key, pyslurm.get_debug_flags(ctl_dict[key]))
	else:
		if 'key_pairs' not in key:
			print "\t%-35s : %s" % (key, ctl_dict[key])

if ctl_dict.has_key('key_pairs'):

	print ""
	print "Additional Information :"
	print "------------------------"
	print ""

	for key in sorted(ctl_dict['key_pairs'].iterkeys()):
		print "\t%-35s : %s" % (key, ctl_dict['key_pairs'][key])

