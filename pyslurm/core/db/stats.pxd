#########################################################################
# stats.pxd - pyslurm slurmdbd job stats
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

from pyslurm cimport slurm
from pyslurm.slurm cimport (
    try_xmalloc,
    slurmdb_stats_t,
    slurmdb_job_rec_t,
)
from pyslurm.core.db.tres cimport TrackableResources
from pyslurm.core.db.step cimport JobStep
from pyslurm.core.common cimport cstr


cdef class JobStats:
    cdef slurmdb_job_rec_t *job
    
    cdef public:
        consumed_energy
        average_cpu_time
        average_cpu_frequency
        # Elapsed * alloc_cpus
        # This is the time the Job has been using the allocated CPUs for.
        # This is not the actual cpu-usage.
        cpu_time
        average_disk_read
        average_disk_write
        average_pages
        average_rss
        average_vmsize
        max_disk_read
        max_disk_read_node
        max_disk_read_task
        max_disk_write
        max_disk_write_node
        max_disk_write_task
        max_pages
        max_pages_node
        max_pages_task
        max_rss
        max_rss_node
        max_rss_task
        max_vmsize
        max_vmsize_node
        max_vmsize_task
        min_cpu_time
        min_cpu_time_node
        min_cpu_time_task
        # uint32_t tot_cpu_sec
        # uint32_t tot_cpu_usec
        total_cpu_time
        # Only available for Jobs from the Database, not sstat
        # uint32_t user_cpu_sec
        # uint32_t user_cpu_usec
        user_cpu_time
        # Only available for Jobs from the Database, not sstat
        # uint32_t sys_cpu_sec
        # uint32_t sys_cpu_usec
        system_cpu_time

    @staticmethod
    cdef JobStats from_step(JobStep step)

