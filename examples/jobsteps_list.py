#!/usr/bin/env python
"""
List steps jobs have gone through
"""
from __future__ import print_function

import pyslurm

steps = pyslurm.jobstep()
a = steps.get()

if a:
    for job, job_step in sorted(a.items()):
        print("Job: {0}".format(job))
        for step, step_data in sorted(job_step.items()):
            print("\tStep: {0}".format(step))
            for step_item, item_data in sorted(step_data.items()):
                if "start_time" in step_item:
                    ddate = pyslurm.epoch2date(item_data)
                    print("\t\t{0:<15} : {1}".format(step_item, ddate))
                else:
                    print("\t\t{0:<15} : {1}".format(step_item, item_data))
            layout = steps.layout(job, step)
            print("\t\tLayout:")
            for name, value in sorted(layout.items()):
                print("\t\t\t{0:<15} : {1}".format(name, value))

    print("{0:*^80}".format(""))
else:
    print("No jobsteps found !")
