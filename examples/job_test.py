#!/usr/bin/env python

from __future__ import print_function

import pyslurm

try:
    a = pyslurm.job()

    jobs =  a.get()
    print(jobs)
except ValueError as e:
    print("Job list error - {0}".format(e.args[0]))
