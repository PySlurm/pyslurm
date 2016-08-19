# c_jobstep.pxd
#
from libc.stdint cimport uint16_t, uint32_t
from libc.stdint cimport int32_t
from libc.stdio cimport FILE
from posix.types cimport time_t
from .slurm_common cimport dynamic_plugin_data_t

cdef extern from "slurm/slurm.h" nogil:
    ctypedef struct job_step_info_t:
        uint32_t array_job_id
        uint32_t array_task_id
        char *ckpt_dir
        uint16_t ckpt_interval
        char *gres
        uint32_t job_id
        char *name
        char *network
        char *nodes
        int32_t *node_inx
        uint32_t num_cpus
        uint32_t cpu_freq_min
        uint32_t cpu_freq_max
        uint32_t cpu_freq_gov
        uint32_t num_tasks
        char *partition
        char *resv_ports
        time_t run_time
        dynamic_plugin_data_t *select_jobinfo
        time_t start_time
        uint32_t state
        uint32_t step_id
        uint32_t task_dist
        uint32_t time_limit
        char *tres_alloc_str
        uint32_t user_id

    ctypedef struct job_step_info_response_msg_t:
        time_t last_update
        uint32_t job_step_count
        job_step_info_t *job_steps

    ctypedef struct slurm_step_layout_t:
        char *front_end
        uint32_t node_cnt
        char *node_list
        uint16_t plane_size
        uint16_t *tasks
        uint32_t task_cnt
        uint32_t task_dist
        uint32_t **tids

    ctypedef struct list:
        pass

    ctypedef list *List

    ctypedef struct job_step_stat_response_msg_t:
        uint32_t job_id
        List stats_list
        uint32_t step_id

    ctypedef struct job_step_pids_response_msg_t:
        uint32_t job_id
        List pids_list
        uint32_t step_id

    ctypedef struct job_step_pids_t:
        char *node_name
        uint32_t *pid
        uint32_t pid_cnt

    ctypedef struct jobacctinfo:
        pass

    ctypedef jobacctinfo jobacctinfo_t

    ctypedef struct job_step_stat_t:
        jobacctinfo_t *jobacct
        uint32_t num_tasks
        uint32_t return_code
        job_step_pids_t *step_pids

    ctypedef struct step_update_request_msg_t:
        time_t end_time
        uint32_t exit_code
        uint32_t job_id
        jobacctinfo_t *jobacct
        char *name
        time_t start_time
        uint32_t step_id
        uint32_t time_limit

    ctypedef enum task_dist_states_t:
        SLURM_DIST_CYCLIC
        SLURM_DIST_BLOCK
        SLURM_DIST_ARBITRARY
        SLURM_DIST_PLANE
        SLURM_DIST_CYCLIC_CYCLIC
        SLURM_DIST_CYCLIC_BLOCK
        SLURM_DIST_CYCLIC_CFULL
        SLURM_DIST_BLOCK_CYCLIC
        SLURM_DIST_BLOCK_BLOCK
        SLURM_DIST_BLOCK_CFULL
        SLURM_DIST_CYCLIC_CYCLIC_CYCLIC
        SLURM_DIST_CYCLIC_CYCLIC_BLOCK
        SLURM_DIST_CYCLIC_CYCLIC_CFULL
        SLURM_DIST_CYCLIC_BLOCK_CYCLIC
        SLURM_DIST_CYCLIC_BLOCK_BLOCK
        SLURM_DIST_CYCLIC_BLOCK_CFULL
        SLURM_DIST_CYCLIC_CFULL_CYCLIC
        SLURM_DIST_CYCLIC_CFULL_BLOCK
        SLURM_DIST_CYCLIC_CFULL_CFULL
        SLURM_DIST_BLOCK_CYCLIC_CYCLIC
        SLURM_DIST_BLOCK_CYCLIC_BLOCK
        SLURM_DIST_BLOCK_CYCLIC_CFULL
        SLURM_DIST_BLOCK_BLOCK_CYCLIC
        SLURM_DIST_BLOCK_BLOCK_BLOCK
        SLURM_DIST_BLOCK_BLOCK_CFULL
        SLURM_DIST_BLOCK_CFULL_CYCLIC
        SLURM_DIST_BLOCK_CFULL_BLOCK
        SLURM_DIST_BLOCK_CFULL_CFULL
        SLURM_DIST_NODECYCLIC
        SLURM_DIST_NODEBLOCK
        SLURM_DIST_SOCKCYCLIC
        SLURM_DIST_SOCKBLOCK
        SLURM_DIST_SOCKCFULL
        SLURM_DIST_CORECYCLIC
        SLURM_DIST_COREBLOCK
        SLURM_DIST_CORECFULL
        SLURM_DIST_NO_LLLP
        SLURM_DIST_UNKNOWN


    int slurm_get_job_steps(time_t update_time, uint32_t job_id,
                            uint32_t step_id,
                            job_step_info_response_msg_t **step_response_pptr,
                            uint16_t show_flags)

    void slurm_free_job_step_info_response_msg(job_step_info_response_msg_t *msg)

    void slurm_print_job_step_info_msg(
        FILE *out,
        job_step_info_response_msg_t *job_step_info_msg_ptr,
        int one_liner
    )

    void slurm_print_job_step_info(FILE *out, job_step_info_t *step_ptr,
                                   int one_liner)

    slurm_step_layout_t *slurm_job_step_layout_get(uint32_t job_id,
                                                   uint32_t step_id)

    int slurm_job_step_stat(uint32_t job_id, uint32_t step_id, char *node_list,
                            job_step_stat_response_msg_t **resp)

    int slurm_job_step_get_pids(uint32_t job_id, uint32_t step_id,
                                char *node_list,
                                job_step_pids_response_msg_t **resp)

    void slurm_job_step_layout_free(slurm_step_layout_t *layout)
    void slurm_job_step_pids_free(job_step_pids_t *object)
    void slurm_job_step_pids_response_msg_free(void *object)
    void slurm_job_step_stat_free(job_step_stat_t *object)
    void slurm_job_step_stat_response_msg_free(void *object)
    int slurm_update_step(step_update_request_msg_t *step_msg)

#
# Job declarations outside of slurm.h
#

cdef extern char *slurm_step_layout_type_name(task_dist_states_t task_dist)
