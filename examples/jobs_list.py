import pyslurm
from time import gmtime, strftime

a, b = pyslurm.slurm_load_jobs("", 2)
jobs =  pyslurm.get_job_data(b)

if jobs:

	date_fields = [ 'start_time', 
			'suspend_time',
			'submit_time',
			'end_time',
			'eligible_time',
			'resize_time'
			]

	for key, value in jobs.iteritems():

		print "JobID %s :" % key
		for part_key in sorted(value.iterkeys()):

			if part_key in date_fields:

				if value[part_key] == 0:
					print "\t%-20s : N/A" % (part_key)
				else:
					ddate = pyslurm.epoch2date(value[part_key])
					print "\t%-20s : %s" % (part_key, ddate)

			else:
				print "\t%-20s : %s" % (part_key, value[part_key])
		print "-" * 80

		#pyslurm.slurm_job_step_layout_get(key, 0)
else:
	
	print "No jobs found !"

