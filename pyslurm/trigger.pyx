# cython: embedsignature=True
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

import time

from libc.stdio cimport stdout
from libc.errno cimport EAGAIN

from .c_trigger cimport *
from .slurm_common cimport *
from .utils cimport *
from .exceptions import PySlurmError

cdef class Trigger:
    """An object to wrap `trigger_info_t` structs."""
    cdef:
        readonly uint16_t flags
        readonly unicode flags_str
        readonly uint16_t offset
        readonly unicode program
        readonly unicode res_id
        readonly uint16_t res_type
        readonly unicode res_type_str
        readonly uint32_t trig_id
        readonly uint32_t trig_type
        readonly unicode trig_type_str
        readonly uint32_t user_id


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
        trigger_info_msg_t *trigger_msg_ptr
        int rc
        uint16_t offset

    rc = slurm_get_triggers(&trigger_msg_ptr)

    trigger_list = []
    if rc == SLURM_SUCCESS:
        for record in trigger_msg_ptr.trigger_array[:trigger_msg_ptr.record_count]:
            if ids and trigger is None:
                trigger_list.append(record.trig_id)
                continue

            this_trigger = Trigger()

            this_trigger.trig_id = record.trig_id
            this_trigger.res_type = record.res_type
            this_trigger.res_type_str = trigger_res_type(record.res_type)
            this_trigger.res_id = tounicode(record.res_id)
            this_trigger.trig_type = record.trig_type
            this_trigger.trig_type_str = trigger_type(record.trig_type)
            this_trigger.offset = record.offset - 0x8000
            this_trigger.user_id = record.user_id
            this_trigger.flags = record.flags

            if record.flags & TRIGGER_FLAG_PERM:
                this_trigger.flags_str = "PERM"

            this_trigger.program = tounicode(record.program)

            trigger_list.append(this_trigger)

        slurm_free_trigger_msg(trigger_msg_ptr)
        trigger_msg_ptr = NULL

        if trigger and trigger_list:
            return trigger_list[0]
        else:
            return trigger_list
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


def clear_trigger(trigger_id=None, user_id=None, job_id=None):
    """
    """
    cdef:
        trigger_info_t ti
        int rc

    if not (trigger_id or user_id or job_id):
        raise PySlurmError("""
        The `trigger_id`, `user_id` or `job_id` options must be specified to
        identify the trigger(s) to be cleared.
        """)

    slurm_init_trigger_msg(&ti)

    if trigger_id is not None:
        ti.trig_id = trigger_id

    if user_id is not None:
        ti.user_id = user_id

    if job_id is not None:
        ti.res_type = TRIGGER_RES_TYPE_JOB
        b_job_id = str(job_id).encode("UTF-8")
        ti.res_id = b_job_id

    rc = slurm_clear_trigger(&ti)

    if rc == SLURM_SUCCESS:
        return rc
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


def set_trigger(dict trigger_dict):
    """
    """
    cdef:
        trigger_info_t ti
        int rc

    slurm_init_trigger_msg(&ti)

    if trigger_dict.get("job_id"):
        ti.res_type = TRIGGER_RES_TYPE_JOB
        b_job_id = str(trigger_dict.get("job_id")).encode("UTF-8")
        ti.res_id = b_job_id

        if trigger_dict.get("job_fini"):
            ti.trig_type |= TRIGGER_TYPE_FINI
        if trigger_dict.get("time_limit"):
            ti.trig_type |= TRIGGER_TYPE_TIME
    elif trigger_dict.get("front_end"):
        ti.res_type = TRIGGER_RES_TYPE_FRONT_END
    elif trigger_dict.get("burst_buffer"):
        ti.res_type = TRIGGER_RES_TYPE_OTHER
    else:
        ti.res_type = TRIGGER_RES_TYPE_NODE
        if trigger_dict.get("node_id"):
            b_node_id = trigger_dict.get("node_id").encode("UTF-8")
            ti.res_id = b_node_id
        else:
            ti.res_id = "*"

    if trigger_dict.get("burst_buffer"):
        ti.trig_type |= TRIGGER_TYPE_BURST_BUFFER;
    if trigger_dict.get("node_down"):
        ti.trig_type |= TRIGGER_TYPE_DOWN;
    if trigger_dict.get("node_drained"):
        ti.trig_type |= TRIGGER_TYPE_DRAINED;
    if trigger_dict.get("node_fail"):
        ti.trig_type |= TRIGGER_TYPE_FAIL;
    if trigger_dict.get("node_idle"):
        ti.trig_type |= TRIGGER_TYPE_IDLE;
    if trigger_dict.get("node_up"):
        ti.trig_type |= TRIGGER_TYPE_UP;
    if trigger_dict.get("reconfig"):
        ti.trig_type |= TRIGGER_TYPE_RECONFIG;
    if trigger_dict.get("pri_ctld_fail"):
        ti.trig_type |= TRIGGER_TYPE_PRI_CTLD_FAIL;
        ti.res_type = TRIGGER_RES_TYPE_SLURMCTLD;
    if trigger_dict.get("pri_ctld_res_op"):
        ti.trig_type |= TRIGGER_TYPE_PRI_CTLD_RES_OP;
        ti.res_type = TRIGGER_RES_TYPE_SLURMCTLD;
    if trigger_dict.get("pri_ctld_res_ctrl"):
        ti.trig_type |=  TRIGGER_TYPE_PRI_CTLD_RES_CTRL;
        ti.res_type = TRIGGER_RES_TYPE_SLURMCTLD;
    if trigger_dict.get("pri_ctld_acct_buffer_full"):
        ti.trig_type |= TRIGGER_TYPE_PRI_CTLD_ACCT_FULL;
        ti.res_type = TRIGGER_RES_TYPE_SLURMCTLD;
    if trigger_dict.get("bu_ctld_fail"):
        ti.trig_type |= TRIGGER_TYPE_BU_CTLD_FAIL;
        ti.res_type = TRIGGER_RES_TYPE_SLURMCTLD;
    if trigger_dict.get("bu_ctld_res_op"):
        ti.trig_type |= TRIGGER_TYPE_BU_CTLD_RES_OP;
        ti.res_type = TRIGGER_RES_TYPE_SLURMCTLD;
    if trigger_dict.get("bu_ctld_as_ctrl"):
        ti.trig_type |= TRIGGER_TYPE_BU_CTLD_AS_CTRL;
        ti.res_type = TRIGGER_RES_TYPE_SLURMCTLD;
    if trigger_dict.get("pri_dbd_fail"):
        ti.trig_type |= TRIGGER_TYPE_PRI_DBD_FAIL;
        ti.res_type = TRIGGER_RES_TYPE_SLURMDBD;
    if trigger_dict.get("pri_dbd_res_op"):
        ti.trig_type |= TRIGGER_TYPE_PRI_DBD_RES_OP;
        ti.res_type = TRIGGER_RES_TYPE_SLURMDBD;
    if trigger_dict.get("pri_dbd_fail"):
        ti.trig_type |= TRIGGER_TYPE_PRI_DB_FAIL;
        ti.res_type = TRIGGER_RES_TYPE_DATABASE;
    if trigger_dict.get("pri_db_res_op"):
        ti.trig_type |= TRIGGER_TYPE_PRI_DB_RES_OP;
        ti.res_type = TRIGGER_RES_TYPE_DATABASE;

    if trigger_dict.get("flags"):
        ti.flags = trigger_dict.get("flags")

    if trigger_dict.get("offset"):
        ti.offset = trigger_dict.get("offset") + 0x8000
    else:
        ti.offset = 0x8000

    b_program = trigger_dict.get("program").encode("UTF-8")
    ti.program = b_program

    while slurm_set_trigger(&ti):
        if slurm_get_errno() != EAGAIN:
            print(slurm_strerror(slurm_get_errno()), slurm_get_errno())
            return 1
        time.sleep(5)

    return 0


