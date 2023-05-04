#########################################################################
# job/step.pyx - interface to retrieve slurm job step informations
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

from libc.string cimport memcpy, memset
from typing import Union
from pyslurm.core.common cimport cstr, ctime
from pyslurm.core.common import cstr, ctime
from pyslurm.core.common.uint cimport *
from pyslurm.core.common.uint import *
from pyslurm.core.common.ctime cimport time_t
from pyslurm.core.error import RPCError, verify_rpc
from pyslurm.core.common import (
    signal_to_num,
    instance_to_dict, 
    uid_to_name,
)
from pyslurm.core.job.util import cpu_freq_int_to_str
from pyslurm.core.job.task_dist cimport TaskDistribution

from pyslurm.core.common.ctime import (
    secs_to_timestr,
    mins_to_timestr,
    timestr_to_mins,
    timestamp_to_date,
    _raw_time,
)


cdef class JobSteps(dict):

    def __dealloc__(self):
        slurm_free_job_step_info_response_msg(self.info)

    def __cinit__(self):
        self.info = NULL

    def __init__(self):
        pass

    @staticmethod
    def load(job):
        """Load the Steps for a specific Job

        Args:
            job (Union[Job, int]):
                The Job for which the Steps should be loaded

        Returns:
            (pyslurm.JobSteps): JobSteps of the Job
        """
        cdef Job _job
        _job = Job.load(job.id) if isinstance(job, Job) else Job.load(job)
        return JobSteps._load(_job)

    @staticmethod
    cdef JobSteps _load(Job job):
        cdef JobSteps steps = JobSteps.__new__(JobSteps)

        step_info = steps._get_info(job.id, slurm.SHOW_ALL)
        if not step_info and not slurm.IS_JOB_PENDING(job.ptr):
            msg = f"Failed to load step info for Job {job.id}."
            raise RPCError(msg=msg)

        # No super().__init__() needed? Cython probably already initialized
        # the dict automatically.
        steps.update(step_info[job.id])
        return steps
         
    cdef dict _get_info(self, uint32_t job_id, int flags):
        cdef:
            JobStep step
            JobSteps steps
            uint32_t cnt = 0
            dict out = {}

        rc = slurm_get_job_steps(<time_t>0, job_id, slurm.NO_VAL, &self.info,
                                 flags)
        verify_rpc(rc)

        # zero-out a dummy job_step_info_t
        memset(&self.tmp_info, 0, sizeof(job_step_info_t))

        # Put each job-step pointer into its own "JobStep" instance.
        for cnt in range(self.info.job_step_count):
            step = JobStep.from_ptr(&self.info.job_steps[cnt])

            # Prevent double free if xmalloc fails mid-loop and a MemoryError
            # is raised by replacing it with a zeroed-out job_step_info_t.
            self.info.job_steps[cnt] = self.tmp_info

            if not step.job_id in out:
                steps = JobSteps.__new__(JobSteps)
                out[step.job_id] = steps

            out[step.job_id].update({step.id: step})

        # At this point we memcpy'd all the memory for the Steps. Setting this
        # to 0 will prevent the slurm step free function to deallocate the
        # memory for the individual steps. This should be fine, because they
        # are free'd automatically in __dealloc__ since the lifetime of each
        # step-pointer is tied to the lifetime of its corresponding JobStep
        # instance.
        self.info.job_step_count = 0

        return out

    @staticmethod
    def load_all():
        """Loads all the steps in the system.

        Returns:
            (dict): A dict where every JobID (key) is mapped with an instance
                of its JobSteps (value).
        """
        cdef JobSteps steps = JobSteps.__new__(JobSteps)
        return steps._get_info(slurm.NO_VAL, slurm.SHOW_ALL)


