#########################################################################
# step.pyx - pyslurm slurmdbd step api
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

from os import WIFSIGNALED, WIFEXITED, WTERMSIG, WEXITSTATUS
from pyslurm.core.error import RPCError
from pyslurm.core.db.tres cimport TrackableResources, TrackableResource
from pyslurm.core.common.uint import *
from pyslurm.core.common.ctime import _raw_time
from pyslurm.core.common import (
    gid_to_name,
    uid_to_name,
    instance_to_dict,
)
from pyslurm.core.job.util import cpufreq_to_str


cdef class JobStep:

    def __cinit__(self):
        self.ptr = NULL

    def __dealloc__(self):
        slurmdb_destroy_step_rec(self.ptr)
        self.ptr = NULL

    @staticmethod
    cdef JobStep from_ptr(slurmdb_step_rec_t *step):
        cdef JobStep wrap = JobStep.__new__(JobStep)
        wrap.ptr = step
        wrap.stats = JobStats.from_step(wrap)
        return wrap

    def as_dict(self):
        cdef dict out = instance_to_dict(self)
        out["stats"] = self.stats.as_dict()
        return out

    def _xlate_from_id(self, sid):
        if sid == slurm.SLURM_BATCH_SCRIPT:
            return "batch"
        elif sid == slurm.SLURM_EXTERN_CONT:
            return "extern"
        elif sid == slurm.SLURM_INTERACTIVE_STEP:
            return "interactive"
        elif sid == slurm.SLURM_PENDING_STEP:
            return "pending"
        else:
            return sid

    def _xlate_to_id(self, sid):
        if sid == "batch":
            return slurm.SLURM_BATCH_SCRIPT
        elif sid == "extern":
            return slurm.SLURM_EXTERN_CONT
        elif sid == "interactive":
            return slurm.SLURM_INTERACTIVE_STEP
        elif sid == "pending":
            return slurm.SLURM_PENDING_STEP
        else:
            return int(sid)

    @property
    def num_nodes(self):
        nnodes = u32_parse(self.ptr.nnodes)
        if not nnodes and self.ptr.tres_alloc_str:
            return TrackableResources.find_count_in_str(
                    self.ptr.tres_alloc_str, slurm.TRES_NODE)
        else:
            return nnodes

    @property
    def cpus(self):
        req_cpus = TrackableResources.find_count_in_str(
                self.ptr.tres_alloc_str, slurm.TRES_CPU)

        if req_cpus == slurm.INFINITE64:
            return 0

        return req_cpus
#       if req_cpus == slurm.INFINITE64 and step.job_ptr:
#           tres_alloc_str = cstr.to_unicode(step.job_ptr.tres_alloc_str)
#           req_cpus = TrackableResources.find_count_in_str(tres_alloc_str,
#                                                           slurm.TRES_CPU)
#           if not req_cpus:
#               tres_req_str = cstr.to_unicode(step.job_ptr.tres_req_str)
#               req_cpus = TrackableResources.find_count_in_str(tres_req_str,
#                                                                slurm.TRES_CPU)

    @property
    def memory(self):
        val = TrackableResources.find_count_in_str(self.ptr.tres_alloc_str, 
                                                   slurm.TRES_MEM)
        return val

    # Only in Parent Job available:
    # resvcpu?

    @property
    def container(self):
        return cstr.to_unicode(self.ptr.container)

    @property
    def elapsed_time(self):
        # seconds
        return _raw_time(self.ptr.elapsed)

    @property
    def end_time(self):
        return _raw_time(self.ptr.end)

    @property
    def eligible_time(self):
        return _raw_time(self.ptr.start)

    @property
    def start_time(self):
        return _raw_time(self.ptr.start)

    @property
    def exit_code(self):
        # TODO
        return None

    @property
    def ntasks(self):
        return u32_parse(self.ptr.ntasks)

    @property
    def cpu_frequency_min(self):
        return cpufreq_to_str(self.ptr.req_cpufreq_min)

    @property
    def cpu_frequency_max(self):
        return cpufreq_to_str(self.ptr.req_cpufreq_max)

    @property
    def cpu_frequency_governor(self):
        return cpufreq_to_str(self.ptr.req_cpufreq_gov)

    @property
    def nodelist(self):
        return cstr.to_unicode(self.ptr.nodes)

    @property
    def id(self):
        return self._xlate_from_id(self.ptr.step_id.step_id)

    @property
    def job_id(self):
        return self.ptr.step_id.job_id

    @property
    def name(self):
        return cstr.to_unicode(self.ptr.stepname)

#    @property
#    def distribution(self):
#        # ptr.task_dist
#        pass

    @property
    def state(self):
        """str: State this Job step is in."""
        return cstr.to_unicode(slurm_job_state_string(self.ptr.state))

    @property
    def cancelled_by(self):
        return uid_to_name(self.ptr.requid)

    @property
    def submit_line(self):
        return cstr.to_unicode(self.ptr.submit_line)

    @property
    def suspended_time(self):
        # seconds
        return _raw_time(self.ptr.elapsed)