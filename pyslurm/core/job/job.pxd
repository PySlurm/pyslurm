#########################################################################
# job.pyx - interface to retrieve slurm job informations
#########################################################################
# Copyright (C) 2022 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# Pyslurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
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

from pyslurm.core.common cimport cstr, ctime
from pyslurm.core.common.uint cimport *
from pyslurm.core.common.ctime cimport time_t

from libc.string cimport memcpy, memset
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t, int64_t
from libc.stdlib cimport free

from pyslurm.core.job.submission cimport JobSubmitDescription
from pyslurm.core.job.step cimport JobSteps, JobStep

from pyslurm cimport slurm
from pyslurm.slurm cimport (
    working_cluster_rec,
    slurm_msg_t,
    job_id_msg_t,
    slurm_msg_t_init,
    return_code_msg_t,
    slurm_send_recv_controller_msg,
    slurm_free_return_code_msg,
    slurm_free_job_info_msg,
    slurm_free_job_info,
    slurm_load_job,
    slurm_load_jobs,
    job_info_msg_t,
    slurm_job_info_t,
    slurm_job_state_string,
    slurm_job_reason_string,
    slurm_job_share_string,
    slurm_job_batch_script,
    slurm_get_job_stdin,
    slurm_get_job_stdout,
    slurm_get_job_stderr,
    slurm_signal_job,
    slurm_kill_job,
    slurm_resume,
    slurm_suspend,
    slurm_update_job,
    slurm_notify_job,
    slurm_requeue,
    xfree,
    try_xmalloc,
)


cdef class Jobs(dict):

    cdef:
        job_info_msg_t *info
        slurm_job_info_t tmp_info


cdef class Job:

    cdef:
        slurm_job_info_t *ptr
        dict passwd
        dict groups

    cdef alloc(self)
    cdef _calc_run_time(self)

    @staticmethod
    cdef Job from_ptr(slurm_job_info_t *in_ptr)

