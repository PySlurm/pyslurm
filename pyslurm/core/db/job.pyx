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
from pyslurm.core import slurmctld
from pyslurm.core.common.uint import *
from pyslurm.core.common.ctime import (
    date_to_timestamp,
    timestr_to_mins,
    _raw_time,
)
from pyslurm.core.common import (
    gid_to_name,
    group_to_gid,
    user_to_uid,
    uid_to_name,
    nodelist_to_range_str,
    instance_to_dict,
)


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

    def _parse_qos(self):
        if not self.qualities_of_service:
            return None

        qos_id_list = []
        qos = QualitiesOfService.load()
        for q in self.qualities_of_service:
            if isinstance(q, int):
                qos_id_list.append(q)
            elif q in qos:
                qos_id_list.append(str(qos[q].id))
            else:
                raise ValueError(f"QoS {q} does not exist")

        return qos_id_list

    def _parse_groups(self):
        if not self.groups:
            return None

        gid_list = []
        for group in self.groups:
            if isinstance(group, int):
                gid_list.append(group)
            else:
                gid_list.append(group_to_gid(group))

        return gid_list

    def _parse_users(self):
        if not self.users:
            return None

        uid_list = []
        for user in self.users:
            if isinstance(user, int):
                uid_list.append(user)
            else:
                uid_list.append(user_to_uid(user))

        return uid_list

    def _parse_clusters(self):
        if not self.clusters:
            # Get the local cluster name
            # This is a requirement for some other parameters to function
            # correctly, like self.nodelist
            slurm_conf = slurmctld.Config.load()
            return [slurm_conf.cluster]
        elif self.clusters == "all":
            return None
        else:
            return self.clusters

    def _parse_state(self):
        # TODO: implement
        return None
            
    def _create(self):
        self._alloc()
        cdef:
            slurmdb_job_cond_t *ptr = self.ptr
            slurm_selected_step_t *selected_step

        ptr.usage_start = date_to_timestamp(self.start_time)  
        ptr.usage_end = date_to_timestamp(self.end_time)  
        slurmdb_job_cond_def_start_end(ptr)
        ptr.cpus_min = u32(self.cpus, on_noval=0)
        ptr.cpus_max = u32(self.max_cpus, on_noval=0)
        ptr.nodes_min = u32(self.nodes, on_noval=0)
        ptr.nodes_max = u32(self.max_nodes, on_noval=0)
        ptr.timelimit_min = u32(timestr_to_mins(self.timelimit), on_noval=0)
        ptr.timelimit_max = u32(timestr_to_mins(self.max_timelimit),
                                on_noval=0)
        SlurmList.to_char_list(&ptr.acct_list, self.accounts)
        SlurmList.to_char_list(&ptr.associd_list, self.association_ids)
        SlurmList.to_char_list(&ptr.cluster_list, self._parse_clusters())
        SlurmList.to_char_list(&ptr.constraint_list, self.constraints)
        SlurmList.to_char_list(&ptr.jobname_list, self.names)
        SlurmList.to_char_list(&ptr.groupid_list, self._parse_groups())
        SlurmList.to_char_list(&ptr.userid_list, self._parse_users())
        SlurmList.to_char_list(&ptr.wckey_list, self.wckeys)
        SlurmList.to_char_list(&ptr.partition_list, self.partitions)
        SlurmList.to_char_list(&ptr.qos_list, self._parse_qos())
        SlurmList.to_char_list(&ptr.state_list, self._parse_state())

        if self.nodelist:
            cstr.fmalloc(&ptr.used_nodes,
                         nodelist_to_range_str(self.nodelist))
            
        if self.ids:
            # These are only allowed by the slurmdbd when specific jobs are
            # requested.
            if self.with_script:
                ptr.flags |= slurm.JOBCOND_FLAG_SCRIPT
            elif self.with_env:
                # TODO: implement a new "envrironment" attribute in the job
                # class
                ptr.flags |= slurm.JOBCOND_FLAG_ENV

            ptr.step_list = slurm_list_create(slurm_destroy_selected_step)
            already_added = []
            for i in self.ids:
                job_id = u32(i)

                selected_step = NULL
                selected_step = <slurm_selected_step_t*>try_xmalloc(
                        sizeof(slurm_selected_step_t))
                if not selected_step:
                    raise MemoryError("xmalloc failed for slurm_selected_step_t")

                selected_step.array_task_id = slurm.NO_VAL
                selected_step.het_job_offset = slurm.NO_VAL
                selected_step.step_id.step_id = slurm.NO_VAL
                selected_step.step_id.job_id = job_id

                if not job_id in already_added:
                    slurm_list_append(ptr.step_list, selected_step)


cdef class Jobs(dict):

    def __init__(self, *args, **kwargs):
        # TODO: ability to initialize with existing job objects
        pass

    @staticmethod
    def load(*args, **kwargs):
        cdef:
            Jobs jobs = Jobs()
            Job job
            JobStep step
            JobConditions cond
            SlurmListItem job_ptr
            SlurmListItem step_ptr
            SlurmList step_list
            QualitiesOfService qos_data
            int cpu_tres_rec_count = 0
            int step_cpu_tres_rec_count = 0

        # Allow the user to both specify search conditions via a JobConditions
        # instance or **kwargs.
        if args and isinstance(args[0], JobConditions):
            cond = <JobConditions>args[0]
        else:
            cond = JobConditions(**kwargs)

        cond._create()
        jobs.db_conn = Connection()
        jobs.info = SlurmList.wrap(slurmdb_jobs_get(jobs.db_conn.ptr,
                                                    cond.ptr))
        if jobs.info.is_null():
            raise RPCError(msg="Failed to get Jobs from slurmdbd")

        qos_data = QualitiesOfService.load(name_is_key=False,
                                           db_connection=jobs.db_conn)

        # tres_alloc_str = cstr.to_unicode()
        # cpu_tres_rec_count 

        # TODO: also get trackable resources with slurmdb_tres_get and store
        # it in each job instance. tres_alloc_str and tres_req_str only
        # contain the numeric tres ids, but it probably makes more sense to
        # convert them to its type name for the user in advance.

        # TODO: For multi-cluster support, remove duplicate federation jobs
        for job_ptr in SlurmList.iter_and_pop(jobs.info):
            job = Job.from_ptr(<slurmdb_job_rec_t*>job_ptr.data)
            job.qos_data = qos_data
            jobs[job.id] = job

            step_list = SlurmList.wrap(job.ptr.steps, owned=False) 
            for step_ptr in SlurmList.iter_and_pop(step_list):
                step = JobStep.from_ptr(<slurmdb_step_rec_t*>step_ptr.data)
                job.steps[step.id] = step

            job._sum_stats_from_steps()

        return jobs


cdef class Job:

    def __cinit__(self):
        self.ptr = NULL

    def __init__(self, job_id):
        self._alloc()
        self.ptr.jobid = int(job_id)

    def __dealloc__(self):
        slurmdb_destroy_job_rec(self.ptr)
        self.ptr = NULL

    def _alloc(self):
        if not self.ptr:
            self.ptr = <slurmdb_job_rec_t*>try_xmalloc(
                    sizeof(slurmdb_job_rec_t))
            if not self.ptr:
                raise MemoryError("xmalloc failed for slurmdb_job_rec_t")

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
        _qos = self.qos_data.get(self.ptr.qosid, None)
        if _qos:
            return _qos.name
        else:
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
