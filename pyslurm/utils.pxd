from __future__ import absolute_import

from libc.stdint cimport uint16_t, uint32_t, uint64_t
from posix.types cimport uid_t, gid_t
from .slurm_common cimport cpu_bind_type_t, List

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


cdef unicode tounicode(char* s)
cdef cpu_freq_to_string(uint32_t cpu_freq)
cdef cpu_freq_govlist_to_string(uint32_t govs)
cdef debug_flags2str(uint64_t debug_flags)
cdef health_check_node_state_str(uint32_t node_state)
cdef job_defaults_str(List in_list)
cdef log_num2string(uint16_t inx)
cdef priority_flags_string(uint16_t priority_flags)
cdef prolog_flags2str(uint16_t prolog_flags)
cdef reconfig_flags2str(uint16_t reconfig_flags)
cdef reset_period_str(uint16_t reset_period)
cdef select_type_param_string(uint16_t select_type_params)
cdef slurm_sprint_cpu_bind_type(cpu_bind_type_t cpu_bind_type)
cdef trigger_res_type(uint16_t res_type)
cdef trigger_type(uint32_t trig_type)
cdef trig_offset(uint16_t offset)
cdef trig_flags(uint16_t flags)
