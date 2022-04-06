#########################################################################
# job/step.pxd - interface to retrieve slurm job step informations
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
# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
# cython: language_level=3

from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from .job cimport Job

from pyslurm cimport slurm
from pyslurm.slurm cimport (
    job_step_info_t,
    slurm_get_job_steps,
    job_step_info_response_msg_t,
    step_update_request_msg_t,
    slurm_free_job_step_info_response_msg,
    slurm_init_update_step_msg,
    slurm_free_update_step_msg,
    slurm_free_job_step_info_response_msg,
    slurm_free_job_step_info_members,
    slurm_update_step,
    slurm_signal_job_step,
    slurm_kill_job_step,
    slurm_job_state_string,
    xfree,
    try_xmalloc,
)

cdef class JobSteps(dict):

    cdef:
        job_step_info_response_msg_t *info
        job_step_info_t tmp_info

    cdef dict _load(self, uint32_t job_id, int flags)
        

cdef class JobStep:

    cdef:
        job_step_info_t *ptr
        step_update_request_msg_t *umsg

    @staticmethod
    cdef JobStep from_ptr(job_step_info_t *in_ptr)
