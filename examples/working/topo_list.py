#!/usr/bin/env python

import sys
import pyslurm
from time import gmtime, strftime

aux = pyslurm.topology()
err = aux.load()

if err:
    print ("Error loading topology")
    sys.exit(-1)
    
topology = aux.get()
print "*"*80

for item, topo in topology.items():
    print ("-----")
    print(item)
    print ("    nodes: " + str(topo['nodes']))
    print ("    switches: " + str(topo['switches']))
#pyslurm.slurm_print_topo_info_msg(b)
print "*"*80


