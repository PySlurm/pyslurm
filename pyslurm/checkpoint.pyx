# cython: embedsignature=True
"""
===========
:mod:`checkpoint`
===========

The checkpoint extension module is used to wrap Slurm job checkpoint functions.

"""
from __future__ import print_function, division, unicode_literals

from libc.stdint cimport uint16_t, uint32_t, uint64_t
from c_checkpoint cimport *
from slurm_common cimport *


def checkpoint_able(uint32_t job_id, uint32_t step_id, int starttime):
    """
    Determine if the specified job step can presently be checkpointed.

    Args:
        job_id (int): job on which to perform operation
        step_id (int): job step on which to perform operation
        starttime (int): time at which checkpoint request was issued (0 for now)
    Returns:
        Return 0 (can be checkpointed) or a slurm error code
    """
    cdef time_t start_time
    start_time = <time_t>starttime

    return slurm_checkpoint_able(job_id, step_id, &start_time)


def checkpoint_disable(uint32_t job_id, uint32_t step_id):
    """
    Disable checkpoint requests for some job step.

    Args:
        job_id (int): job on which to perform operation
        step_id (int): job step on which to perform operation
    Returns:
        Return 0 or a slurm error code
    """
    return slurm_checkpoint_disable(job_id, step_id)


def checkpoint_enable(uint32_t job_id, uint32_t step_id):
    """
    Enable checkpoint requests for some job step.

    Args:
        job_id (int): job on which to perform operation
        step_id (int): job step on which to perform operation
    Returns:
        Return 0 or a slurm error code
    """
    return slurm_checkpoint_enable(job_id, step_id)


def checkpoint_create(uint32_t job_id, uint32_t step_id, uint16_t max_wait, image_dir):
    """
    Initiate a checkpoint request for some job step.  The job will continue
    execution after the checkpoint operation completes.

    Args:
        job_id (int): job on which to perform operation
        step_id (int): job step on which to perform operation
        max_wait (int): maximum wait for operation to complete, in seconds
        image_dir (str): directory to store image files
    Returns:
        Return 0 or a slurm error code
    """
    b_image_dir = image_dir.encode("UTF-8", "replace")
    return slurm_checkpoint_create(job_id, step_id, max_wait, b_image_dir)


def checkpoint_requeue(uint32_t job_id, uint16_t max_wait, image_dir):
    """
    Initiate a checkpoint request for some job.  The job will be requeued after
    the checkpoint operation completes.

    Args:
        job_id (int): job on which to perform operation
        max_wait (int): maximum wait for operation to complete, in seconds
        image_dir (str): directory to store image files
    Returns:
        Return 0 or a slurm error code
    """
    b_image_dir = image_dir.encode("UTF-8", "replace")
    return slurm_checkpoint_requeue(job_id, max_wait, b_image_dir)


def checkpoint_vacate(uint32_t job_id, uint32_t step_id, uint16_t max_wait, image_dir):
    """
    Initiate a checkpoint request for some job step.  The job will terminate
    after the checkpoint operation completes.

    Args:
        job_id (int): job on which to perform operation
        step_id (int): job step on which to perform operation
        max_wait (int): maximum wait for operation to complete, in seconds
        image_dir (str): directory to store image files
    Returns:
        Return 0 or a slurm error code
    """
    b_image_dir = image_dir.encode("UTF-8", "replace")
    return slurm_checkpoint_vacate(job_id, step_id, max_wait, b_image_dir)


def checkpoint_restart(uint32_t job_id, uint32_t step_id, uint16_t stick, image_dir):
    """
    Restart execution of a checkpointed job step.

    Args:
        job_id (int): job on which to perform operation
        step_id (int): job step on which to perform operation
        stick (int): stick to nodes previously running on
        image_dir (str): directory to find checkpoint image files
    Returns:
        Return 0 or a slurm error code
    """
    b_image_dir = image_dir.encode("UTF-8", "replace")
    return slurm_checkpoint_restart(job_id, step_id, stick, b_image_dir)


def checkpoint_complete(uint32_t job_id,
    uint32_t step_id,
    int begin_time,
    uint32_t error_code,
    error_msg):
    """
    Note the completion of a job step's checkpoint operation.

    Args:
        job_id (int): job on which to perform operation
        step_id (int): job step on which to perform operation
        begin_time (int): time at which checkpoint began
        error_code (int): error code, highest value for all complete calls is preserved
        error_msg (str): error message, preserved for highest error_code
    Returns:
        Return 0 or a slurm error code
    """
    b_error_msg = error_msg.encode("UTF-8", "replace")
    return slurm_checkpoint_complete(
        job_id, step_id, <time_t>begin_time, error_code, b_error_msg
    )


def checkpoint_task_complete(uint32_t job_id,
    uint32_t step_id,
    uint32_t task_id,
    int begin_time,
    uint32_t error_code,
    error_msg):
    """
    Note the completion of a job step's checkpoint operation.

    Args:
        job_id (int): job on which to perform operation
        step_id (int): job step on which to perform operation
        task_id (int): task which completed the operation
        begin_time (int): time at which checkpoint began
        error_code (int): error code, highest value for all complete calls is preserved
        error_msg (str): error message, preserved for highest error_code
    Returns:
        Return 0 or a slurm error code
    """
    b_error_msg = error_msg.encode("UTF-8", "replace")
    return slurm_checkpoint_task_complete(
        job_id, step_id, task_id, <time_t>begin_time, error_code, b_error_msg
    )


def checkpoint_tasks(uint32_t job_id,
    uint16_t step_id,
    int begin_time,
    image_dir,
    uint16_t max_wait,
    nodelist):
    """
    Send checkpoint request to tasks of specified step.

    Args:
        job_id (int): job ID of step
        step_id (int): step ID of step
        begin_time (int): ?
        image_dir (str): location to store ckpt images, parameter to plugin
        max_wait (int): seconds to wait for the operation to complete
        nodelist (str): nodes to send the request
    Returns:
        Return 0 on success, non-zero on failure with errno set
    """
    b_image_dir = image_dir.encode("UTF-8", "replace")
    b_nodelist = nodelist.encode("UTF-8", "replace")
    return slurm_checkpoint_tasks(
        job_id, step_id, <time_t>begin_time, image_dir, max_wait, nodelist
    )
