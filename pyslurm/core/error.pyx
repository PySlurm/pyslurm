#########################################################################
# error.pyx - pyslurm error utilities
#########################################################################
# Copyright (C) 2022 Toni Harzendorf <toni.harzendorf@gmail.com>
#
# This file is part of PySlurm
#
# PySlurm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# PySlurm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PySlurm; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# cython: c_string_type=unicode, c_string_encoding=default
# cython: language_level=3

from pyslurm.utils cimport cstr
from pyslurm cimport slurm
cimport libc.errno


def _check_modify_arguments(changes, **kwargs):
    if changes is None and not kwargs:
        raise ArgumentError("Nothing to change was provided")

    if changes is not None and kwargs:
        raise ArgumentError("Provide either a changes object or keyword arguments, not both")


def _get_modify_arguments_for(cls, changes, **kwargs):
    _check_modify_arguments(changes, **kwargs)
    return changes or cls(**kwargs)


def slurm_strerror(errno):
    """Convert a slurm errno to a string.

    Args:
        errno (int):
            The error number for which the string representation should be
            returned.

    Returns:
        (str): String representation of errno.
    """
    return cstr.to_unicode(slurm.slurm_strerror(errno))


def slurm_errno():
    """Get the current slurm errno.

    Returns:
        (int): Current slurm errno
    """
    return libc.errno.errno


def get_last_slurm_error():
    """Get the last slurm error that occurred as a tuple of errno and string.

    Returns:
        errno (int): The error number
        errno_str (str): The errno converted to a String
    """
    errno = slurm_errno()

    if errno == slurm.SLURM_SUCCESS:
        return (errno, 'Success')
    else:
        return (errno, slurm_strerror(errno))


class PyslurmError(Exception):
    """The base Exception for all Pyslurm errors."""


class ClientError(PyslurmError):
    pass


class ServerError(PyslurmError):
    pass


class RPCError(ServerError):
    """Exception for handling Slurm RPC errors.

    Args:
        errno (int):
            A slurm error number returned by RPC functions. Default is None,
            which will get the last slurm error automatically.
        msg (str):
            An optional, custom error description. If this is set, the errno
            will not be translated to its string representation.

    Examples:
        >>> import pyslurm
        ... try:
        ...     myjob = pyslurm.Job.load(9999)
        ... except pyslurm.RPCError as e:
        ...     print("Loading the Job failed")
    """
    def __init__(self, errno=slurm.SLURM_ERROR, msg=None):
        self.msg = msg
        self.errno = errno

        if not msg:
            if errno == slurm.SLURM_ERROR:
                self.errno, self.msg = get_last_slurm_error()
            else:
                self.msg = slurm_strerror(errno)

        super().__init__(self.msg)


class InvalidUsageError(ClientError):
    pass


class ArgumentError(InvalidUsageError):
    pass


class NotFoundError(RPCError):
    pass


def verify_rpc(errno, msg=None):
    """Verify a Slurm RPC

    Args:
        errno (int):
            A Slurm error value
        msg (str):
            An optional message
    """
    if errno != slurm.SLURM_SUCCESS:
        raise RPCError(errno, msg)
