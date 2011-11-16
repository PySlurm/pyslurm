import pyslurm

res_dict = pyslurm.create_reservation_dict()

res_dict["name"] = "root_10"
res_dict["duration"] = 8000

rc = pyslurm.slurm_update_reservation(res_dict)
if rc == -1:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
elif rc == 0:
	print "Reservation %s updated" % res_dict["name"]