cdef trigger_res_type(uint16_t res_type):
    if res_type == TRIGGER_RES_TYPE_JOB:
        return "job"
    elif res_type == TRIGGER_RES_TYPE_NODE:
        return "node"
    elif res_type == TRIGGER_RES_TYPE_SLURMCTLD:
        return "slurmctld"
    elif res_type == TRIGGER_RES_TYPE_SLURMDBD:
        return "slurmdbd"
    elif res_type == TRIGGER_RES_TYPE_DATABASE:
        return "database"
    elif res_type == TRIGGER_RES_TYPE_FRONT_END:
        return "front_end"
    elif res_type == TRIGGER_RES_TYPE_OTHER:
        return "other"
    else:
        return "unknown"


cdef trigger_type(uint32_t trig_type):
    if trig_type == TRIGGER_TYPE_UP:
        return "up"
    elif trig_type == TRIGGER_TYPE_DOWN:
        return "down"
    elif trig_type == TRIGGER_TYPE_DRAINED:
        return "drained"
    elif trig_type == TRIGGER_TYPE_FAIL:
        return "fail"
    elif trig_type == TRIGGER_TYPE_IDLE:
        return "idle"
    elif trig_type == TRIGGER_TYPE_TIME:
        return "time"
    elif trig_type == TRIGGER_TYPE_FINI:
        return "fini"
    elif trig_type == TRIGGER_TYPE_RECONFIG:
        return "reconfig"
    elif trig_type == TRIGGER_TYPE_PRI_CTLD_FAIL:
        return "primary_slurmctld_failure"
    elif trig_type == TRIGGER_TYPE_PRI_CTLD_RES_OP:
        return "primary_slurmctld_resumed_operation"
    elif trig_type == TRIGGER_TYPE_PRI_CTLD_RES_CTRL:
        return "primary_slurmctld_resumed_control"
    elif trig_type == TRIGGER_TYPE_PRI_CTLD_ACCT_FULL:
        return "primary_slurmctld_acct_buffer_full"
    elif trig_type == TRIGGER_TYPE_BU_CTLD_FAIL:
        return "backup_slurmctld_failure"
    elif trig_type == TRIGGER_TYPE_BU_CTLD_RES_OP:
        return "backup_slurmctld_resumed_operation"
    elif trig_type == TRIGGER_TYPE_BU_CTLD_AS_CTRL:
        return "backup_slurmctld_assumed_control"
    elif trig_type == TRIGGER_TYPE_PRI_DBD_FAIL:
        return "primary_slurmdbd_failure"
    elif trig_type == TRIGGER_TYPE_PRI_DBD_RES_OP:
        return "primary_slurmdbd_resumed_operation"
    elif trig_type == TRIGGER_TYPE_PRI_DB_FAIL:
        return "primary_database_failure"
    elif trig_type == TRIGGER_TYPE_PRI_DB_RES_OP:
        return "primary_database_resumed_operation"
    elif trig_type == TRIGGER_TYPE_BURST_BUFFER:
        return "burst_buffer"
    else:
        return "unknown"
