import pyslurm

TrigID = 5
rc = pyslurm.slurm_clear_trigger(TrigID)
if rc != 0:
	rc = pyslurm.slurm_get_errno()
	print "Unable to clear trigger : %s" % pyslurm.slurm_strerror(rc)
else:
	print "TriggerID (%s) cleared" % TrigID 

