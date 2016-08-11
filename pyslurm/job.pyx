# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
# cython: cdivision=True

from __future__ import print_function, division, unicode_literals

from posix.types cimport pid_t, time_t
from c_job cimport *
from slurm_common cimport *
from exceptions import PySlurmError
from pwd import getpwnam
from utils cimport *

cdef class Job:
    pass


cpdef list get_jobs_ids():
    """
    Return all job ids.

    This function calls slurm_load_jobs and returns a list of job ids for all
    jobs on the cluster.

    Args:
        None
    Returns:
        A list of all job ids.
    Raises:
        PySlurmError: if slurm_load_job is not successful.
    """
    cdef:
        job_info_msg_t *job_info_msg_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        uint32_t i
        int rc
        list all_jobs = []

    rc = slurm_load_jobs(<time_t>NULL, &job_info_msg_ptr, show_flags)

    if rc == SLURM_SUCCESS:
        for i in range(job_info_msg_ptr.record_count):
            all_jobs.append(job_info_msg_ptr.job_array[i].job_id)

        slurm_free_job_info_msg(job_info_msg_ptr)
        job_info_msg_ptr = NULL
        return all_jobs
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
