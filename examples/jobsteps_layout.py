#!/usr/bin/env python
"""
Display Slurm jobsteps
"""
from __future__ import print_function

import pyslurm


def display(steps):
    """Format output"""
    date_fields = ["start_time"]

    for job, job_step in sorted(steps.items()):

        print("Job: {0}".format(job))
        for step, step_dict in job_step.items():

            print("\tStep: {0}".format(step))
            for task, value in sorted(step_dict.items()):

                if task in date_fields:

                    if value == 0:
                        print("\t\t{0:<20} : N/A".format(task))
                    else:
                        ddate = pyslurm.epoch2date(value)
                        print("\t\t{0:<20} : {1}".format(task, ddate))
                else:
                    print("\t\t{0:<20} : {1}".format(task, value))


if __name__ == "__main__":

    a = pyslurm.jobstep()
    steps = a.get()

    if steps:
        display(steps)
