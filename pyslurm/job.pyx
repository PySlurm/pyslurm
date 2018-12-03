# cython: embedsignature=True
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
- slurm_get_rem_time
- slurm_get_end_time
- slurm_kill_job
- slurm_notify_job

Job Objects
------------

Several functions in this module wrap the ``job_info_t`` struct found in
`slurm.h`. The members of this struct are converted to a :class:`Job` object,
which implements Python properties to retrieve the value of each attribute.

Each job record in a ``job_info_msg_t`` struct is converted to a
:class:`Job` object when calling some of the functions in this module.

"""
from __future__ import absolute_import, division, unicode_literals

# Python Imports
from os import getuid, getgid
from pwd import getpwnam

# Cython Includes
#from cpython.string cimport PyString_AsString
from cpython cimport bool
from libc.errno cimport errno
from libc.signal cimport SIGKILL
from libc.stdlib cimport free
from libc.stdio cimport stdout
from libc.time cimport difftime
from libc.time cimport time as c_time
from posix.types cimport pid_t, time_t
from posix.wait cimport WIFSIGNALED, WTERMSIG, WEXITSTATUS, WIFEXITED

# PySlurm imports
from .c_job cimport *
from .c_hostlist cimport *
from .c_node cimport node_info_msg_t, slurm_load_node, slurm_free_node_info_msg
from .slurm_common cimport *
#from .hostlist import Hostlist
from .utils cimport *
from .exceptions import PySlurmError

include "job.pxi"

DEF CONVERT_NUM_UNIT_EXACT = 0x00000001

cdef inline FREE_NULL_BITMAP(bitstr_t *_X):
    while (0):
        if <_X>slurm_bit_free(_X):
            _X = NULL


cdef node_info_msg_t *job_node_ptr = NULL


cdef class Job:
    """An object to wrap `job_info_t` structs."""
    cdef:
        readonly unicode account
        readonly time_t accrue_time
        readonly unicode accrue_time_str
        readonly unicode admin_comment
        readonly unicode alloc_node
        readonly uint32_t alloc_sid
        readonly uint32_t array_job_id
        readonly uint32_t array_task_id
        readonly unicode array_task_str
        readonly uint16_t batch_flag
        readonly unicode batch_host
        readonly unicode batch_features
        readonly unicode batch_script
        uint16_t boards_per_node
        readonly unicode burst_buffer
        readonly unicode burst_buffer_state
        readonly list cluster_features
        readonly unicode command
        readonly unicode comment
        readonly uint16_t contiguous
        uint16_t cores_per_socket
        uint16_t core_spec
        readonly unicode cpu_ids
        readonly uint16_t cpus_per_task
        readonly unicode cpus_per_tres
        readonly uint32_t delay_boot
        unicode delay_boot_str
        readonly time_t deadline
        readonly unicode deadline_str
        readonly unicode dependency
        uint32_t derived_exit_code
        readonly uint16_t derived_exit_code_exit_status
        readonly uint16_t derived_exit_code_term_sig
        readonly time_t eligible_time
        readonly unicode eligible_time_str
        readonly time_t end_time
        readonly unicode end_time_str
        readonly list exc_midplane_list
        readonly list exc_node_list
        uint32_t exit_code
        readonly uint16_t exit_code_exit_status
        readonly uint16_t exit_code_term_sig
        readonly list features
        readonly unicode fed_origin
        readonly unicode fed_active_siblings
        readonly unicode fed_viable_siblings
        readonly list gres
        readonly bool gres_enforce_bind
        readonly unicode gres_idx
        readonly uint32_t group_id
        readonly unicode ionodes
        readonly uint32_t job_id
        readonly unicode job_name
        readonly unicode job_state
        readonly bool kill_o_in_invalid_dependent
        readonly time_t last_sched_eval
        readonly unicode last_sched_eval_str
        readonly unicode licenses
        unicode mcs_label
        readonly uint64_t mem
        readonly bool mem_per_cpu
        readonly bool mem_per_node
        readonly unicode mem_per_tres
        readonly uint16_t min_cpus_node
        readonly unicode min_memory_cpu
        readonly unicode min_memory_node
        readonly unicode min_tmp_disk_node
        readonly unicode network
        readonly uint16_t nice
        readonly unicode node_list
        readonly unicode nodes
        readonly uint32_t pack_job_id
        readonly unicode pack_job_id_set
        readonly uint32_t pack_job_offset
        uint16_t ntasks_per_board
        uint16_t ntasks_per_core
        uint16_t ntasks_per_node
        uint16_t ntasks_per_socket
        readonly unicode num_cpus
        readonly unicode num_nodes
        readonly uint32_t num_tasks
        readonly uint16_t over_subscribe
        unicode over_subscribe_str
        readonly unicode partition
        readonly uint8_t power
        unicode power_str
        readonly time_t preempt_time
        unicode preempt_time_str
        readonly uint32_t priority
        readonly unicode qos
        readonly unicode reason
        readonly uint8_t reboot
        readonly list req_node_list
        readonly uint32_t req_switch
        readonly uint16_t requeue
        readonly time_t resize_time
        readonly unicode resize_time_str
        readonly uint16_t restarts
        readonly unicode reservation
        readonly time_t run_time
        readonly unicode run_time_str
        readonly unicode sched_node_list
        readonly int secs_pre_suspend
        readonly bool spread_job
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
        unicode suspend_time_str
        readonly unicode system_comment
        unicode switches
        uint16_t threads_per_core
        readonly double thread_spec
        readonly uint32_t time_limit
        unicode time_limit_str
        readonly uint32_t time_min
        unicode time_min_str
        readonly unicode tres
        readonly unicode tres_bind
        readonly unicode tres_freq
        readonly unicode tres_per_job
        readonly unicode tres_per_node
        readonly unicode tres_per_socket
        readonly unicode tres_per_task
        readonly uint32_t user_id
        readonly uint32_t wait4switch
        readonly unicode work_dir
        readonly unicode wckey

    @property
    def boards_per_node(self):
        """Boards per node, required by job"""
        if self.boards_per_node == NO_VAL16:
            return None
        else:
            return self.boards_per_node

    @property
    def core_spec(self):
        """Specialized core count"""
        if self.core_spec == NO_VAL16:
            return None
        elif (self.core_spec & CORE_SPEC_THREAD):
            self.thread_spec = self.core_spec & (~CORE_SPEC_THREAD)
        else:
            return self.core_spec

    @property
    def cores_per_socket(self):
        """Cores per socket, required by job"""
        if self.cores_per_socket == NO_VAL16:
            return None
        else:
            return self.cores_per_socket

    @property
    def delay_boot_str(self):
        """Delay boot for desired node state"""
        cdef char tmp1[128]
        slurm_secs2time_str(<time_t>self.delay_boot, tmp1, sizeof(tmp1))
        return tounicode(tmp1)

    @property
    def derived_exit_code(self):
        """Highest exit code of all job steps."""
        cdef:
            uint16_t exit_status = 0
            uint16_t term_sig = 0

        if WIFSIGNALED(self.derived_exit_code):
            term_sig = WTERMSIG(self.derived_exit_code)
        elif WIFEXITED(self.derived_exit_code):
            exit_status = WEXITSTATUS(self.derived_exit_code)

        self.derived_exit_code_exit_status = exit_status
        self.derived_exit_code_term_sig = term_sig

        return "%s:%s" % (exit_status, term_sig)

    @property
    def exit_code(self):
        """Exit code for job (status from wait call)."""
        cdef:
            uint16_t exit_status = 0
            uint16_t term_sig = 0

        if WIFSIGNALED(self.exit_code):
            term_sig = WTERMSIG(self.exit_code)
        elif WIFEXITED(self.exit_code):
            exit_status = WEXITSTATUS(self.exit_code)

        self.exit_code_exit_status = exit_status
        self.exit_code_term_sig = term_sig

        return "%s:%s" % (exit_status, term_sig)

    @property
    def mcs_label(self):
        """mcs_label if mcs plugin in use."""
        if self.mcs_label:
            return self.mcs_label
        else:
            return None

    @property
    def ntasks_per_board(self):
        """Number of tasks to invoke on each board"""
        if self.ntasks_per_board == NO_VAL16:
            return None
        else:
            return self.ntasks_per_board

    @property
    def ntasks_per_core(self):
        """Number of tasks to invoke on each core"""
        if (self.ntasks_per_core == NO_VAL16 or self.ntasks_per_core == INFINITE16):
            return None
        else:
            return self.ntasks_per_core

    @property
    def ntasks_per_node(self):
        """Number of tasks to invoke on each node"""
        if self.ntasks_per_node == NO_VAL16:
            return None
        else:
            return self.ntasks_per_node

    @property
    def ntasks_per_socket(self):
        """Number of tasks to invoke on each socket"""
        if (self.ntasks_per_socket == NO_VAL16 or self.ntasks_per_socket == INFINITE16):
            return None
        else:
            return self.ntasks_per_socket

    @property
    def over_subscribe_str(self):
        """1 if job can share nodes with other jobs"""
        return tounicode(slurm_job_share_string(self.over_subscribe))

    @property
    def power_str(self):
        """Power management flags"""
        if (self.power & SLURM_POWER_FLAGS_LEVEL):
            return tounicode("LEVEL")
        else:
            return None

    @property
    def preempt_time_str(self):
        """Preemption signal time"""
        cdef char time_str[32]
        if self.preempt_time == 0:
            return None
        else:
            slurm_make_time_str(<time_t *>&self.preempt_time, time_str, sizeof(time_str))
            return tounicode(time_str)

    @property
    def sockets_per_board(self):
        """Sockets per board, required by job"""
        if self.sockets_per_board == NO_VAL16:
            return None
        else:
            return self.sockets_per_board

    @property
    def socks_per_node(self):
        """Sockets per node, required by job"""
        if self.socks_per_node == NO_VAL16:
            return None
        else:
            return self.socks_per_node

    @property
    def suspend_time_str(self):
        """Time job last suspended or resumed"""
        cdef char time_str[32]
        if self.suspend_time:
            slurm_make_time_str(<time_t *>&self.suspend_time, time_str, sizeof(time_str))
            return tounicode(time_str)
        else:
            return None

    @property
    def switches(self):
        cdef char time_buf[32]
        slurm_secs2time_str(<time_t>self.wait4switch, time_buf, sizeof(time_buf))
        return str(self.req_switch) + "@" + tounicode(time_buf)

    @property
    def threads_per_core(self):
        """Threads per core, required by job"""
        if self.threads_per_core == NO_VAL16:
            return None
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
            return tounicode(time_str)

    @property
    def time_min_str(self):
        """Minimum run time in minutes or INFINITE."""
        cdef char time_str[32]
        if self.time_min == 0:
            return None
        else:
            slurm_mins2time_str(<time_t>self.time_min, time_str, sizeof(time_str))
            return tounicode(time_str)


cdef class Jobmsg:
    """An object to wrap job_desc_msg_t structs."""
    cdef:
        job_desc_msg_t job_mesg
        submit_response_msg_t *resp_mesg
        public list environment
        char *script
        public uint32_t user_id
        char *work_dir

    def __cinit__(self, *args, **kwargs):
        slurm_init_job_desc_msg(&self.job_mesg)

    def __dealloc__(self):
        if self.resp_mesg != NULL:
            slurm_free_submit_response_response_msg(self.resp_mesg)
            self.resp_mesg = NULL

    def submit_batch_job(self):
        cdef int rc

        rc = slurm_submit_batch_job(&self.job_mesg, &self.resp_mesg)

        if rc == SLURM_SUCCESS:
            this_jobid = self.resp_mesg.job_id
            slurm_free_submit_response_response_msg(self.resp_mesg)
            self.resp_mesg = NULL
            return this_jobid
        else:
            errno = slurm_get_errno()
            raise PySlurmError(slurm_strerror(errno), errno)

    @property
    def script(self):
        if self.script != NULL:
            return self.script

    @script.setter
    def script(self, value):
        self.script = value

    @property
    def work_dir(self):
        if self.work_dir != NULL:
            return self.work_dir

    @work_dir.setter
    def work_dir(self, value):
        self.work_dir = value


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
    if isinstance(jobid, int):
        jobid = str(jobid).encode("UTF-8")
    else:
        jobid = jobid.encode("UTF-8")

    jobid_xlate = slurm_xlate_job_id(jobid)
    return get_job_info_msg(jobid_xlate)


cdef get_job_info_msg(jobid, ids=False):
    cdef:
        job_info_msg_t *job_info_msg_ptr = NULL
        job_resources_t *job_resources
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        char time_str[32]
        char tmp_line[1024 * 128]
        char tmp1[128]
        char tmp2[128]
        char *host
        char *ionodes = NULL
        char *gres_last = ""
        int abs_node_inx
        int i
        int bit_inx
        int bit_reps
        int last
        int rc
        int rel_node_inx
        int sock_inx
        int sock_reps
        bitstr_t *cpu_bitmap
        time_t end_time
        time_t run_time
        uint64_t nice
        uint32_t cluster_flags = slurmdb_setup_cluster_flags()
        uint32_t max_nodes = 0
        uint32_t min_nodes = 0
        uint32_t threads
        uint64_t *last_mem_alloc_ptr = NULL
        uint64_t last_mem_alloc = NO_VAL64
        hostlist_t hl
        hostlist_t hl_last

    if jobid is None:
        rc = slurm_load_jobs(<time_t>NULL, &job_info_msg_ptr, show_flags)
    else:
        rc = slurm_load_job(&job_info_msg_ptr, jobid, show_flags)

    _load_node_info
    job_list = []
    if rc == SLURM_SUCCESS:
        for record in job_info_msg_ptr.job_array[:job_info_msg_ptr.record_count]:
            if ids and jobid is None:
                job_list.append(record.job_id)
                continue

            this_job = Job()

            # Line 1
            this_job.job_id = record.job_id

            if record.array_job_id:
                if record.array_task_str:
                    this_job.array_job_id = record.array_job_id
                    this_job.array_task_str = tounicode(record.array_task_str)
                else:
                    this_job.array_job_id = record.array_job_id
                    this_job.array_task_id = record.array_task_id
            elif record.pack_job_id:
                this_job.pack_job_id = record.pack_job_id
                this_job.pack_job_offset = record.pack_job_offset

            this_job.job_name = tounicode(record.name)

            # Line
            this_job.pack_job_id_set = tounicode(record.pack_job_id_set)

            # Line 2
            this_job.user_id = record.user_id
            this_job.group_id = record.group_id
            this_job.mcs_label = tounicode(record.mcs_label)

            # Line 3
            nice = <int64_t>record.nice - NICE_OFFSET
            this_job.nice = nice

            this_job.priority = record.priority
            this_job.account = tounicode(record.account)
            this_job.qos = tounicode(record.qos)

            if slurm_get_track_wckey():
                this_job.wckey = tounicode(record.wckey)

            # Line 4
            if record.job_state:
                this_job.job_state = tounicode(slurm_job_state_string(record.job_state))

            if record.state_desc:
                this_job.reason = tounicode(record.state_desc.replace(" ", "_"))
            else:
                if record.state_reason:
                    this_job.reason = tounicode(
                        slurm_job_reason_string(<job_state_reason>record.state_reason)
                    )

            this_job.dependency = tounicode(record.dependency)

            # Line 5
            this_job.requeue = record.requeue
            this_job.restarts = record.restart_cnt
            this_job.batch_flag = record.batch_flag
            this_job.reboot = record.reboot
            this_job.exit_code = record.exit_code

            # Line 5a
            this_job.derived_exit_code = record.derived_ec

            # Line 6
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
            this_job.run_time_str = tounicode(time_str)

            this_job.time_limit = record.time_limit
            this_job.time_min = record.time_min

            # Line 7
            this_job.submit_time = record.submit_time
            slurm_make_time_str(<time_t *>&record.submit_time, time_str, sizeof(time_str))
            this_job.submit_time_str = tounicode(time_str)

            this_job.eligible_time = record.eligible_time
            slurm_make_time_str(<time_t *>&record.eligible_time, time_str, sizeof(time_str))
            this_job.eligible_time_str = tounicode(time_str)

            # Line 7.5
            this_job.accrue_time = record.accrue_time
            slurm_make_time_str(<time_t *>&record.accrue_time, time_str, sizeof(time_str))
            this_job.accrue_time_str = tounicode(time_str)

            # Line 8
            if record.resize_time:
                this_job.resize_time = record.resize_time
                slurm_make_time_str(<time_t *>&record.resize_time, time_str,
                                    sizeof(time_str))
                this_job.resize_time_str = tounicode(time_str)

            # Line 9
            this_job.start_time = record.start_time
            slurm_make_time_str(<time_t *>&record.start_time, time_str, sizeof(time_str))
            this_job.start_time_str = tounicode(time_str)

            this_job.end_time = record.end_time
            if (record.time_limit == INFINITE) and (record.end_time > c_time(NULL)):
                this_job.end_time_str = tounicode("Unknown")
            else:
                slurm_make_time_str(<time_t *>&record.end_time, time_str, sizeof(time_str))
                this_job.end_time_str = tounicode(time_str)

            this_job.deadline = record.deadline
            if record.deadline:
                slurm_make_time_str(<time_t *>&record.deadline, time_str, sizeof(time_str))
                this_job.deadline_str = tounicode(time_str)

            # Line 10
            this_job.preempt_time = record.preempt_time
            this_job.suspend_time = record.suspend_time
            this_job.secs_pre_suspend = <int>record.pre_sus_time

            # Line
            this_job.last_sched_eval = record.last_sched_eval
            slurm_make_time_str(<time_t *>&record.last_sched_eval, time_str,
                                sizeof(time_str))
            this_job.last_sched_eval_str = tounicode(time_str)

            # Line 11
            this_job.partition = tounicode(record.partition)
            this_job.alloc_node = tounicode(record.alloc_node)
            this_job.alloc_sid = record.alloc_sid

            # Line 12
            if record.req_nodes:
                this_job.req_node_list = tounicode(record.req_nodes).split(",")
            if record.exc_nodes:
                this_job.exc_node_list = tounicode(record.exc_nodes).split(",")

            # Line 13
            this_job.node_list = tounicode(record.nodes)

            if record.nodes and ionodes:
                this_job.ionodes = tounicode(ionodes)

            if record.sched_nodes:
                this_job.sched_node_list = tounicode(record.sched_nodes).split(",")

            # Line 14
            this_job.batch_features = tounicode(record.batch_features)
            this_job.batch_host = tounicode(record.batch_host)

            # Line 14a
            if record.fed_siblings_active or record.fed_siblings_viable:
                this_job.fed_origin = tounicode(record.fed_origin_str)
                this_job.fed_viable_siblings = tounicode(record.fed_siblings_viable_str)
                this_job.fed_active_siblings = tounicode(record.fed_siblings_active_str)

            # Line 15
            if IS_JOB_PENDING(record):
                min_nodes = record.num_nodes
                max_nodes = record.max_nodes
                if max_nodes and (max_nodes < min_nodes):
                    min_nodes = max_nodes
            else:
                min_nodes = record.num_nodes
                max_nodes = 0

            this_job.num_nodes = _get_range(min_nodes, max_nodes)
            this_job.num_cpus = _get_range(record.num_cpus, record.max_cpus)
            this_job.num_tasks = record.num_tasks
            this_job.cpus_per_task = record.cpus_per_task

            this_job.boards_per_node = record.boards_per_node
            this_job.sockets_per_board = record.sockets_per_board
            this_job.cores_per_socket = record.cores_per_socket
            this_job.threads_per_core = record.threads_per_core

            # Line 16
            if record.tres_alloc_str:
                this_job.tres = tounicode(record.tres_alloc_str)
            else:
                this_job.tres = tounicode(record.tres_req_str)

            # Line 17
            this_job.socks_per_node = record.sockets_per_node
            this_job.ntasks_per_node = record.ntasks_per_node
            this_job.ntasks_per_board = record.ntasks_per_board
            this_job.ntasks_per_socket = record.ntasks_per_socket
            this_job.ntasks_per_core = record.ntasks_per_core
            this_job.core_spec = record.core_spec

            # TODO
            job_resources = record.job_resrcs

            if job_resources and job_resources.core_bitmap:
                last = slurm_bit_fls(job_resources.core_bitmap)
                if last != -1:
                    hl = slurm_hostlist_create(job_resources.nodes)

                    if hl is NULL:
                        slurm_perror(
                            "slurm_sprint_job_info: hostlist_create: %s".encode("UTF-8") %
                            job_resources.nodes
                        )
                        return None

                    hl_last = slurm_hostlist_create(NULL)

                    if hl_last is NULL:
                        slurm_perror("slurm_sprint_job_info: hostlist_create: NULL")
                        slurm_hostlist_destroy(hl)
                        return None

                    bit_inx = 0
                    i = 0
                    sock_inx = 0
                    sock_reps = 0
                    abs_node_inx = record.node_inx[1]

                    gres_last = ""
                    # tmp1[] stores the current cpu(s) allocated
                    #tmp2[0] = "\0".encode("UTF-8")

                    for rel_node_inx in range(job_resources.nhosts):
                        if sock_reps >= job_resources.sock_core_rep_count[sock_inx]:
                            sock_inx += 1
                            sock_reps = 0

                        sock_reps += 1

                        bit_reps = (job_resources.sockets_per_node[sock_inx] * 
                                    job_resources.cores_per_socket[sock_inx])

                        host = slurm_hostlist_shift(hl)
                        threads = _threads_per_core(host)
                        cpu_bitmap = slurm_bit_alloc(bit_reps * threads)

                        for j in range(bit_reps):
                            if slurm_bit_test(job_resources.core_bitmap, bit_inx):
                                for k in range(threads):
                                    slurm_bit_set(cpu_bitmap, (j * threads) + k)
                            bit_inx += 1

                        slurm_bit_fmt(tmp1, sizeof(tmp1), cpu_bitmap)
                        FREE_NULL_BITMAP(cpu_bitmap)
                        
                        if ((tmp1 == tmp2) or
                            (rel_node_inx < record.gres_detail_cnt) and
                            (record.gres_detail_str[rel_node_inx] == gres_last) or
                            (last_mem_alloc_ptr != job_resources.memory_allocated) or
                            (job_resources.memory_allocated and
                            (last_mem_alloc != job_resources.memory_allocated[rel_node_inx])
                            )):
                            if slurm_hostlist_count(hl_last):
                                last_hosts = slurm_hostlist_ranged_string_xmalloc(hl_last)
                                this_job.nodes = tounicode(last_hosts)
                                this_job.cpu_ids = tounicode(tmp2)

                                if last_mem_alloc_ptr:
                                    this_job.mem = last_mem_alloc
                                else:
                                    this_job.mem = 0

                                this_job.gres_idx = tounicode(gres_last)
                                xfree(last_hosts)
                                slurm_hostlist_destroy(hl_last)
                                hl_last = slurm_hostlist_create(NULL)

                            tmp2 = tmp1

                            if rel_node_inx < record.gres_detail_cnt:
                                gres_last = record.gres_detail_str[rel_node_inx]
                            else:
                                gres_last = ""

                            last_mem_alloc_ptr = job_resources.memory_allocated

                            if last_mem_alloc_ptr:
                                last_mem_alloc = (
                                    job_resources.memory_allocated[rel_node_inx]
                                )
                            else:
                                last_mem_alloc = NO_VAL64

                        slurm_hostlist_push_host(hl_last, host)
                        free(host)

                        if bit_inx > last:
                            break

                        if abs_node_inx > record.node_inx[i+1]:
                            i += 2
                            abs_node_inx = record.node_inx[i]
                        else:
                            abs_node_inx += 1

                    if slurm_hostlist_count(hl_last):
                        last_hosts = slurm_hostlist_ranged_string_xmalloc(hl_last)
                        this_job.nodes = tounicode(last_hosts)
                        this_job.cpu_ids = tounicode(tmp2)

                        if last_mem_alloc_ptr:
                            this_job.mem = last_mem_alloc
                        else:
                            this_job.mem = 0
                        this_job.gres_idx = tounicode(gres_last)

                        xfree(last_hosts)

                    slurm_hostlist_destroy(hl)
                    slurm_hostlist_destroy(hl_last)
            
            # Line 18
            this_job.min_cpus_node = record.pn_min_cpus

            slurm_convert_num_unit(
                <float>record.pn_min_memory,
                tmp1,
                sizeof(tmp1),
                UNIT_MEGA,
                NO_VAL,
                CONVERT_NUM_UNIT_EXACT
            )

            slurm_convert_num_unit(
                <float>record.pn_min_tmp_disk,
                tmp2,
                sizeof(tmp2),
                UNIT_MEGA,
                NO_VAL,
                CONVERT_NUM_UNIT_EXACT
            )

            if (record.pn_min_memory & MEM_PER_CPU):
                record.pn_min_memory &= (~MEM_PER_CPU)
                this_job.mem_per_cpu = True
                this_job.mem_per_node = False
                this_job.min_memory_cpu = tounicode(tmp1)
            else:
                this_job.mem_per_cpu = False
                this_job.mem_per_node = True
                this_job.min_memory_node = tounicode(tmp1)

            this_job.min_tmp_disk_node = tounicode(tmp2)

            # Line
            if record.cluster_features:
                this_job.cluster_features = tounicode(record.cluster_features).split(",")

            # Line 19
            if record.features:
                this_job.features = tounicode(record.features).split(",")

            this_job.delay_boot = record.delay_boot
            this_job.reservation = tounicode(record.resv_name)

            # Line 20
            this_job.over_subscribe = record.shared
            this_job.contiguous = record.contiguous
            this_job.licenses = tounicode(record.licenses)
            this_job.network = tounicode(record.network)

            # Line 21
            this_job.command = tounicode(record.command)

            # Line 22
            this_job.work_dir = tounicode(record.work_dir)

            # Line
            this_job.admin_comment = tounicode(record.admin_comment)

            # Line
            this_job.system_comment = tounicode(record.system_comment)

            # Line
            this_job.comment = tounicode(record.comment)

            # Lines 30-32
            if record.batch_flag:
                slurm_get_job_stderr(tmp_line, sizeof(tmp_line), &record)
                this_job.std_err = tounicode(tmp_line)

                slurm_get_job_stdin(tmp_line, sizeof(tmp_line), &record)
                this_job.std_in = tounicode(tmp_line)

                slurm_get_job_stdout(tmp_line, sizeof(tmp_line), &record)
                this_job.std_out = tounicode(tmp_line)

            # Line 34
            if record.req_switch:
                this_job.req_switch = record.req_switch
                this_job.wait4switch = record.wait4switch

            # Line 35
            this_job.burst_buffer = tounicode(record.burst_buffer)

            # Line
            this_job.burst_buffer_state = tounicode(record.burst_buffer_state)

            # TODO
            # Line 36: cpu_freq_debug

            # Line 37
            this_job.power = record.power_flags

            # Line 38
            if record.bitflags:
                if (record.bitflags & GRES_DISABLE_BIND):
                    this_job.gres_enforce_bind = False
                if (record.bitflags & GRES_ENFORCE_BIND):
                    this_job.gres_enforce_bind = True
                if (record.bitflags & KILL_INV_DEP):
                    this_job.kill_o_in_invalid_dependent = True
                if (record.bitflags & NO_KILL_INV_DEP):
                    this_job.kill_o_in_invalid_dependent = False
                if (record.bitflags & SPREAD_JOB):
                    this_job.spread_job = True

            # Line
            this_job.cpus_per_tres = tounicode(record.cpus_per_tres)

            # Line
            this_job.mem_per_tres = tounicode(record.mem_per_tres)

            # Line
            this_job.tres_bind = tounicode(record.tres_bind)

            # Line
            this_job.tres_freq = tounicode(record.tres_freq)

            # Line
            this_job.tres_per_job = tounicode(record.tres_per_job)

            # Line
            this_job.tres_per_node = tounicode(record.tres_per_node)

            # Line
            this_job.tres_per_socket = tounicode(record.tres_per_socket)

            # Line
            this_job.tres_per_task = tounicode(record.tres_per_task)

            job_list.append(this_job)

        slurm_free_job_info_msg(job_info_msg_ptr)
        job_info_msg_ptr = NULL
        _free_node_info()

        if jobid is None or len(job_list) > 1:
            return job_list
        else:
            return this_job
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


def get_user_jobs(user):
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

    if isinstance(user, str):
        try:
            user_id = getpwnam(user)[2]
        except KeyError:
            raise PySlurmError("user " + user + " not found")
    else:
        user_id = user

    rc = slurm_load_job_user(&job_info_msg_ptr, user_id, show_flags)

    if rc == SLURM_SUCCESS:
        pass
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


def pid2jobid(pid_t job_pid):
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


def kill_job(uint32_t jobid, uint16_t signal=SIGKILL, uint16_t flags=0):
    """
    Send the specified signal to all steps of an existing job.

    This function may only be successfully executed by the job's owner or user
    root. The following flags are available (see slurm.h for more info):

    * KILL_JOB_BATCH
    * KILL_JOB_ARRAY
    * KILL_STEPS_ONLY
    * KILL_FULL_JOB

    For a list of signal numbers, see `man 7 signal` or run `kill -l`.

    Args:
        jobid (int): slurm job id
        signal (int): signal number (Default: SIGKILL(15))
        flags (str): KILL_JOB_* flags (Default: 0)
    Returns:
        0 on success, otherwise return -1 and set errno to indicate error
    """
    cdef:
        int rc

    rc = slurm_kill_job(jobid, signal, flags)

    if rc == SLURM_SUCCESS:
        return rc
    else:
        errno = slurm_get_errno()
        raise PySlurmError(slurm_strerror(errno), errno)


def notify_job(uint32_t jobid, message):
    """
    Send message to the job's stdout.

    This function may only be successfully executed by the user root.

    Args:
        jobid (int): slurm job_id or 0 for all jobs
        message (str): arbitrary message
    Returns:
        0 on success, otherwise return -1
    """
    cdef:
        int rc

#    b_message = message.encode("UTF-8")
    rc = slurm_notify_job(jobid, message.encode("UTF-8", "replace"))

    if rc == SLURM_SUCCESS:
        return rc
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


def get_rem_time(uint32_t jobid, slurm_format=False):
    """
    Return remaining time for a given job in seconds.

    Args:
        jobid (int): slurm job id
        slurm_format (bool): time in seconds if False, slurm time formatted if
            True (Default: False)
    Returns:
        remaining time in seconds or -1 for error
    """
    cdef:
        int rem_time
        char time_buf[32]

    rem_time = slurm_get_rem_time(jobid)
    if rem_time != -1:
        if slurm_format:
            slurm_secs2time_str(<time_t>rem_time, time_buf, sizeof(time_buf))
            return time_buf
        else:
            return rem_time
    return rem_time


def get_end_time(uint32_t jobid, slurm_format=False):
    """
    Get the expected end time for a given slurm job

    Args:
        jobid (int): slurm job_id
        slurm_format (bool): time since epoch if False, slurm time formatted if
            True (Default: False)
    Returns:
        end time
    """
    cdef:
        int rc
        char time_str[32]
        time_t end_time

    rc = slurm_get_end_time(jobid, &end_time)

    if rc == SLURM_SUCCESS:
        if not slurm_format:
            return end_time
        else:
            slurm_make_time_str(<time_t *>&end_time,
                                time_str, sizeof(time_str))
            return time_str
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


#cdef int __job_cpus_allocated_on_node(job_resources_t *job_resrcs_ptr, node):
#    """
#    """
#    #return slurm_job_cpus_allocated_on_node(&job_resrcs_ptr, node)
#    pass


