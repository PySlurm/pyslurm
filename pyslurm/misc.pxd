from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libc.stdint cimport int32_t


cdef extern from "slurm/slurm.h" nogil:
    long SLURM_VERSION_NUMBER
    long SLURM_VERSION_MAJOR(long a)
    long SLURM_VERSION_MINOR(long a)
    long SLURM_VERSION_MICRO(long a)

