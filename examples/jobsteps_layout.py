import pyslurm

def display(steps):

	time_fields = ['time_limit']
	date_fields = ['start_time']

	for job, job_step in sorted(steps.iteritems()):

		print "Job: %s" % job
		for step, step_dict in job_step.iteritems():

			print "\tStep: %s" % step
               		for task, value in sorted(step_dict.iteritems()):

				if task in date_fields:

					if value == 0:
						print "\t\t%-20s : N/A" % (task)
					else:
						ddate = pyslurm.epoch2date(value)
						print "\t\t%-20s : %s" % (task, ddate)
				else:
					print "\t\t%-20s : %s" % (task, value)

if __name__ == "__main__":

	a = pyslurm.jobstep()
	steps = a.get()

	if len(steps) > 0:

		display(steps)
