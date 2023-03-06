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
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3

from os import WIFSIGNALED, WIFEXITED, WTERMSIG, WEXITSTATUS
import re
from typing import Union
from pyslurm.core.common import cstr, ctime
from pyslurm.core.common.uint import *
from pyslurm.core.job.util import *
from pyslurm.core.error import (
    RPCError,
    verify_rpc,
    slurm_errno,
)
from pyslurm.core.common.ctime import (
    secs_to_timestr,
    mins_to_timestr,
    timestamp_to_date,
    _raw_time,
)
from pyslurm.core.common import (
    uid_to_name,
    gid_to_name,
    humanize, 
    signal_to_num,
    _getgrall_to_dict,
    _getpwall_to_dict,
    nodelist_from_range_str,
    nodelist_to_range_str,
    instance_to_dict,
)


cdef class Jobs(dict):
    """A collection of :obj:`Job` objects.

    By creating a new :obj:`Jobs` instance, all Jobs in the system will be
    fetched from the slurmctld.
    """
    def __dealloc__(self):
        slurm_free_job_info_msg(self.info)

    def __init__(self, preload_passwd_info=False):
        """Initialize a Jobs collection

        Args:
            preload_passwd_info (bool): 
                Decides whether to query passwd and groups information from
                the system.
                Could potentially speed up access to attributes of the Job
                where a UID/GID is translated to a name. If True, the
                information will fetched and stored in each of the Job
                instances. The default is False.

        Raises:
            RPCError: When getting all the Jobs from the slurmctld failed.
            MemoryError: If malloc fails to allocate memory.
        """
        cdef:
            dict passwd = {}
            dict groups = {}
            int flags   = slurm.SHOW_ALL | slurm.SHOW_DETAIL
            Job job

        self.info = NULL
        verify_rpc(slurm_load_jobs(0, &self.info, flags))

        # If requested, preload the passwd and groups database to potentially
        # speedup lookups for an attribute in a Job, e.g. user_name or
        # group_name.
        if preload_passwd_info:
            passwd = _getpwall_to_dict()
            groups = _getgrall_to_dict()

        # zero-out a dummy job_step_info_t
        memset(&self.tmp_info, 0, sizeof(slurm_job_info_t))

        # Put each job pointer into its own "Job" instance.
        for cnt in range(self.info.record_count):
            job = Job.from_ptr(&self.info.job_array[cnt])

            # Prevent double free if xmalloc fails mid-loop and a MemoryError
            # is raised by replacing it with a zeroed-out slurm_job_info_t.
            self.info.job_array[cnt] = self.tmp_info

            if preload_passwd_info:
                job.passwd = passwd
                job.groups = groups

            self[job.id] = job

        # At this point we memcpy'd all the memory for the Jobs. Setting this
        # to 0 will prevent the slurm job free function to deallocate the
        # memory for the individual jobs. This should be fine, because they
        # are free'd automatically in __dealloc__ since the lifetime of each
        # job-pointer is tied to the lifetime of its corresponding "Job"
        # instance.
        self.info.record_count = 0

    def load_steps(self):
        """Load all Job steps for this collection of Jobs.

        Note:
            Pending Jobs will be ignored, since they don't have any Steps yet.

        Raises:
            RPCError: When retrieving the Job information for all the Steps
                failed.

        Returns:
            dict: JobSteps information for each JobID.
        """
        cdef:
            Job job
            dict step_info = JobSteps.load_all()
            dict out

        # Ignore any Steps from Jobs which do not exist in this collection.
        out = {jid: step_info[jid] for jid in self if jid in step_info}
        return out 

    def as_list(self):
        """Format the information as list of Job objects.

        Returns:
            list: List of Job objects
        """
        return list(self.values())


