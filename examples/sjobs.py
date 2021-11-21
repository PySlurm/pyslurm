#!/usr/bin/env python
"""
List Slurm jobs from certain users
"""

import sys
from pwd import getpwnam, getpwuid

import pyslurm


def list_users(job_dict):
    """List Slurm users"""
    job_users = []
    if job_dict:

        for _, value in sorted(job_dict.items()):

            if value["account"] not in job_users:
                job_users.append(value["account"])

    return job_users


if __name__ == "__main__":

    try:
        pyslurmjob = pyslurm.job()
        jobs = pyslurmjob.get()
    except ValueError as value_error:
        print(f"Job query failed - {value_error.args[0]}")
        sys.exit(1)

    users = list_users(jobs)

    DELIM = "+-------------------------------------------+-----------+------------"
    "+---------------+-----------------+--------------+--------------+"
    print(DELIM)
    print(
        "|                USER (NAME)                | CPUS USED | NODES USED "
        "| CPU REQUESTED | NODES REQUESTED | JOBS RUNNING | JOBS PENDING |"
    )
    print(DELIM)

    TOTAL_PROCS_REQUEST = 0
    TOTAL_NODES_REQUEST = 0
    TOTAL_PROCS_USED = 0
    TOTAL_NODES_USED = 0
    TOTAL_JOB_RUNNING = 0
    TOTAL_JOB_PENDING = 0

    for user in users:

        user_jobs = pyslurmjob.find("account", user)
        try:
            gecos = getpwnam(user)[4].split(",")[0]
        except ValueError:
            print(f"Couldn't split\n {gecos}")
            sys.exit(1)

        PROCS_REQUEST = 0
        NODES_REQUEST = 0
        PROCS_USED = 0
        NODES_USED = 0
        RUNNING = 0
        PENDING = 0

        for jobid in user_jobs:

            if not user:
                user = jobs[jobid]["user_id"]
                gecos = f"{getpwuid(user)[4]}"
                user = f"{user}"

            if jobs[jobid]["job_state"] == "PENDING":
                PENDING = PENDING + 1
                PROCS_REQUEST = PROCS_REQUEST + jobs[jobid]["num_cpus"]
                NODES_REQUEST = NODES_REQUEST + jobs[jobid]["num_nodes"]

            if jobs[jobid]["job_state"] == "RUNNING":
                RUNNING = RUNNING + 1
                PROCS_USED = PROCS_USED + jobs[jobid]["num_cpus"]
                NODES_USED = NODES_USED + jobs[jobid]["num_nodes"]

        TOTAL_PROCS_REQUEST = TOTAL_PROCS_REQUEST + PROCS_REQUEST
        TOTAL_NODES_REQUEST = TOTAL_NODES_REQUEST + NODES_REQUEST
        TOTAL_PROCS_USED = TOTAL_PROCS_USED + PROCS_USED
        TOTAL_NODES_USED = TOTAL_NODES_USED + NODES_USED
        TOTAL_JOB_RUNNING = TOTAL_JOB_RUNNING + RUNNING
        TOTAL_JOB_PENDING = TOTAL_JOB_PENDING + PENDING

        print(
            f"|{user.upper():>9} ({gecos:30}) | {PROCS_USED:>9d} | {NODES_USED:>10d} "
            f"| {PROCS_REQUEST:>13d} | {NODES_REQUEST:>15d} | {RUNNING:>12d} | {PENDING:>12d} |"
        )

    print(DELIM)
    print(
        f"|                   TOTAL                   | {TOTAL_PROCS_USED:>9d} "
        f"| {TOTAL_NODES_USED:>10d} | {TOTAL_PROCS_REQUEST:>13d} | {TOTAL_NODES_REQUEST:>15d} "
        f"| {TOTAL_JOB_RUNNING:>12d} | {TOTAL_JOB_PENDING:>12d} |"
    )
    print(DELIM)
