# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8

from __future__ import division, unicode_literals

from common cimport *
from utils cimport *
from exceptions import PySlurmError

# Overall Slurm Information
cpdef api_version():
    """
    Return Slurm API version number.

    Args:
        None
    Returns:
        A tuple representing the API version number (MAJOR, MINOR, MICRO).
    """
    return (SLURM_VERSION_MAJOR(SLURM_VERSION_NUMBER),
            SLURM_VERSION_MINOR(SLURM_VERSION_NUMBER),
            SLURM_VERSION_MICRO(SLURM_VERSION_NUMBER))

cpdef print_ctl_conf():
    """
    Print Slurm error information to standard output

    Args:
        msg (str): error message string
    Returns:
        None
    """
    cdef:
        slurm_ctl_conf_t *slurm_ctl_conf_ptr = NULL
        int rc

    rc = slurm_load_ctl_conf(<time_t>NULL, &slurm_ctl_conf_ptr)

    if rc == SLURM_SUCCESS:
        slurm_print_ctl_conf(stdout, slurm_ctl_conf_ptr)
        slurm_free_ctl_conf(slurm_ctl_conf_ptr)
        slurm_ctl_conf_ptr = NULL
    else:
        raise PySlurmError(slurm_strerror(rc), rc)