cdef _get_range(uint32_t lower, uint32_t upper):
    """
    """
    cdef:
        char tmp[128]
        char tmp2[128]
        uint32_t cluster_flags = slurmdb_setup_cluster_flags()

    if (cluster_flags & CLUSTER_FLAG_BG):
        slurm_convert_num_unit(<float>lower, tmp, sizeof(tmp), UNIT_NONE,
                               NO_VAL, CONVERT_NUM_UNIT_EXACT)
        if upper > 0:
            slurm_convert_num_unit(<float>upper, tmp2, sizeof(tmp2), UNIT_NONE,
                                   NO_VAL, CONVERT_NUM_UNIT_EXACT)
            return "%s-%s" % (tmp, tmp2)
        else:
            return "%s" % tmp
    else:
        if upper > 0:
            return "%s-%s" % (lower, upper)
        else:
            return "%s" % lower


def allocate_resources(dict job_descriptor):
    """
    Example:

        >>> a = {
        ...     "name": "job01",
        ...     "time_limit": 300,
        ...     "pn_min_memory": 100,
        ...     "num_tasks": 2,
        ...     "user_id": os.getuid(),
        ...     "group_id": os.getgid()
        ... }
        >>> pyslurm.job.allocate_resources(job_descriptor)
        1234567

    """
    cdef:
        job_desc_msg_t job_desc_msg
        resource_allocation_response_msg_t *slurm_alloc_msg_ptr
        int rc

    slurm_init_job_desc_msg(&job_desc_msg)
    try:
        job_desc_msg.name = job_descriptor["name"]
    except KeyError:
        job_desc_msg.name = NULL

    job_desc_msg.time_limit = job_descriptor["time_limit"]
    job_desc_msg.pn_min_memory = job_descriptor["pn_min_memory"]
    job_desc_msg.num_tasks = job_descriptor["num_tasks"]
    job_desc_msg.user_id = job_descriptor["user_id"]
    job_desc_msg.group_id = job_descriptor["group_id"]

    rc = slurm_allocate_resources(&job_desc_msg, &slurm_alloc_msg_ptr)

    if rc == SLURM_SUCCESS:
        this_jobid = slurm_alloc_msg_ptr.job_id
        slurm_free_resource_allocation_response_msg(slurm_alloc_msg_ptr)
        slurm_alloc_msg_ptr = NULL
        return this_jobid
    else:
        errno = slurm_get_errno()
        raise PySlurmError(slurm_strerror(errno), errno)


