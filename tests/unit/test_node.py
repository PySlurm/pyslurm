"""test_node.py - Test the node api functions."""

import pytest
import pyslurm
from pyslurm import Node, Nodes


def test_create_instance():
    node = Node("localhost")
    assert node.name == "localhost"


def test_parse_all():
    Node("localhost").as_dict()


def test_create_nodes_collection():
    # TODO
    assert True


def test_setting_attributes():
    # TODO
    assert True
