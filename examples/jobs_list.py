#!/usr/bin/env python
from __future__ import print_function

import pyslurm
import sys

from time import gmtime, strftime, sleep

def display(alljobs):
    if alljobs:
        # TODO: add slurm epoch2date function to PySlurm API
        for job in alljobs:
            print("JobID {0} :".format(job.job_id))
#            print("\t{0:<20} : {1}".format("account", job.account))
#            print("\t{0:<20} : {1}".format("alloc_node", job.alloc_node))
#            print("\t{0:<20} : {1}".format("alloc_sid", job.alloc_sid))
#            print("\t{0:<20} : {1}".format("array_job_id", job.array_job_id))
#            print("\t{0:<20} : {1}".format("array_task_id", job.array_task_id))
#            print("\t{0:<20} : {1}".format("array_task_str", job.array_task_str))
#            print("\t{0:<20} : {1}".format("batch_flag", job.batch_flag))
#            print("\t{0:<20} : {1}".format("batch_host", job.batch_host))
#            print("\t{0:<20} : {1}".format("batch_script", job.batch_script))
#            print("\t{0:<20} : {1}".format("batch_host", job.batch_host))
#            print("\t{0:<20} : {1}".format("boards_per_node", job.boards_per_node))
#            print("\t{0:<20} : {1}".format("burst_buffer", job.burst_buffer))
#            print("\t{0:<20} : {1}".format("command", job.command))
#            print("\t{0:<20} : {1}".format("comment", job.comment))
#            print("\t{0:<20} : {1}".format("contiguous", job.contiguous))
#            print("\t{0:<20} : {1}".format("core_spec", job.core_spec))
#            print("\t{0:<20} : {1}".format("cores_per_socket", job.cores_per_socket))
#            print("\t{0:<20} : {1}".format("cpus_per_task", job.cpus_per_task))
#            print("\t{0:<20} : {1}".format("dependency", job.dependency))
##            print("\t{0:<20} : {1}".format("derived_exit_code", job.derived_exit_code))
#            print("\t{0:<20} : {1}".format("eligible_time", job.eligible_time_str))
#            print("\t{0:<20} : {1}".format("end_time", job.end_time_str))
#            print("\t{0:<20} : {1}".format("features", job.features))
#            print("\t{0:<20} : {1}".format("gres", job.gres))
#            print("\t{0:<20} : {1}".format("group_name", job.group_name))
#            print("\t{0:<20} : {1}".format("group_name", job.group_name))
            for attr in dir(job):
                if not attr.startswith("_"):
                    print("\t{0:<20} : {1}".format(attr, getattr(job, attr)))
            print("-" * 80)


if __name__ == "__main__":
    try:
        alljobs = pyslurm.job.get_jobs()
        if len(alljobs) > 0:
            display(alljobs)
            print()
            print("Number of Jobs - {0}".format(len(alljobs)))
            print()
            # TODO
#            pending = pyslurm.job.find('job_state', 'PENDING')
#            running = a.find('job_state', 'RUNNING')
#            held = a.find('job_state', 'RUNNING')
#            print("Number of pending jobs - {0}".format(len(pending)))
#            print("Number of running jobs - {0}".format(len(running)))
#            print()
#            print("JobIDs in Running state - {0}".format(running))
#            print("JobIDs in Pending state - {0}".format(pending))
            print()
        else:
            print("No jobs found!")
    except ValueError as e:
        print("Job query failed - {0}".format(e.args[0]))
