#########################################################################
# collections.pyx - pyslurm custom collections
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
#
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3

from pyslurm.db.cluster import LOCAL_CLUSTER


class BaseView:

    def __init__(self, mcm):
        self._mcm = mcm
        self._data = mcm.data

    def __len__(self):
        return len(self._mcm)

    def __repr__(self):
        data = ", ".join(map(repr, self))
        return f'{self.__class__.__name__}([{data}])'


class ValuesView(BaseView):

    def __contains__(self, val):
        for item in self._mcm:
            if item is val or item == val:
                return True
        return False

    def __iter__(self):
        for item in self._mcm:
            yield item


class MCKeysView(BaseView):

    def __contains__(self, item):
        cluster, key, = item
        return key in self._data[cluster]

    def __iter__(self):
        for cluster, keys in self._data.items():
            for key in keys:
                yield (cluster, key)


class KeysView(BaseView):

    def __contains__(self, item):
        return item in self._mcm

    def __iter__(self):
        for cluster, keys in self._data.items():
            yield from keys

    def with_cluster(self):
        return MCKeysView(self._mcm)


class ItemsView(BaseView):

    def __contains__(self, item):
        key, val = item
        cluster = self._mcm._get_cluster()

        try:
            out = self._mcm.data[cluster][key]
        except KeyError:
            return False
        else:
            return out is val or out == val

    def __iter__(self):
        for cluster, data in self._mcm.data.items():
            for key in data:
                yield (key, data[key])

    def with_cluster(self):
        return MCItemsView(self._mcm)

    
class MCItemsView(BaseView):

    def __contains__(self, item):
        cluster, key, val = item

        try:
            out = self._mcm.data[cluster][key]
        except KeyError:
            return False
        else:
            return out is val or out == val

    def __iter__(self):
        for cluster, data in self._mcm.data.items():
            for key in data:
                yield (cluster, key, data[key])


cdef class MultiClusterCollection:

    def __init__(self, data, col_type=None,
                 col_val_type=None, col_key_type=None, init_data=True):
        self.data = data if data else {LOCAL_CLUSTER: {}}
        self._col_type = col_type
        self._col_key_type = col_key_type
        self._col_val_type = col_val_type
        if init_data:
            self._init_data(data)

    def _init_data(self, data):
        if isinstance(data, list):
            for item in data:
                if isinstance(item, self._col_key_type):
                    item = self._col_val_type(item)
                self.data[LOCAL_CLUSTER].update({item._id: item})
        elif isinstance(data, str):
            itemlist = data.split(",")
            items = {item:self._col_val_type(item) for item in itemlist}
            self.data[LOCAL_CLUSTER].update(items)
        #elif isinstance(data, dict):
        #    self.extend([item for item in data.values()])
        elif data is not None:
            raise TypeError("Invalid Type: {type(data)}")

    def _get_key_and_cluster(self, item):
        cluster = self._get_cluster()
        key = item

        if isinstance(item, self._col_val_type):
            cluster, key = item.cluster, item._id
        elif isinstance(item, tuple) and len(item) == 2:
            cluster, key = item
        return cluster, key

    def __getitem__(self, item):
        cluster, key = self._get_key_and_cluster(item)
        return self.data[cluster][key]

    def __setitem__(self, where, item):
        cluster, key = self._get_key_and_cluster(where)
        self.data[cluster][key] = item

    def __delitem__(self, item):
        cluster, key = self._get_key_and_cluster(item)
        del self.data[cluster][key]

    def __len__(self):
        sum(len(data) for data in self.data.values())

    def __repr__(self):
        return f'{self._col_type}([{", ".join(map(repr, self))}])'

    def __contains__(self, item):
        if isinstance(item, self._col_val_type):
            return self._check_for_value(item._id, item.cluster)
        elif isinstance(item, self._col_key_type):
            return self._check_for_value(item, self._get_cluster())
        elif isinstance(item, tuple):
            cluster, item = item
            return self._check_for_value(item, cluster)

        return False

    def _check_for_value(self, val_id, cluster):
        cluster_data = self.data.get(cluster)
        if cluster_data and val_id in cluster_data:
            return True
        return False

    def _get_cluster(self):
        if LOCAL_CLUSTER in self.data:
            return LOCAL_CLUSTER
        else:
            return next(iter(self.keys()))

    def __copy__(self):
        return self.copy()

    def copy(self):
        return MultiClusterCollection(
            data=self.data.copy(),
            col_type=self._col_type,
            col_key_type=self._col_key_type,
            col_val_type=self._col_val_type,
            init_data=False,
        )

    def __iter__(self):
        for cluster in self.data.values():
            for item in cluster.values():
                yield item

    def get(self, key, cluster=None, default=None):
        cluster = self._get_cluster() if not cluster else cluster
        cluster_data = self.data.get(cluster, {})
        return cluster_data.get(key, default)

    def add(self, item):
        if item.cluster not in self.data:
            self.data[item.cluster] = {}
        self.data[item.cluster][item._id] = item

    def remove(self, item):
        cluster = self._get_cluster()
        key = item

        if isinstance(item, self._col_val_type):
            if self._check_for_value(item._id, item.cluster):
                cluster = item.cluster
                del self.data[item.cluster][item._id]
        elif isinstance(item, tuple) and len(item) == 2:
            cluster, key = item
            del self.data[cluster][key]
        elif isinstance(item, self._col_key_type):
            del self.data[cluster][key]

        if not self.data[cluster]:
            del self.data[cluster]

    def as_dict(self, recursive=False):
        return self.data

    def keys(self):
        return KeysView(self)
                
    def items(self):
        return ItemsView(self)

    def values(self):
        return self

    def popitem(self):
        try:
            item = next(iter(self))
        except StopIteration:
            raise KeyError from None

        del self.data[item.cluster][item._id]
        return item

    def clear(self):
        self.data.clear()

    def pop(self, key, cluster=None, default=None):
        item = self.get(key, default, cluster)
        if not item:
            return default
    
        del self.data[cluster][key]
        return item
