#!/usr/bin/env python

import pyslurm
import sys
from pwd import getpwnam, getpwuid
from time import gmtime, strftime, sleep

def list_users(job_dict):
 
	users = []
	if job_dict:

		for jobid, value in sorted(job_dict.iteritems()):

			if value["account"] not in users:

				users.append(value["account"])

	return users

if __name__ == "__main__":

	try:
		pyslurmjob = pyslurm.job()
		jobs = pyslurmjob.get()
	except ValueError as e:
        	print 'Job query failed - %s' % (e)
		sys.exit(1)

	users = list_users(jobs)

	delim =  "+-------------------------------------------+-----------+------------+---------------+-----------------+--------------+--------------+"
	print delim
	print "|                USER (NAME)                | CPUS USED | NODES USED | CPU REQUESTED | NODES REQUESTED | JOBS RUNNING | JOBS PENDING |"
	print delim

	total_procs_request = 0
	total_nodes_request = 0
	total_procs_used = 0
	total_nodes_used = 0
	total_job_running = 0
	total_job_pending = 0

	for user in users:

		user_jobs = pyslurmjob.find('account', user)
		try:
			gecos = getpwnam(user)[4].split(",")[0]
		except:
			pass

		procs_request = 0
		nodes_request = 0
		procs_used = 0
		nodes_used = 0
		running = 0
		pending = 0

		for jobid in user_jobs:

			if not user:
				user = jobs[jobid]["user_id"]
				gecos = "%s" % getpwuid(user)[4]
				user = "%s" % user

			if jobs[jobid]["job_state"] == "PENDING":
				pending = pending + 1
				procs_request = procs_request + jobs[jobid]["num_cpus"] 
				nodes_request = nodes_request + jobs[jobid]["num_nodes"]

			if jobs[jobid]["job_state"] == "RUNNING":
				running = running + 1
				procs_used = procs_used + jobs[jobid]["num_cpus"] 
				nodes_used = nodes_used + jobs[jobid]["num_nodes"]

		total_procs_request = total_procs_request + procs_request
		total_nodes_request = total_nodes_request + nodes_request
		total_procs_used = total_procs_used + procs_used
		total_nodes_used = total_nodes_used + nodes_used
		total_job_running = total_job_running + running
		total_job_pending = total_job_pending + pending

		print "|%9s (%30s) | %9d | %10d | %13d | %15d | %12d | %12d |" % (user.upper(), gecos, procs_used, nodes_used, procs_request, nodes_request, running, pending)

	print delim
	print "|                   TOTAL                   | %9d | %10d | %13d | %15d | %12d | %12d |" % (total_procs_used, total_nodes_used, total_procs_request, total_nodes_request, total_job_running, total_job_pending)
	print delim

