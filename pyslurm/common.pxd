from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libc.stdint cimport int32_t

cdef extern from "time.h" nogil:
    ctypedef long time_t


cdef extern from 'stdio.h' nogil:
    ctypedef struct FILE
    cdef FILE *stdout


cdef extern from "slurm/slurm.h" nogil:
    uint32_t INFINITE
    uint64_t INFINITE64
    uint32_t NO_VAL
    uint64_t NO_VAL64

    enum:
        SHOW_ALL
        SHOW_DETAIL
        SHOW_DETAIL2
        SHOW_MIXED

    ctypedef struct dynamic_plugin_data_t:
        void *data
        uint32_t plugin_id


cdef extern from "slurm/slurmdb.h" nogil:
    enum:
        CLUSTER_FLAG_BG


cdef extern from "slurm/slurm_errno.h" nogil:
    enum:
        SLURM_SUCCESS
        SLURM_ERROR
        SLURM_FAILURE

    char *slurm_strerror(int errnum)
    int slurm_get_errno()


#
# Declarations outside of slurm.h
#

cdef extern void slurm_make_time_str(time_t *time, char *string, int size)
