#!/usr/bin/env python
"""
Modify the state of a Node or BG Base Partition

   Valid States :

          NODE_RESUME
          NODE_STATE_DRAIN
          NODE_STATE_COMPLETING
          NODE_STATE_NO_RESPOND
          NODE_STATE_POWERED_DOWN
          NODE_STATE_FAIL
          NODE_STATE_POWERING_UP

   Some states are not valid on a Blue Gene
"""

import pyslurm

Node_dict = {
    "node_names": "c10",
    "node_state": pyslurm.NODE_STATE_DRAIN,
    "reason": "API test",
}

try:
    a = pyslurm.node()
    rc = a.update(Node_dict)
except ValueError as e:
    print(f"Node Update error - {e.args[0]}")
else:
    print(f"Node {Node_dict['node_names']} successfully updated")
