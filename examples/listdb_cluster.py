#!/usr/bin/env python
"""
List clusters
"""
from datetime import datetime

import pyslurm


def cluster_display(cluster):
    """Format output"""
    for key, value in cluster.items():
        if key == "accounting":
            print("\t accounting {")
            for acct_key, acct_value in value.items():
                print("\t\t{}={}".format(acct_key, acct_value))
            print("\t }")
        else:
            print("\t{}={}".format(key, value))


if __name__ == "__main__":
    try:
        start = (datetime(2016, 12, 1) - datetime(1970, 1, 1)).total_seconds()
        end = (datetime(2016, 12, 2) - datetime(1970, 1, 1)).total_seconds() - 1
        print("start={}, end={}".format(start, end))
        clusters = pyslurm.slurmdb_clusters()
        print(clusters.set_cluster_condition(start, end))
        clusters_dict = clusters.get()
        if clusters_dict:
            for key, value in clusters_dict.items():
                print("{} Clusters: {}".format("{", key))
                cluster_display(value)
                print("}")
        else:
            print("No cluster found --")
    except ValueError as e:
        print("Error:{}".format(e.args[0]))
