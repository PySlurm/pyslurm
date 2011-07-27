import pyslurm

print pyslurm.slurm_load_node.__doc__
a, b = pyslurm.slurm_load_node()

print pyslurm.get_node_data.__doc__
c = pyslurm.get_node_data(b)
print c
