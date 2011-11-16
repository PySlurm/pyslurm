import pyslurm
import time

dstring = "2010-12-31T18:00:00"
dpattern = "%Y-%m-%dT%H:%M:%S"
start_epoch = int(time.mktime(time.strptime(dstring, dpattern)))

res_dict = pyslurm.create_reservation_dict()

res_dict["node_cnt"] = 1
res_dict["users"] = "root"
res_dict["start_time"] = start_epoch
res_dict["duration"] = 600

a = pyslurm.slurm_create_reservation(res_dict)
print "-" * 80
print a
a, b = pyslurm.slurm_load_reservations()
pyslurm.slurm_print_reservation_info(a)
print "-" * 80
