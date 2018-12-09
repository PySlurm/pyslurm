# cython: embedsignature=True
"""
===========
:mod:`ping_reconfigure_shutdown`
===========

The ping_reconfigure_shutdown extension module is used to wrap Slurm ping,
reconfigure and shutdown functions.

"""
from __future__ import print_function, division, unicode_literals

from libc.stdint cimport uint16_t, uint32_t, uint64_t
from c_ping_reconfigure_shutdown cimport *
from slurm_common cimport *

#
# Error Handling
#

def get_errno():
    """
    Return the error code set by the last Slurm API function executed.

    Args:
        None
    Returns:
        Return code integer
    """
    return slurm_get_errno()


def seterrno(errnum):
    """
    Set a Slurm error number value

    Args:
        errnum (int): numerical error code
    Returns:
        None
    """
    slurm_seterrno(errnum)


def perror(msg):
    """
    Print Slurm error information to standard output

    Args:
        msg (str): error message string
    Returns:
        None
    """
    b_msg = msg.encode("UTF-8", "replace")
    slurm_perror(b_msg)


def strerror(errnum):
    """
    Return a text description of the given Slurm error code meaning.

    Args:
        errnum (int): numerical error code
    Returns:
        Text description of numerical error code
    """
    return slurm_strerror(errnum)


# SLURM PING/RECONFIGURE/SHUTDOWN FUNCTIONS
def ping(int dest):
    """
    Issue RPC to ping primary or secondary controller.

    Args:
        dest (int): controller to contact 0=primary, 1=backup, 2=backup2, etc.
    Returns:
        0 or a slurm error code
    """
    return slurm_ping(dest)


def reconfigure():
    """
    Issue RPC to have Slurm controller (slurmctld) reload its configuration file

    Args:
        None
    Returns:
        0 or a slurm error code
    """
    return slurm_reconfigure()


def shutdown(uint16_t options):
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


def takeover(int backup_inx):
    """
    Issue RPC to have Slurm backup controller (slurmctld) take over the primary.

    Args:
        backup_inx: Index of BackupController to assume controller (typically 1)
    Returns:
        0 or a slurm error code
    """
    return slurm_takeover(backup_inx)


def set_debugflags(uint64_t debug_flags_plus, uint64_t debug_flags_minus):
    """
    Issue RPC to set slurm controller debug flags.

    Args:
        debug_flags_plus (int): debug flags to be added
        debug_flags_minus (int): debug flags to be removed
    Returns:
        0 on success, otherwise return -1 and set errno to indicate the error
    """
    return slurm_set_debugflags(debug_flags_plus, debug_flags_minus)


def set_debug_level(debug_level):
    """
    Issue RPC to set slurm controller debug level

    Args:
        debug_level (int): requested debug level
    Returns:
        0 on success, otherwise return -1 and set errno to indicate the error
    """
    return slurm_set_debug_level(debug_level)


def set_schedlog_level(uint32_t schedlog_level):
    """
    Issue RPC to set slurm scheduler log level

    Args:
        schedlog_level (int): requested scheduler log level
    Returns:
        0 on success, otherwise return -1 and set errno to indicate the error
    """
    return slurm_set_schedlog_level(schedlog_level)

def set_fs_dampeningfactor(uint16_t factor):
    """
    Issue RPC to set slurm scheduler log level

    Args:
        factor (int): requested fs dampening factor
    Returns:
        0 on success, otherwise return -1 and set errno to indicate the error
    """
    return slurm_set_fs_dampeningfactor(factor)
