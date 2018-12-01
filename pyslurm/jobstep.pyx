# cython: embedsignature=True
# cython: cdivision=True
"""
==============
:mod:`jobstep`
==============

The jobstep extension module is used to get Slurm jobstep information.

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

- slurm_get_job_steps
- slurm_free_job_step_info_response_msg
- slurm_kill_job_step

Jobstep Objects
---------------

Several functions in this module wrap the ``job_step_info_t`` struct found in
`slurm.h`. The members of this struct are converted to a :class:`Jobstep`
object, which implements Python properties to retrieve the value of each
attribute.

Each job record in a ``job_step_`` struct is converted to a
:class:`Job` object when calling some of the functions in this module.

"""
from __future__ import absolute_import, division, unicode_literals

from libc.errno cimport errno
from libc.signal cimport SIGKILL
from posix.types cimport time_t

from .c_hostlist cimport *
from .c_jobstep cimport *
from .c_job cimport *
from .slurm_common cimport *
from .utils cimport *
from .exceptions import PySlurmError
from .hostlist import Hostlist

DEF CONVERT_NUM_UNIT_EXACT = 0x00000001
DEF SLURM_PROTOCOL_VERSION = ((33 << 8) | 0)


cdef class Jobstep:
    """An object to wrap `jobstep_info_t` structs."""
    cdef:
        readonly uint32_t array_job_id
        readonly uint32_t array_task_id
        readonly uint16_t checkpoint
        readonly unicode checkpoint_dir
        readonly unicode cpu_freq_req
        readonly uint32_t cpus
        readonly unicode cpus_per_tres
        readonly unicode dist
        readonly uint32_t job_id
        readonly unicode mem_per_tres
        readonly unicode name
        readonly unicode network
        readonly unicode node_list
        readonly unicode nodes
        readonly unicode partition
        readonly unicode resv_ports
        readonly unicode srun_host
        readonly uint32_t srun_pid
        readonly time_t start_time
        readonly unicode start_time_str
        readonly unicode state
        readonly uint32_t tasks
        uint32_t time_limit
        readonly unicode time_limit_str
        readonly unicode tres
        readonly unicode tres_bind
        readonly unicode tres_freq
        readonly unicode tres_per_step
        readonly unicode tres_per_node
        readonly unicode tres_per_socket
        readonly unicode tres_per_task
        readonly uint32_t user_id
        uint32_t step_id

    @property
    def step_id(self):
        """Step ID"""
        if self.array_job_id:
            if self.step_id == INFINITE:
                return "%s_%s.TBD" % (self.array_job_id,
                                      self.array_task_id)
            else:
                return "%s_%s.%s" % (self.array_job_id,
                                     self.array_task_id,
                                     self.step_id)
        else:
            if self.step_id == INFINITE:
                return "%s.TBD" % (self.job_id)
            else:
                return "%s.%s" % (self.job_id, self.step_id)

    @property
    def time_limit(self):
        if self.time_limit == INFINITE:
            return "UNLIMITED"
        else:
            return self.time_limit


cdef class JobStepPids:
    """
    """
    cdef:
        readonly unicode node_name
        readonly list pidlist


cdef class JobStepLayout:
    """
    """
    cdef:
        readonly unicode front_end
        readonly uint16_t node_cnt
        readonly unicode node_list
        readonly uint16_t plane_size
        readonly uint16_t start_protocol_ver
        readonly list tasks
        readonly uint32_t task_cnt
        readonly uint32_t task_dist
        readonly unicode task_dist_str
        readonly dict tids


def get_jobsteps(ids=False):
    """
    Return a list of all jobs as :class:`Jobstep` objects.

    This function calls ``slurm_get_job_steps`` to retrieve information for all
    jobs.

    Args:
        ids (Optional[bool]): Return list of only job ids if True (default
            False).
    Returns:
        list: A list of :class:`Jobstep` objects, one for each job.
    Raises:
        PySlurmError: if ``slurm_get_job_steps`` is unsuccessful.

    """
    return get_jobstep_info_msg(None, None, ids)


def get_jobstep(jobid, stepid):
    """
    Return a single :class:`Jobstep` object for the given jobid.

    This function calls ``slurm_get_job_steps`` to retrieve information for the
    given jobid.

    Args:
        jobid (str): jobid to query
    Returns:
        Job: A single :class:`Jobstep` object
    Raises:
        PySlurmError: if ``slurm_get_job_steps`` is unsuccessful.

    """
    return get_jobstep_info_msg(jobid, stepid)


