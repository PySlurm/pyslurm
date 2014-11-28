#!/usr/bin/env python

import pyslurm
import sys
from time import gmtime, strftime

steps = pyslurm.jobstep()
a = steps.get()

for job, job_step in sorted(a.iteritems()):


		print "Job: %s" % (job)
		for step, step_data in sorted(job_step.iteritems()):

			print "\tStep: %s" % (step)
			for step_item, item_data in sorted(step_data.iteritems()):

				if 'start_time' in step_item:
					ddate = pyslurm.epoch2date(item_data)
					print "\t\t%-15s : %s" % (step_item, ddate)
				else:
					print "\t\t%-15s : %s" % (step_item, item_data)

			layout = steps.layout(job, step)
			print "\t\tLayout:"
			for name, value in sorted(layout.iteritems()):
				print "\t\t\t%-15s : %s" % (name, value)

print "-" * 80

