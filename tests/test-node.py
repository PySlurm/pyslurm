from __future__ import print_function, division, absolute_import

import pyslurm
import subprocess
from types import *

def setup():
    pass


def teardown():
    pass


def test_get_nodes():
    all_nodes = pyslurm.node.get_nodes()
    assert type(all_nodes) is ListType

    all_node_ids = pyslurm.node.get_nodes_ids()
    assert type(all_node_ids) is ListType

    first_node = all_nodes[0]
    assert first_node.name in all_node_ids
