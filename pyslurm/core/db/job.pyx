#########################################################################
# job.pyx - pyslurm slurmdbd job api
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
from pyslurm.core.common.ctime import (
    date_to_timestamp,
    _raw_time,
)
from pyslurm.core.common import (
    gid_to_name,
    uid_to_name,
    instance_to_dict,
)

# Maybe prefix these classes with something like "DB" to avoid name collision
# with the other classes from pyslurm/core/job ?

cdef class JobConditions:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)

    def __dealloc__(self):
        self._dealloc()

    def _dealloc(self):
        slurmdb_destroy_job_cond(self.ptr)
        self.ptr = NULL

    def _alloc(self):
        self._dealloc()
        self.ptr = <slurmdb_job_cond_t*>try_xmalloc(sizeof(slurmdb_job_cond_t))
        if not self.ptr:
            raise MemoryError("xmalloc failed for slurmdb_job_cond_t")
        
        self.ptr.db_flags = slurm.SLURMDB_JOB_FLAG_NOTSET
        self.ptr.flags |= slurm.JOBCOND_FLAG_NO_TRUNC

    def _create_job_cond(self):
        self._alloc()
        cdef slurmdb_job_cond_t *ptr = self.ptr

        ptr.usage_start = date_to_timestamp(self.start_time)  
        ptr.usage_end = date_to_timestamp(self.end_time)  
        slurmdb_job_cond_def_start_end(ptr)
        SlurmList.to_char_list(&ptr.acct_list, self.accounts)
        SlurmList.to_char_list(&ptr.associd_list, self.association_ids)
        SlurmList.to_char_list(&ptr.cluster_list, self.clusters)
        SlurmList.to_char_list(&ptr.constraint_list, self.constraints)


cdef class Jobs(dict):

    def __dealloc__(self):
        self.db_conn.close()

    def __init__(self, *args, **kwargs):
        cdef:
            Job job
            JobStep step
            JobConditions job_cond
            SlurmListItem job_ptr
            SlurmListItem step_ptr
            SlurmList step_list
            int cpu_tres_rec_count = 0
            int step_cpu_tres_rec_count = 0

        # Allow the user to both specify search conditions via a JobConditions
        # instance or **kwargs.
        if args and isinstance(args[0], JobConditions):
            job_cond = <JobConditions>args[0]
        else:
            job_cond = JobConditions(**kwargs)

        job_cond._create_job_cond()
        # TODO: Have a single, global DB connection in pyslurm internally?
        self.db_conn = Connection()
        self.info = SlurmList.wrap(slurmdb_jobs_get(self.db_conn.ptr,
                                                    job_cond.ptr))

        if self.info.is_null():
            raise RPCError(msg="Failed to get Jobs from slurmdbd")

        # tres_alloc_str = cstr.to_unicode()
        # cpu_tres_rec_count 

        # TODO: also get trackable resources with slurmdb_tres_get and store
        # it in each job instance. tres_alloc_str and tres_req_str only
        # contain the numeric tres ids, but it probably makes more sense to
        # convert them to its type name for the user in advance.

        # TODO: For multi-cluster support, remove duplicate federation jobs
        for job_ptr in SlurmList.iter_and_pop(self.info):
            job = Job.from_ptr(<slurmdb_job_rec_t*>job_ptr.data)
            self[job.id] = job

            step_list = SlurmList.wrap(job.ptr.steps, owned=False) 
            for step_ptr in SlurmList.iter_and_pop(step_list):
                step = JobStep.from_ptr(<slurmdb_step_rec_t*>step_ptr.data)
                job.steps[step.id] = step

            job._sum_stats_from_steps()

        
