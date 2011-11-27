import pyslurm

a, ptr = pyslurm.slurm_load_ctl_conf()
pyslurm.slurm_print_ctl_conf(ptr)
ctl_dict = pyslurm.get_ctl_data(ptr)
pyslurm.slurm_free_ctl_conf(ptr)

# Process the sorted SLURM configuration dictionary

date_fields = [ 'boot_time', 'last_update' ]
for key in sorted(ctl_dict.iterkeys()):

	if key in date_fields:

		if ctl_dict[key] == 0:
			print "\t%-35s : N/A" % (key)
		else:
			ddate = pyslurm.epoch2date(ctl_dict[key])
			print "\t%-35s : %s" % (key, ddate)

	else:
		print "\t%-35s : %s" % (key, ctl_dict[key])

