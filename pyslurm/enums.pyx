#########################################################################
# enums.pyx - pyslurm enums for various types
#########################################################################
# Copyright (C) 2026 Toni Harzendorf <toni.harzendorf@gmail.com>
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


from enum import auto
from pyslurm.utils.enums import SlurmEnum
from pyslurm cimport slurm


# TODO: Move everything enum related here.


class SchedulerType(SlurmEnum):
    SUBMIT = auto(), slurm.SLURMDB_JOB_FLAG_SUBMIT
    MAIN = auto(), slurm.SLURMDB_JOB_FLAG_SCHED
    BACKFILL = auto(), slurm.SLURMDB_JOB_FLAG_BACKFILL
    UNKNOWN = auto()


SchedulerType.SUBMIT.__doc__ = "Scheduled immediately on submit"
SchedulerType.MAIN.__doc__ = "Scheduled by the Main Scheduler"
SchedulerType.SUBMIT.__doc__ = "Scheduled by the Backfill Scheduler"


class JobExclusive(SlurmEnum):
    """Exclusive resource allocation mode of a Job."""
    NONE = "NONE", slurm.JOB_EXCLUSIVE_NONE
    NODE = "NODE", slurm.JOB_EXCLUSIVE_NODE
    USER = "USER", slurm.JOB_EXCLUSIVE_USER
    MCS  = "MCS",  slurm.JOB_EXCLUSIVE_MCS
    TOPO = "TOPO", slurm.JOB_EXCLUSIVE_TOPO


JobExclusive.NONE.__doc__ = "Nodes may be shared with other Jobs"
JobExclusive.NODE.__doc__ = "Nodes are allocated exclusively to this Job"
JobExclusive.USER.__doc__ = "Nodes are shared only with Jobs of the same User"
JobExclusive.MCS.__doc__ = "Nodes are shared only within the same MCS label"
JobExclusive.TOPO.__doc__ = "Topology segment is allocated exclusively"


class JobOversubscribe(SlurmEnum):
    """Whether a Job is willing to oversubscribe resources."""
    NO  = "NO",  slurm.JOB_OVERSUBSCRIBE_NO
    YES = "YES", slurm.JOB_OVERSUBSCRIBE_YES
    OK  = "OK",  slurm.JOB_OVERSUBSCRIBE_OK


JobOversubscribe.NO.__doc__ = "Resources are not oversubscribed"
JobOversubscribe.YES.__doc__ = "Job wants to oversubscribe resources"
JobOversubscribe.OK.__doc__ = "Job accepts oversubscribed resources"


__all__ = [
    "SchedulerType",
    "JobExclusive",
    "JobOversubscribe",
]
