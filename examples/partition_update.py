import pyslurm

partition_dict = { 'NodeName': 'makalu', 'State': 0x0200, 'Reason':'API test' }

c = pyslurm.slurm_update_partition(partition_dict)
