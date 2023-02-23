"""test_node.py - Test the node api functions."""

import sys
import time
import pytest
import pyslurm
import os
from pyslurm import Node, Nodes, RPCError


def test_reload():
    node = Node(Nodes().as_list()[0].name)

    # Nothing has been loaded at this point, just make sure everything is
    # on default values.
    assert node.weight is None
    assert node.slurm_version is None
    # Now load the node info
    node.reload()
    assert node.name == "localhost"
    assert node.weight is not None
    assert node.slurm_version is not None

    with pytest.raises(RPCError,
                       match=f"Node 'nonexistent' does not exist"):
        Node("nonexistent").reload()


def test_create():
    node = Node("testhostpyslurm")
    node.create()

    with pytest.raises(RPCError,
                       match=f"Invalid node state specified"):
        Node("testhostpyslurm2").create("idle")


# def test_delete():
#    node = Node("testhost1").delete()


def test_modify():
    node = Node(Nodes().as_list()[0].name)

    node.modify(weight=10000)
    assert node.reload().weight == 10000

    node.modify(Node(weight=20000))
    assert node.reload().weight == 20000

    node.modify(Node(weight=5000))
    assert node.reload().weight == 5000


def test_parse_all():
    Node(Nodes().as_list()[0].name).reload().as_dict()
