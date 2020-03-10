#!/usr/bin/env python
"""
List Slurm jobs
"""
from __future__ import print_function

import pyslurm


def display(job_dict):
    """Format output"""
    if job_dict:

        time_fields = ["time_limit"]

        date_fields = [
            "start_time",
            "submit_time",
            "end_time",
            "eligible_time",
            "resize_time",
        ]

        for key, value in sorted(job_dict.items()):

            print("JobID {0} :".format(key))
            for part_key in sorted(value.keys()):

                if part_key in time_fields:
                    print("\t{0:<20} : Infinite".format(part_key))
                    continue

                if part_key in date_fields:

                    if value[part_key] == 0:
                        print("\t{0:<20} : N/A".format(part_key))
                    else:
                        ddate = pyslurm.epoch2date(value[part_key])
                        print("\t{0:<20} : {1}".format(part_key, ddate))
                else:
                    print("\t{0:<20} : {1}".format(part_key, value[part_key]))

            print("-" * 80)


if __name__ == "__main__":

    try:
        a = pyslurm.job()
        jobs = a.get()

        if jobs:

            display(jobs)

            print()
            print("Number of Jobs - {0}".format(len(jobs)))
            print()

            pending = a.find("job_state", "PENDING")
            running = a.find("job_state", "RUNNING")
            held = a.find("job_state", "RUNNING")

            print("Number of pending jobs - {0}".format(len(pending)))
            print("Number of running jobs - {0}".format(len(running)))
            print()

            print("JobIDs in Running state - {0}".format(running))
            print("JobIDs in Pending state - {0}".format(pending))
            print()
        else:
            print("No jobs found !")
    except ValueError as value_error:
        print("Job query failed - {0}".format(value_error.args[0]))
