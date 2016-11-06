# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
# cython: cdivision=True
"""
===========
:mod:`job`
===========

The job extension module is used to get Slurm job information.

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

- slurm_free_job_info_msg
- slurm_load_job
- slurm_load_jobs
- slurm_pid2jobid

Job Objects
------------

Several functions in this module wrap the ``job_info_t`` struct found in
`slurm.h`. The members of this struct are converted to a :class:`Job` object,
which implements Python properties to retrieve the value of each attribute.

Each job record in a ``job_info_msg_t`` struct is converted to a
:class:`Job` object when calling some of the functions in this module.

"""
from __future__ import absolute_import, division, unicode_literals

from grp import getgrgid
from pwd import getpwnam, getpwuid

from libc.time cimport difftime
from libc.time cimport time as c_time
from posix.types cimport pid_t, time_t
from posix.wait cimport WIFSIGNALED, WTERMSIG, WEXITSTATUS

from .c_job cimport *
from .slurm_common cimport *
from .utils cimport *
from .exceptions import PySlurmError

cdef class Job:
    """An object to wrap `job_info_t` structs."""
    cdef:
        readonly unicode account
        readonly unicode alloc_node
        readonly uint32_t alloc_sid
        readonly uint32_t array_job_id
        readonly uint32_t array_task_id
        readonly unicode array_task_str
        readonly uint16_t batch_flag
        readonly unicode batch_host
        readonly unicode batch_script
        uint16_t boards_per_node
        readonly unicode burst_buffer
        readonly unicode command
        readonly unicode comment
        readonly uint16_t contiguous
        uint16_t cores_per_socket
        uint16_t core_spec
        readonly uint16_t cpus_per_task
        readonly unicode dependency
        uint32_t derived_exit_code
        readonly time_t eligible_time
        readonly unicode eligible_time_str
        readonly time_t end_time
        readonly unicode end_time_str
        readonly list exc_midplane_list
        readonly list exc_node_list
        uint32_t exit_code
        readonly list features
        readonly list gres
        readonly uint32_t group_id
        readonly unicode group_name
        readonly uint32_t job_id
        readonly unicode job_name
        readonly unicode job_state
        readonly unicode kill_o_in_invalid_dependent
        readonly unicode licenses
        readonly unicode midplane_list
        unicode mcs_label
        readonly uint32_t min_cpus_node
        readonly unicode network
        readonly uint16_t nice
        readonly unicode node_list
        uint16_t ntasks_per_board
        uint16_t ntasks_per_core
        uint16_t ntasks_per_node
        uint16_t ntasks_per_socket
        uint32_t num_cpus
        uint32_t num_nodes
        readonly unicode partition
        readonly unicode power
        readonly time_t preempt_time
        readonly unicode preempt_time_str
        readonly uint32_t priority
        readonly unicode qos
        readonly unicode reason
        readonly uint8_t reboot
        readonly list req_midplane_list
        readonly list req_node_list
        readonly uint32_t req_switch
        readonly uint16_t requeue
        readonly time_t resize_time
        readonly unicode resize_time_str
        readonly uint16_t restarts
        readonly unicode reservation
        readonly time_t run_time
        readonly unicode run_time_str
        readonly unicode sched_midplane_list
        readonly unicode sched_node_list
        readonly int secs_pre_suspend
        uint16_t over_subscribe
        readonly time_t start_time
        readonly unicode start_time_str
        readonly unicode std_err
        readonly unicode std_in
        readonly unicode std_out
        uint16_t sockets_per_board
        uint16_t socks_per_node
        readonly time_t submit_time
        readonly unicode submit_time_str
        readonly time_t suspend_time
        readonly unicode suspend_time_str
        unicode switches
        uint16_t threads_per_core
        readonly uint32_t time_limit
        unicode time_limit_str
        readonly uint32_t time_min
        unicode time_min_str
        readonly unicode tres
        readonly uint32_t user_id
        readonly unicode user_name
        readonly uint32_t wait4switch
        readonly unicode work_dir
        readonly unicode wckey

    @property
    def boards_per_node(self):
        """Boards per node, required by job"""
        if self.boards_per_node == <uint16_t>NO_VAL:
            return "*"
        else:
            return self.boards_per_node

    @property
    def core_spec(self):
        """Specialized core count"""
        if self.core_spec == <uint16_t>NO_VAL:
            return "*"
        elif (self.core_spec & CORE_SPEC_THREAD):
            return None
        else:
            return self.core_spec

    @property
    def cores_per_socket(self):
        """Cores per socket, required by job"""
        if self.cores_per_socket == <uint16_t>NO_VAL:
            return "*"
        else:
            return self.cores_per_socket

    @property
    def derived_exit_code(self):
        """Highest exit code of all job steps."""
        cdef:
            uint16_t exit_status = 0
            uint16_t term_sig = 0

        if WIFSIGNALED(self.derived_exit_code):
            term_sig = WTERMSIG(self.derived_exit_code)

        exit_status = WEXITSTATUS(self.derived_exit_code)
        return "%s:%s" % exit_status, term_sig

    @property
    def exit_code(self):
        """Exit code for job (status from wait call)."""
        cdef:
            uint16_t exit_status = 0
            uint16_t term_sig = 0

        if WIFSIGNALED(self.exit_code):
            term_sig = WTERMSIG(self.exit_code)

        exit_status = WEXITSTATUS(self.exit_code)
        return "%s:%s" % exit_status, term_sig

    @property
    def mcs_label(self):
        """mcs_label if mcs plugin in use."""
        if self.mcs_label:
            return self.mcs_label
        else:
            return "N/A"

    @property
    def ntasks_per_board(self):
        """Number of tasks to invoke on each board"""
        if self.ntasks_per_board == <uint16_t>NO_VAL:
            return "*"
        else:
            return self.ntasks_per_board

    @property
    def ntasks_per_core(self):
        """Number of tasks to invoke on each core"""
        if (self.ntasks_per_core == <uint16_t>NO_VAL or
            self.ntasks_per_core == <uint16_t>INFINITE):
            return "*"
        else:
            return self.ntasks_per_core

    @property
    def ntasks_per_node(self):
        """Number of tasks to invoke on each node"""
        if self.ntasks_per_node == <uint16_t>NO_VAL:
            return "*"
        else:
            return self.ntasks_per_node

    @property
    def ntasks_per_socket(self):
        """Number of tasks to invoke on each socket"""
        if (self.ntasks_per_socket == <uint16_t>NO_VAL or
            self.ntasks_per_socket == <uint16_t>INFINITE):
            return "*"
        else:
            return self.ntasks_per_socket

    @property
    def num_cpus(self):
        """Minimum number of CPUs required by job"""
        pass

    @property
    def num_nodes(self):
        """Minimum number of nodes required by job"""
        pass

    @property
    def over_subscribe(self):
        """1 if job can share nodes with other jobs"""
        return slurm_job_share_string(self.over_subscribe)

    @property
    def sockets_per_board(self):
        """Sockets per board, required by job"""
        if self.sockets_per_board == <uint16_t>NO_VAL:
            return "*"
        else:
            return self.sockets_per_board

    @property
    def socks_per_node(self):
        """Sockets per node, required by job"""
        if self.socks_per_node == <uint16_t>NO_VAL:
            return "*"
        else:
            return self.socks_per_node

    @property
    def switches(self):
        cdef char time_buf[32]
        slurm_secs2time_str(<time_t>self.wait4switch, time_buf, sizeof(time_buf))
        return self.req_switch + "@" + time_buf

    @property
    def thread_spec(self):
        """Specialized core/thread count"""
        if (self.core_spec & CORE_SPEC_THREAD):
            return self.core_spec & (~CORE_SPEC_THREAD)

    @property
    def threads_per_core(self):
        """Threads per core, required by job"""
        if self.threads_per_core == <uint16_t>NO_VAL:
            return "*"
        else:
            return self.threads_per_core

    @property
    def time_limit_str(self):
        """Maximum run time in minutes or INFINITE."""
        cdef char time_str[32]
        if self.time_limit == NO_VAL:
            return "Partition_Limit"
        else:
            slurm_mins2time_str(<time_t>self.time_limit, time_str, sizeof(time_str))
            return time_str

    @property
    def time_min_str(self):
        """Minimum run time in minutes or INFINITE."""
        cdef char time_str[32]
        if self.time_min == 0:
            return "N/A"
        else:
            slurm_mins2time_str(<time_t>self.time_min, time_str, sizeof(time_str))
            return time_str