cdef class Job:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, job_id):
        pass

    def __dealloc__(self):
        slurmdb_destroy_job_rec(self.ptr)
        self.ptr = NULL

    @staticmethod
    cdef Job from_ptr(slurmdb_job_rec_t *in_ptr):
        cdef Job wrap = Job.__new__(Job)
        wrap.ptr = in_ptr
        wrap.steps = JobSteps.__new__(JobSteps)
        wrap.stats = JobStats()
        return wrap

    def _sum_stats_from_steps(self):
        cdef:
            JobStats job_stats = self.stats
            JobStats step_stats = None

        for step in self.steps.values():
            step_stats = step.stats

            job_stats.consumed_energy += step_stats.consumed_energy
            job_stats.average_cpu_time += step_stats.average_cpu_time
            job_stats.average_cpu_frequency += step_stats.average_cpu_frequency
            job_stats.cpu_time += step_stats.cpu_time
            job_stats.average_disk_read += step_stats.average_disk_read
            job_stats.average_disk_write += step_stats.average_disk_write
            job_stats.average_pages += step_stats.average_pages
            job_stats.average_rss += step_stats.average_rss
            job_stats.average_vmsize += step_stats.average_vmsize

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

            if step_stats.max_vmsize >= job_stats.max_vmsize:
                job_stats.max_vmsize = step_stats.max_vmsize
                job_stats.max_vmsize_node = step_stats.max_vmsize_node
                job_stats.max_vmsize_task = step_stats.max_vmsize_task

            if step_stats.min_cpu_time >= job_stats.min_cpu_time:
                job_stats.min_cpu_time = step_stats.min_cpu_time
                job_stats.min_cpu_time_node = step_stats.min_cpu_time_node
                job_stats.min_cpu_time_task = step_stats.min_cpu_time_task

        if self.ptr.tot_cpu_sec != slurm.NO_VAL64:
            job_stats.total_cpu_time = self.ptr.tot_cpu_sec

        if self.ptr.user_cpu_sec != slurm.NO_VAL64:
            job_stats.user_cpu_time = self.ptr.user_cpu_sec

        if self.ptr.sys_cpu_sec != slurm.NO_VAL64:
            job_stats.system_cpu_time = self.ptr.sys_cpu_sec

        elapsed = self.elapsed_time if self.elapsed_time else 0
        cpus = self.cpus if self.cpus else 0
        job_stats.cpu_time = elapsed * cpus
        job_stats.average_cpu_frequency /= len(self.steps)

    def as_dict(self):
        cdef dict out = instance_to_dict(self)
        out["stats"] = self.stats.as_dict()
        steps = out.pop("steps", {})

        out["steps"] = {}
        for step_id, step in steps.items():
            out["steps"][step_id] = step.as_dict() 
        return out

    @property
    def account(self):
        return cstr.to_unicode(self.ptr.account)

    @property
    def admin_comment(self):
        return cstr.to_unicode(self.ptr.admin_comment)

    @property
    def num_nodes(self):
        val = TrackableResources.find_count_in_str(self.ptr.tres_alloc_str, 
                                                   slurm.TRES_NODE)
        if val is not None:
            # Job is already running and has nodes allocated
            return val
        else:
            # Job is still pending, so we return the number of requested nodes
            # instead.
            val = TrackableResources.find_count_in_str(self.ptr.tres_req_str, 
                                                       slurm.TRES_NODE)
            return val

    @property
    def array_id(self):
        return u32_parse(self.ptr.array_job_id)

    @property
    def array_tasks_parallel(self):
        return u32_parse(self.ptr.array_max_tasks)

    @property
    def array_task_id(self):
        return u32_parse(self.ptr.array_task_id)

    @property
    def array_tasks_waiting(self):
        task_str = cstr.to_unicode(self.ptr.array_task_str)
        if not task_str:
            return None
        
        if "%" in task_str:
            # We don't want this % character and everything after it
            # in here, so remove it.
            task_str = task_str[:task_str.rindex("%")]

        return task_str

    @property
    def association_id(self):
        return u32_parse(self.ptr.associd)

    @property
    def block_id(self):
        return cstr.to_unicode(self.ptr.blockid)

    @property
    def cluster(self):
        return cstr.to_unicode(self.ptr.cluster)

    @property
    def constraints(self):
        return cstr.to_list(self.ptr.constraints)

    @property
    def container(self):
        return cstr.to_list(self.ptr.container)

    @property
    def db_index(self):
        return u64_parse(self.ptr.db_index)

    @property
    def derived_exit_code(self):
        """int: The derived exit code for the Job."""
        if (self.ptr.derived_ec == slurm.NO_VAL
                or not WIFEXITED(self.ptr.derived_ec)):
            return None

        return WEXITSTATUS(self.ptr.derived_ec)

    @property
    def derived_exit_code_signal(self):
        """int: Signal for the derived exit code."""
        if (self.ptr.derived_ec == slurm.NO_VAL
                or not WIFSIGNALED(self.ptr.derived_ec)): 
            return None

        return WTERMSIG(self.ptr.derived_ec)

    @property
    def comment(self):
        return cstr.to_unicode(self.ptr.derived_es)

    @property
    def elapsed_time(self):
        return _raw_time(self.ptr.elapsed)

    @property
    def eligible_time(self):
        return _raw_time(self.ptr.eligible)

    @property
    def end_time(self):
        return _raw_time(self.ptr.end)

    @property
    def exit_code(self):
        # TODO
        return None

    # uint32_t flags

    def group_id(self):
        return u32_parse(self.ptr.gid, zero_is_noval=False)

    def group_name(self):
        return gid_to_name(self.ptr.gid)

    # uint32_t het_job_id
    # uint32_t het_job_offset

    @property
    def id(self):
        return self.ptr.jobid

    @property
    def name(self):
        return cstr.to_unicode(self.ptr.jobname)

    # uint32_t lft
    
    @property
    def mcs_label(self):
        return cstr.to_unicode(self.ptr.mcs_label)

    @property
    def nodelist(self):
        return cstr.to_unicode(self.ptr.nodes)

    @property
    def partition(self):
        return cstr.to_unicode(self.ptr.partition)

    @property
    def priority(self):
        return u32_parse(self.ptr.priority, zero_is_noval=False)

    @property
    def qos(self):
        # Need to convert the raw uint32_t qosid to a name, by calling
        # slurmdb_qos_get. To avoid doing this repeatedly, we'll probably need
        # to also get the qos list when calling slurmdb_jobs_get and store it
        # in each job instance.
        return None

    @property
    def cpus(self):
        val = TrackableResources.find_count_in_str(self.ptr.tres_alloc_str, 
                                                   slurm.TRES_CPU)
        if val is not None:
            # Job is already running and has cpus allocated
            return val
        else:
            # Job is still pending, so we return the number of requested cpus
            # instead.
            return u32_parse(self.ptr.req_cpus)

    @property
    def memory(self):
        val = TrackableResources.find_count_in_str(self.ptr.tres_req_str, 
                                                   slurm.TRES_MEM)
        return val

    @property
    def reservation(self):
        return cstr.to_unicode(self.ptr.resv_name)

