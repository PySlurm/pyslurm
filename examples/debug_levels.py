import pyslurm

rc = pyslurm.slurm_set_debug_level(1)
if rc == -1:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
elif rc == 0:
	print "Slurmd debug level updated" 

rc = pyslurm.slurm_set_schedlog_level(0)
if rc == -1:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
elif rc == 0:
	print "Schedlog log level updated" 


