#########################################################################
# job/step.pyx - interface to retrieve slurm job step informations
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

from libc.string cimport memcpy, memset
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
from pyslurm.core.job.util import (
    cpufreq_to_str,
    get_task_dist,
)
from pyslurm.core.common.ctime import (
    secs_to_timestr,
    mins_to_timestr,
    timestr_to_mins,
    timestamp_to_date,
    _raw_time,
)


cdef class JobSteps(dict):
    """A collection of :obj:`JobStep` objects for a given Job."""
    def __dealloc__(self):
        slurm_free_job_step_info_response_msg(self.info)

    def __cinit__(self):
        self.info = NULL

    def __init__(self, job):
        """Initialize a JobSteps collection

        Args:
            job (Union[Job, int]):
                A Job for which the Steps should be loaded.

        Raises:
            RPCError: When getting the Job steps from the slurmctld failed.
            MemoryError: If malloc fails to allocate memory.
        """
        cdef Job _job

        # Reload the Job in order to have updated information about its state.
        _job = job.reload() if isinstance(job, Job) else Job(job).reload()

        step_info = self._load(_job.id, slurm.SHOW_ALL)
        if not step_info and not slurm.IS_JOB_PENDING(_job.ptr):
            msg = f"Failed to load step info for Job {_job.id}."
            raise RPCError(msg=msg)

        # No super().__init__() needed? Cython probably already initialized
        # the dict automatically.
        self.update(step_info[_job.id])

    cdef dict _load(self, uint32_t job_id, int flags):
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
        """Loads and returns all the steps in the system.

        Returns:
            dict: A dict where every JobID (key) is mapped with an instance of
                its JobSteps (value).
        """
        cdef JobSteps steps = JobSteps.__new__(JobSteps)
        return steps._load(slurm.NO_VAL, slurm.SHOW_ALL)


