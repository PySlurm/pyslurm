#!/usr/bin/env python
"""
List clusters
"""
from datetime import datetime

import pyslurm


def cluster_display(cluster):
    """Format output"""
    for cluster_key, cluster_value in cluster.items():
        if cluster_key == "accounting":
            print("\t accounting {")
            for acct_key, acct_value in cluster_value.items():
                print(f"\t\t{acct_key}={acct_value}")
            print("\t }")
        else:
            print(f"\t{cluster_key}={cluster_value}")


if __name__ == "__main__":
    try:
        start = (datetime(2016, 12, 1) - datetime(1970, 1, 1)).total_seconds()
        end = (datetime(2016, 12, 2) - datetime(1970, 1, 1)).total_seconds() - 1
        print(f"start={start}, end={end}")
        clusters = pyslurm.slurmdb_clusters()
        print(clusters.set_cluster_condition(start, end))
        clusters_dict = clusters.get()
        if clusters_dict:
            for key, value in clusters_dict.items():
                print(f"{'{'} Clusters: {key}")
                cluster_display(value)
                print("}")
        else:
            print("No cluster found --")
    except ValueError as e:
        print(f"Error:{e.args[0]}")
