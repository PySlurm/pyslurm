#!/usr/bin/env python
"""
Print cluster utilization.
"""

import sys

import pyslurm


def human_readable(num, suffix="B"):
    """Convert bytes to a human readable form"""
    if num == 0:
        return "0.0 GB"
    for unit in ["", "K", "M", "G", "T", "P"]:
        if abs(num) < 1024.0:
            return f"{num:.1f} {unit}{suffix}"
        num /= 1024.0


def get_util(nodes):
    """Return a tuple of cpu and memory percent values."""
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
    print(f"Total Allocated Nodes      : {metrics['total_nodes_alloc']:>8}")
    print(f"Total Mixed Nodes          : {metrics['total_nodes_mixed']:>8}")
    print(f"Total Idle Nodes           : {metrics['total_nodes_idle']:>8}")
    print(f"Total Down Nodes           : {metrics['total_nodes_down']:>8}")
    print(
        "Total Eligible Nodes       : "
        f"{metrics['total_nodes_config'] - metrics['total_nodes_down']:>8}"
    )
    print(f"Total Configured Nodes     : {metrics['total_nodes_config']:>8}")
    print("")

    print(f"Total Allocated CPUs       : {metrics['total_cpus_alloc']:>8}")
    print(f"Total Idle CPUs            : {metrics['total_cpus_idle']:>8}")
    print(f"Total Down CPUs            : {metrics['total_cpus_down']:>8}")
    print(
        "Total Eligible CPUs        : "
        f"{metrics['total_cpus_config'] - metrics['total_cpus_down']:>8}"
    )
    print(f"Total Configured CPUs      : {metrics['total_cpus_config']:>8}")
    cluster_cpu_util = (
        metrics["total_cpus_alloc"]
        * 100
        / (metrics["total_cpus_config"] - metrics["total_cpus_down"])
    )
    print(f"Cluster CPU Utilization    : {cluster_cpu_util:>7}")
    print()

    print(
        "Total Allocated Memory     : "
        f"{human_readable(metrics['total_memory_alloc'] * 1024 * 1024):>8}"
    )
    total_memory_idle = human_readable(metrics["total_memory_idle"] * 1024 * 1024)
    print(f"Total Idle Memory          : {total_memory_idle:>8}")
    total_memory_down = human_readable(metrics["total_memory_down"] * 1024 * 1024)
    print(f"Total Down Memory          : {total_memory_down:>8}")
    total_eligible_memory = human_readable(
        (metrics["total_memory_config"] - metrics["total_memory_down"]) * 1024 * 1024
    )
    print(f"Total Eligible Memory      : {total_eligible_memory:>8}")
    print(
        "Total Configured Memory    : "
        f"{human_readable(metrics['total_memory_config'] * 1024 * 1024):>8}"
    )
    memory_util = (
        metrics["total_memory_alloc"]
        * 100
        / (metrics["total_memory_config"] - metrics["total_memory_down"])
    )
    print(f"Cluster Memory Utilization : {memory_util:>7}")
    print()


if __name__ == "__main__":
    try:
        # Make sure pyslurm works or else exit here
        pyslurmnode = pyslurm.node()
        # Get all node info
        new_nodes = pyslurmnode.get()
    except ValueError as value_error:
        print(f"Query failed - {value_error}")
        sys.exit(1)

    new_metrics = get_util(new_nodes)
    display_metrics(new_metrics)
