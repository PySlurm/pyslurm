#!/usr/bin/env python
"""
Display Slurm jobsteps
"""

import pyslurm


def display(steps):
    """Format output"""
    date_fields = ["start_time"]

    for job, job_step in sorted(steps.items()):

        print(f"Job: {job}")
        for step, step_dict in job_step.items():

            print(f"\tStep: {step}")
            for task, value in sorted(step_dict.items()):

                if task in date_fields:

                    if value == 0:
                        print(f"\t\t{task:<20} : N/A")
                    else:
                        ddate = pyslurm.epoch2date(value)
                        print(f"\t\t{task:<20} : {ddate}")
                else:
                    print(f"\t\t{task:<20} : {value}")


if __name__ == "__main__":

    a = pyslurm.jobstep()
    job_steps = a.get()

    if job_steps:
        display(job_steps)