cdef class Job:
    """A Slurm Job.

    All attributes in this class are read-only.

    Args:
        job_id (int):
            An Integer representing a Job-ID.

    Raises:
        MemoryError: If malloc fails to allocate memory.
    """
    def __init__(self, int job_id):
        self.alloc()
        self.ptr.job_id = job_id
        self.passwd = {}
        self.groups = {}

    cdef alloc(self):
        self.ptr = <slurm_job_info_t*>try_xmalloc(sizeof(slurm_job_info_t))
        if not self.ptr:
            raise MemoryError("xmalloc failed for job_info_t")

    def __dealloc__(self):
        slurm_free_job_info(self.ptr)
        self.ptr = NULL

    def __eq__(self, other):
        return isinstance(other, Job) and self.id == other.id

    def reload(self):
        """(Re)load information for a job.

        Implements the slurm_load_job RPC.

        Note:
            You can call this function repeatedly to refresh the information
            of an instance. Using the Job object returned is optional.

        Returns:
            Job: This function returns the current Job-instance object itself.

        Raises:
            RPCError: If requesting the Job information from the slurmctld was
                not successful.
            MemoryError: If malloc failed to allocate memory.

        Examples:
            >>> from pyslurm import Job
            >>> job = Job(9999)
            >>> job.reload()
            >>> 
            >>> # You can also write this in one-line:
            >>> job = Job(9999).reload()
        """
        cdef:
            job_info_msg_t *info = NULL

        try: 
            verify_rpc(slurm_load_job(&info, self.id, slurm.SHOW_DETAIL))

            if info and info.record_count:
                # Cleanup the old info
                slurm_free_job_info(self.ptr)

                # Copy new info
                self.alloc()
                memcpy(self.ptr, &info.job_array[0], sizeof(slurm_job_info_t))
                info.record_count = 0
        except Exception as e:
            raise e
        finally:
            slurm_free_job_info_msg(info)

        return self

    @staticmethod
    cdef Job from_ptr(slurm_job_info_t *in_ptr):
        cdef Job wrap = Job.__new__(Job)
        wrap.alloc()
        wrap.passwd = {}
        wrap.groups = {}
        memcpy(wrap.ptr, in_ptr, sizeof(slurm_job_info_t))

        return wrap

    def as_dict(self):
        """Job information formatted as a dictionary.

        Returns:
            dict: Job information as dict
        """
        return instance_to_dict(self)

    def send_signal(self, signal, steps="children", hurry=False):
        """Send a signal to a running Job.

        Implements the slurm_signal_job RPC.

        Args:
            signal (Union[str, int]): 
                Any valid signal which will be sent to the Job. Can be either
                a str like 'SIGUSR1', or simply an int.
            steps (str):
                Selects which steps should be signaled. Valid values for this
                are: "all", "batch" and "children". The default value is
                "children", where all steps except the batch-step will be
                signaled.
                The value "batch" in contrast means, that only the batch-step
                will be signaled. With "all" every step is signaled.
            hurry (bool): 
                If True, no burst buffer data will be staged out. The default
                value is False.

        Raises:
            RPCError: When sending the signal was not successful.

        Examples:
            Specifying the signal as a string:

            >>> from pyslurm import Job
            >>> Job(9999).send_signal("SIGUSR1")

            or passing in a numeric signal:

            >>> Job(9999).send_signal(9)
        """
        cdef uint16_t flags = 0

        if steps.casefold() == "all":
            flags |= slurm.KILL_FULL_JOB
        elif steps.casefold() == "batch":
            flags |= slurm.KILL_JOB_BATCH
        
        if hurry:
            flags |= slurm.KILL_HURRY

        sig = signal_to_num(signal)
        slurm_kill_job(self.id, sig, flags)

        # Ignore errors when the Job is already done or when SIGKILL was
        # specified and the job id is already purged from slurmctlds memory.
        errno = slurm_errno()
        if (errno == slurm.ESLURM_ALREADY_DONE
                or errno == slurm.ESLURM_INVALID_JOB_ID and sig == 9):
            pass
        else:
            verify_rpc(errno)

    def cancel(self):
        """Cancel a Job.

        Implements the slurm_kill_job RPC.

        Raises:
            RPCError: When cancelling the Job was not successful.

        Examples:
            >>> from pyslurm import Job
            >>> Job(9999).cancel()
        """
        self.send_signal(9)

    def suspend(self):
        """Suspend a running Job.

        Implements the slurm_suspend RPC.

        Raises:
            RPCError: When suspending the Job was not successful.

        Examples:
            >>> from pyslurm import Job
            >>> Job(9999).suspend()
        """
        # TODO: Report as a misbehaviour to schedmd that slurm_suspend is not
        # correctly returning error code when it cannot find the job in
        # _slurm_rpc_suspend it should return ESLURM_INVALID_JOB_ID, but
        # returns -1
        # https://github.com/SchedMD/slurm/blob/master/src/slurmctld/proc_req.c#L4693
        verify_rpc(slurm_suspend(self.id))

    def unsuspend(self):
        """Unsuspend a currently suspended Job.

        Implements the slurm_resume RPC.

        Raises:
            RPCError: When unsuspending the Job was not successful.

        Examples:
            >>> from pyslurm import Jobs
            >>> Job(9999).unsuspend()
        """
        # Same problem as described in suspend()
        verify_rpc(slurm_resume(self.id))

    def modify(self, JobSubmitDescription changes):
        """Modify a Job.

        Implements the slurm_update_job RPC.

        Args:
            changes (JobSubmitDescription):
                A JobSubmitDescription object which contains all the
                modifications that should be done on the Job.

        Raises:
            RPCError: When updating the Job was not successful.

        Examples:
            >>> from pyslurm import Job, JobSubmitDescription
            >>> 
            >>> # Setting the new time-limit to 20 days
            >>> changes = JobSubmitDescription(time_limit="20-00:00:00")
            >>> Job(9999).modify(changes)
        """
        changes._create_job_submit_desc(is_update=True)
        changes.ptr.job_id = self.id
        verify_rpc(slurm_update_job(changes.ptr))

    def hold(self, mode=None):
        """Hold a currently pending Job, preventing it from being scheduled.

        Args:
            mode (str):
                Determines in which mode the Job should be held. Possible
                values are "user" or "admin". By default, the Job is held in
                "admin" mode, meaning only an Administrator will be able to
                release the Job again. If you specify the mode as "user", the
                User will also be able to release the job.

        Note:
            Uses the modify() function to set the Job's priority to 0.

        Raises:
            RPCError: When holding the Job was not successful.

        Examples:
            >>> from pyslurm import Job
            >>> 
            >>> # Holding a Job (in "admin" mode by default)
            >>> Job(9999).hold()
            >>> 
            >>> # Holding a Job in "user" mode
            >>> Job(9999).hold(mode="user")
        """
        cdef JobSubmitDescription job_sub = JobSubmitDescription(priority=0)

        if mode and mode.casefold() == "user":
            job_sub.ptr.alloc_sid = slurm.ALLOC_SID_USER_HOLD

        self.modify(job_sub)

    def release(self):
        """Release a currently held Job, allowing it to be scheduled again.

        Note:
            Uses the modify() function to reset the priority back to
            be controlled by the slurmctld's priority calculation routine.

        Raises:
            RPCError: When releasing a held Job was not successful.

        Examples:
            >>> from pyslurm import Job
            >>> Job(9999).release()
        """
        self.modify(JobSubmitDescription(priority=slurm.INFINITE))

    def requeue(self, hold=False):
        """Requeue a currently running Job.

        Implements the slurm_requeue RPC.

        Args:
            hold (bool):
                Controls whether the Job should be put in a held state or not.
                Default for this is 'False', so it will not be held.

        Raises:
            RPCError: When requeing the Job was not successful.

        Examples:
            >>> from pyslurm import Job
            >>> 
            >>> # Requeing a Job while allowing it to be
            >>> # scheduled again immediately
            >>> Job(9999).requeue()
            >>> 
            >>> # Requeing a Job while putting it in a held state
            >>> Job(9999).requeue(hold=True)
        """
        cdef uint32_t flags = 0

        if hold:
            flags |= slurm.JOB_REQUEUE_HOLD

        verify_rpc(slurm_requeue(self.id, flags))

    def notify(self, msg):
        """Sends a message to the Jobs stdout.

        Implements the slurm_notify_job RPC.

        Args:
            msg (str):
                The message that should be sent.

        Raises:
            RPCError: When sending the message to the Job was not successful.
                
        Examples:
            >>> from pyslurm import Job
            >>> Job(9999).notify("Hello Friends!")
        """
        verify_rpc(slurm_notify_job(self.id, msg))

    def get_batch_script(self):
        """Return the content of the script for a Batch-Job.

        Note:
            The string returned also includes all the "\n" characters
                (new-line).

        Returns:
            str: The content of the batch script.

        Raises:
            RPCError: When retrieving the Batch-Script for the Job was not
            successful.

        Examples:
            >>> from pyslurm import Job
            >>> script = Job(9999).get_batch_script()
        """
        # This reimplements the slurm_job_batch_script API call. Otherwise we
        # would have to parse back the FILE* ptr we get from it back into a
        # char* which would be a bit silly.
        # Source: https://github.com/SchedMD/slurm/blob/7162f15af8deaf02c3bbf940d59e818cdeb5c69d/src/api/job_info.c#L1319
        cdef:
            job_id_msg_t msg
            slurm_msg_t req
            slurm_msg_t resp
            int rc = slurm.SLURM_SUCCESS
            str script = None

        slurm_msg_t_init(&req)
        slurm_msg_t_init(&resp)

        memset(&msg, 0, sizeof(msg))
        msg.job_id   = self.id
        req.msg_type = slurm.REQUEST_BATCH_SCRIPT
        req.data     = &msg

        rc = slurm_send_recv_controller_msg(&req, &resp, working_cluster_rec)
        verify_rpc(rc)

        if resp.msg_type == slurm.RESPONSE_BATCH_SCRIPT:
            script = cstr.to_unicode(<char*>resp.data)
            xfree(resp.data)
        elif resp.msg_type == slurm.RESPONSE_SLURM_RC:
            rc = (<return_code_msg_t*> resp.data).return_code
            slurm_free_return_code_msg(<return_code_msg_t*>resp.data)
            verify_rpc(rc)
        else:
            verify_rpc(slurm.SLURM_ERROR)

        return script

    @property
    def name(self):
        """str: Name of the Job"""
        return cstr.to_unicode(self.ptr.name)

    @property
    def id(self):
        """int: Unique Job-ID"""
        return self.ptr.job_id

    @property
    def association_id(self):
        """int: ID of the Association this Job is run under."""
        return u32_parse(self.ptr.assoc_id)

    @property
    def account(self):
        """str: Name of the Account this Job is run under."""
        return cstr.to_unicode(self.ptr.account)

    @property
    def uid(self):
        """int: UID of the User who submitted the Job."""
        return u32_parse(self.ptr.user_id, zero_is_noval=False)

    @property
    def user(self):
        """str: Name of the User who submitted the Job."""
        return uid_to_name(self.ptr.user_id, lookup=self.passwd)

    @property
    def gid(self):
        """int: GID of the Group that Job runs under."""
        return u32_parse(self.ptr.group_id, zero_is_noval=False)

    @property
    def group(self):
        """str: Name of the Group this Job runs under."""
        return gid_to_name(self.ptr.group_id, lookup=self.groups)

    @property
    def priority(self):
        """int: Priority of the Job."""
        return u32_parse(self.ptr.priority, zero_is_noval=False)

    @property
    def nice(self):
        """int: Nice Value of the Job."""
        if self.ptr.nice == slurm.NO_VAL: 
            return None

        return self.ptr.nice - slurm.NICE_OFFSET

    @property
    def qos(self):
        """str: QOS Name of the Job."""
        return cstr.to_unicode(self.ptr.qos)

    @property
    def min_cpus_per_node(self):
        """int: Minimum Amount of CPUs per Node the Job requested."""
        return u32_parse(self.ptr.pn_min_cpus)

    # I don't think this is used anymore - there is no way in sbatch to ask
    # for a "maximum cpu" count, so it will always be empty.
    # @property
    # def max_cpus(self):
    #     """Maximum Amount of CPUs the Job requested."""
    #     return u32_parse(self.ptr.max_cpus)

    @property
    def state(self):
        """str: State this Job is currently in."""
        return cstr.to_unicode(slurm_job_state_string(self.ptr.job_state))

    @property
    def state_reason(self):
        """str: A Reason explaining why the Job is in its current state."""
        if self.ptr.state_desc: 
            return cstr.to_unicode(self.ptr.state_desc)

        return cstr.to_unicode(slurm_job_reason_string(self.ptr.state_reason))

    @property
    def is_requeueable(self):
        """bool: Whether the Job is requeuable or not."""
        return u16_parse_bool(self.ptr.requeue)

    @property
    def requeue_count(self):
        """int: Amount of times the Job has been requeued."""
        return u16_parse(self.ptr.restart_cnt, on_noval=0)

    @property
    def is_batch_job(self):
        """bool: Whether the Job is a batch job or not."""
        return u16_parse_bool(self.ptr.batch_flag)

    @property
    def reboot_nodes(self):
        """bool: Whether the Job requires the Nodes to be rebooted first."""
        return u8_parse_bool(self.ptr.reboot)

    @property
    def dependencies(self):
        """dict: Dependencies the Job has to other Jobs."""
        dep = cstr.to_unicode(self.ptr.dependency, default=[])
        if not dep:
            return None

        out = {
            "after": [],
            "afterany": [],
            "afterburstbuffer": [],
            "aftercorr": [],
            "afternotok": [],
            "afterok": [],
            "singleton": False,
            "satisfy": "all",
        }

        delim = ","
        if "?" in dep:
            delim = "?"
            out["satisfy"] = "any"

        for item in dep.split(delim):
            if item == "singleton":
                out["singleton"] = True

            dep_and_job = item.split(":", 1)
            if len(dep_and_job) != 2:
                continue

            dep_name, jobs = dep_and_job[0], dep_and_job[1].split(":")
            if dep_name not in out:
                continue

            for job in jobs:
                out[dep_name].append(int(job) if job.isdigit() else job)

        return out

    @property
    def time_limit_raw(self):
        """int: Time-Limit for this Job. (Unix timestamp)"""
        return _raw_time(self.ptr.time_limit)

    @property
    def time_limit(self):
        """str: Time-Limit for this Job. (formatted)"""
        return mins_to_timestr(self.ptr.time_limit, "PartitionLimit")

    @property
    def time_limit_min_raw(self):
        """int: Minimum Time-Limit for this Job (Unix timestamp)"""
        return _raw_time(self.ptr.time_min)

    @property
    def time_limit_min(self):
        """str: Minimum Time-limit acceptable for this Job (formatted)"""
        return mins_to_timestr(self.ptr.time_min)

    @property
    def submit_time_raw(self):
        """int: Time the Job was submitted. (Unix timestamp)"""
        return _raw_time(self.ptr.submit_time)

    @property
    def submit_time(self):
        """str: Time the Job was submitted. (formatted)"""
        return timestamp_to_date(self.ptr.submit_time)

    @property
    def eligible_time_raw(self):
        """int: Time the Job is eligible to start. (Unix timestamp)"""
        return _raw_time(self.ptr.eligible_time)

    @property
    def eligible_time(self):
        """str: Time the Job is eligible to start. (formatted)"""
        return timestamp_to_date(self.ptr.eligible_time)

    @property
    def accrue_time_raw(self):
        """int: Job accrue time (Unix timestamp)"""
        return _raw_time(self.ptr.accrue_time)

    @property
    def accrue_time(self):
        """str: Job accrue time (formatted)"""
        return timestamp_to_date(self.ptr.accrue_time)

    @property
    def start_time_raw(self):
        """int: Time this Job has started execution. (Unix timestamp)"""
        return _raw_time(self.ptr.start_time)

    @property
    def start_time(self):
        """str: Time this Job has started execution. (formatted)"""
        return timestamp_to_date(self.ptr.start_time)

    @property
    def resize_time_raw(self):
        """int: Time the job was resized. (Unix timestamp)"""
        return _raw_time(self.ptr.resize_time)

    @property
    def resize_time(self):
        """str: Time the job was resized. (formatted)"""
        return timestamp_to_date(self.ptr.resize_time)

    @property
    def deadline_time_raw(self):
        """int: Time when a pending Job will be cancelled. (Unix timestamp)"""
        return _raw_time(self.ptr.deadline)

    @property
    def deadline_time(self):
        """str: Time at which a pending Job will be cancelled. (formatted)"""
        return timestamp_to_date(self.ptr.deadline)

    @property
    def preempt_eligible_time_raw(self):
        """int: Time the Job is eligible for preemption. (Unix timestamp)"""
        return _raw_time(self.ptr.preemptable_time)

    @property
    def preempt_eligible_time(self):
        """str: Time when the Job is eligible for preemption. (formatted)"""
        return timestamp_to_date(self.ptr.preemptable_time)

    @property
    def preempt_time_raw(self):
        """int: Time the Job was signaled for preemption. (Unix timestamp)"""
        return _raw_time(self.ptr.preempt_time)

    @property
    def preempt_time(self):
        """str: Time the Job was signaled for preemption. (formatted)"""
        return timestamp_to_date(self.ptr.preempt_time)

    @property
    def suspend_time_raw(self):
        """int: Last Time the Job was suspended. (Unix timestamp)"""
        return _raw_time(self.ptr.suspend_time)

    @property
    def suspend_time(self):
        """str: Last Time the Job was suspended. (formatted)"""
        return timestamp_to_date(self.ptr.suspend_time)

    @property
    def last_sched_eval_time_raw(self):
        """int: Last time evaluated for Scheduling. (Unix timestamp)"""
        return _raw_time(self.ptr.last_sched_eval)

    @property
    def last_sched_eval_time(self):
        """str: Last Time evaluated for Scheduling. (formatted)"""
        return timestamp_to_date(self.ptr.last_sched_eval)

    @property
    def pre_suspension_time_raw(self):
        """int: Amount of seconds the Job ran prior to suspension."""
        return _raw_time(self.ptr.pre_sus_time)

    @property
    def pre_suspension_time(self):
        """str: Time the Job ran prior to suspension. (formatted)"""
        return secs_to_timestr(self.ptr.pre_sus_time)

    @property
    def mcs_label(self):
        """str: MCS Label for the Job"""
        return cstr.to_unicode(self.ptr.mcs_label)

    @property
    def partition(self):
        """str: Name of the Partition the Job runs in."""
        return cstr.to_unicode(self.ptr.partition)

    @property
    def submit_host(self):
        """str: Name of the Host this Job was submitted from."""
        return cstr.to_unicode(self.ptr.alloc_node)

    @property
    def batch_host(self):
        """str: Name of the Host where the Batch-Script is executed."""
        return cstr.to_unicode(self.ptr.batch_host)

    @property
    def min_nodes(self):
        """int: Minimum amount of Nodes the Job has requested."""
        return u32_parse(self.ptr.num_nodes)

    @property
    def max_nodes(self):
        """int: Maximum amount of Nodes the Job has requested."""
        return u32_parse(self.ptr.max_nodes)

    @property
    def alloc_nodes(self):
        """str: Nodes the Job is using.

        This is the formatted string of Nodes as shown by scontrol.
        For example, it can look like this:

        "node001,node[005-010]"

        If you want to expand this string into a list of nodenames you can
        use the "pyslurm.nodelist_from_range_str" function.

        Note:
            This is only valid when the Job is running. If the Job is pending,
            it will always return an empty list.
        """
        return cstr.to_unicode(self.ptr.nodes)

    @property
    def required_nodes(self):
        """str: Nodes the Job is explicitly requiring to run on.

        This is the formatted string of Nodes as shown by scontrol.
        For example, it can look like this:

        "node001,node[005-010]"

        If you want to expand this string into a list of nodenames you can
        use the "pyslurm.nodelist_from_range_str" function.
        """
        return cstr.to_unicode(self.ptr.req_nodes)

    @property
    def excluded_nodes(self):
        """str: Nodes that are explicitly excluded for execution.

        This is the formatted string of Nodes as shown by scontrol.
        For example, it can look like this:

        "node001,node[005-010]"

        If you want to expand this string into a list of nodenames you can
        use the "pyslurm.nodelist_from_range_str" function.
        """
        return cstr.to_unicode(self.ptr.exc_nodes)

    @property
    def scheduled_nodes(self):
        """str: Nodes the Job is scheduled on by the slurm controller.

        This is the formatted string of Nodes as shown by scontrol.
        For example, it can look like this:

        "node001,node[005-010]"

        If you want to expand this string into a list of nodenames you can
        use the "pyslurm.nodelist_from_range_str" function.
        """
        return cstr.to_unicode(self.ptr.sched_nodes)

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
    def exit_code(self):
        """int: Code with which the Job has exited."""
        if (self.ptr.exit_code == slurm.NO_VAL
                or not WIFEXITED(self.ptr.exit_code)):
            return None

        return WEXITSTATUS(self.ptr.exit_code)

    @property
    def exit_code_signal(self):
        """int: The signal which has led to the exit code of the Job."""
        if (self.ptr.exit_code == slurm.NO_VAL
                or not WIFSIGNALED(self.ptr.exit_code)):
            return None

        return WTERMSIG(self.ptr.exit_code)

    @property
    def batch_constraints(self):
        """list: Features that node(s) should have for the batch script.

        Controls where it is possible to execute the batch-script of the job.
        Also see 'constraints'
        """
        return cstr.to_list(self.ptr.batch_features)

    @property
    def federation_origin(self):
        """str: Federation Origin"""
        return cstr.to_unicode(self.ptr.fed_origin_str)

    @property
    def federation_siblings_active(self):
        """str: Federation siblings active"""
        return u64_parse(self.ptr.fed_siblings_active)

    @property
    def federation_siblings_viable(self):
        """str: Federation siblings viable"""
        return u64_parse(self.ptr.fed_siblings_viable)

    @property
    def alloc_cpus(self):
        """int: Total amount of CPUs the Job is using.

        If the Job is still pending, this will be None.
        """
        return u32_parse(self.ptr.num_cpus)

    @property
    def cpus_per_task(self):
        """int: Number of CPUs per Task used."""
        if self.ptr.cpus_per_tres:
            return None
        
        return u16_parse(self.ptr.cpus_per_task, on_noval=1)

    @property
    def cpus_per_gpu(self):
        """int: Number of CPUs per GPU used."""
        if (not self.ptr.cpus_per_tres
                or self.ptr.cpus_per_task != slurm.NO_VAL16):
            return None

        # TODO: Make a function that, given a GRES type, safely extracts its
        # value from the string.
        val = cstr.to_unicode(self.ptr.cpus_per_tres).split(":")[2]
        return u16_parse(val)

    @property
    def boards_per_node(self):
        """int: Number of boards per Node."""
        return u16_parse(self.ptr.boards_per_node)

    @property
    def sockets_per_board(self):
        """int: Number of sockets per board."""
        return u16_parse(self.ptr.sockets_per_board)

    @property
    def sockets_per_node(self):
        """int: Number of sockets per node."""
        return u16_parse(self.ptr.sockets_per_node)

    @property
    def cores_per_socket(self):
        """int: Number of cores per socket."""
        return u16_parse(self.ptr.cores_per_socket)

    @property
    def threads_per_core(self):
        """int: Number of threads per core."""
        return u16_parse(self.ptr.threads_per_core)

    @property
    def ntasks(self):
        """int: Number of parallel processes."""
        return u32_parse(self.ptr.num_tasks, on_noval=1)

    @property
    def ntasks_per_node(self):
        """int: Number of parallel processes per node."""
        return u16_parse(self.ptr.ntasks_per_node)

    @property
    def ntasks_per_board(self):
        """int: Number of parallel processes per board."""
        return u16_parse(self.ptr.ntasks_per_board)

    @property
    def ntasks_per_socket(self):
        """int: Number of parallel processes per socket."""
        return u16_parse(self.ptr.ntasks_per_socket)

    @property
    def ntasks_per_core(self):
        """int: Number of parallel processes per core."""
        return u16_parse(self.ptr.ntasks_per_core)

    @property
    def ntasks_per_gpu(self):
        """int: Number of parallel processes per GPU."""
        return u16_parse(self.ptr.ntasks_per_tres)

    @property
    def delay_boot_time_raw(self):
        """int: https://slurm.schedmd.com/sbatch.html#OPT_delay-boot"""
        return _raw_time(self.ptr.delay_boot)

    @property
    def delay_boot_time(self):
        """str: https://slurm.schedmd.com/sbatch.html#OPT_delay-boot"""
        return secs_to_timestr(self.ptr.delay_boot)

    @property
    def constraints(self):
        """list: A list of features the Job requires nodes to have.

        In contrast, the 'batch_constraints' option only focuses on the
        initial batch-script placement.

        This option however means features to restrict the list of nodes a
        job is able to execute on in general beyond the initial batch-script.
        """
        return cstr.to_list(self.ptr.features)

    @property
    def cluster(self):
        """str: Name of the cluster the job is executing on."""
        return cstr.to_unicode(self.ptr.cluster)

    @property
    def cluster_constraints(self):
        """list: A List of features that a cluster should have.""" 
        return cstr.to_list(self.ptr.cluster_features)

    @property
    def reservation(self):
        """str: Name of the reservation this Job uses."""
        return cstr.to_unicode(self.ptr.resv_name)

    @property
    def resource_sharing(self):
        """str: Mode controlling how a job shares resources with others."""
        return cstr.to_unicode(slurm_job_share_string(self.ptr.shared))

    @property
    def contiguous(self):
        """bool: Whether the Job requires a set of contiguous nodes."""
        return u16_parse_bool(self.ptr.contiguous)

    @property
    def licenses(self):
        """list: List of licenses the Job needs."""
        return cstr.to_list(self.ptr.licenses)

    @property
    def network(self):
        """str: Network specification for the Job."""
        return cstr.to_unicode(self.ptr.network)

    @property
    def command(self):
        """str: The command that is executed for the Job."""
        return cstr.to_unicode(self.ptr.command)

    @property
    def work_dir(self):
        """str: Path to the working directory for this Job."""
        return cstr.to_unicode(self.ptr.work_dir)

    @property
    def admin_comment(self):
        """str: An arbitrary comment set by an administrator for the Job."""
        return cstr.to_unicode(self.ptr.admin_comment)

    @property
    def system_comment(self):
        """str: An arbitrary comment set by the slurmctld for the Job."""
        return cstr.to_unicode(self.ptr.system_comment)

    @property
    def container(self):
        """str: The container this Job uses."""
        return cstr.to_unicode(self.ptr.container)

    @property
    def comment(self):
        """str: An arbitrary comment set for the Job."""
        return cstr.to_unicode(self.ptr.comment)

    @property
    def stdin(self):
        """str: The path to the file for stdin."""
        cdef char tmp[1024]
        slurm_get_job_stdin(tmp, sizeof(tmp), self.ptr)
        return cstr.to_unicode(tmp)

    @property
    def stdout(self):
        """str: The path to the log file for stdout."""
        cdef char tmp[1024]
        slurm_get_job_stdout(tmp, sizeof(tmp), self.ptr)
        return cstr.to_unicode(tmp)

    @property
    def stderr(self):
        """The path to the log file for stderr."""
        cdef char tmp[1024]
        slurm_get_job_stderr(tmp, sizeof(tmp), self.ptr)
        return cstr.to_unicode(tmp)

    @property
    def num_switches(self):
        """int: Number of switches requested."""
        return u32_parse(self.ptr.req_switch)

    @property
    def max_wait_time_switches_raw(self):
        """int: Amount of seconds to wait for the switches."""
        return _raw_time(self.ptr.wait4switch)

    @property
    def max_wait_time_switches(self):
        """str: Amount of seconds to wait for the switches. (formatted)"""
        return secs_to_timestr(self.ptr.wait4switch)

    @property
    def burst_buffer(self):
        """str: Burst buffer specification"""
        return cstr.to_unicode(self.ptr.burst_buffer)

    @property
    def burst_buffer_state(self):
        """str: Burst buffer state"""
        return cstr.to_unicode(self.ptr.burst_buffer_state)

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

    #   @property
    #   def tres_bindings(self):
    #       """str: ?"""
    #       # TODO: Find out how it works
    #       return cstr.to_unicode(self.ptr.tres_bind)

    #   @property
    #   def tres_frequency(self):
    #       """?"""
    #       # TODO: Find out how it works
    #       return cstr.to_unicode(self.ptr.tres_freq)

    @property
    def wckey(self):
        """str: Name of the WCKey this Job uses."""
        return cstr.to_unicode(self.ptr.wckey)

    @property
    def mail_user(self):
        """list: Users that should receive Mails for this Job."""
        return cstr.to_list(self.ptr.mail_user)

    @property
    def mail_types(self):
        """list: Mail Flags specified by the User."""
        return get_mail_type(self.ptr.mail_type)

    @property
    def hetjob_id(self):
        """int: Heterogeneous ID"""
        return u32_parse(self.ptr.het_job_id, noval=0)

    @property
    def hetjob_offset(self):
        """int: Heterogeneous Job offset"""
        return u32_parse(self.ptr.het_job_offset, noval=0)

    #   @property
    #   def hetjob_component_ids(self):
    #       """str: ?"""
    #       # TODO: Find out how to parse it in a more proper way?
    #       return cstr.to_unicode(self.ptr.het_job_id_set)

    @property
    def tmp_disk_per_node_raw(self):
        """int: Temporary disk space available per Node. (in Mebibytes)"""
        return u32_parse(self.ptr.pn_min_tmp_disk)

    @property
    def tmp_disk_per_node(self):
        """str: Amount of temporary disk space available per Node.

        The output for this value is already in a human readable format,
        with appropriate unit suffixes like K|M|G|T.
        """
        return humanize(self.tmp_disk_per_node_raw)

    @property
    def array_job_id(self):
        """int: The master Array-Job ID."""
        return u32_parse(self.ptr.array_job_id)

    @property
    def array_tasks_parallel(self):
        """int: Number of array tasks allowed to run in simultaneously."""
        return u32_parse(self.ptr.array_max_tasks)

    @property
    def array_task_id(self):
        """int: The Task-ID if the Job is an Array-Job."""
        return u32_parse(self.ptr.array_task_id)

    @property
    def array_tasks_waiting(self):
        """str: Array Tasks that are still waiting.

        This is the formatted string of Task-IDs as shown by scontrol.
        For example, it can look like this:

        "1-3,5-7,8,9"

        If you want to expand this string including the ranges into a
        list, you can use the "pyslurm.expand_range_str" function.
        """
        task_str = cstr.to_unicode(self.ptr.array_task_str)
        if not task_str:
            return None
        
        if "%" in task_str:
            # We don't want this % character and everything after it
            # in here, so remove it.
            task_str = task_str[:task_str.rindex("%")]

        return task_str

    @property
    def end_time(self):
        """int: Time at which this Job has ended. (Unix timestamp)"""
        return _raw_time(self.ptr.end_time)
    
    @property
    def end_time(self):
        """str: Time at which this Job has ended. (formatted)"""
        return timestamp_to_date(self.ptr.end_time)

    # https://github.com/SchedMD/slurm/blob/d525b6872a106d32916b33a8738f12510ec7cf04/src/api/job_info.c#L480
    cdef _calc_run_time(self):
        cdef time_t rtime
        cdef time_t etime

        if slurm.IS_JOB_PENDING(self.ptr):
            return None
        elif slurm.IS_JOB_SUSPENDED(self.ptr):
            return self.pre_suspension_time
        else:
            if slurm.IS_JOB_RUNNING(self.ptr) or self.ptr.end_time == 0:
                etime = ctime.time(NULL)
            else:
                etime = self.ptr.end_time

            if self.ptr.suspend_time:
                rtime = <time_t>ctime.difftime(
                    etime,
                    self.ptr.suspend_time + self.ptr.pre_sus_time)
            else:
                rtime = <time_t>ctime.difftime(etime, self.ptr.start_time)

        return u64_parse(rtime)

    @property
    def run_time_raw(self):
        """int: Amount of seconds the Job has been running. (Unix timestamp)"""
        return _raw_time(self._calc_run_time())

    @property
    def run_time(self):
        """str: Amount of seconds the Job has been running. (formatted)"""
        return secs_to_timestr(self._calc_run_time())

    @property
    def cores_reserved_for_system(self):
        """int: Amount of cores reserved for System use only."""
        if self.ptr.core_spec != slurm.NO_VAL16:
            if not self.ptr.core_spec & slurm.CORE_SPEC_THREAD:
                return self.ptr.core_spec

    @property
    def threads_reserved_for_system(self):
        """int: Amount of Threads reserved for System use only."""
        if self.ptr.core_spec != slurm.NO_VAL16:
            if self.ptr.core_spec & slurm.CORE_SPEC_THREAD:
                return self.ptr.core_spec & (~slurm.CORE_SPEC_THREAD)

    @property
    def mem_per_cpu_raw(self):
        """int: Amount of Memory per CPU this Job has. (in Mebibytes)"""
        if self.ptr.pn_min_memory != slurm.NO_VAL64:
            if self.ptr.pn_min_memory & slurm.MEM_PER_CPU:
                mem = self.ptr.pn_min_memory & (~slurm.MEM_PER_CPU)
                return u64_parse(mem)
        else:
            return None

    @property
    def mem_per_cpu(self):
        """str: Humanized amount of Memory per CPU this Job has."""
        return humanize(self.mem_per_cpu_raw)

    @property
    def mem_per_node_raw(self):
        """int: Amount of Memory per Node this Job has. (in Mebibytes)"""
        if self.ptr.pn_min_memory != slurm.NO_VAL64:
            if not self.ptr.pn_min_memory & slurm.MEM_PER_CPU:
                return u64_parse(self.ptr.pn_min_memory)
        else:
            return None

    @property
    def mem_per_node(self):
        """str: Humanized amount of Memory per Node this Job has."""
        return humanize(self.mem_per_node_raw)

    @property
    def mem_per_gpu_raw(self):
        """int: Amount of Memory per GPU this Job has. (in Mebibytes)"""
        if self.ptr.mem_per_tres and self.ptr.pn_min_memory == slurm.NO_VAL64:
            # TODO: Make a function that, given a GRES type, safely extracts
            # its value from the string.
            mem = int(cstr.to_unicode(self.ptr.mem_per_tres).split(":")[2])
            return u64_parse(mem)
        else:
            return None

    @property
    def mem_per_gpu(self):
        """str: Humanized amount of Memory per GPU this Job has."""
        return humanize(self.mem_per_gpu_raw)

    @property
    def gres_per_node(self):
        """dict: GRES (e.g. GPU) this Job is using per Node."""
        return cstr.to_gres_dict(self.ptr.tres_per_node)

    @property
    def accounting_gather_profile(self):
        """list: Options that control gathering of Accounting information."""
        return get_acctg_profile(self.ptr.profile)

    @property
    def gres_binding(self):
        """str: Binding Enforcement of a GRES resource (e.g. GPU)."""
        if self.ptr.bitflags & slurm.GRES_ENFORCE_BIND:
            return "enforce"
        elif self.ptr.bitflags & slurm.GRES_DISABLE_BIND:
            return "disable"
        else:
            return None

    @property
    def kill_on_invalid_dep(self):
        """bool: Whether the Job should be killed on an invalid dependency."""
        return u64_parse_bool_flag(self.ptr.bitflags, slurm.KILL_INV_DEP)

    @property
    def spread_job(self):
        """bool: Whether the Job should be spread accross the nodes."""
        return u64_parse_bool_flag(self.ptr.bitflags, slurm.SPREAD_JOB)

    @property
    def power(self):
        """list: Options for Power Management."""
        return get_power_type(self.ptr.power_flags)

    @property
    def is_cronjob(self):
        """bool: Whether this Job is a cronjob."""
        return u64_parse_bool_flag(self.ptr.bitflags, slurm.CRON_JOB)

    @property
    def cronjob_time(self):
        """str: The time specification for the Cronjob."""
        return cstr.to_unicode(self.ptr.cronspec)

    def get_resource_layout_per_node(self):
        """Retrieve the resource layout of this Job on each node.

        This contains the following information:
            * cpus (int)
            * gres (dict)
            * memory (str) - Humanized Memory str
            * memory_raw (int) - Value in Mebibytes

        Returns:
            dict: Resource layout
        """
        # TODO: Explain the structure of the return value a bit more.
        cdef:
            slurm.job_resources *resources = <slurm.job_resources*>self.ptr.job_resrcs
            slurm.hostlist_t hl
            uint32_t rel_node_inx
            int bit_inx = 0
            int bit_reps = 0
            int sock_inx = 0
            uint32_t sock_reps = 0
            int i = 0, j
            uint32_t k = 0
            char *host
            char *gres = NULL
            slurm.bitstr_t *cpu_bitmap
            char cpu_bitmap_str[128]
            uint32_t threads
            dict output = {}

        if not resources or not resources.core_bitmap:
            return output

        hl = slurm.slurm_hostlist_create(resources.nodes)
        if not hl:
            raise ValueError("Unable to create hostlist.")

        for rel_node_inx in range(resources.nhosts):
            # Check how many consecutive nodes have the same cpu allocation
            # layout.
            if sock_reps >= resources.sock_core_rep_count[sock_inx]:
                sock_inx += 1
                sock_reps = 0
            sock_reps += 1

            # Get the next node from the list of nodenames
            host = slurm.slurm_hostlist_shift(hl)

            # How many rounds we have to do in order to calculate the complete
            # cpu bitmap.
            bit_reps = (resources.sockets_per_node[sock_inx]
                        * resources.cores_per_socket[sock_inx])

            # Calculate the amount of threads per core this job has on the
            # specific host.
            threads = _threads_per_core(host)

            # Allocate a new, big enough cpu bitmap
            cpu_bitmap = slurm.slurm_bit_alloc(bit_reps * threads)

            # Calculate the cpu bitmap for this host.
            for j in range(bit_reps):
                if slurm.slurm_bit_test(resources.core_bitmap, bit_inx):
                    for k in range(threads):
                        slurm.slurm_bit_set(cpu_bitmap, (j*threads)+k)
                bit_inx += 1

            # Extract the cpu bitmap into a char *cpu_bitmap_str
            slurm.slurm_bit_fmt(cpu_bitmap_str,
                                sizeof(cpu_bitmap_str), cpu_bitmap)
            slurm.slurm_bit_free(&cpu_bitmap)

            nodename = cstr.to_unicode(host)
            cpu_ids  = cstr.to_unicode(cpu_bitmap_str)
            mem      = None

            if rel_node_inx < self.ptr.gres_detail_cnt:
                gres = self.ptr.gres_detail_str[rel_node_inx]

            if resources.memory_allocated:
                mem = u64_parse(resources.memory_allocated[rel_node_inx])

            if nodename:
                output[nodename] = {
                    "cpus":   cpu_ids,
                    "gres":   cstr.to_gres_dict(gres),
                    "memory": humanize(mem),
                    "memory_raw": mem,
                }

            free(host)

        slurm.slurm_hostlist_destroy(hl)
        return output    

            
# https://github.com/SchedMD/slurm/blob/d525b6872a106d32916b33a8738f12510ec7cf04/src/api/job_info.c#L99
cdef _threads_per_core(char *host):
    # TODO
    return 1