cdef class JobStep:

    def __cinit__(self):
        self.ptr = NULL
        self.umsg = NULL

    def __init__(self, job_id=0, step_id=0, **kwargs):
        self._alloc_impl()
        self.job_id = job_id.id if isinstance(job_id, Job) else job_id
        self.id = step_id

        # Initialize attributes, if any were provided
        for k, v in kwargs.items():
            setattr(self, k, v)

    def _alloc_info(self):
        if not self.ptr:
            self.ptr = <job_step_info_t*>try_xmalloc(
                    sizeof(job_step_info_t))
            if not self.ptr:
                raise MemoryError("xmalloc failed for job_step_info_t")

    def _alloc_umsg(self):
        if not self.umsg:
            self.umsg = <step_update_request_msg_t*>try_xmalloc(
                    sizeof(step_update_request_msg_t))
            if not self.ptr:
                raise MemoryError("xmalloc failed for "
                                  "step_update_request_msg_t")
            slurm_init_update_step_msg(self.umsg)

    def _alloc_impl(self):
        self._alloc_info()
        self._alloc_umsg()

    def __dealloc__(self):
        self._dealloc_impl()

    def _dealloc_impl(self):
        slurm_free_job_step_info_members(self.ptr)
        xfree(self.ptr)
        slurm_free_update_step_msg(self.umsg)
        self.umsg = NULL

    def __setattr__(self, name, val):
        # When a user wants to set attributes on a instance that was created
        # by calling JobSteps.load(), the "umsg" pointer is not yet allocated.
        # We only allocate memory for it by the time the user actually wants
        # to modify something.
        self._alloc_umsg()
        # Call descriptors __set__ directly
        JobStep.__dict__[name].__set__(self, val)

    @staticmethod
    def load(job_id, step_id):
        """Load information for a specific job step.

        Implements the slurm_get_job_steps RPC.

        Args:
            job_id (Union[pyslurm.Job, int]):
                ID of the Job the Step belongs to.
            step_id (Union[int, str]):
                Step-ID for the Step to be loaded.

        Returns:
            (pyslurm.JobStep): Returns a new JobStep instance

        Raises:
            RPCError: When retrieving Step information from the slurmctld was
                not successful.
            MemoryError: If malloc failed to allocate memory.

        Examples:
            >>> import pyslurm
            >>> jobstep = pyslurm.JobStep.load(9999, 1)
        """
        cdef:
            job_step_info_response_msg_t *info = NULL
            JobStep wrap = JobStep.__new__(JobStep)

        job_id = job_id.id if isinstance(job_id, Job) else job_id
        rc = slurm_get_job_steps(<time_t>0, job_id, dehumanize_step_id(step_id),
                                       &info, slurm.SHOW_ALL)
        verify_rpc(rc)

        if info and info.job_step_count == 1:
            # Copy new info
            wrap._alloc_impl()
            memcpy(wrap.ptr, &info.job_steps[0], sizeof(job_step_info_t))
            info.job_step_count = 0
            slurm_free_job_step_info_response_msg(info)
        else:
            slurm_free_job_step_info_response_msg(info)
            msg = f"Step {step_id} of Job {job_id} not found."
            raise RPCError(msg=msg)

        return wrap

    @staticmethod
    cdef JobStep from_ptr(job_step_info_t *in_ptr):
        cdef JobStep wrap = JobStep.__new__(JobStep)
        wrap._alloc_info()
        memcpy(wrap.ptr, in_ptr, sizeof(job_step_info_t))
        return wrap

    def send_signal(self, signal):
        """Send a signal to a running Job step.

        Implements the slurm_signal_job_step RPC.

        Args:
            signal (Union[str, int]): 
                Any valid signal which will be sent to the Job. Can be either
                a str like 'SIGUSR1', or simply an int.

        Raises:
            RPCError: When sending the signal was not successful.

        Examples:
            Specifying the signal as a string:

            >>> import pyslurm
            >>> pyslurm.JobStep(9999, 1).send_signal("SIGUSR1")

            or passing in a numeric signal:

            >>> pyslurm.JobStep(9999, 1).send_signal(9)
        """
        step_id = self.ptr.step_id.step_id
        sig = signal_to_num(signal)
        verify_rpc(slurm_signal_job_step(self.job_id, step_id, sig))

    def cancel(self):
        """Cancel a Job step.

        Implements the slurm_kill_job_step RPC.

        Raises:
            RPCError: When cancelling the Job was not successful.

        Examples:
            >>> import pyslurm
            >>> pyslurm.JobStep(9999, 1).cancel()
        """
        step_id = self.ptr.step_id.step_id
        verify_rpc(slurm_kill_job_step(self.job_id, step_id, 9))

    def modify(self, changes):
        """Modify a job step.

        Implements the slurm_update_step RPC.

        Args:
            changes (pyslurm.JobStep):
                Another JobStep object which contains all the changes that
                should be applied to this instance.
        Raises:
            RPCError: When updating the JobStep was not successful.

        Examples:
            >>> import pyslurm
            >>> 
            >>> # Setting the new time-limit to 20 days
            >>> changes = pyslurm.JobStep(time_limit="20-00:00:00")
            >>> pyslurm.JobStep(9999, 1).modify(changes)
        """
        cdef JobStep js = <JobStep>changes
        js._alloc_umsg()
        js.umsg.step_id = self.ptr.step_id.step_id
        js.umsg.job_id = self.ptr.step_id.job_id
        verify_rpc(slurm_update_step(js.umsg))

    def as_dict(self):
        """JobStep information formatted as a dictionary.

        Returns:
            (dict): JobStep information as dict
        """
        return instance_to_dict(self)

    @property
    def id(self):
        return humanize_step_id(self.ptr.step_id.step_id)

    @id.setter
    def id(self, val):
        self.ptr.step_id.step_id = dehumanize_step_id(val)

    @property
    def job_id(self):
        return self.ptr.step_id.job_id

    @job_id.setter
    def job_id(self, val):
        self.ptr.step_id.job_id = int(val)

    @property
    def name(self):
        return cstr.to_unicode(self.ptr.name)

    @property
    def user_id(self):
        return u32_parse(self.ptr.user_id, zero_is_noval=False)

    @property
    def user_name(self):
        return uid_to_name(self.ptr.user_id)

    @property
    def time_limit(self):
        return _raw_time(self.ptr.time_limit)

    @time_limit.setter
    def time_limit(self, val):
        self.umsg.time_limit=self.ptr.time_limit = timestr_to_mins(val)

    @property
    def network(self):
        return cstr.to_unicode(self.ptr.network)

    @property
    def cpu_frequency_min(self):
        return cpu_freq_int_to_str(self.ptr.cpu_freq_min)

    @property
    def cpu_frequency_max(self):
        return cpu_freq_int_to_str(self.ptr.cpu_freq_max)

    @property
    def cpu_frequency_governor(self):
        return cpu_freq_int_to_str(self.ptr.cpu_freq_gov)

    @property
    def reserved_ports(self):
        return cstr.to_unicode(self.ptr.resv_ports)

    @property
    def cluster(self):
        return cstr.to_unicode(self.ptr.cluster)
    
    @property
    def srun_host(self):
        return cstr.to_unicode(self.ptr.srun_host)

    @property
    def srun_process_id(self):
        return u32_parse(self.ptr.srun_pid)

    @property
    def container(self):
        return cstr.to_unicode(self.ptr.container)

    @property
    def allocated_nodes(self):
        return cstr.to_list(self.ptr.nodes)

    @property
    def start_time(self):
        return _raw_time(self.ptr.start_time)

    @property
    def run_time(self):
        return _raw_time(self.ptr.run_time)

    @property
    def partition(self):
        return cstr.to_unicode(self.ptr.partition)

    @property
    def state(self):
        return cstr.to_unicode(slurm_job_state_string(self.ptr.state))

    @property
    def alloc_cpus(self):
        return u32_parse(self.ptr.num_cpus)

    @property
    def ntasks(self):
        return u32_parse(self.ptr.num_tasks)
        
    @property
    def distribution(self):
        return TaskDistribution.from_int(self.ptr.task_dist)

    @property
    def command(self):
        return cstr.to_unicode(self.ptr.submit_line)

    @property
    def slurm_protocol_version(self):
        return u32_parse(self.ptr.start_protocol_ver)


def humanize_step_id(sid):
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


def dehumanize_step_id(sid):
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
