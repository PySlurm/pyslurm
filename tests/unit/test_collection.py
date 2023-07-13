#########################################################################
# test_collection.py - custom collection unit tests
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
"""test_collection.py - Unit test custom collection functionality."""

import pytest
import pyslurm
from pyslurm.xcollections import sum_property

LOCAL_CLUSTER = pyslurm.settings.LOCAL_CLUSTER
OTHER_CLUSTER = "other_cluster"


class TestMultiClusterMap:

    def _create_collection(self):
        data = {
            LOCAL_CLUSTER: {
                1: pyslurm.db.Job(1),
                2: pyslurm.db.Job(2),
            },
            OTHER_CLUSTER: {
                1: pyslurm.db.Job(1, cluster="other_cluster"),
                10: pyslurm.db.Job(10, cluster="other_cluster"),
            }
        }
        col = pyslurm.db.Jobs()
        col.update(data)
        return col

    def test_create(self):
        jobs = pyslurm.db.Jobs("101,102")
        assert len(jobs) == 2
        assert 101 in jobs
        assert 102 in jobs
        assert jobs[101].id == 101
        assert jobs[102].id == 102

        jobs = pyslurm.db.Jobs([101, 102])
        assert len(jobs) == 2
        assert 101 in jobs
        assert 102 in jobs
        assert jobs[101].id == 101
        assert jobs[102].id == 102
        
        jobs = pyslurm.db.Jobs(
            {
                101: pyslurm.db.Job(101),
                102: pyslurm.db.Job(102),
            }
        )
        assert len(jobs) == 2
        assert 101 in jobs
        assert 102 in jobs
        assert jobs[101].id == 101
        assert jobs[102].id == 102
        assert True

    def test_add(self):
        col = self._create_collection()
        col_len = len(col)

        item = pyslurm.db.Job(20)
        col.add(item)

        assert len(col[LOCAL_CLUSTER]) == 3
        assert len(col) == col_len+1

        item = pyslurm.db.Job(20, cluster=OTHER_CLUSTER)
        col.add(item)

        assert len(col[LOCAL_CLUSTER]) == 3
        assert len(col) == col_len+2

    def test_get(self):
        col = self._create_collection()

        item = col.get(1)
        assert item is not None
        assert isinstance(item, pyslurm.db.Job)
        assert item.cluster == LOCAL_CLUSTER

        item = col.get((OTHER_CLUSTER, 1))
        assert item is not None
        assert isinstance(item, pyslurm.db.Job)
        assert item.cluster == OTHER_CLUSTER

        item = col.get(30)
        assert item is None

    def test_keys(self):
        col = self._create_collection()

        keys = col.keys()
        keys_with_cluster = keys.with_cluster()
        assert len(keys) == len(col)

        for k in keys:
            assert k

        for cluster, k in keys_with_cluster:
            assert cluster
            assert cluster in col.data
            assert k

    def test_values(self):
        col = self._create_collection()
        values = col.values()

        assert len(values) == len(col)

        for item in values:
            assert item
            print(item)
            assert isinstance(item, pyslurm.db.Job)
            assert item.cluster in col.data

    def test_getitem(self):
        col = self._create_collection()

        item1 = col[LOCAL_CLUSTER][1]
        item2 = col[1]
        item3 = col[OTHER_CLUSTER][1]

        assert item1
        assert item2
        assert item3
        assert item1 == item2
        assert item1 != item3

        with pytest.raises(KeyError):
            item = col[30]

        with pytest.raises(KeyError):
            item = col[OTHER_CLUSTER][30]

    def test_setitem(self):
        col = self._create_collection()
        col_len = len(col)

        item = pyslurm.db.Job(30)
        col[item.id] = item
        assert len(col[LOCAL_CLUSTER]) == 3
        assert len(col) == col_len+1

        item = pyslurm.db.Job(50, cluster=OTHER_CLUSTER)
        col[OTHER_CLUSTER][item.id] = item
        assert len(col[OTHER_CLUSTER]) == 3
        assert len(col) == col_len+2

        item = pyslurm.db.Job(100, cluster=OTHER_CLUSTER)
        col[item] = item
        assert len(col[OTHER_CLUSTER]) == 4
        assert len(col) == col_len+3

        item = pyslurm.db.Job(101, cluster=OTHER_CLUSTER)
        col[(item.cluster, item.id)] = item
        assert len(col[OTHER_CLUSTER]) == 5
        assert len(col) == col_len+4

        new_other_data = {
            1: pyslurm.db.Job(1),
            2: pyslurm.db.Job(2),
        }
        col[OTHER_CLUSTER] = new_other_data
        assert len(col[OTHER_CLUSTER]) == 2
        assert len(col[LOCAL_CLUSTER]) == 3
        assert 1 in col[OTHER_CLUSTER]
        assert 2 in col[OTHER_CLUSTER]

    def test_delitem(self):
        col = self._create_collection()
        col_len = len(col)

        del col[1]
        assert len(col[LOCAL_CLUSTER]) == 1
        assert len(col) == col_len-1

        del col[OTHER_CLUSTER][1]
        assert len(col[OTHER_CLUSTER]) == 1
        assert len(col) == col_len-2

        del col[OTHER_CLUSTER]
        assert len(col) == 1
        assert OTHER_CLUSTER not in col.data

    def test_copy(self):
        col = self._create_collection()
        col_copy = col.copy()
        assert col == col_copy

    def test_iter(self):
        col = self._create_collection()
        for k in col:
            assert k

    def test_items(self):
        col = self._create_collection()
        for k, v in col.items():
            assert k
            assert v
            assert isinstance(v, pyslurm.db.Job)

        for c, k, v in col.items().with_cluster():
            assert c
            assert k
            assert v
            assert isinstance(v, pyslurm.db.Job)

    def test_popitem(self):
        col = self._create_collection()
        col_len = len(col)

        item = col.popitem()
        assert item
        assert isinstance(item, pyslurm.db.Job)
        assert len(col) == col_len-1

    def test_update(self):
        col = self._create_collection()
        col_len = len(col)

        col_update = {
            30: pyslurm.db.Job(30),
            50: pyslurm.db.Job(50),
        }
        col.update(col_update)
        assert len(col) == col_len+2
        assert len(col[LOCAL_CLUSTER]) == 4
        assert 30 in col
        assert 50 in col

        col_update = {
            "new_cluster": {
                80: pyslurm.db.Job(80, cluster="new_cluster"),
                50: pyslurm.db.Job(50, cluster="new_cluster"),
            }
        }
        col.update(col_update)
        assert len(col) == col_len+4
        assert len(col[LOCAL_CLUSTER]) == 4
        assert len(col["new_cluster"]) == 2
        assert 80 in col
        assert 50 in col
        
        col_update = {
            200: pyslurm.db.Job(200, cluster=OTHER_CLUSTER),
            300: pyslurm.db.Job(300, cluster=OTHER_CLUSTER),
        }
        col.update({OTHER_CLUSTER: col_update})
        assert len(col) == col_len+6
        assert len(col[OTHER_CLUSTER]) == 4
        assert 200 in col
        assert 300 in col

        empty_col = pyslurm.db.Jobs()
        empty_col.update(col_update)
        assert len(empty_col) == 2

    def test_pop(self):
        col = self._create_collection()
        col_len = len(col)
        
        item = col.pop(1)
        assert item
        assert item.id == 1
        assert len(col) == col_len-1

        item = col.pop(999, default="def")
        assert item == "def"

    def test_contains(self):
        col = self._create_collection()
        item = pyslurm.db.Job(1)
        assert item in col

        assert 10 in col
        assert 20 not in col

        assert (OTHER_CLUSTER, 10) in col
        assert (LOCAL_CLUSTER, 10) not in col

    def test_to_json(self):
        col = self._create_collection()
        data = col.to_json(multi_cluster=True)
        assert data

    def test_cluster_view(self):
        col = self._create_collection()
        assert len(col.clusters()) == 2
        for c in col.clusters():
            assert c

    def test_sum_property(self):
        class TestObject:
            @property
            def memory(self):
                return 10240

            @property
            def cpus(self):
                return None

        object_dict = {i: TestObject() for i in range(10)}

        expected = 10240 * 10
        assert sum_property(object_dict, TestObject.memory) == expected

        expected = 0
        assert sum_property(object_dict, TestObject.cpus) == expected
