import pyslurm

triggers = pyslurm.slurm_get_triggers()
if len(triggers) > 0:

	print "-" * 80
	for key, value in triggers.iteritems():
		print "Trigger ID                : %s" % (key)
		for part_key in sorted(value.iterkeys()):
			print "%-25s : %s" % (part_key, value[part_key])
		print "-" * 80
else:
	print "No triggers found !"

