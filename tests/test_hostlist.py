"""Test cases for hostlist."""

import pyslurm


def test_hostlist_create_new():
    """Hostlist: Create new hostlist"""
    hl = pyslurm.hostlist()
    hosts = "c1, c[2-3]"

    assert hl.create(hosts)
    assert hl.count() == 3

    assert hl.find("c3") == 2

    assert hl.push("c[4-5]") == 2
    assert hl.count() == 5

    assert hl.push_host("c6") == 1

    assert hl.ranged_string() == "c[1-6]"

    assert hl.shift() == "c1"
    assert hl.count() == 5

    assert hl.push_host("c6") == 1
    assert hl.ranged_string() == "c[2-6,6]"

    hl.uniq()
    assert hl.ranged_string() == "c[2-6]"

    hl.destroy()
    assert hl.count() == -1


def test_hostlist_create_empty():
    """Hostlist: Test create empty hostlist."""
    hl = pyslurm.hostlist()

    hl.create()
    assert hl.count() == 0

    hl.destroy()
    assert hl.count() == -1
