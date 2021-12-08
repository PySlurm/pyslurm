#!/usr/bin/env python
"""
List Slurm jobs
"""

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

            print(f"JobID {key} :")
            for part_key in sorted(value.keys()):

                if part_key in time_fields:
                    print(f"\t{part_key:<20} : Infinite")
                    continue

                if part_key in date_fields:

                    if value[part_key] == 0:
                        print(f"\t{part_key:<20} : N/A")
                    else:
                        ddate = pyslurm.epoch2date(value[part_key])
                        print(f"\t{part_key:<20} : {ddate}")
                else:
                    print(f"\t{part_key:<20} : {value[part_key]}")

            print("-" * 80)


if __name__ == "__main__":

    try:
        a = pyslurm.job()
        jobs = a.get()

        if jobs:

            display(jobs)

            print()
            print(f"Number of Jobs - {len(jobs)}")
            print()

            pending = a.find("job_state", "PENDING")
            running = a.find("job_state", "RUNNING")
            held = a.find("job_state", "RUNNING")

            print(f"Number of pending jobs - {len(pending)}")
            print(f"Number of running jobs - {len(running)}")
            print()

            print(f"JobIDs in Running state - {running}")
            print(f"JobIDs in Pending state - {pending}")
            print()
        else:
            print("No jobs found !")
    except ValueError as value_error:
        print(f"Job query failed - {value_error.args[0]}")
