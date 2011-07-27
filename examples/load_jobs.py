import pyslurm

print pyslurm.slurm_load_jobs.__doc__
a, b = pyslurm.slurm_load_jobs()

print a
print pyslurm.get_job_data.__doc__
print pyslurm.get_job_data(b)

