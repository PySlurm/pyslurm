#########################################################################
# test_db_connection.py - database connection api integration tests
#########################################################################
# Copyright (C) 2023 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# This file is part of PySlurm
#
# PySlurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# PySlurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PySlurm; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
"""test_db_connection.py - Test database connecting api functionalities."""

import pytest
import pyslurm


def test_create_instance():
    with pytest.raises(RuntimeError):
        pyslurm.db.Connection()


def test_open():
    conn = pyslurm.db.Connection.open() 
    assert conn.is_open


def test_close():
    conn = pyslurm.db.Connection.open() 
    assert conn.is_open

    conn.close()
    assert not conn.is_open
    # no-op
    conn.close()


def test_commit():
    conn = pyslurm.db.Connection.open() 
    assert conn.is_open
    conn.commit()


def test_rollback():
    conn = pyslurm.db.Connection.open() 
    assert conn.is_open
    conn.rollback()