def allocate_resources_blocking(dict job_descriptor):
    """
    """
    cdef:
        job_desc_msg_t job_desc_msg
        resource_allocation_response_msg_t *slurm_alloc_msg_ptr

    slurm_init_job_desc_msg(&job_desc_msg)
    job_desc_msg.name = job_descriptor["name"]
    job_desc_msg.time_limit = job_descriptor["time_limit"]
    job_desc_msg.pn_min_memory = job_descriptor["pn_min_memory"]
    job_desc_msg.num_tasks = job_descriptor["num_tasks"]
    job_desc_msg.user_id = job_descriptor["user_id"]
    job_desc_msg.group_id = job_descriptor["group_id"]

    slurm_alloc_msg_ptr = slurm_allocate_resources_blocking(&job_desc_msg, 0, NULL)

    if slurm_alloc_msg_ptr:
        slurm_free_resource_allocation_response_msg(slurm_alloc_msg_ptr)
        slurm_alloc_msg_ptr = NULL
    else:
        raise PySlurmError("slurm_allocate_resources_blocking error")


def submit_batch_job(dict jobdict):
    """
    """
    cdef:
        job_desc_msg_t job_desc_msg
        submit_response_msg_t *slurm_alloc_msg_ptr
        int rc
#        char **env = NULL

    slurm_init_job_desc_msg(&job_desc_msg)

    if "account" in jobdict:
        job_desc_msg.account = jobdict["account"]

    if "acctg_freq" in jobdict:
        job_desc_msg.acctg_freq = jobdict["acctg_freq"]

    if "alloc_node" in jobdict:
        job_desc_msg.alloc_node = jobdict["alloc_node"]

    if "alloc_sid" in jobdict:
        job_desc_msg.alloc_sid = jobdict["alloc_sid"]

    if "begin_time" in jobdict:
        job_desc_msg.begin_time = jobdict["begin_time"]

    if "clusters" in jobdict:
        job_desc_msg.clusters = jobdict["clusters"]

    if "comment" in jobdict:
        job_desc_msg.comment = jobdict["comment"]

    if "contiguous" in jobdict:
        job_desc_msg.contiguous = jobdict["contiguous"]

    if "cpu_freq_min" in jobdict:
        job_desc_msg.cpu_freq_min = jobdict["cpu_freq_min"]

    if "cpu_freq_max" in jobdict:
        job_desc_msg.cpu_freq_max = jobdict["cpu_freq_max"]

    if "cpu_freq_gov" in jobdict:
        job_desc_msg.cpu_freq_gov = jobdict["cpu_freq_gov"]

    if "deadline" in jobdict:
        job_desc_msg.deadline = jobdict["deadline"]

    if "dependency" in jobdict:
        job_desc_msg.dependency = jobdict["dependency"]

