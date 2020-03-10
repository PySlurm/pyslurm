#!/usr/bin/env python
"""
Print cluster utilization.
"""
from __future__ import print_function

import sys

import pyslurm


def human_readable(num, suffix="B"):
    """Convert bytes to a human readable form"""
    if num == 0:
        return "0.0 GB"
    for unit in ["", "K", "M", "G", "T", "P"]:
        if abs(num) < 1024.0:
            return "%.1f %s%s" % (num, unit, suffix)
        num /= 1024.0


def get_util(nodes):
    """ Return a tuple of cpu and memory percent values."""
    all_metrics = {
        "total_cpus_alloc": 0,
        "total_cpus_idle": 0,
        "total_cpus_down": 0,
        "total_cpus_config": 0,
        "total_memory_alloc": 0,
        "total_memory_idle": 0,
        "total_memory_down": 0,
        "total_memory_config": 0,
        "total_nodes_mixed": 0,
        "total_nodes_alloc": 0,
        "total_nodes_idle": 0,
        "total_nodes_down": 0,
        "total_nodes_config": 0,
    }

    for node in nodes:
        nodeinfo = nodes.get(node)

        state = nodeinfo.get("state").upper()
        cpus_alloc = nodeinfo.get("alloc_cpus")
        cpus_total = nodeinfo.get("cpus")
        memory_alloc = nodeinfo.get("alloc_mem")
        memory_real = nodeinfo.get("real_memory")

        all_metrics["total_nodes_config"] += 1
        all_metrics["total_cpus_config"] += cpus_total
        all_metrics["total_memory_config"] += memory_real

        if "DOWN" in state or "DRAIN" in state:
            all_metrics["total_nodes_down"] += 1
            all_metrics["total_cpus_down"] += cpus_total
            all_metrics["total_memory_down"] += memory_real
        else:
            all_metrics["total_cpus_alloc"] += cpus_alloc
            all_metrics["total_cpus_idle"] += cpus_total - cpus_alloc

            all_metrics["total_memory_alloc"] += memory_alloc
            all_metrics["total_memory_idle"] += memory_real - memory_alloc

            if "ALLOCATED" in state:
                all_metrics["total_nodes_alloc"] += 1
            elif "MIXED" in state:
                all_metrics["total_nodes_mixed"] += 1
            elif "IDLE" in state:
                all_metrics["total_nodes_idle"] += 1

    return all_metrics


def display_metrics(metrics):
    """
    Print cluster utilization.

    IN: (dict) dictionary of all node, cpu and memory states
    """
    print()
    print("Total Allocated Nodes      : {0:>8}".format(metrics["total_nodes_alloc"]))
    print("Total Mixed Nodes          : {0:>8}".format(metrics["total_nodes_mixed"]))
    print("Total Idle Nodes           : {0:>8}".format(metrics["total_nodes_idle"]))
    print("Total Down Nodes           : {0:>8}".format(metrics["total_nodes_down"]))
    print(
        "Total Eligible Nodes       : {0:>8}".format(
            metrics["total_nodes_config"] - metrics["total_nodes_down"]
        )
    )
    print("Total Configured Nodes     : {0:>8}".format(metrics["total_nodes_config"]))
    print("")

    print("Total Allocated CPUs       : {0:>8}".format(metrics["total_cpus_alloc"]))
    print("Total Idle CPUs            : {0:>8}".format(metrics["total_cpus_idle"]))
    print("Total Down CPUs            : {0:>8}".format(metrics["total_cpus_down"]))
    print(
        "Total Eligible CPUs        : {0:>8}".format(
            metrics["total_cpus_config"] - metrics["total_cpus_down"]
        )
    )
    print("Total Configured CPUs      : {0:>8}".format(metrics["total_cpus_config"]))
    print(
        "Cluster CPU Utilization    : {0:>7}%".format(
            metrics["total_cpus_alloc"]
            * 100
            / (metrics["total_cpus_config"] - metrics["total_cpus_down"])
        )
    )
    print()

    print(
        "Total Allocated Memory     : {0:>8}".format(
            human_readable(metrics["total_memory_alloc"] * 1024 * 1024)
        )
    )
    print(
        "Total Idle Memory          : {0:>8}".format(
            human_readable(metrics["total_memory_idle"] * 1024 * 1024)
        )
    )
    print(
        "Total Down Memory          : {0:>8}".format(
            human_readable(metrics["total_memory_down"] * 1024 * 1024)
        )
    )
    print(
        "Total Eligible Memory      : {0:>8}".format(
            human_readable(
                (metrics["total_memory_config"] - metrics["total_memory_down"])
                * 1024
                * 1024
            )
        )
    )
    print(
        "Total Configured Memory    : {0:>8}".format(
            human_readable(metrics["total_memory_config"] * 1024 * 1024)
        )
    )
    print(
        "Cluster Memory Utilization : {0:>7}%".format(
            metrics["total_memory_alloc"]
            * 100
            / (metrics["total_memory_config"] - metrics["total_memory_down"])
        )
    )
    print()


if __name__ == "__main__":
    try:
        # Make sure pyslurm works or else exit here
        pyslurmnode = pyslurm.node()
        # Get all node info
        nodes = pyslurmnode.get()
    except ValueError as value_error:
        print("Query failed - {0}".format(value_error))
        sys.exit(1)

    metrics = get_util(nodes)
    display_metrics(metrics)