cdef get_jobstep_info_msg(jobid, stepid, ids=False):
    cdef:
        job_step_info_response_msg_t *job_step_info_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        char time_str[32]
        char tmp_node_cnt[40]
        char limit_str[32]
        char *io_nodes = NULL
        uint32_t cluster_flags = slurmdb_setup_cluster_flags()
        int rc

    if jobid is None and stepid is None:
        rc = slurm_get_job_steps(<time_t>NULL, NO_VAL, NO_VAL,
                                 &job_step_info_ptr, show_flags)
    elif jobid and stepid is None:
        rc = slurm_get_job_steps(<time_t>NULL, jobid, NO_VAL,
                                 &job_step_info_ptr, show_flags)
    else:
        rc = slurm_get_job_steps(<time_t>NULL, jobid, stepid,
                                 &job_step_info_ptr, show_flags)

    jobstep_list = []
    if rc == SLURM_SUCCESS:
        for record in job_step_info_ptr.job_steps[:job_step_info_ptr.job_step_count]:
            this_jobstep = Jobstep()

            # Line 1
            this_jobstep.start_time = record.start_time
            slurm_make_time_str(<time_t *>&record.start_time, time_str, sizeof(time_str))
            this_jobstep.start_time_str = tounicode(time_str)

            this_jobstep.time_limit = record.time_limit
            if record.time_limit == INFINITE:
                this_jobstep.time_limit_str = "UNLIMITED"
            else:
                slurm_secs2time_str(
                    <time_t>record.time_limit * 60, limit_str, sizeof(limit_str)
                )
                this_jobstep.time_limit_str = tounicode(limit_str)

            this_jobstep.array_job_id = record.array_job_id
            this_jobstep.array_task_id = record.array_task_id
            this_jobstep.step_id = record.step_id
            this_jobstep.job_id = record.job_id
            this_jobstep.user_id = record.user_id

            # Line 2
            this_jobstep.state = tounicode(slurm_job_state_string(record.state))
            this_jobstep.partition = tounicode(record.partition)
            this_jobstep.node_list = tounicode(record.nodes)

            # Line 3
            slurm_convert_num_unit(
                <float>_nodes_in_list(record.nodes),
                tmp_node_cnt, sizeof(tmp_node_cnt), UNIT_NONE, NO_VAL,
                CONVERT_NUM_UNIT_EXACT
            )
            this_jobstep.nodes = tounicode(tmp_node_cnt)
            this_jobstep.cpus = record.num_cpus
            this_jobstep.tasks = record.num_tasks
            this_jobstep.name = tounicode(record.name)
            this_jobstep.network = tounicode(record.network)

            # Line 4
            this_jobstep.tres = tounicode(record.tres_alloc_str)

            # Line 5
            this_jobstep.resv_ports = tounicode(record.resv_ports)
            this_jobstep.checkpoint = record.ckpt_interval
            this_jobstep.checkpoint_dir = tounicode(record.ckpt_dir)

            # Line 6:
            #TODO: CPUFreqReq

            this_jobstep.dist = tounicode(
                slurm_step_layout_type_name(<task_dist_states_t>record.task_dist)
            )

            # Line 7
            this_jobstep.srun_host = tounicode(record.srun_host)
            this_jobstep.srun_pid = record.srun_pid

            if record.cpus_per_tres:
                this_jobstep.cpus_per_tres = tounicode(record.cpus_per_tres)

            if record.mem_per_tres:
                this_jobstep.mem_per_tres = tounicode(record.mem_per_tres)

            if record.tres_bind:
                this_jobstep.tres_bind = tounicode(record.tres_bind)

            if record.tres_freq:
                this_jobstep.tres_freq = tounicode(record.tres_freq)

            if record.tres_per_step:
                this_jobstep.tres_per_step = tounicode(record.tres_per_step)

            if record.tres_per_node:
                this_jobstep.tres_per_node = tounicode(record.tres_per_node)

            if record.tres_per_socket:
                this_jobstep.tres_per_socket = tounicode(record.tres_per_socket)

            if record.tres_per_task:
                this_jobstep.tres_per_task = tounicode(record.tres_per_task)

            jobstep_list.append(this_jobstep)

        slurm_free_job_step_info_response_msg(job_step_info_ptr)
        job_step_info_ptr = NULL
        return jobstep_list
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


cdef class JobStepStat:
    """
    """
    cdef:
        readonly uint32_t num_tasks
        readonly uint32_t return_code
        readonly list step_pids


