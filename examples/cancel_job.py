import pyslurm

rc = pyslurm.slurm_kill_job(10, 9, 0)
if rc == -1:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
else:
	print "Success"

