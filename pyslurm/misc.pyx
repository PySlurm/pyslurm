# cython: c_string_type=unicode, c_string_encoding=utf8
# cython: cdivision=True

from __future__ import print_function, division, unicode_literals

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



# Error Handling error codes and functions for slurm
# slurm_get_errno
# slurm_seterrno
# slurm_perror
# slurm_strerr


# slurm_load_slurmd_status

# SLURM PING/RECONFIGURE/SHUTDOWN FUNCTIONS
# slurm_ping
# slurm_reconfigure
# slurm_shutdown
# slurm_takeover
# slurm_set_debugflags
# slurm_set_debug_level
# slurm_set_schedlog_level
