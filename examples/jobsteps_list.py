import pyslurm
from time import gmtime, strftime

a = pyslurm.slurm_get_job_steps(5,0,0)
for job, job_step in sorted(a.iteritems()):

		print "Job: %s" % (job)
		for step, step_data in sorted(job_step.iteritems()):

			print "\tStep: %s" % (step)
			for step_item, item_data in sorted(step_data.iteritems()):

				if 'start_time' in step_item:
					ddate = pyslurm.epoch2date(item_data)
					print "\t\t%-10s : %s" % (step_item, ddate)
				else:
					print "\t\t%-10s : %s" % (step_item, item_data)

print "-" * 80

