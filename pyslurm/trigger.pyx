# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
"""
==============
:mod:`trigger`
==============

The trigger extension module is used to execute Slurm trigger functions.

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

- slurm_set_trigger
- slurm_clear_trigger
- slurm_get_triggers
- slurm_pull_trigger
- slurm_free_trigger_msg
- slurm_init_trigger_msg


Trigger Object
--------------

Functions in this module wrap the ``trigger_info_t`` struct found in `slurm.h`.
The members of this struct are converted to a :class:`Trigger` object, which
implements Python properties to retrieve the value of each attribute.

Each trigger record in a ``trigger_info_msg_t`` struct is converted to a
:class:`Trigger` object when calling some of the functions in this module.

"""
from __future__ import absolute_import, unicode_literals

from libc.stdio cimport stdout

from .c_trigger cimport *
from .slurm_common cimport *
from .utils cimport trigger_res_type, trigger_type
from .exceptions import PySlurmError

cdef class Trigger:
    """An object to wrap `trigger_info_t` structs."""
    cdef:
        readonly unicode res_id
        readonly unicode res_type
        readonly uint32_t trig_id
        readonly unicode trig_type


def get_triggers(ids=False):
    """
    Return a list of all triggers as :class:`Trigger` objects.  This function calls
    ``slurm_get_triggers`` to retrieve all triggers.

    Args:
        ids (Optional[bool]): Return list of only trigger ids if True
            (default: False).

    Returns:
        list: A list of :class:`Trigger` objects, one for each trigger.

    Raises:
        PySlurmError: if ``slurm_get_triggers`` is unsuccessful.

    """
    return get_triggers_msg(None, ids)


def get_trigger(trigger):
    """
    Return a single :class:`Trigger` object for the given trigger.  This
    function calls ``slurm_get_triggers`` to retrieve information for all
    triggers, but the response only includes the specified trigger.

    Args:
        trigger (str): trigger name to query

    Returns:
        Trigger: A single :class:`Trigger` object

    Raises:
        PySlurmError: if ``slurm_get_triggers`` is unsuccessful.
    """
    return get_triggers_msg(trigger)


cdef get_triggers_msg(trigger, ids=False):
    cdef:
        trigger_info_msg_t *trigger_msg_ptr = NULL
        int rc

    rc = slurm_get_triggers(&trigger_msg_ptr)

    trigger_list = []
    if rc == SLURM_SUCCESS:
        for record in trigger_msg_ptr.trigger_array[:trigger_msg_ptr.record_count]:
            if ids and trigger is None:
                trigger_list.append(record.trig_id)
                continue

            this_trigger = Trigger()

            this_trigger.trig_id = record.trig_id
            this_trigger.res_type = trigger_res_type(record.res_type)
            this_trigger.res_id = record.res_id
            this_trigger.trig_type = trigger_type(record.trig_type)

            trigger_list.append(this_trigger)

        slurm_free_trigger_msg(trigger_msg_ptr)
        trigger_msg_ptr = NULL

        if trigger and trigger_list:
            return trigger_list[0]
        else:
            return trigger_list
    else:
        raise PySlurmError(slurm_strerror(rc), rc)
