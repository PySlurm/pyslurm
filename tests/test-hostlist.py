from __future__ import absolute_import, unicode_literals

import pyslurm
from nose.tools import assert_equals, assert_true

def test_hostlist_create_new():
    """Hostlist: Create new hostlist"""
    hl = pyslurm.hostlist()
    hosts = "c1, c[2-3]"

    assert_true(hl.create(hosts))
    assert_equals(hl.count(), 3)

    assert_equals(hl.find("c3"), 2)

    assert_equals(hl.push("c[4-5]"), 2)
    assert_equals(hl.count(), 5)

    assert_equals(hl.push_host("c6"), 1)

    assert_equals(hl.ranged_string(), "c[1-6]")

    assert_equals(hl.shift(), "c1")
    assert_equals(hl.count(), 5)

    assert_equals(hl.push_host("c6"), 1)
    assert_equals(hl.ranged_string(), "c[2-6,6]")

    hl.uniq()
    assert_equals(hl.ranged_string(), "c[2-6]")

    hl.destroy()
    assert_equals(hl.count(), -1)


def test_hostlist_create_empty():
    """Hostlist: Test create empty hostlist."""
    hl = pyslurm.hostlist()

    hl.create()
    assert_equals(hl.count(), 0)

    hl.destroy()
    assert_equals(hl.count(), -1)
