#!/usr/bin/env python

import pyslurm
from time import gmtime, strftime

a, b = pyslurm.slurm_load_topo()
print "*"*80
pyslurm.slurm_print_topo_info_msg(b)
print "*"*80


