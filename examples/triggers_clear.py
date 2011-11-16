import pyslurm

TrigID = 2
rc = pyslurm.slurm_clear_trigger(TrigID)
if rc == -1:
	print "No triggerID (%s) found !" % TrigID
else:
	print "TriggerID (%s) cleared" % TrigID 