cdef class JobStep:
    """A Slurm Jobstep"""
    def __cinit__(self):
        self.ptr = NULL
        self.umsg = NULL

    def __init__(self, job=0, step=0, **kwargs):
        """Initialize the JobStep instance

        Args:
            job (Union[Job, int]):
                The Job this Step belongs to.
            step (Union[int, str]):
                Step-ID for this JobStep object.

        Raises:
            MemoryError: If malloc fails to allocate memory.
        """
        self._alloc_impl()
        self.job_id = job.id if isinstance(job, Job) else job
        self.id = step

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
        # When a user wants to set attributes on a Node instance that was
        # created by calling Nodes(), the "umsg" pointer is not yet allocated.
        # We only allocate memory for it by the time the user actually wants
        # to modify something.
        self._alloc_umsg()
        # Call descriptors __set__ directly
        JobStep.__dict__[name].__set__(self, val)

    def reload(self):
        """(Re)load information for a specific job step.

        Implements the slurm_get_job_steps RPC.

        Note:
            You can call this function repeatedly to refresh the information
            of an instance. Using the JobStep object returned is optional.

        Raises:
            RPCError: When retrieving Step information from the slurmctld was
                not successful.
            MemoryError: If malloc failed to allocate memory.

        Returns:
            JobStep: This function returns the current JobStep-instance object
                itself.

        Examples:
            >>> from pyslurm import JobStep
            >>> jobstep = JobStep(9999, 1)
            >>> jobstep.reload()
            >>> 
            >>> # You can also write this in one-line:
            >>> jobstep = JobStep(9999, 1).reload()
        """
        cdef:
            job_step_info_response_msg_t *info = NULL
            uint32_t save_jid = self.job_id
            uint32_t save_sid = self.ptr.step_id.step_id

        rc = slurm_get_job_steps(<time_t>0, save_jid, save_sid,
                                       &info, slurm.SHOW_ALL)
        verify_rpc(rc)

        if info.job_step_count == 1:
            # Cleanup the old info.
            self._dealloc_impl()

            # Copy new info
            self._alloc_impl()
            memcpy(self.ptr, &info.job_steps[0], sizeof(job_step_info_t))
            info.job_step_count = 0
            slurm_free_job_step_info_response_msg(info)
        else:
            slurm_free_job_step_info_response_msg(info)

            sid = self._xlate_from_id(save_sid)
            msg = f"Step {sid} of Job {save_jid} not found."
            raise RPCError(msg=msg)

        return self

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

            >>> from pyslurm import JobStep
            >>> JobStep(9999, 1).send_signal("SIGUSR1")

            or passing in a numeric signal:

            >>> JobStep(9999, 1).send_signal(9)
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
            >>> from pyslurm import JobStep
            >>> JobStep(9999, 1).cancel()
        """
        step_id = self.ptr.step_id.step_id
        verify_rpc(slurm_kill_job_step(self.job_id, step_id, 9))

    def modify(self, step=None, **kwargs):
        """Modify a job step.

        Implements the slurm_update_step RPC.

        Args:
            step (JobStep):
                Another JobStep object which contains all the changes that
                should be applied to this instance.
            **kwargs:
                You can also specify all the changes as keyword arguments.
                Allowed values are only attributes which can actually be set
                on a JobStep instance. If a step is explicitly specified as
                parameter, all **kwargs will be ignored.

        Raises:
            RPCError: When updating the JobStep was not successful.

        Examples:
            >>> from pyslurm import JobStep
            >>> 
            >>> # Setting the new time-limit to 20 days
            >>> changes = JobStep(time_limit="20-00:00:00")
            >>> JobStep(9999, 1).modify(changes)
            >>>
            >>> # Or by specifying the changes directly to the modify function
            >>> JobStep(9999, 1).modify(time_limit="20-00:00:00")
        """
        cdef JobStep js = self

        # Allow the user to both specify changes via object and **kwargs.
        if step and isinstance(step, JobStep):
            js = <JobStep>step
        elif kwargs:
            js = JobStep(**kwargs)

        js._alloc_umsg()
        js.umsg.step_id = self.ptr.step_id.step_id
        js.umsg.job_id = self.ptr.step_id.job_id
        verify_rpc(slurm_update_step(js.umsg))

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

    def as_dict(self):
        """JobStep information formatted as a dictionary.

        Returns:
            dict: JobStep information as dict
        """
        return instance_to_dict(self)

    @property
    def id(self):
        """Union[str, int]: The id for this step."""
        return self._xlate_from_id(self.ptr.step_id.step_id)

    @id.setter
    def id(self, val):
        self.ptr.step_id.step_id = self._xlate_to_id(val)

    @property
    def job_id(self):
        """int: The id for the Job this step belongs to."""
        return self.ptr.step_id.job_id

    @job_id.setter
    def job_id(self, val):
        self.ptr.step_id.job_id = int(val)

    @property
    def name(self):
        """str: Name of the step."""
        return cstr.to_unicode(self.ptr.name)

    @property
    def uid(self):
        """int: User ID who owns this step."""
        return u32_parse(self.ptr.user_id, zero_is_noval=False)

    @property
    def user(self):
        """str: Name of the User who owns this step."""
        return uid_to_name(self.ptr.user_id)

    @property
    def time_limit_raw(self):
        """int: Time limit in Minutes for this step."""
        return _raw_time(self.ptr.time_limit)

    @property
    def time_limit(self):
        """str: Time limit for this step. (formatted)"""
        return mins_to_timestr(self.ptr.time_limit)

    @time_limit.setter
    def time_limit(self, val):
        self.umsg.time_limit=self.ptr.time_limit = timestr_to_mins(val)

    @property
    def network(self):
        """str: Network specification for the step."""
        return cstr.to_unicode(self.ptr.network)

    @property
    def cpu_freq_min(self):
        """Union[str, int]: Minimum CPU-Frequency requested."""
        return cpufreq_to_str(self.ptr.cpu_freq_min)

    @property
    def cpu_freq_max(self):
        """Union[str, int]: Maximum CPU-Frequency requested."""
        return cpufreq_to_str(self.ptr.cpu_freq_max)

    @property
    def cpu_freq_governor(self):
        """Union[str, int]: CPU-Frequency Governor requested."""
        return cpufreq_to_str(self.ptr.cpu_freq_gov)

    @property
    def reserved_ports(self):
        """str: Reserved ports for the step."""
        return cstr.to_unicode(self.ptr.resv_ports)

    @property
    def cluster(self):
        """str: Name of the cluster this step runs on."""
        return cstr.to_unicode(self.ptr.cluster)
    
    @property
    def srun_host(self):
        """str: Name of the host srun was executed on."""
        return cstr.to_unicode(self.ptr.srun_host)

    @property
    def srun_pid(self):
        """int: PID of the srun command."""
        return u32_parse(self.ptr.srun_pid)

    @property
    def container(self):
        """str: Path to the container OCI."""
        return cstr.to_unicode(self.ptr.container)

    @property
    def alloc_nodes(self):
        """str: Nodes the Job is using.

        This is the formatted string of Nodes as shown by scontrol.
        For example, it can look like this:

        "node001,node[005-010]"

        If you want to expand this string into a list of nodenames you can
        use the pyslurm.nodelist_from_range_str function.
        """
        return cstr.to_list(self.ptr.nodes)

    @property
    def start_time_raw(self):
        """int: Time this step started. (Unix timestamp)"""
        return _raw_time(self.ptr.start_time)

    @property
    def start_time(self):
        """str: Time this step started. (formatted)"""
        return timestamp_to_date(self.ptr.start_time)

    @property
    def run_time_raw(self):
        """int: Seconds this step has been running for."""
        return _raw_time(self.ptr.run_time)

    @property
    def run_time(self):
        """str: Seconds this step has been running for. (formatted)"""
        return secs_to_timestr(self.ptr.run_time)

    @property
    def partition(self):
        """str: Name of the partition this step runs in."""
        return cstr.to_unicode(self.ptr.partition)

    @property
    def state(self):
        """str: State the step is in."""
        return cstr.to_unicode(slurm_job_state_string(self.ptr.state))

    @property
    def alloc_cpus(self):
        """int: Number of CPUs this step uses in total."""
        return u32_parse(self.ptr.num_cpus)

    @property
    def ntasks(self):
        """int: Number of tasks this step uses."""
        return u32_parse(self.ptr.num_tasks)
        
    @property
    def distribution(self):
        """dict: Task distribution specification for the step."""
        return get_task_dist(self.ptr.task_dist)

    @property
    def command(self):
        """str: Command that was specified with srun."""
        return cstr.to_unicode(self.ptr.submit_line)

    @property
    def protocol_version(self):
        """int: Slurm protocol version in use."""
        return u32_parse(self.ptr.start_protocol_ver)