import pyslurm

print pyslurm.slurm_load_partitions.__doc__
a, b = pyslurm.slurm_load_partitions()

print pyslurm.get_partition_data.__doc__
c = pyslurm.get_partition_data(b)
print c
