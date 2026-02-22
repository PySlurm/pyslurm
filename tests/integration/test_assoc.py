#########################################################################
# test_assoc.py - database assoc/accounts/user api tests
#########################################################################
# Copyright (C) 2026 Toni Harzendorf <toni.harzendorf@gmail.com>
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
"""test_assoc.py - Integration test assoc/account/user functionalities."""

import pyslurm
import pytest
import uuid
from pyslurm.db import (
    User,
    Account,
    Association,
)


def _modify_account(account, conn):
    new_desc = "this is a new description"
    changes = Account(description=new_desc)
    assert account.description != new_desc
    assoc_before = account.association.to_dict(recursive=True)
    account.modify(conn, changes)
    account = Account.load(conn, account.name)
    assoc_after = account.association.to_dict(recursive=True)
    assert account.description == new_desc
    # Make sure we didn't change anything in the Association
    assert assoc_before == assoc_after


def _modify_user(user, conn):
    user_changes = User(
        admin_level = pyslurm.AdminLevel.ADMINISTRATOR
    )
    assert user.admin_level == pyslurm.AdminLevel.NONE
    assoc_before = user.default_association.to_dict(recursive=True)
    user.modify(conn, user_changes)
    user = User.load(conn, user.name)
    assoc_after = user.default_association.to_dict(recursive=True)
    assert user.admin_level == pyslurm.AdminLevel.ADMINISTRATOR
    # Make sure we didn't change anything in the Association
    assert assoc_before == assoc_after


def _load_assoc(assoc_id, conn):
    assocs = pyslurm.db.Associations.load(conn)
    return assocs.get(assoc_id)


def _load_account(name, conn):
    accounts = pyslurm.db.Accounts.load(conn)
    assert len(accounts)
    return accounts.get(name)


def _load_user(name, conn):
    users = pyslurm.db.Users.load(conn)
    assert len(users)
    return users.get(name)


def _delete_account(account, conn):
    account = Account.load(conn, account.name)
    account.delete(conn)
    conn.commit()
    assert not _load_account(account.name, conn)
    assert not _load_assoc(account.association.id, conn)


def _add_account(account, conn):
    account.create(conn)
    # Although everything works without this commit, the slurmdbd complains
    # that it can't find the account assoc when going to add the user.
    # Everything is created properly, but this error appears. This is
    # probably why you can't create both account and user / associations
    # directly with sacctmgr. Either it is designed like this, or this is a
    # bug in the as_mysql plugin.
    # The tests pass anyway, so it is fine, but needs to be documented.
    conn.commit()
    account = _load_account(account.name, conn)
    assoc = account.association
    assert assoc
    assert _load_assoc(assoc.id, conn)
    assert assoc.account == account.name
    assert assoc.user is None
    assert assoc.parent_account == "root"
    return account


def _add_user(user, conn):
    user.create(conn)
    conn.commit()
    user = _load_user(user.name, conn)
    assert len(user.associations) == 1
    assoc = user.default_association
    assert assoc
    assert _load_assoc(assoc.id, conn)
    assert assoc.user == user.name
    assert assoc.account == user.default_account
    assert assoc.is_default
    return user


def _delete_user(user, conn):
    assoc_id = user.default_association.id
    user = User.load(conn, user.name)
    user.delete(conn)
    conn.commit()
    assert not _load_user(user.name, conn)
    assert not _load_assoc(assoc_id, conn)


def _test_modify_delete(user, account, conn):
    assert conn.is_open
    _modify_account(account, conn)
    _modify_user(user, conn)
    _delete_account(account, conn)
    _delete_user(user, conn)


def test_user_and_account_no_assoc():
    random_name = str(uuid.uuid4())[:8]
    user_name = f"user_{random_name}"
    acc_name = f"acc_{random_name}"

    with pyslurm.db.connect() as conn:
        account = Account(name=acc_name)
        user = User(name=user_name, default_account=acc_name)

        account = _add_account(account, conn)
        user = _add_user(user, conn)
        assert user.name == user_name
        assert account.name == acc_name
        _test_modify_delete(user, account, conn)


def test_user_and_accounts_with_assoc_empty():
    random_name = str(uuid.uuid4())[:8]
    user_name = f"user_{random_name}"
    acc_name = f"acc_{random_name}"

    with pyslurm.db.connect() as conn:
        account_assoc = Association(account=acc_name)
        account = Account(name=acc_name, association=account_assoc)
        user_assoc = Association(user=user_name, account=acc_name)
        user = User(name=user_name, associations=[user_assoc])

        account = _add_account(account, conn)
        user = _add_user(user, conn)
        assert user.name == user_name
        assert account.name == acc_name
        _test_modify_delete(user, account, conn)