#    @property
#    def reservation_id(self):
#        return u32_parse(self.ptr.resvid)

    @property
    def script(self):
        return cstr.to_unicode(self.ptr.script)

    # uint32_t show_full

    @property
    def start_time(self):
        return _raw_time(self.ptr.start)

    @property
    def state(self):
        """str: State this Job is in."""
        return cstr.to_unicode(slurm_job_state_string(self.ptr.state))

    @property
    def state_reason(self):
        return cstr.to_unicode(slurm_job_reason_string
                               (self.ptr.state_reason_prev))

    @property
    def cancelled_by(self):
        return uid_to_name(self.ptr.requid)

    @property
    def submit_time(self):
        return _raw_time(self.ptr.submit)

    @property
    def submit_line(self):
        return cstr.to_unicode(self.ptr.submit_line)

    @property
    def suspended_time(self):
        # seconds
        return _raw_time(self.ptr.elapsed)

    @property
    def system_comment(self):
        return cstr.to_unicode(self.ptr.system_comment)

    @property
    def time_limit(self):
        # minutes
        # TODO: Perhaps we should just find out what the actual PartitionLimit
        # is?
        return _raw_time(self.ptr.timelimit, "PartitionLimit")

    @property
    def user_id(self):
        return u32_parse(self.ptr.uid, zero_is_noval=False)

    @property
    def user_name(self):
        # Theres also a ptr->user
        # https://github.com/SchedMD/slurm/blob/6365a8b7c9480c48678eeedef99864d8d3b6a6b5/src/sacct/print.c#L1946
        return uid_to_name(self.ptr.uid)

    # TODO: used gres

    @property
    def wckey(self):
        return cstr.to_unicode(self.ptr.wckey)

#    @property
#    def wckey_id(self):
#        return u32_parse(self.ptr.wckeyid)

    @property
    def working_directory(self):
        return cstr.to_unicode(self.ptr.work_dir)

#    @property
#    def tres_allocated(self):
#        return TrackableResources.from_str(self.ptr.tres_alloc_str)

#    @property
#    def tres_requested(self):
#        return TrackableResources.from_str(self.ptr.tres_req_str)
