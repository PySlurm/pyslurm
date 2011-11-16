import pyslurm

rc, Time = pyslurm.slurm_checkpoint_able(6,0,0)
if rc != 0:
	print "Error : %s" % pyslurm.slurm_strerror(rc)
else:
	print "Job can be checkpointed"

