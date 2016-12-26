# slurmdb_common.pxd
#
# Slurm DB declarations common to all other DB extension files.
#
cdef extern from "slurm/slurmdb.h" nogil:
    ctypedef struct list:
        pass

    ctypedef list *List

    ctypedef struct listIterator:
        pass

    ctypedef listIterator *ListIterator