def get_jobs(ids=False):
    """
    Return a list of all jobs as :class:`Job` objects.

    This function calls ``slurm_load_jobs`` to retrieve information for all
    jobs.

    Args:
        ids (Optional[bool]): Return list of only job ids if True (default
            False).
    Returns:
        list: A list of :class:`Job` objects, one for each job.
    Raises:
        PySlurmError: if ``slurm_load_jobs`` is unsuccessful.

    """
    return get_job_info_msg(None, ids)


def get_job(jobid):
    """
    Return a single :class:`Job` object for the given jobid.

    This function calls ``slurm_load_job`` to retrieve information for the
    given jobid.

    Args:
        jobid (str): jobid to query
    Returns:
        Job: A single :class:`Job` object
    Raises:
        PySlurmError: if ``slurm_load_job`` is unsuccessful.

    """
    return get_job_info_msg(jobid)


cdef get_job_info_msg(jobid, ids=False):
    cdef:
        job_info_msg_t *job_info_msg_ptr = NULL
        job_resources_t *job_resrcs = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        char time_str[32]
        char tmp_line[1024 * 128]
        char tmp1[128]
        char *ionodes = NULL
        time_t end_time
        time_t run_time
        int rc
        uint64_t nice
        uint32_t cluster_flags = slurmdb_setup_cluster_flags()
        uint32_t max_nodes = 0
        uint32_t min_nodes = 0

    if jobid is None:
        rc = slurm_load_jobs(<time_t>NULL, &job_info_msg_ptr, show_flags)
    else:
        rc = slurm_load_job(&job_info_msg_ptr, jobid, show_flags)

    job_list = []
    if rc == SLURM_SUCCESS:
        for record in job_info_msg_ptr.job_array[:job_info_msg_ptr.record_count]:
            if ids and jobid is None:
                job_list.append(record.job_id)
                continue

            this_job = Job()
            this_job.job_id = record.job_id

            if record.array_job_id:
                if record.array_task_str:
                    this_job.array_job_id = record.array_job_id
                    # FIXME
                    this_job.array_task_str = record.array_task_str
                else:
                    this_job.array_job_id = record.array_job_id
                    this_job.array_task_id = record.array_task_id

            if record.name:
                this_job.job_name = record.name

            this_job.user_id = record.user_id
            try:
                this_job.user_name = (
                    getpwuid(record.user_id)[0].decode("UTF-8", "replace")
                )
            except:
                pass

            this_job.group_id = record.group_id

            try:
                this_job.group_name = (
                    getgrgid(record.group_id)[0].decode("UTF-8", "replace")
                )
            else:
                pass

            this_job.mcs_label = tounicode(record.mcs_label)

            nice = record.nice
            nice -= NICE_OFFSET
            this_job.nice = nice

            this_job.priority = record.priority
            if record.account:
                this_job.account = record.account

            if record.qos:
                this_job.qos = record.qos

            if slurm_get_track_wckey():
                this_job.wckey = record.wckey

            if record.state_desc:
                this_job.reason = record.state_desc.replace(" ", "_")
            else:
                if record.state_reason:
                    this_job.reason = (
                        slurm_job_reason_string(<job_state_reason>record.state_reason)
                    )

            if record.job_state:
                this_job.job_state = slurm_job_state_string(record.job_state)

            if record.dependency:
                this_job.dependency = record.dependency

            this_job.requeue = record.requeue
            this_job.restarts = record.restart_cnt
            this_job.batch_flag = record.batch_flag
            this_job.reboot = record.reboot
            this_job.exit_code = record.exit_code
            this_job.derived_exit_code = record.derived_ec

            if IS_JOB_PENDING(record):
                run_time = 0
            elif IS_JOB_SUSPENDED(record):
                run_time = record.pre_sus_time
            else:
                if IS_JOB_RUNNING(record) or record.end_time == 0:
                    end_time = c_time(NULL)
                else:
                    end_time = record.end_time

                if record.suspend_time:
                    run_time = <time_t>(difftime(end_time, record.suspend_time)
                                        + record.pre_sus_time)
                else:
                    run_time = <time_t>(difftime(end_time, record.start_time))

            this_job.run_time = run_time
            slurm_secs2time_str(run_time, time_str, sizeof(time_str))
            this_job.run_time_str = time_str

            this_job.time_limit = record.time_limit
            this_job.time_min = record.time_min

            this_job.submit_time = record.submit_time
            slurm_make_time_str(<time_t *>&record.submit_time, time_str,
                                sizeof(time_str))
            this_job.submit_time_str = time_str

            this_job.eligible_time = record.eligible_time
            slurm_make_time_str(<time_t *>&record.eligible_time, time_str,
                                sizeof(time_str))
            this_job.eligible_time_str = time_str

            if record.resize_time:
                this_job.resize_time = record.resize_time
                slurm_make_time_str(<time_t *>&record.resize_time, time_str,
                                    sizeof(time_str))
                this_job.resize_time_str = time_str

            this_job.start_time = record.start_time
            slurm_make_time_str(<time_t *>&record.start_time, time_str,
                                sizeof(time_str))
            this_job.start_time_str = time_str

            this_job.end_time = record.end_time
            if (record.time_limit == INFINITE) and (record.end_time > c_time(NULL)):
                this_job.end_time_str = "Unknown"
            else:
                slurm_make_time_str(<time_t *>&record.end_time, time_str,
                                    sizeof(time_str))
                this_job.end_time_str = time_str

            this_job.preempt_time = record.preempt_time
            if record.preempt_time == 0:
                pass
