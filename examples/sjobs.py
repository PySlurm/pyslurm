#!/usr/bin/env python
"""
List Slurm jobs from certain users
"""
from __future__ import print_function

import sys
from pwd import getpwnam, getpwuid

import pyslurm


def list_users(job_dict):
    """List Slurm users"""
    users = []
    if job_dict:

        for _, value in sorted(job_dict.items()):

            if value["account"] not in users:
                users.append(value["account"])

    return users


if __name__ == "__main__":

    try:
        pyslurmjob = pyslurm.job()
        jobs = pyslurmjob.get()
    except ValueError as value_error:
        print("Job query failed - {0}".format(value_error.args[0]))
        sys.exit(1)

    users = list_users(jobs)

    delim = "+-------------------------------------------+-----------+------------+---------------+-----------------+--------------+--------------+"
    print(delim)
    print(
        "|                USER (NAME)                | CPUS USED | NODES USED | CPU REQUESTED | NODES REQUESTED | JOBS RUNNING | JOBS PENDING |"
    )
    print(delim)

    total_procs_request = 0
    total_nodes_request = 0
    total_procs_used = 0
    total_nodes_used = 0
    total_job_running = 0
    total_job_pending = 0

    for user in users:

        user_jobs = pyslurmjob.find("account", user)
        try:
            gecos = getpwnam(user)[4].split(",")[0]
        except Exception as split_error:
            print("Couldn't split\n {}".format(gecos))
            sys.exit(1)

        procs_request = 0
        nodes_request = 0
        procs_used = 0
        nodes_used = 0
        running = 0
        pending = 0

        for jobid in user_jobs:

            if not user:
                user = jobs[jobid]["user_id"]
                gecos = "{0}".format(getpwuid(user)[4])
                user = "{0}".format(user)

            if jobs[jobid]["job_state"] == "PENDING":
                pending = pending + 1
                procs_request = procs_request + jobs[jobid]["num_cpus"]
                nodes_request = nodes_request + jobs[jobid]["num_nodes"]

            if jobs[jobid]["job_state"] == "RUNNING":
                running = running + 1
                procs_used = procs_used + jobs[jobid]["num_cpus"]
                nodes_used = nodes_used + jobs[jobid]["num_nodes"]

        total_procs_request = total_procs_request + procs_request
        total_nodes_request = total_nodes_request + nodes_request
        total_procs_used = total_procs_used + procs_used
        total_nodes_used = total_nodes_used + nodes_used
        total_job_running = total_job_running + running
        total_job_pending = total_job_pending + pending

        print(
            "|{0:>9} ({1:30}) | {2:>9d} | {3:>10d} | {4:>13d} | {5:>15d} | {6:>12d} | {7:>12d} |".format(
                user.upper(),
                gecos,
                procs_used,
                nodes_used,
                procs_request,
                nodes_request,
                running,
                pending,
            )
        )

    print(delim)
    print(
        "|                   TOTAL                   | {0:>9d} | {1:>10d} | {2:>13d} | {3:>15d} | {4:>12d} | {5:>12d} |".format(
            total_procs_used,
            total_nodes_used,
            total_procs_request,
            total_nodes_request,
            total_job_running,
            total_job_pending,
        )
    )
    print(delim)
