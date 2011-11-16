import pyslurm

partition_dict = pyslurm.create_partition_dict()
partition_dict['PartitionName'] ='mark'

rc = pyslurm.slurm_create_partition(partition_dict)
if rc == -1:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
elif rc == 0:
	print "Partition %s created" % partition_dict["PartitionName"]
  