#                this_job.preempt_time_str = None
            else:
                slurm_make_time_str(<time_t *>&record.preempt_time, time_str,
                                    sizeof(time_str))
                this_job.preempt_time_str = time_str

            this_job.suspend_time = record.suspend_time
            if record.suspend_time:
                slurm_make_time_str(<time_t *>&record.suspend_time, time_str,
                                    sizeof(time_str))
                this_job.suspend_time_str = time_str
#            else:
#                this_job.suspend_time_str = None
            this_job.secs_pre_suspend = <int>record.pre_sus_time

            if record.partition:
                this_job.partition = record.partition

            if record.alloc_node:
                this_job.alloc_node = record.alloc_node

            this_job.alloc_sid = record.alloc_sid

            if (cluster_flags & CLUSTER_FLAG_BG):
                if record.req_nodes:
                    this_job.req_midplane_list = record.req_nodes.split(",")
                if record.exc_nodes:
                    this_job.exc_midplane_list = record.exc_nodes.split(",")
                slurm_get_select_jobinfo(record.select_jobinfo,
                                         SELECT_JOBDATA_IONODES,
                                         &ionodes)
            else:
                if record.req_nodes:
                    this_job.req_node_list = record.req_nodes.split(",")
                if record.exc_nodes:
                    this_job.exc_node_list = record.exc_nodes.split(",")

            if record.nodes:
                if ionodes:
                    this_job.midplane_list = (
                        record.nodes + "[" + ionodes + "]"
                    )
                else:
                    this_job.node_list = record.nodes

            if record.sched_nodes:
                if ionodes:
                    this_job.sched_midplane_list = record.sched_nodes
                else:
                    this_job.sched_node_list = record.sched_nodes

            if record.batch_host:
                this_job.batch_host = record.batch_host

            if (cluster_flags & CLUSTER_FLAG_BG):
                slurm_get_select_jobinfo(record.select_jobinfo,
                                         SELECT_JOBDATA_NODE_CNT,
                                         &min_nodes)
                if (min_nodes == 0) or (min_nodes == NO_VAL):
                    min_nodes = record.num_nodes
                    max_nodes = record.max_nodes
                elif record.max_nodes:
                    max_nodes = min_nodes
            elif IS_JOB_PENDING(record):
                min_nodes = record.num_nodes
                max_nodes = record.max_nodes
                if max_nodes and (max_nodes < min_nodes):
                    min_nodes = max_nodes
            else:
                min_nodes = record.num_nodes
                max_nodes = 0

            this_job.boards_per_node = record.boards_per_node
            this_job.sockets_per_board = record.sockets_per_board
            this_job.cores_per_socket = record.cores_per_socket
            this_job.threads_per_core = record.threads_per_core

