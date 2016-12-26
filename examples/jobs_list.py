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
            # TODO: need to re-implement find in v2 API
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
