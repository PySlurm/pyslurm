#!/usr/bin/env python
"""
List all jobs in Slurm, similar to `sacct`
"""
import time

import pyslurm


def job_display(job):
    """Format output"""
    for key, value in job.items():
        print("\t{}={}".format(key, value))


if __name__ == "__main__":
    try:
        end = time.time()
        start = end - (30 * 24 * 60 * 60)
        print("start={}, end={}".format(start, end))
        jobs = pyslurm.slurmdb_jobs()
        jobs_dict = jobs.get(starttime=start, endtime=end)
        if jobs_dict:
            for key, value in jobs_dict.items():
                print("{} Job: {}".format("{", key))
                job_display(value)
                print("}")
        else:
            print("No job found")
    except ValueError as job_exception:
        print("Error:{}".format(job_exception.args[0]))
