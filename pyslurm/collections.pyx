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


cdef class MultiClusterMap:

    def __init__(self, data, typ=None,
                 val_type=None, key_type=None, id_attr=None, init_data=True):
        self.data = {} if init_data else data
        self._typ = typ
        self._key_type = key_type
        self._val_type = val_type
        self._id_attr = id_attr
        if init_data:
            self._init_data(data)

    def _init_data(self, data):
        if isinstance(data, list):
            for item in data:
                if isinstance(item, self._key_type):
                    item = self._val_type(item)
                    if LOCAL_CLUSTER not in self.data:
                        self.data[LOCAL_CLUSTER] = {}

                self.data[LOCAL_CLUSTER].update({self._item_id(item): item})
        elif isinstance(data, str):
            itemlist = data.split(",")
            items = {self._key_type(item):self._val_type(item)
                     for item in itemlist}
            self.data[LOCAL_CLUSTER] = items
        elif isinstance(data, dict):
            self.update(data)
        elif data is not None:
            raise TypeError(f"Invalid Type: {type(data)}")

    def _get_key_and_cluster(self, item):
        cluster = self._get_cluster()
        key = item

        if isinstance(item, self._val_type):
            cluster, key = item.cluster, self._item_id(item)
        elif isinstance(item, tuple) and len(item) == 2:
            cluster, key = item
        return cluster, key

    def _item_id(self, item):
        return self._id_attr.__get__(item)

    def __getitem__(self, item):
        if item in self.data:
            return self.data[item]

        cluster, key = self._get_key_and_cluster(item)
        return self.data[cluster][key]

    def __setitem__(self, where, item):
        if where in self.data:
            self.data[where] = item
        else:
            cluster, key = self._get_key_and_cluster(where)
            self.data[cluster][key] = item

    def __delitem__(self, item):
        if item in self.data:
            del self.data[item]
        else:
            cluster, key = self._get_key_and_cluster(item)
            del self.data[cluster][key]

    def __len__(self):
        return sum(len(data) for data in self.data.values())

    def __repr__(self):
        return f'{self._typ}([{", ".join(map(repr, self))}])'

    def __contains__(self, item):
        if isinstance(item, self._val_type):
            return self._check_for_value(self._item_id(item), item.cluster)
        elif isinstance(item, self._key_type):
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
        if not self.data or LOCAL_CLUSTER in self.data:
            return LOCAL_CLUSTER
        else:
            return next(iter(self.keys()))

    def __copy__(self):
        return self.copy()

    def copy(self):
        out = self.__class__.__new__(self.__class__)
        super(self.__class__, out).__init__(
            data=self.data.copy(),
            typ=self._typ,
            key_type=self._key_type,
            val_type=self._val_type,
            init_data=False,
        )
        return out

    def __iter__(self):
        for cluster in self.data.values():
            for item in cluster.values():
                yield item

    def __bool__(self):
        return bool(self.data)

    def get(self, key, cluster=None, default=None):
        cluster = self._get_cluster() if not cluster else cluster
        return self.data.get(cluster, {}).get(key, default)

    def add(self, item):
        if item.cluster not in self.data:
            self.data[item.cluster] = {}
        self.data[item.cluster][self._item_id(item)] = item

    def remove(self, item):
        cluster = self._get_cluster()
        key = item

        if isinstance(item, self._val_type):
            if self._check_for_value(self._item_id(item), item.cluster):
                cluster = item.cluster
                del self.data[item.cluster][self._item_id(item)]
        elif isinstance(item, tuple) and len(item) == 2:
            cluster, key = item
            del self.data[cluster][key]
        elif isinstance(item, self._key_type):
            del self.data[cluster][key]

        if not self.data[cluster]:
            del self.data[cluster]

    def as_dict(self, recursive=False, multi_cluster=False):
        cdef dict out = self.data.get(self._get_cluster(), {})

        if multi_cluster:
            if recursive:
                return multi_dict_recursive(self)
            return self.data
        elif recursive:
            return dict_recursive(out)

        return out

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

        del self.data[item.cluster][self._item_id(item)]
        return item

    def clear(self):
        self.data.clear()

    def pop(self, key, cluster=None, default=None):
        item = self.get(key, cluster=cluster, default=default)
        if not item:
            return default
    
        del self.data[cluster][key]
        return item

    def _check_val_type(self, item):
        if not isinstance(item, self._val_type):
            raise TypeError(f"Invalid Type: {type(item).__name__}. "
                            f"{self._val_type}.__name__ is required.")
        

    def _update(self, data, clus):
        for key in data:
            try:
                iterator = iter(data[key])
            except TypeError as e:
                cluster = self._get_cluster() if not clus else clus
                if not cluster in self.data:
                    self.data[cluster] = {}
                self.data[cluster].update(data)
                break
            else:
                cluster = key
                if not cluster in self.data:
                    self.data[cluster] = {}
                self.data[cluster].update(data[cluster])
#                col = data[cluster]
#               if hasattr(col, "keys") and callable(col.keys):
#                   for k in col.keys():

#               else:
#                   for item in col:
#                       k, v = item


    def update(self, data=None, cluster=None, **kwargs):
        if data:
            self._update(data, cluster)
        
        if kwargs:
            self._update(kwargs, cluster)


def multi_reload(cur, frozen=True):
    if not cur:
        return cur

    new = cur.__class__.load()
    for cluster, item in list(cur.keys().with_cluster()):
        if (cluster, item) in new.keys().with_cluster():
            cur[cluster][item] = new.pop(item, cluster)
        elif not frozen:
            del cur[cluster][item]

    if not frozen:
        for cluster, item in new.keys().with_cluster():
            if (cluster, item) not in cur.keys().with_cluster():
                cur[cluster][item] = new[cluster][item]
                
    return cur


def dict_recursive(collection):
    cdef dict out = {}
    for item_id, item in collection.items():
        out[item_id] = item.as_dict()
    return out


def multi_dict_recursive(collection):
    cdef dict out = collection.data.copy()
    for cluster, data in collection.data.items():
        out[cluster] = dict_recursive(data)
#       if group_id:
#           grp_id = group_id.__get__(item)
#           if grp_id not in out[cluster]:
#               out[cluster][grp_id] = {}
#           out[cluster][grp_id].update({_id: data})
#       else:
#           out[cluster][_id] = data

    return out


def sum_property(collection, prop, startval=0):
    out = startval
    for item in collection.values():
        data = prop.__get__(item)
        if data is not None:
            out += data

    return out
