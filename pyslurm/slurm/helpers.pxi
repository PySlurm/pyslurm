cdef inline FREE_NULL_LIST(List _X):
    if _X:
        slurm_list_destroy(_X)

    _X = NULL


cdef inline listOrNone(char* value, sep_char):
    if value is NULL:
        return []

    if not sep_char:
        return value.decode("UTF-8", "replace")

    if sep_char == '':
        return value.decode("UTF-8", "replace")

    return value.decode("UTF_8", "replace").split(sep_char)


cdef inline stringOrNone(char* value, value2):
    if value is NULL:
        if value2 is '':
            return None
        return value2
    return value.decode("UTF-8", "replace")


cdef inline int16orNone(uint16_t value):
    if value is NO_VAL16:
        return None
    else:
        return value


cdef inline int32orNone(uint32_t value):
    if value is NO_VAL:
        return None
    else:
        return value


cdef inline int64orNone(uint64_t value):
    if value is NO_VAL64:
        return None
    else:
        return value


cdef inline int16orUnlimited(uint16_t value, return_type):
    if value is INFINITE16:
        if return_type is "int":
            return None
        else:
            return "UNLIMITED"
    else:
        if return_type is "int":
            return value
        else:
            return str(value)


cdef inline boolToString(int value):
    if value == 0:
        return 'False'
    return 'True'


#
# Job States
#

cdef inline IS_JOB_PENDING(slurm_job_info_t *_X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_PENDING

cdef inline IS_JOB_RUNNING(slurm_job_info_t *_X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_RUNNING

cdef inline IS_JOB_SUSPENDED(slurm_job_info_t *_X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_SUSPENDED

cdef inline IS_JOB_COMPLETE(slurm_job_info_t *_X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_COMPLETE

cdef inline IS_JOB_CANCELLED(slurm_job_info_t *_X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_CANCELLED

cdef inline IS_JOB_FAILED(slurm_job_info_t *_X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_FAILED

cdef inline IS_JOB_TIMEOUT(slurm_job_info_t *_X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_TIMEOUT

cdef inline IS_JOB_NODE_FAILED(slurm_job_info_t *_X):
    return (_X.job_state & JOB_STATE_BASE) == JOB_NODE_FAIL

cdef inline IS_JOB_COMPLETING(slurm_job_info_t *_X):
    return _X.job_state & JOB_COMPLETING

cdef inline IS_JOB_CONFIGURING(slurm_job_info_t *_X):
    return _X.job_state & JOB_CONFIGURING

cdef inline IS_JOB_STARTED(slurm_job_info_t *_X):
    return (_X.job_state & JOB_STATE_BASE) > JOB_PENDING

cdef inline IS_JOB_FINISHED(slurm_job_info_t *_X):
    return (_X.job_state & JOB_STATE_BASE) > JOB_SUSPENDED

cdef inline IS_JOB_COMPLETED(slurm_job_info_t *_X):
    return (IS_JOB_FINISHED(_X) and (_X.job_state & JOB_COMPLETING) == 0)

cdef inline IS_JOB_RESIZING(slurm_job_info_t *_X):
    return _X.job_state & JOB_RESIZING

cdef inline IS_JOB_REQUEUED(slurm_job_info_t *_X):
    return _X.job_state & JOB_REQUEUE

cdef inline IS_JOB_UPDATE_DB(slurm_job_info_t *_X):
    return _X.job_state & JOB_UPDATE_DB

#
# Node states
#

cdef inline IS_NODE_UNKNOWN(node_info_t *_X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_UNKNOWN

cdef inline IS_NODE_DOWN(node_info_t *_X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_DOWN

cdef inline IS_NODE_IDLE(node_info_t *_X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_IDLE

cdef inline IS_NODE_ALLOCATED(node_info_t *_X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_ALLOCATED

cdef inline IS_NODE_ERROR(node_info_t *_X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_ERROR

cdef inline IS_NODE_MIXED(node_info_t *_X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_MIXED

cdef inline IS_NODE_FUTURE(node_info_t *_X):
    return (_X.node_state & NODE_STATE_BASE) == NODE_STATE_FUTURE

cdef inline IS_NODE_CLOUD(node_info_t *_X):
    return _X.node_state & NODE_STATE_CLOUD

cdef inline IS_NODE_DRAIN(node_info_t *_X):
    return _X.node_state & NODE_STATE_DRAIN

cdef inline IS_NODE_DRAINING(node_info_t *_X):
    return ((_X.node_state & NODE_STATE_DRAIN) and
            (IS_NODE_ALLOCATED(_X) or IS_NODE_ERROR(_X) or IS_NODE_MIXED(_X)))

cdef inline IS_NODE_DRAINED(node_info_t *_X):
    return IS_NODE_DRAIN(_X) and not IS_NODE_DRAINING(_X)

cdef inline IS_NODE_COMPLETING(node_info_t *_X):
    return _X.node_state & NODE_STATE_COMPLETING

cdef inline IS_NODE_NO_RESPOND(node_info_t *_X):
    return _X.node_state & NODE_STATE_NO_RESPOND

cdef inline IS_NODE_FAIL(node_info_t *_X):
    return _X.node_state & NODE_STATE_FAIL

cdef inline IS_NODE_POWER_UP(node_info_t *_X):
    return _X.node_state & NODE_STATE_POWER_UP

cdef inline IS_NODE_MAINT(node_info_t *_X):
    return _X.node_state & NODE_STATE_MAINT
