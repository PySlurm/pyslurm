import pyslurm
import datetime

a, b = pyslurm.slurm_load_reservations()
res_dict =  pyslurm.get_reservation_data(b)

if len(res_dict) > 0:

	date_fields = [ 'end_time', 'start_time' ]

	for key, value in res_dict.iteritems():

		print "Res ID : %s" % (key)
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
	print "No reservations found !"

