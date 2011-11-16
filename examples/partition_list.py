import pyslurm
from time import gmtime, strftime

a, b = pyslurm.slurm_load_partitions()
part_dict = pyslurm.get_partition_data(b)
pyslurm.slurm_free_partition_info_msg(b)

if len(part_dict) > 0:

	for key, value in part_dict.iteritems():

		print "%s :" % key
		for part_key in sorted(value.iterkeys()):

			valStr = value[part_key]
			if 'default_time' in part_key:

				if value[part_key] == 0xffffffff:
					valStr = (value[part_key], "infinite")	
				elif value[part_key] == 0xfffffffe:
					valStr = (value[part_key], "no_value")
				else:
					valStr = (value[part_key], "%s minutes" % (value[part_key]/60) )

			elif part_key in [ 'max_nodes', 'max_time']:
				if value[part_key] == 0xffffffff:
					valStr = "Unlimited"
			
			print "\t%-20s : %s" % (part_key, valStr)
		print "-" * 80

else:
	
	print "No partitions found !"

