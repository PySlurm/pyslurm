#!/usr/bin/env python

import pyslurm
import sys

from time import gmtime, strftime, sleep

def display(job_dict):

	if job_dict:

		time_fields = ['time_limit']

		date_fields = ['start_time',
				'submit_time',
				'end_time',
				'eligible_time',
				'resize_time']

		for key, value in sorted(job_dict.iteritems()):

			print "JobID %s :" % key
			for part_key in sorted(value.iterkeys()):

				if part_key in time_fields:
					print "\t%-20s : Infinite" % (part_key)
					continue

				if part_key in date_fields:

					if value[part_key] == 0:
						print "\t%-20s : N/A" % (part_key)
					else:
						ddate = pyslurm.epoch2date(value[part_key])
						print "\t%-20s : %s" % (part_key, ddate)

				elif part_key == 'state_reason':
					print "\t%-20s : (%s, %s)" % (part_key, value[part_key], pyslurm.get_job_state_reason(value[part_key]))
				elif part_key == 'job_state':
					print "\t%-20s : (%s, %s)" % (part_key, value[part_key], pyslurm.get_job_state(value[part_key]))
				elif part_key == 'conn_type':
					print "\t%-20s : (%s, %s)" % (part_key, value[part_key], pyslurm.get_connection_type(value[part_key]))
				else:
					print "\t%-20s : %s" % (part_key, value[part_key])
			print "-" * 80

if __name__ == "__main__":

	a = pyslurm.job()
	jobs = a.get()

	if len(jobs) > 0:

		display(jobs)

		print
		print "Number of Jobs - %s" % len(jobs)
		print

		pending = a.find('job_state', pyslurm.JOB_PENDING)
		running = a.find('job_state', pyslurm.JOB_RUNNING)

		print "%s" % a.find('state_reason', pyslurm.WAIT_HELD_USER) 

		print "Number of pending jobs - %s" % len(pending)
		print "Number of running jobs - %s" % len(running)
		print
		
		print "JobIDs in Running state - %s" % running
		print
	else:
	
		print "No jobs found !"

	#print a.find_id(10000)
