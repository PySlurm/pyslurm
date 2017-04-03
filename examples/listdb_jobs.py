#!/usr/bin/env python

import time
import pyslurm

def job_display( job ):
    for key,value in job.items():
        print("\t{}={}".format(key, value))

if __name__ == "__main__":
    try:
        end = time.time()
        start = end - (30*24*60*60)
        print("start={}, end={}".format(start,end))
        jobs = pyslurm.slurmdb_jobs()
        jobs_dict = jobs.get(starttime=start, endtime=end)
        if len(jobs_dict):
            for key, value in jobs_dict.items():
                print("{} Job: {}".format('{',key))
                job_display(value)
                print("}")
        else:
            print("No job found")
    except ValueError as e:
        print("Error:{}".format(e.args[0]))

