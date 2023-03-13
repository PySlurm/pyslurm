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


cdef class JobStats:

    @property
    def consumed_energy(self):
        return None

    @property
    def avg_cpu_time(self):
        return None

    @property
    def avg_cpu_freq(self):
        return None

    @property
    def cpu_time(self):
        # Elapsed * alloc_cpus
        # This is the time the Job has been using the allocated CPUs for.
        # This is not the actual cpu-usage.
        return None

    @property
    def avg_disk_read(self):
        return None

    @property
    def avg_disk_write(self):
        return None

    @property
    def avg_pages(self):
        return None

    @property
    def avg_rss(self):
        return None

    @property
    def avg_vmsize(self):
        return None

    @property
    def max_disk_read(self):
        return None

    @property
    def max_disk_read_node(self):
        return None

    @property
    def max_disk_read_task(self):
        return None

    @property
    def max_disk_write(self):
        return None

    @property
    def max_disk_write_node(self):
        return None

    @property
    def max_disk_write_task(self):
        return None

    @property
    def max_pages(self):
        return None

    @property
    def max_pages_node(self):
        return None

    @property
    def max_pages_task(self):
        return None

    @property
    def max_rss(self):
        return None

    @property
    def max_rss_node(self):
        return None

    @property
    def max_rss_task(self):
        return None

    @property
    def max_vmsize(self):
        return None

    @property
    def max_vmsize_node(self):
        return None

    @property
    def max_vmsize_task(self):
        return None

    @property
    def min_cpu_time(self):
        return None

    @property
    def min_cpu_time_node(self):
        return None

    @property
    def min_cpu_time_task(self):
        return None

    @property
    def total_cpu_time(self):
        return None

    @property
    def user_cpu_time(self):
        return None
    
    @property
    def system_cpu_time(self):
        return None
