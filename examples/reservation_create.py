import pyslurm
import sys
import string
import time
import datetime

dstring = "2013-12-31T18:00:00"
dpattern = "%Y-%m-%dT%H:%M:%S"
start_epoch = int(time.mktime(time.strptime(dstring, dpattern)))

res_dict = pyslurm.create_reservation_dict()

res_dict["node_cnt"] = 1
res_dict["users"] = "root"
res_dict["start_time"] = start_epoch
res_dict["duration"] = 600

resid = pyslurm.slurm_create_reservation(res_dict)
rc = pyslurm.slurm_get_errno()
if rc != 0:
	print "Failed - Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
	sys.exit(-1)
else:
	print "Success - Created reservation %s\n" % resid

a, b = pyslurm.slurm_load_reservations()
res_dict =  pyslurm.get_reservation_data(b)

if res_dict.has_key(resid):

	date_fields = [ 'end_time', 'start_time' ]

	value = res_dict[resid]
	print "Res ID : %s" % (resid)
	for res_key in sorted(value.iterkeys()):

		if res_key in date_fields:

			if value[res_key] == 0:
				print "\t%-20s : N/A" % (res_key)
			else:
				ddate = pyslurm.epoch2date(value[res_key])
				print "\t%-20s : %s" % (res_key, ddate)
		else:
				print "\t%-20s : %s" % (res_key, value[res_key])

	print "-" * 80

else:
        print "No reservation %s found !" % resid
	sys.exit(-1)

print "\n"
print "%s" % ' All Reservations '.center(80, '-')
pyslurm.slurm_print_reservation_info_msg(b, False)
print "-" * 80