#            this_job.num_nodes = # TODO
#            this_job.num_cpus = # TODO

            this_job.cpus_per_task = record.cpus_per_task

            if record.tres_alloc_str:
                this_job.tres = record.tres_alloc_str
            else:
                this_job.tres = record.tres_req_str

            this_job.socks_per_node = record.sockets_per_node
            this_job.ntasks_per_node = record.ntasks_per_node
            this_job.ntasks_per_board = record.ntasks_per_board
            this_job.ntasks_per_socket = record.ntasks_per_socket
            this_job.ntasks_per_core = record.ntasks_per_core
            this_job.core_spec = record.core_spec

            # TODO
            job_resrcs = record.job_resrcs

            if job_resrcs:
                if (cluster_flags & CLUSTER_FLAG_BG):
                    pass

            # TODO
            if (record.pn_min_memory & MEM_PER_CPU):
                record.pn_min_memory &= (~MEM_PER_CPU)
#                this_job.
                pass

            if (cluster_flags & CLUSTER_FLAG_BG):
#                convert_num_unit(<float>record.pn_min_cpus,
                pass
            else:
                this_job.min_cpus_node = record.pn_min_cpus

            # TODO
            # Line 18: min_memory / min_tmp_disk_node

            if record.features:
                this_job.features = record.features.split(",")

            if record.gres:
                this_job.gres = record.gres.split(",")

            if record.resv_name:
                this_job.reservation = record.resv_name

            this_job.over_subscribe = record.shared
            this_job.contiguous = record.contiguous

            if record.licenses:
                this_job.licenses = record.licenses

            if record.network:
                this_job.network = record.network

            if record.command:
                this_job.command = record.command

            if record.work_dir:
                this_job.work_dir = record.work_dir

            # TODO
            # Lines 23 - 28

            if record.comment:
                this_job.comment = record.comment

            if record.batch_flag:
                slurm_get_job_stderr(tmp_line, sizeof(tmp_line), &record)
                this_job.std_err = tmp_line

                slurm_get_job_stdin(tmp_line, sizeof(tmp_line), &record)
                this_job.std_in = tmp_line

                slurm_get_job_stdout(tmp_line, sizeof(tmp_line), &record)
                this_job.std_out = tmp_line

                if record.batch_script:
                    this_job.batch_script = record.batch_script

            if record.req_switch:
                this_job.req_switch = record.req_switch
                this_job.wait4switch = record.wait4switch

            # TODO: Line 34 (wait4switch slurm_secs2time_str)

            if record.burst_buffer:
                this_job.burst_buffer = record.burst_buffer

            # Line 36: cpu_freq_debug

            if (record.power_flags & SLURM_POWER_FLAGS_LEVEL):
                this_job.power = "LEVEL"
            else:
                this_job.power = ""

            if record.bitflags:
                if (record.bitflags & KILL_INV_DEP):
                    this_job.kill_o_in_invalid_dependent = "Yes"
                if (record.bitflags & NO_KILL_INV_DEP):
                    this_job.kill_o_in_invalid_dependent = "No"

            job_list.append(this_job)

        slurm_free_job_info_msg(job_info_msg_ptr)
        job_info_msg_ptr = NULL

        if jobid is None:
            return job_list
        else:
            return this_job
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


cpdef list get_user_jobs(user):
    """
    Return all jobs associated with a specific user.

    This method calls slurm_load_job_user to get all job_table records
    associated with a specific user.

    Args:
        user (str): User string to search
    Returns:
        A list of Job objects associated with specified user.
    Raises:
        PySlurmError: if slurm_load_job_user is not successful.
    """
    cdef:
        job_info_msg_t *job_info_msg_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        int rc
        uint32_t user_id
        char *username

    if isinstance(user, str):
        try:
            username = user
            user_id = getpwnam(username)[2]
        except KeyError:
            raise PySlurmError("user " + user + " not found")
    else:
        user_id = user

    rc = slurm_load_job_user(&job_info_msg_ptr, user_id, show_flags)

    if rc == SLURM_SUCCESS:
        pass
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


cpdef int pid2jobid(pid_t job_pid):
    """
    Return a Slurm job id corresponding to the given local process id.

    Args:
        job_pid (int): job pid
    Returns:
        Job id.
    """
    cdef:
        uint32_t job_id
        int rc

    rc = slurm_pid2jobid(job_pid, &job_id)

    if rc == SLURM_SUCCESS:
        return job_id
    else:
        raise PySlurmError(slurm_strerror(rc), rc)
