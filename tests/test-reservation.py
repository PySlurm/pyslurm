from __future__ import absolute_import, unicode_literals

import pyslurm
import time
from nose.tools import assert_equals, assert_true

from common import scontrol_show

def test_reservation_create():
    """Reservation: Test reservation().create()."""
    resv_test = {
        "node_cnt": 1,
        "users": 'root,slurm',
        "start_time": int(time.time()),
        "duration": 600,
        "licenses": "matlab:1",
        "name": "resv_test"
    }
    r = pyslurm.reservation().create(resv_test)
    assert_equals(r, "resv_test")


def test_reservation_get():
    """Reservation: Test reservation().get()."""
    resv = pyslurm.reservation().get()

    assert_true(isinstance(resv, dict))
    assert_equals(resv["resv_test"]["licenses"], {"matlab": "1"})
    assert_equals(resv["resv_test"]["users"], ["root", "slurm"])

    start = resv["resv_test"]["start_time"]
    end = resv["resv_test"]["end_time"]

    assert_equals(end - start, 600 * 60)


def test_reservation_update():
    """Reservation: Test reservation().update()."""
    resv_update = {
        "name": "resv_test",
        "duration": 8000
    }
    rc = pyslurm.reservation().update(resv_update)
    assert_equals(rc, 0)


def test_reservation_count():
    """Reservation: Test reservation count."""
    resv = pyslurm.reservation().get()
    assert_equals(len(resv), 1)


def test_reservation_scontrol():
    """Reservation: Compare scontrol values to PySlurm values."""
    test_resv_info = pyslurm.reservation().get()["resv_test"]
    sctl_dict = scontrol_show('reservation', 'resv_test')

    assert_equals(test_resv_info["node_list"], sctl_dict["Nodes"])
    assert_equals(test_resv_info["node_cnt"], int(sctl_dict["NodeCnt"]))
    assert_equals(",".join(test_resv_info["users"]), sctl_dict["Users"])


def test_reservation_delete():
    """Reservation: Test reservation().delete()."""
    delete = pyslurm.reservation().delete("resv_test")
    count = pyslurm.reservation().get()
    assert_equals(delete, 0)
    assert_equals(len(count), 0)
