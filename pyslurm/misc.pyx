# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8

from __future__ import print_function, division, unicode_literals

from common cimport *
from utils cimport *
from exceptions import PySlurmError

#
# Error Handling
#

cpdef int get_errno():
    """
    Return the error code set by the last Slurm API function executed.

    Args:
        None
    Returns:
        Return code integer
    """
    return slurm_get_errno()


cpdef void seterrno(int errnum):
    """
    Set a Slurm error number value

    Args:
        errnum (int): numerical error code
    Returns:
        None
    """
    slurm_seterrno(errnum)


cpdef void perror(char *msg):
    """
    Print Slurm error information to standard output

    Args:
        msg (str): error message string
    Returns:
        None
    """
    slurm_perror(msg)


cpdef strerror(int errnum):
    """
    Return a text description of the given Slurm error code meaning.

    Args:
        errnum (int): numerical error code
    Returns:
        Text description of numerical error code
    """
    return slurm_strerror(errnum)


# slurm_load_slurmd_status

# SLURM PING/RECONFIGURE/SHUTDOWN FUNCTIONS
cpdef int ping(int controller):
    """
    Issue RPC to ping primary or secondary controller.

    Args:
        controller (int):
            1 - ping the primary controller
            2 - ping the secondary controller
    Returns:
        Slurm error return code
    """
    return slurm_ping(controller)


cpdef int reconfigure():
    """
    Request that the Slurm controller re-read its configuration file.

    This method required root privileges.

    Args:
        None
    Returns:
        0 or a slurm error code
    """
    return slurm_reconfigure()


cpdef int shutdown(uint16_t options):
    """
    Issue RPC to have Slurm controller (slurmctld) cease operations.

    This function will shutdown both primary and backup controller.
    This method required root privileges.

    Args:
        options (int):
            0 - all slurm daemons are shutdown
            1 - slurmctld generates a core file
            2 - only the slurmctld is shutdown (no core file)
    Returns:
        0 or a slurm error code
    """
    return slurm_shutdown(options)


cpdef int takeover():
    """
    Issue RPC to have Slurm backup controller (slurmctld) take over the primary.

    This method required root privileges.

    Args:
        None
    Returns:
        0 or a slurm error code
    """
    return slurm_takeover()


cpdef int set_debugflags(uint64_t debug_flags_plus,
                         uint64_t debug_flags_minus):
    """
    Issue RPC to set slurm controller debug flags.

    Args:
        debug_flags_plus (int): debug flags to be added
        debug_flags_minus (int): debug flags to be removed
    Returns:
        0 on success, otherwise return -1 and set errno to indicate the error
    """
    return slurm_set_debugflags(debug_flags_plus, debug_flags_minus)


cpdef int set_debug_level(uint32_t debug_level):
    """
    Issue RPC to set slurm controller debug level

    Args:
        debug_level (int): requested debug level
    Returns:
        0 on success, otherwise return -1 and set errno to indicate the error
    """
    return slurm_set_debug_level(debug_level)


cpdef int set_schedlog_level(uint32_t schedlog_level):
    """
    Issue RPC to set slurm scheduler log level

    Args:
        schedlog_level (int): requested scheduler log level
    Returns:
        0 on success, otherwise return -1 and set errno to indicate the error
    """
    return slurm_set_schedlog_level(schedlog_level)
