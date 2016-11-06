# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
# cython: cdivision=True
"""
===========
:mod:`jobstep`
===========

The jobstep extension module is used to get Slurm jobstep information.

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

- slurm_get_job

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

from posix.types cimport time_t

from .c_jobstep cimport *
from .c_job cimport slurm_get_select_jobinfo, slurm_job_state_string
from .c_job cimport SELECT_JOBDATA_IONODES
from .slurm_common cimport *
from .exceptions import PySlurmError

cdef class Jobstep:
    """An object to wrap `jobstep_info_t` structs."""
    cdef:
        readonly uint32_t array_job_id
        readonly uint32_t array_task_id
        readonly uint16_t checkpoint
        readonly unicode checkpoint_dir
        readonly unicode cpu_freq_req
        readonly uint32_t cpus
        readonly unicode dist
        readonly uint32_t job_id
        readonly unicode gres
        readonly unicode midplane_list
        readonly unicode name
        readonly unicode network
        readonly unicode node_list
        readonly unicode nodes
        readonly unicode partition
        readonly unicode resv_ports
        readonly time_t start_time
        readonly unicode start_time_str
        readonly unicode state
        readonly uint32_t tasks
        uint32_t time_limit
        readonly unicode time_limit_str
        readonly unicode tres
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


def get_jobsteps(ids=False):
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
    return get_jobstep_info_msg(None, None, ids)


def get_jobstep(jobid, stepid):
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
    return get_jobstep_info_msg(jobid, stepid)


cdef get_jobstep_info_msg(jobid, stepid, ids=False):
    cdef:
        job_step_info_response_msg_t *job_step_info_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        char time_str[32]
        char limit_str[32]
        char *io_nodes = NULL
        uint32_t cluster_flags = slurmdb_setup_cluster_flags()
        int rc

    if jobid is None and stepid is None:
        rc = slurm_get_job_steps(<time_t>NULL, NO_VAL, NO_VAL,
                                 &job_step_info_ptr, show_flags)

    jobstep_list = []
    if rc == SLURM_SUCCESS:
        for record in job_step_info_ptr.job_steps[:job_step_info_ptr.job_step_count]:
            this_jobstep = Jobstep()

            this_jobstep.start_time = record.start_time
            slurm_make_time_str(<time_t *>&record.start_time,
                                time_str, sizeof(time_str))
            this_jobstep.start_time_str = time_str

            this_jobstep.user_id = record.user_id

            this_jobstep.time_limit = record.time_limit
            if record.time_limit == INFINITE:
                this_jobstep.time_limit_str = "UNLIMITED"
            else:
                slurm_secs2time_str(<time_t>record.time_limit * 60, limit_str, sizeof(limit_str))
                this_jobstep.time_limit_str = limit_str

            this_jobstep.array_job_id = record.array_job_id
            this_jobstep.array_task_id = record.array_task_id
            this_jobstep.step_id = record.step_id
            this_jobstep.job_id = record.job_id

            if record.state:
                this_jobstep.state = slurm_job_state_string(record.state)

            if (cluster_flags & CLUSTER_FLAG_BG):
                slurm_get_select_jobinfo(record.select_jobinfo,
                                         SELECT_JOBDATA_IONODES,
                                         &io_nodes)
                if io_nodes:
                    this_jobstep.midplane_list = (
                        record.nodes + "[" + io_nodes + "]"
                    )
                else:
                    this_jobstep.midplane_list = record.nodes

            else:
                this_jobstep.node_list = record.nodes

            if record.partition:
                this_jobstep.partition = record.partition

            if record.gres:
                this_jobstep.gres = record.gres

            if (cluster_flags & CLUSTER_FLAG_BGQ):
                # no access to convert_num_unit()
                pass
            else:
                # no access to convert_num_unit()
                #this_jobstep.nodes = 
                pass

            this_jobstep.cpus = record.num_cpus
            this_jobstep.tasks = record.num_tasks

            if record.name:
                this_jobstep.name = record.name

            if record.network:
                this_jobstep.network = record.network

            if record.tres_alloc_str:
                this_jobstep.tres = record.tres_alloc_str

            if record.resv_ports:
                this_jobstep.resv_ports = record.resv_ports

            this_jobstep.checkpoint = record.ckpt_interval

            if record.ckpt_dir:
                this_jobstep.checkpoint_dir = record.ckpt_dir

            # Line 6: cpu_freq_debug

            if record.task_dist:
                this_jobstep.dist = slurm_step_layout_type_name(
                    <task_dist_states_t>record.task_dist
                )

            jobstep_list.append(this_jobstep)

        slurm_free_job_step_info_response_msg(job_step_info_ptr)
        job_step_info_ptr = NULL
        return jobstep_list
    else:
        raise PySlurmError(slurm_strerror(rc), rc)