#    if "environment" in jobdict:
#        # "environment" must be of type list.
#        # "env_size" is the size of the list.
#        # "env" is a C string array.  The following converts "environment" to a
#        # cstring array, for example:
#        #    char *env[2]
#        #    job_desc_msg.env_size = 2 
#        #    env[0] = "SLURM_ENV_0=looking_good" 
#        #    env[1] = "SLURM_ENV_1=still_good" 
#        #    job_desc_msg.environment = env
#        job_desc_msg.env_size = len(jobdict["environment"])
#        env = <char **>malloc(len(jobdict["environment"]) * sizeof(char *))
#        for index, item in enumerate(jobdict["environment"]):
#            env[index] = PyString_AsString(item)
#        job_desc_msg.environment = env

    if "features" in jobdict:
        job_desc_msg.features = jobdict["features"]

    if "group_id" in jobdict:
        job_desc_msg.group_id = jobdict["group_id"]

    if "immediate" in jobdict:
        job_desc_msg.immediate = jobdict["immediate"]

    if "kill_on_node_fail" in jobdict:
        job_desc_msg.kill_on_node_fail = jobdict["kill_on_node_fail"]

    if "licenses" in jobdict:
        job_desc_msg.licenses = jobdict["licenses"]

    if "mail_type" in jobdict:
        job_desc_msg.mail_type = jobdict["mail_type"]

    if "mail_user" in jobdict:
        job_desc_msg.mail_user = jobdict["mail_user"]

    if "name" in jobdict:
        job_desc_msg.name = jobdict["name"]

    if "num_tasks" in jobdict:
        job_desc_msg.num_tasks = jobdict["num_tasks"]

    if "open_mode" in jobdict:
        job_desc_msg.open_mode = jobdict["open_mode"]

    if "overcommit" in jobdict:
        job_desc_msg.overcommit = jobdict["overcommit"]

    if "partition" in jobdict:
        job_desc_msg.partition = jobdict["partition"]

    if "plane_size" in jobdict:
        job_desc_msg.plane_size = jobdict["plane_size"]

    if "power_flags" in jobdict:
        job_desc_msg.power_flags = jobdict["power_flags"]

    if "priority" in jobdict:
        job_desc_msg.priority = jobdict["priority"]

    if "qos" in jobdict:
        job_desc_msg.qos = jobdict["qos"]

    if "reboot" in jobdict:
        job_desc_msg.reboot = jobdict["reboot"]

    if "req_nodes" in jobdict:
        job_desc_msg.req_nodes = jobdict["req_nodes"]

    if "requeue" in jobdict:
        job_desc_msg.requeue = jobdict["requeue"]

    if "reservation" in jobdict:
        job_desc_msg.reservation = jobdict["reservation"]

    if "script" in jobdict:
        job_desc_msg.script = jobdict["script"]

    if "shared" in jobdict:
        job_desc_msg.shared = jobdict["shared"]

    if "time_limit" in jobdict:
        job_desc_msg.time_limit = jobdict["time_limit"]

    if "time_min" in jobdict:
        job_desc_msg.time_min = jobdict["time_min"]

    if "user_id" in jobdict:
        job_desc_msg.user_id = jobdict["user_id"]

    if "wait_all_nodes" in jobdict:
        job_desc_msg.wait_all_nodes = jobdict["wait_all_nodes"]

    if "work_dir" in jobdict:
        job_desc_msg.work_dir = jobdict["work_dir"]

    # job constraints
    if "cpus_per_task" in jobdict:
        job_desc_msg.cpus_per_task = jobdict["cpus_per_task"]

    if "min_cpus" in jobdict:
        job_desc_msg.min_cpus = jobdict["min_cpus"]

    if "max_cpus" in jobdict:
        job_desc_msg.max_cpus = jobdict["max_cpus"]

    if "min_nodes" in jobdict:
        job_desc_msg.min_nodes = jobdict["min_nodes"]

    if "max_nodes" in jobdict:
        job_desc_msg.max_nodes = jobdict["max_nodes"]

    if "boards_per_node" in jobdict:
        job_desc_msg.boards_per_node = jobdict["boards_per_node"]

    if "sockets_per_board" in jobdict:
        job_desc_msg.sockets_per_board = jobdict["sockets_per_board"]

    if "sockets_per_node" in jobdict:
        job_desc_msg.sockets_per_node = jobdict["sockets_per_node"]

    if "cores_per_socket" in jobdict:
        job_desc_msg.cores_per_socket = jobdict["cores_per_socket"]

    if "threads_per_core" in jobdict:
        job_desc_msg.threads_per_core = jobdict["threads_per_core"]

    if "ntasks_per_node" in jobdict:
        job_desc_msg.ntasks_per_node = jobdict["ntasks_per_node"]

    if "ntasks_per_socket" in jobdict:
        job_desc_msg.ntasks_per_socket = jobdict["ntasks_per_socket"]

    if "ntasks_per_core" in jobdict:
        job_desc_msg.ntasks_per_core = jobdict["ntasks_per_core"]

    if "ntasks_per_board" in jobdict:
        job_desc_msg.ntasks_per_board = jobdict["ntasks_per_board"]

    if "pn_min_cpus" in jobdict:
        job_desc_msg.pn_min_cpus = jobdict["pn_min_cpus"]

    if "pn_min_memory" in jobdict:
        job_desc_msg.pn_min_memory = jobdict["pn_min_memory"]

    if "pn_min_tmp_disk" in jobdict:
        job_desc_msg.pn_min_tmp_disk = jobdict["pn_min_tmp_disk"]

    if "req_switch" in jobdict:
        job_desc_msg.req_switch = jobdict["req_switch"]

    if "std_err" in jobdict:
        job_desc_msg.std_err = jobdict["std_err"]

    if "std_in" in jobdict:
        job_desc_msg.std_in = jobdict["std_in"]

    if "std_out" in jobdict:
        job_desc_msg.std_out = jobdict["std_out"]

    if "wait4switch" in jobdict:
        job_desc_msg.wait4switch = jobdict["wait4switch"]

    if "wckey" in jobdict:
        job_desc_msg.wckey = jobdict["wckey"]

    rc = slurm_submit_batch_job(&job_desc_msg, &slurm_alloc_msg_ptr)

