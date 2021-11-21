#!/usr/bin/env python
"""
List all jobs in Slurm, similar to `sacct`
"""

import datetime

import pyslurm


def job_display(job):
    """Format output"""
    for job_key, job_value in job.items():
        print(f"\t{job_key}={job_value}")


if __name__ == "__main__":
    try:
        start = (datetime.datetime.utcnow() - datetime.timedelta(days=1)).strftime(
            "%Y-%m-%dT00:00:00"
        )
        end = (datetime.datetime.utcnow() + datetime.timedelta(days=1)).strftime(
            "%Y-%m-%dT00:00:00"
        )

        jobs = pyslurm.slurmdb_jobs()
        jobs_dict = jobs.get(
            starttime=start.encode("utf-8"), endtime=end.encode("utf-8")
        )
        if jobs_dict:
            for key, value in jobs_dict.items():
                print(f"{'{'} Job: {key}")
                job_display(value)
                print("}")
        else:
            print("No job found")
    except ValueError as job_exception:
        print(f"Error:{job_exception.args[0]}")
