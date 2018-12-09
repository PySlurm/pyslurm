from libc.stdint cimport uint16_t, uint32_t, uint64_t

cdef extern from "slurm/slurm.h" nogil:
    ctypedef struct job_array_resp_msg_t:
        uint32_t job_array_count
        char **job_array_id
        uint32_t *error_code

    int slurm_ping(int dest)
    int slurm_reconfigure()
    int slurm_shutdown(uint16_t options)
    int slurm_takeover(int backup_inx)
    int slurm_set_debugflags(uint64_t debug_flags_plus, uint64_t debug_flags_minus)
    int slurm_set_debug_level(uint32_t debug_level)
    int slurm_set_schedlog_level(uint32_t schedlog_level)
    int slurm_set_fs_dampeningfactor(uint16_t factor)
    int slurm_suspend(uint32_t job_id)
    int slurm_suspend2(char *job_id, job_array_resp_msg_t **resp)
    int slurm_resume(uint32_t job_id)
    int slurm_resume2(char *job_id, job_array_resp_msg_t **resp)
    int slurm_requeue(uint32_t job_id, uint32_t state)
    int slurm_requeue2(char *job_id, uint32_t state, job_array_resp_msg_t **resp)
