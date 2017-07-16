# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
"""
==============
:mod:`license`
==============

The license extension module is used to get Slurm license information.

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

- slurm_load_licenses
- slurm_free_license_info_msg

License Objects
---------------

Functions in this module wrap the ``license_info_t`` struct found in
`slurm.h`. The members of this struct are converted to a :class:`License` object,
which implements Python properties to retrieve the value of each attribute.

Each license record in a ``license_info_msg_t`` struct is converted to a
:class:`License` object when calling some of the functions in this module.

"""
from __future__ import absolute_import, division, unicode_literals

from posix.types cimport time_t

from .c_license cimport *
from .slurm_common cimport *
from .utils cimport *
from .exceptions import PySlurmError

cdef class License:
    """An object to wrap `license_info_t` structs."""
    cdef:
        readonly unicode license_name
        readonly uint32_t total
        readonly uint32_t used
        readonly uint32_t free
        uint8_t remote

    @property
    def remote(self):
        """Non-zero if remote license (not defined in slurm.conf)"""
        if self.remote:
            return "yes"
        else:
            return "no"


def get_licenses(ids=False):
    """
    Return a list of all licenses as :class:`License` objects.

    This function calls ``slurm_load_licenses`` to retrieve information for all
    licenses.

    Args:
        ids (Optional[bool]): Return list of only license names if True (default
            False).
    Returns:
        list: A list of :class:`License` objects, one for each license.
    Raises:
        PySlurmError: if ``slurm_load_licenses`` is unsuccessful.

    """
    return get_license_info_msg(None, ids)


def get_license(license):
    """
    Return a single :class:`License` object for the given license.

    This function calls ``slurm_load_licenses`` to retrieve information for the
    given license.

    Args:
        license (str): license to query
    Returns:
        Job: A single :class:`License` object
    Raises:
        PySlurmError: if ``slurm_load_licenses`` is unsuccessful.

    """
    return get_license_info_msg(license)


cdef get_license_info_msg(license, ids=False):
    cdef:
        license_info_msg_t *license_info_msg_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        int rc

    rc = slurm_load_licenses(<time_t>NULL, &license_info_msg_ptr, show_flags)

    license_list = []
    if rc == SLURM_PROTOCOL_SUCCESS:
        for record in license_info_msg_ptr.lic_array[:license_info_msg_ptr.num_lic]:
            if license:
                if license and (license != <unicode>record.name):
                    continue

            if ids and record.name and license is None:
                license_list.append(record.name)
                continue

            this_license = License()

            if record.name:
                this_license.license_name = tounicode(record.name)

            this_license.total = record.total
            this_license.used = record.in_use
            this_license.free = record.available
            this_license.remote = record.remote

            license_list.append(this_license)

        slurm_free_license_info_msg(license_info_msg_ptr)
        license_info_msg_ptr = NULL

        if license and license_list:
            return license_list[0]
        else:
            return license_list
    else:
        raise PySlurmError(slurm_strerror(rc), rc)
