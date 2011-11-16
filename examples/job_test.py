import pyslurm

a, b = pyslurm.slurm_load_jobs()
print pyslurm.slurm_job_cpus_allocated_on_node_id(b,5)

jobs =  pyslurm.get_job_data(b)
print jobs
