from common cimport *

cdef extern from "slurm/slurm.h" nogil:
    int slurm_ping(int primary)
    int slurm_reconfigure()
    int slurm_shutdown(uint16_t options)
    int slurm_takeover()
    int slurm_set_debugflags(uint64_t debug_flags_plus,
                             uint64_t debug_flags_minus)
    int slurm_set_debug_level(uint32_t debug_level)
    int slurm_set_schedlog_level(uint32_t schedlog_level)
