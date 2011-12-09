#!/usr/bin/env python

import pyslurm

a = pyslurm.reservation()
res_dict = pyslurm.create_reservation_dict()

res_dict["name"] = "root_10"
res_dict["duration"] = 8000

rc = a.update(res_dict)
if rc == -1:
	rc = pyslurm.slurm_get_errno()
	print "Error : %s" % pyslurm.slurm_strerror(rc)
elif rc == 0:
	print "Reservation %s updated" % res_dict["name"]
