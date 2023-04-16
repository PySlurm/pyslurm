#########################################################################
# stats.pyx - pyslurm slurmdbd job stats
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

from pyslurm.core.common import nodelist_from_range_str, instance_to_dict


cdef class JobStats:

    def __init__(self):
        for attr, val in instance_to_dict(self).items():
            setattr(self, attr, 0)

        self.max_disk_read_node = None
        self.max_disk_read_task = None
        self.max_disk_write_node = None
        self.max_disk_write_task = None
        self.max_pages_node = None
        self.max_pages_task = None
        self.max_rss_node = None
        self.max_rss_task = None
        self.max_vmsize_node = None
        self.max_vmsize_task = None
        self.min_cpu_time_node = None
        self.min_cpu_time_task = None

    def as_dict(self):
        return instance_to_dict(self)

    @staticmethod
    cdef JobStats from_step(JobStep step):
        cdef JobStats wrap = JobStats()
        if not &step.ptr.stats:
            return wrap

        cdef:
            list nodes = nodelist_from_range_str(
                    cstr.to_unicode(step.ptr.nodes))
            cpu_time_adj = 1000
            slurmdb_stats_t *ptr = &step.ptr.stats

        if ptr.consumed_energy != slurm.NO_VAL64:
            wrap.consumed_energy = ptr.consumed_energy

        wrap.average_cpu_time = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_ave, slurm.TRES_CPU) / cpu_time_adj
        # TODO
        # wrap.cpu_time = elapsed * step_cpu_tres_rec

        ave_freq = int(ptr.act_cpufreq)
        if ave_freq != slurm.NO_VAL:
            wrap.average_cpu_frequency = ptr.act_cpufreq

        # Convert to MiB instead of raw bytes?
        wrap.average_disk_read = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_ave, slurm.TRES_FS_DISK)
        wrap.average_disk_write = TrackableResources.find_count_in_str(
                ptr.tres_usage_out_ave, slurm.TRES_FS_DISK)
        wrap.average_pages = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_ave, slurm.TRES_PAGES)
        wrap.average_rss = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_ave, slurm.TRES_MEM)
        wrap.average_vmsize = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_ave, slurm.TRES_VMEM)
        
        wrap.max_disk_read = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_max, slurm.TRES_FS_DISK)
        max_disk_read_nodeid = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_max_nodeid, slurm.TRES_FS_DISK)
        wrap.max_disk_read_task = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_max_taskid, slurm.TRES_FS_DISK)

        wrap.max_disk_write = TrackableResources.find_count_in_str(
                ptr.tres_usage_out_max, slurm.TRES_FS_DISK)
        max_disk_write_nodeid = TrackableResources.find_count_in_str(
                ptr.tres_usage_out_max_nodeid, slurm.TRES_FS_DISK)
        wrap.max_disk_write_task = TrackableResources.find_count_in_str(
                ptr.tres_usage_out_max_taskid, slurm.TRES_FS_DISK)

        wrap.max_rss = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_max, slurm.TRES_MEM)
        max_rss_nodeid = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_max_nodeid, slurm.TRES_MEM)
        wrap.max_rss_task = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_max_taskid, slurm.TRES_MEM)

        wrap.max_vmsize = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_max, slurm.TRES_VMEM)
        max_vmsize_nodeid = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_max_nodeid, slurm.TRES_VMEM)
        wrap.max_vmsize_task = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_max_taskid, slurm.TRES_VMEM)

        wrap.min_cpu_time = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_min, slurm.TRES_CPU) / cpu_time_adj
        min_cpu_time_nodeid = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_min_nodeid, slurm.TRES_CPU)
        wrap.min_cpu_time_task = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_min_taskid, slurm.TRES_CPU)

        wrap.total_cpu_time = TrackableResources.find_count_in_str(
                ptr.tres_usage_in_tot, slurm.TRES_CPU)

        if nodes:
            wrap.max_disk_write_node = nodes[max_disk_write_nodeid]
            wrap.max_disk_read_node = nodes[max_disk_read_nodeid]
            wrap.max_rss_node = nodes[max_rss_nodeid]
            wrap.max_vmsize_node = nodes[max_vmsize_nodeid]
            wrap.min_cpu_time_node = nodes[min_cpu_time_nodeid]

        if step.ptr.user_cpu_sec != slurm.NO_VAL64:
            wrap.user_cpu_time = step.ptr.user_cpu_sec 

        if step.ptr.sys_cpu_sec != slurm.NO_VAL64:
            wrap.system_cpu_time = step.ptr.sys_cpu_sec

        return wrap

    @staticmethod
    def _sum_step_stats_for_job(Job job, JobSteps steps):
        cdef:
            JobStats job_stats = job.stats
            JobStats step_stats = None

        for step in steps.values():
            step_stats = step.stats

            job_stats.consumed_energy += step_stats.consumed_energy
            job_stats.average_cpu_time += step_stats.average_cpu_time
            job_stats.average_cpu_frequency += step_stats.average_cpu_frequency
            job_stats.cpu_time += step_stats.cpu_time
            job_stats.average_disk_read += step_stats.average_disk_read
            job_stats.average_disk_write += step_stats.average_disk_write
            job_stats.average_pages += step_stats.average_pages

            if step_stats.max_disk_read >= job_stats.max_disk_read:
                job_stats.max_disk_read = step_stats.max_disk_read
                job_stats.max_disk_read_node = step_stats.max_disk_read_node
                job_stats.max_disk_read_task = step_stats.max_disk_read_task

            if step_stats.max_disk_write >= job_stats.max_disk_write:
                job_stats.max_disk_write = step_stats.max_disk_write
                job_stats.max_disk_write_node = step_stats.max_disk_write_node
                job_stats.max_disk_write_task = step_stats.max_disk_write_task

            if step_stats.max_pages >= job_stats.max_pages:
                job_stats.max_pages = step_stats.max_pages
                job_stats.max_pages_node = step_stats.max_pages_node
                job_stats.max_pages_task = step_stats.max_pages_task

            if step_stats.max_rss >= job_stats.max_rss:
                job_stats.max_rss = step_stats.max_rss
                job_stats.max_rss_node = step_stats.max_rss_node
                job_stats.max_rss_task = step_stats.max_rss_task
                job_stats.average_rss = job_stats.max_rss

            if step_stats.max_vmsize >= job_stats.max_vmsize:
                job_stats.max_vmsize = step_stats.max_vmsize
                job_stats.max_vmsize_node = step_stats.max_vmsize_node
                job_stats.max_vmsize_task = step_stats.max_vmsize_task
                job_stats.average_vmsize = job_stats.max_vmsize

            if step_stats.min_cpu_time >= job_stats.min_cpu_time:
                job_stats.min_cpu_time = step_stats.min_cpu_time
                job_stats.min_cpu_time_node = step_stats.min_cpu_time_node
                job_stats.min_cpu_time_task = step_stats.min_cpu_time_task

        if job.ptr.tot_cpu_sec != slurm.NO_VAL64:
            job_stats.total_cpu_time = job.ptr.tot_cpu_sec

        if job.ptr.user_cpu_sec != slurm.NO_VAL64:
            job_stats.user_cpu_time = job.ptr.user_cpu_sec

        if job.ptr.sys_cpu_sec != slurm.NO_VAL64:
            job_stats.system_cpu_time = job.ptr.sys_cpu_sec

        elapsed = job.elapsed_time if job.elapsed_time else 0
        cpus = job.cpus if job.cpus else 0
        job_stats.cpu_time = elapsed * cpus
        job_stats.average_cpu_frequency /= len(steps)

