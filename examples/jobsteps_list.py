#!/usr/bin/env python
"""
List steps jobs have gone through
"""

import pyslurm

steps = pyslurm.jobstep()
a = steps.get()

if a:
    for job, job_step in sorted(a.items()):
        print(f"Job: {job}")
        for step, step_data in sorted(job_step.items()):
            print(f"\tStep: {step}")
            for step_item, item_data in sorted(step_data.items()):
                if "start_time" in step_item:
                    ddate = pyslurm.epoch2date(item_data)
                    print(f"\t\t{step_item:<15} : {ddate}")
                else:
                    print(f"\t\t{step_item:<15} : {item_data}")
            layout = steps.layout(job, step)
            print("\t\tLayout:")
            for name, value in sorted(layout.items()):
                print(f"\t\t\t{name:<15} : {value}")

    print(f"{'':*^80}")
else:
    print("No jobsteps found !")
