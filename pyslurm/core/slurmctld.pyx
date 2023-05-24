#########################################################################
# slurmctld.pyx - pyslurm slurmctld api
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

from pyslurm.core.error import verify_rpc, RPCError
from pyslurm.const import PreemptMode
from pyslurm.utils.enum_types import try_cast_enum


cdef class Config:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, job_id):
        raise RuntimeError("Cannot instantiate class directly")

    def __dealloc__(self):
        slurm_free_ctl_conf(self.ptr)
        self.ptr = NULL

    @staticmethod
    def load():
        cdef Config conf = Config.__new__(Config)
        verify_rpc(slurm_load_ctl_conf(0, &conf.ptr))
        return conf
        
    @property
    def cluster(self):
        return cstr.to_unicode(self.ptr.cluster_name)

    @property
    def preempt_mode(self):
        cdef char *tmp = slurm_preempt_mode_string(self.ptr.preempt_mode)
        return try_cast_enum(cstr.to_unicode(tmp), PreemptMode)

    @property
    def suspend_program(self):
        return cstr.to_unicode(self.ptr.suspend_program)

    @property
    def resume_program(self):
        return cstr.to_unicode(self.ptr.resume_program)