def get_step_stat(job_id, step_id):
    """
    """
    cdef:
        job_step_stat_response_msg_t *stat_resp_msg
        uint16_t protocol_version = SLURM_PROTOCOL_VERSION
        ListIterator itr
        int rc
        int i
        int j

    if not step_id:
        step_id = <uint32_t>NO_VAL

    rc = slurm_job_step_stat(job_id, step_id, NULL, protocol_version, &stat_resp_msg)

    if rc != SLURM_SUCCESS:
        raise PySlurmError(slurm_strerror(rc), rc)

    itr = slurm_list_iterator_create(stat_resp_msg.stats_list)

    stepstat_list = []

    for i in range(slurm_list_count(stat_resp_msg.stats_list)):
        step_stat_t = <job_step_stat_t *>slurm_list_next(itr)
        this_stat = JobStepStat()
        this_stat.num_tasks = step_stat_t.num_tasks
        this_stat.return_code = step_stat_t.return_code
        this_stat.step_pids = create_pidlist(step_stat_t.step_pids)
        stepstat_list.append(this_stat)

    slurm_list_iterator_destroy(itr)
    slurm_job_step_stat_response_msg_free(stat_resp_msg)
    return stepstat_list


def get_step_layout(job_id, step_id):
    """
    """
    cdef:
        slurm_step_layout_t *layout
        int i
        int j
        int k

    layout = slurm_job_step_layout_get(job_id, step_id)

    if layout == NULL:
        raise PySlurmError("Could not get job step info", errno)

    this_layout = JobStepLayout()
    this_layout.front_end = tounicode(layout.front_end)
    this_layout.node_cnt = layout.node_cnt
    this_layout.node_list = tounicode(layout.node_list)
    this_layout.plane_size = layout.plane_size
    this_layout.start_protocol_ver = layout.start_protocol_ver

    tasklist = []
    for i in range(layout.node_cnt):
        tasklist.append(layout.tasks[i])

    this_layout.tasks = tasklist
    this_layout.task_cnt = layout.task_cnt
    this_layout.task_dist = layout.task_dist
    this_layout.task_dist_str = tounicode(
        slurm_step_layout_type_name(<task_dist_states_t>layout.task_dist)
    )

    hl = Hostlist()
    hl.create(tounicode(layout.node_list))

    nodes = []
    for _ in range(hl.count()):
        nodes.append(hl.shift())

    hl.destroy()

    tids = {}
    for j in range(layout.node_cnt):
        for k in range(layout.tasks[j]):
            tids[nodes[j]] = layout.tids[j][k]

    this_layout.tids = tids

    slurm_job_step_layout_free(layout)
    return this_layout


def get_step_pids(job_id, step_id=None):
    """
    """
    cdef:
        job_step_pids_response_msg_t *pids_resp_msg
        ListIterator itr
        int rc
        int i
        int j

    if not step_id:
        step_id = <uint32_t>NO_VAL

    rc = slurm_job_step_get_pids(job_id, step_id, NULL, &pids_resp_msg)

    if rc != SLURM_SUCCESS:
        raise PySlurmError(slurm_strerror(rc), rc)

    itr = slurm_list_iterator_create(pids_resp_msg.pid_list)

    steppids_list = []

    for i in range(slurm_list_count(pids_resp_msg.pid_list)):
        step_pids_t = <job_step_pids_t *>slurm_list_next(itr)
        this_steppids = JobStepPids()
        this_steppids.node_name = tounicode(step_pids_t.node_name)
        this_steppids.pidlist = create_pidlist(step_pids_t)
        steppids_list.append(this_steppids)

    slurm_list_iterator_destroy(itr)
    slurm_job_step_pids_response_msg_free(pids_resp_msg)
    return steppids_list

cdef list create_pidlist(job_step_pids_t *step_pids):
    cdef:
        int i

    pidlist = []
    for i in range(step_pids.pid_cnt):
        pidlist.append(step_pids.pid[i])

    return pidlist


def kill_job_step(uint32_t jobid, uint32_t job_step_id, uint16_t signal=SIGKILL):
    """
    Send the specified signal to a job step.

    This function may only be successfully executed by the job's owner or user
    root.  For a list of signal numbers, see `man 7 signal` or run `kill -l`.

    Args:
        jobid (int): job id
        job_step_id (int): job step's id
        signal (int): signal number (Default: SIGKILL(15))
    Returns:
        0 on success, otherwise return -1 and set errno to indicate error
    """
    cdef:
        int rc
        int errno

    rc = slurm_kill_job_step(jobid, job_step_id, signal)

    if rc == SLURM_SUCCESS:
        return rc
    else:
        errno = slurm_get_errno()
        raise PySlurmError(slurm_strerror(errno), errno)


cdef _nodes_in_list(char *node_list):
    cdef:
        hostset_t host_set
        int count

    host_set = slurm_hostset_create(node_list)
    count = slurm_hostset_count(host_set)
    slurm_hostset_destroy(host_set)
    return count
