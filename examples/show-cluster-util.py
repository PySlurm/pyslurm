#!/usr/bin/python

from __future__ import print_function

import pyslurm
import sys


def human_readable(num, suffix="B"):
    """Convert bytes to a human readable form"""
    if num == 0:
        return "0.0 GB"
    else:
        for unit in ['', 'K', 'M', 'G', 'T', 'P']:
            if abs(num) < 1024.0:
                return "%.1f %s%s" % (num, unit, suffix)
            num /= 1024.0


def get_util(nodes):
    """ Return dictionary of total and used cpus, memory and nodes. """
    all_metrics = {"total_cpus_avail": 0,
                   "total_cpus_alloc": 0,
                   "total_cpus_config": 0,
                   "total_memory_avail": 0,
                   "total_memory_alloc": 0,
                   "total_memory_config": 0,
                   "total_nodes_mixed": 0,
                   "total_nodes_alloc": 0,
                   "total_nodes_idle": 0,
                   "total_nodes_down": 0,
                   "total_nodes_config": 0}

    for node in nodes:
        nodeinfo = nodes.get(node)

        state = nodeinfo.get("state")
        alloc_cpus = nodeinfo.get("alloc_cpus")
        avail_cpus = nodeinfo.get("cpus")
        alloc_memory = nodeinfo.get("alloc_memory")
        avail_memory = nodeinfo.get("real_memory")

        all_metrics["total_cpus_config"] += avail_cpus
        all_metrics["total_memory_config"] += avail_memory
        all_metrics["total_nodes_config"] += 1

        if "ALLOCATED" in state:
            all_metrics["total_memory_avail"] += avail_memory
            all_metrics["total_memory_alloc"] += avail_memory
            all_metrics["total_cpus_avail"] += avail_cpus
            all_metrics["total_cpus_alloc"] += alloc_cpus
            all_metrics["total_nodes_alloc"] += 1
        elif "MIXED" in state:
            all_metrics["total_memory_avail"] += avail_memory
            all_metrics["total_memory_alloc"] += alloc_memory
            all_metrics["total_cpus_avail"] += avail_cpus
            all_metrics["total_cpus_alloc"] += alloc_cpus
            all_metrics["total_nodes_mixed"] += 1
        elif "IDLE" in state:
            all_metrics["total_memory_avail"] += avail_memory
            all_metrics["total_cpus_avail"] += avail_cpus
            all_metrics["total_cpus_alloc"] += alloc_cpus
            all_metrics["total_nodes_idle"] += 1
        elif "DOWN" in state:
            all_metrics["total_nodes_down"] += 1

    return all_metrics


def display_metrics(metrics):
    """ Print cluster utilization. """
    # NODES
    print()
    print("Total Allocated Nodes      : {0:>8}".format(
          metrics["total_nodes_alloc"]))
    print("Total Mixed Nodes          : {0:>8}".format(
          metrics["total_nodes_mixed"]))
    print("Total Idle Nodes           : {0:>8}".format(
          metrics["total_nodes_idle"]))
    print("Total Down Nodes           : {0:>8}".format(
          metrics["total_nodes_down"]))
    print("Total Eligible Nodes       : {0:>8}".format(
          metrics["total_nodes_config"] - metrics["total_nodes_down"]))
    print("Total Configured Nodes     : {0:>8}".format(
          metrics["total_nodes_config"]))
    print()

    # CPUS
    print("Total Allocated CPUs       : {0:>8}".format(
          metrics["total_cpus_alloc"]))
    print("Total Eligible CPUs        : {0:>8}".format(
          metrics["total_cpus_avail"]))
    print("Total Configured CPUs      : {0:>8}".format(
          metrics["total_cpus_config"]))
    print("Cluster CPU Utilization    : {0:>7}%".format(
          metrics["total_cpus_alloc"] * 100 / metrics["total_cpus_avail"]))
    print()

    # MEMORY
    print("Total Allocated Memory     : {0:>8}".format(
          human_readable(metrics["total_memory_alloc"] * 1024 * 1024)))
    print("Total Eligible Memory      : {0:>8}".format(
          human_readable(metrics["total_memory_avail"] * 1024 * 1024)))
    print("Total Configured Memory    : {0:>8}".format(
          human_readable(metrics["total_memory_config"] * 1024 * 1024)))
    print("Cluster Memory Utilization : {0:>7}%".format(
          metrics["total_memory_alloc"] * 100 / metrics["total_memory_avail"]))
    print()


if __name__ == "__main__":
    try:
        # Make sure pyslurm works, or else exit here
        pyslurmnode = pyslurm.node()
        # Get all node info
        nodes = pyslurmnode.get()
    except ValueError as e:
        print('Query failed - {0}').format(e)
        sys.exit(1)

    metrics = get_util(nodes)
    display_metrics(metrics)
