"""test_node.py - Test the node api functions."""

import sys
import time
import pytest
import pyslurm
import os
from pyslurm import Node, Nodes, RPCError


def test_load():
    name = Nodes.load().as_list()[0].name

    # Now load the node info
    node = Node.load(name)
    assert node.name == name
    assert node.weight is not None
    assert node.slurm_version is not None

    with pytest.raises(RPCError,
                       match=f"Node 'nonexistent' does not exist"):
        Node.load("nonexistent")


def test_create():
    node = Node("testhostpyslurm")
    node.create()

    with pytest.raises(RPCError,
                       match=f"Invalid node state specified"):
        Node("testhostpyslurm2").create("idle")


# def test_delete():
#    node = Node("testhost1").delete()


def test_modify():
    node = Node(Nodes.load().as_list()[0].name)

    node.modify(weight=10000)
    assert Node.load(node.name).weight == 10000

    node.modify(Node(weight=20000))
    assert Node.load(node.name).weight == 20000

    node.modify(Node(weight=5000))
    assert Node.load(node.name).weight == 5000


def test_parse_all():
    Node.load(Nodes.load().as_list()[0].name).as_dict()
