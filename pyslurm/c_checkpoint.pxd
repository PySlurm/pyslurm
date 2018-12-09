from libc.stdint cimport uint16_t, uint32_t
from posix.types cimport time_t

cdef extern from "slurm/slurm.h" nogil:
    int slurm_checkpoint_able(uint32_t job_id, uint32_t step_id, time_t *start_time)
    int slurm_checkpoint_disable(uint32_t job_id, uint32_t step_id)
    int slurm_checkpoint_enable(uint32_t job_id, uint32_t step_id)

    int slurm_checkpoint_create(
        uint32_t job_id,
        uint32_t step_id,
        uint16_t max_wait,
        char *image_dir
    )

    int slurm_checkpoint_requeue(uint32_t job_id, uint16_t max_wait, char *image_dir)

    int slurm_checkpoint_vacate(
        uint32_t job_id,
        uint32_t step_id,
        uint16_t max_wait,
        char *image_dir
    )

    int slurm_checkpoint_restart(
        uint32_t job_id,
        uint32_t step_id,
        uint16_t stick,
        char *image_dir
    )

    int slurm_checkpoint_complete(
        uint32_t job_id,
        uint32_t step_id,
        time_t begin_time,
        uint32_t error_code,
        char *error_msg
    )

    int slurm_checkpoint_task_complete(
        uint32_t job_id,
        uint32_t step_id,
        uint32_t task_id,
        time_t begin_time,
        uint32_t error_code,
        char *error_msg
    )

    int slurm_checkpoint_tasks(
        uint32_t job_id,
        uint16_t step_id,
        time_t begin_time,
        char *image_dir,
        uint16_t max_wait,
        char *nodelist
    )
