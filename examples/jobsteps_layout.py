import pyslurm

steps = pyslurm.slurm_get_job_steps(5, 0, 2)
print steps
for job, job_step in sorted(steps.iteritems()):

		print "Job: %s" % job
		for step in sorted(job_step.iterkeys()):

			print "\tStep: %s" % step
			step_info = pyslurm.slurm_job_step_layout_get(job, step)
			for task in sorted(step_info.iterkeys()):
				print "\t\t%s:\t%s" % (task, step_info[task])

