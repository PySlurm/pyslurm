#!/usr/bin/env python

import time
import datetime

import pyslurm

def job_display( job ):
    for key,value in job.items():
        print("\t{}={}".format(key, value))

if __name__ == "__main__":
    try:
        start = (datetime.datetime.utcnow() - datetime.timedelta(days=1)).strftime("%Y-%m-%dT00:00:00")
        end = (datetime.datetime.utcnow() + datetime.timedelta(days=1)).strftime("%Y-%m-%dT00:00:00")

        jobs = pyslurm.slurmdb_jobs()
        jobs_dict = jobs.get(starttime=start.encode('utf-8'), endtime=end.encode('utf-8'))
        if len(jobs_dict):
            for key, value in jobs_dict.items():
                print("{} Job: {}".format('{',key))
                job_display(value)
                print("}")
        else:
            print("No job found")
    except ValueError as e:
        print("Error:{}".format(e.args[0]))

