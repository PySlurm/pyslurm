#########################################################################
# util.pxd - pyslurm slurmdbd util functions
#########################################################################
# Copyright (C) 2022 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# Pyslurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Pyslurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3


cdef class SlurmListItem:
    
    def __cinit__(self):
        self.data = NULL

    @staticmethod
    cdef SlurmListItem from_ptr(void *item):
        cdef SlurmListItem wrap = SlurmListItem.__new__(SlurmListItem)
        wrap.data = item
        return wrap


cdef class SlurmList:
    """Convenience Wrapper around slurms List type"""
    def __cinit__(self):
        self.info = NULL
        self.itr = NULL
        self.itr_cnt = 0
        self.cnt = 0
        self.owned = True

    def __dealloc__(self):
        if self.owned:
            if self.itr:
                slurm_list_iterator_destroy(self.itr)

            if self.info:
                slurm_list_destroy(self.info)

    def __iter__(self):
        return self

    def __next__(self):
        if self.itr_cnt < self.cnt:
            self.itr_cnt += 1
            return SlurmListItem.from_ptr(slurm_list_next(self.itr))

        slurm_list_iterator_reset(self.itr)
        self.itr_cnt = 0
        raise StopIteration

    @staticmethod
    def iter_and_pop(SlurmList li):
        cnt = 0
        while cnt < li.cnt:
            yield SlurmListItem.from_ptr(slurm_list_pop(li.info))
            cnt += 1

    @staticmethod
    cdef SlurmList create(slurm.ListDelF delfunc):
        cdef SlurmList wrapper = SlurmList.__new__(SlurmList)
        wrapper.info = slurm_list_create(delfunc)
        wrapper.itr = slurm_list_iterator_create(wrapper.info)
        return wrapper

    @staticmethod
    cdef SlurmList wrap(List li, owned=True):
        if not li:
            raise ValueError("List is NULL")

        cdef SlurmList wrapper = SlurmList.__new__(SlurmList)
        wrapper.info = li
        wrapper.cnt = slurm_list_count(li)
        wrapper.itr = slurm_list_iterator_create(wrapper.info)
        wrapper.owned = owned
        return wrapper

    @staticmethod
    cdef to_str_pylist(List in_list):
        cdef:
            ListIterator itr = slurm_list_iterator_create(in_list)
            char* entry = NULL
            list out = []

        for i in range(slurm_list_count(in_list)):
            entry = <char*>slurm_list_next(itr)
            pystr = cstr.to_unicode(entry)
            if pystr:
                out.append(pystr)

        slurm_list_iterator_destroy(itr)
        return out

    @staticmethod
    cdef to_char_list(List *in_list, vals):
        cdef:
            List li = in_list[0]
            char *entry = NULL

        if in_list[0]:
            slurm_list_destroy(li)
            in_list[0] = NULL

        if not vals:
            in_list[0] = NULL
        else:
            in_list[0] = slurm_list_create(slurm_xfree_ptr)
            for val in vals:
                if val:
                    entry = NULL
                    cstr.fmalloc(&entry, str(val))
                    slurm_list_append(in_list[0], entry)

    def is_null(self):
        if not self.info:
            return True
        else:
            return False
