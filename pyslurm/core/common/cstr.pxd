#########################################################################
# common/cstr.pxd - slurm string functions
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
# cython: c_string_type=unicode, c_string_encoding=utf8
# cython: language_level=3

from pyslurm cimport slurm
from pyslurm.slurm cimport xfree, try_xmalloc, xmalloc, xfree_ptr
from libc.string cimport memcpy, strlen

cdef char *from_unicode(s)
cdef to_unicode(char *s, default=*)
cdef fmalloc(char **old, val)
cdef fmalloc2(char **old, char **old2, val)
cdef free_array(char **arr, count)
cdef list to_list(char *str_list)
cdef from_list(char **old, vals, delim=*)
cdef dict to_dict(char *str_dict, str delim1=*, str delim2=*)
cdef dict from_dict(char **old, vals, prepend=*, str delim1=*, str delim2=*)
cdef to_gres_dict(char *gres)
cdef from_gres_dict(vals, typ=*)