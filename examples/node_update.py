#!/usr/bin/env python

"""Modify the state of a Node or BG Base Partition

   Valid States :

          NODE_RESUME
          NODE_STATE_DRAIN
          NODE_STATE_COMPLETING
          NODE_STATE_NO_RESPOND
          NODE_STATE_POWER_SAVE
          NODE_STATE_FAIL
          NODE_STATE_POWER_UP

   Some states are not valid on a Blue Gene
"""

import pyslurm

Node_dict = {
		'node_names': 'bps000',
		'node_state': pyslurm.NODE_STATE_DRAIN, 
		'reason': 'API test'
	}

try:
	a = pyslurm.node()
	rc = a.update(Node_dict)
except ValueError as e:
	print 'Node Update error - %s' % (e)
else:
	print "Node %s successfully updated" % Node_dict["node_names"]

