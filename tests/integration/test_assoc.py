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


def _modify_account(account, conn, with_kwargs, **kwargs):
    changes = Account(**kwargs)

    assert account.description != changes.description
    assoc_before = account.association.to_dict(recursive=True)

    if with_kwargs:
        account.modify(db_conn=conn, **kwargs)
    else:
        account.modify(changes, conn)

    account = Account.load(conn, account.name)
    assoc_after = account.association.to_dict(recursive=True)
    assert account.description == changes.description
    # Make sure we didn't change anything in the Association
    assert assoc_before == assoc_after


def _modify_user(user, conn, with_kwargs, **kwargs):
    changes = User(**kwargs)

    assert user.admin_level == pyslurm.AdminLevel.NONE
    assoc_before = user.default_association.to_dict(recursive=True)

    if with_kwargs:
        user.modify(db_conn=conn, **kwargs)
    else:
        user.modify(changes, conn)

    user = User.load(conn, user.name)
    assoc_after = user.default_association.to_dict(recursive=True)
    assert user.admin_level == changes.admin_level
    # Make sure we didn't change anything in the Association
    assert assoc_before == assoc_after


def _modify_assoc(assoc, conn, with_kwargs, **kwargs):
    changes = Association(**kwargs)

    assert assoc.group_jobs == "UNLIMITED"
    assert assoc.group_submit_jobs == "UNLIMITED"

    if with_kwargs:
        assoc.modify(db_conn=conn, **kwargs)
    else:
        assoc.modify(changes, conn)

    assoc = Association.load(conn, assoc.id)
    assert assoc.group_jobs == changes.group_jobs
    assert assoc.group_submit_jobs == changes.group_submit_jobs
    assert assoc.group_jobs != "UNLIMITED"
    assert assoc.group_submit_jobs != "UNLIMITED"


def _load_assoc(assoc_id, conn):
    assocs = conn.associations.load()
    return assocs.get(assoc_id)


def _load_account(name, conn):
    accounts = conn.accounts.load()
    assert len(accounts)
    return accounts.get(name)


def _load_user(name, conn):
    users = conn.users.load()
    assert len(users)
    return users.get(name)


def _delete_account(account, conn):
    account = Account.load(conn, account.name)
    account.delete()
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
    user.delete()
    conn.commit()
    assert not _load_user(user.name, conn)
    assert not _load_assoc(assoc_id, conn)


def _test_modify_delete(user, account, conn):
    assert conn.is_open
    _modify_account(account, conn, with_kwargs=False, description="this is a new description")
    _modify_account(account, conn, with_kwargs=True, description="another description")

    _modify_user(user, conn, with_kwargs=False, admin_level="administrator")
    _modify_user(user, conn, with_kwargs=True, admin_level="operator")

    _modify_assoc(user.default_association, conn, with_kwargs=False,
                  group_jobs=10, group_submit_jobs=20)
    _modify_assoc(user.default_association, conn, with_kwargs=True,
                  group_jobs=50, group_submit_jobs=100)

    _delete_account(account, conn)
    _delete_user(user, conn)


def _test_api(user, account, conn):
    # Save them before reloading
    user_name = user.name
    acc_name = account.name

    account = _add_account(account, conn)
    user = _add_user(user, conn)
    assert user.name == user_name
    assert account.name == acc_name
    _test_modify_delete(user, account, conn)


def test_user_and_account_no_assoc():
    random_name = str(uuid.uuid4())[:8]
    user_name = f"user_{random_name}"
    acc_name = f"acc_{random_name}"

    with pyslurm.db.connect() as conn:
        account = Account(name=acc_name)
        user = User(name=user_name, default_account=acc_name)
        _test_api(user, account, conn)


def test_user_and_accounts_with_assoc_empty():
    random_name = str(uuid.uuid4())[:8]
    user_name = f"user_{random_name}"
    acc_name = f"acc_{random_name}"

    with pyslurm.db.connect() as conn:
        account_assoc = Association(account=acc_name)
        account = Account(name=acc_name, association=account_assoc)
        user_assoc = Association(user=user_name, account=acc_name)
        user = User(name=user_name, associations=[user_assoc])
        _test_api(user, account, conn)
