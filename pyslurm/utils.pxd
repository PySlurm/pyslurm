from __future__ import absolute_import

from libc.stdint cimport uint16_t, uint32_t, uint64_t
from posix.types cimport uid_t, gid_t
from .slurm_common cimport cpu_bind_type_t, List

cdef extern from * nogil:
    ctypedef char* const_char_ptr "const char*"

cdef extern from "slurm/slurm.h" nogil:
    enum:
        JOB_DEF_CPU_PER_GPU
        JOB_DEF_MEM_PER_GPU

    ctypedef enum cpu_bind_type_t:
        CPU_BIND_VERBOSE
        CPU_BIND_TO_THREADS
        CPU_BIND_TO_CORES
        CPU_BIND_TO_SOCKETS
        CPU_BIND_TO_LDOMS
        CPU_BIND_TO_BOARDS
        CPU_BIND_NONE
        CPU_BIND_RANK
        CPU_BIND_MAP
        CPU_BIND_MASK
        CPU_BIND_LDRANK
        CPU_BIND_LDMAP
        CPU_BIND_LDMASK
        CPU_BIND_ONE_THREAD_PER_CORE
        CPU_BIND_CPUSETS
        CPU_AUTO_BIND_TO_THREADS
        CPU_AUTO_BIND_TO_CORES
        CPU_AUTO_BIND_TO_SOCKETS
        CPU_BIND_OFF

cdef unicode tounicode(char* s)
cdef fuzzy_equal(v1, v2)
cdef job_defaults_str(List in_list)
cdef select_type_param_string(uint16_t select_type_param)
cdef slurm_sprint_cpu_bind_type(cpu_bind_type_t cpu_bind_type)