#    if env != NULL:
#        free(env)

    if rc == SLURM_SUCCESS:
        this_jobid = slurm_alloc_msg_ptr.job_id
        slurm_free_submit_response_response_msg(slurm_alloc_msg_ptr)
        slurm_alloc_msg_ptr = NULL
        return this_jobid
    else:
        errno = slurm_get_errno()
        raise PySlurmError(slurm_strerror(errno), errno)


def update_job(dict update):
    """
    Issue RPC to update a job's configuration.

    Only usable by user root or (for some parameters) the job's owner.
    """
    cdef:
        job_desc_msg_t update_job_msg
        int rc

    slurm_init_job_desc_msg(&update_job_msg)

    update_job_msg.job_id = update["job_id"]
    update_job_msg.time_limit = update["time_limit"]
    update_job_msg.partition = update["partition"]

    rc = slurm_update_job(&update_job_msg)

    if rc == SLURM_SUCCESS:
        return rc
    else:
        errno = slurm_get_errno()
        raise PySlurmError(slurm_strerror(errno), errno)


def print_job_batch_script(jobid):
    """
    Retrieve the batch script for a given jobid

    Args:
        msg (jobid): jobid
    Returns:
        SLURM_SUCCESS, or appropriate error code
    """
    cdef:
        FILE *out
        int rc

    rc = slurm_job_batch_script(stdout, jobid)

    if rc == SLURM_SUCCESS:
        return
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


cdef void _load_node_info():
    global job_node_ptr
    if job_node_ptr is NULL:
        slurm_load_node(<time_t> NULL, &job_node_ptr, 0)
        

cdef _free_node_info():
    global job_node_ptr
    if job_node_ptr:
        slurm_free_node_info_msg(job_node_ptr)
        job_node_ptr = NULL


cdef _threads_per_core(char *host):
    cdef:
        uint32_t i
        uint32_t threads = 1

    global job_node_ptr

    if job_node_ptr is NULL or host is NULL:
        return threads

    for i in range(job_node_ptr.record_count):
        if job_node_ptr.node_array[i].name and host != job_node_ptr.node_array[i].name:
            threads = job_node_ptr.node_array[i].threads
            break

    return threads
