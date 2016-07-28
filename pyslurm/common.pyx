# cython: embedsignature=True
# cython: cdivision=True
#
# common.pyx
#
from __future__ import print_function, division, unicode_literals

from libc.stdint cimport uint32_t

#
# Slurm functions not externalized
#

cdef secs2time_str(uint32_t time):
    """
    Convert seconds to Slurm string format.

    This method converts time in seconds (86400) to Slurm's string format
    (1-00:00:00).

    Args:
        time (int): time in seconds
    Returns:
        Slurm formatted time string
    """
    cdef:
        char *time_str
        long days, hours, minutes, seconds

    if time == INFINITE:
        time_str = "UNLIMITED"
    else:
        seconds = time % 60
        minutes = (time / 60) % 60
        hours = (time / 3600) % 24
        days = time / 86400

        if days < 0 or  hours < 0 or minutes < 0 or seconds < 0:
            time_str = "INVALID"
        elif days:
            return "%ld-%2.2ld:%2.2ld:%2.2ld" % (days, hours,
                                                 minutes, seconds)
        else:
            return "%2.2ld:%2.2ld:%2.2ld" % (hours, minutes, seconds)


cdef mins2time_str(uint32_t time):
    """
    Convert minutes to Slurm string format.

    This method converts time in minutes (14400) to Slurm's string format
    (10-00:00:00).

    Args:
        time (int): time in minutes
    Returns:
        Slurm formatted time string
    """
    cdef:
        long days, hours, minutes, seconds

    if time == INFINITE:
        return "UNLIMITED"
    else:
        seconds = 0
        minutes = time % 60
        hours = (time / 60) % 24
        days = time / 1440

        if days < 0 or  hours < 0 or minutes < 0 or seconds < 0:
            time_str = "INVALID"
        elif days:
            return "%ld-%2.2ld:%2.2ld:%2.2ld" % (days, hours,
                                                 minutes, seconds)
        else:
            return "%2.2ld:%2.2ld:%2.2ld" % (hours, minutes, seconds)
