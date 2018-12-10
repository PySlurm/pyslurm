# slurmdb_common.pxd
#
# Slurmdb declarations common to all other extension files.
#
from ..slurm_common cimport List

cdef inline FREE_NULL_LIST(List _X):
    while (0):
        if <_X>slurm_list_destroy(_X):
            _X = NULL
