#!/usr/bin/env python

def display(node_dict):

	if node_dict:

		date_fields = [ 'boot_time', 'slurmd_start_time', 'last_update' ]

		print(("-" * 80))
		for key, value in list(node_dict.items()):

			print(("%s :" % (key)))
			for part_key in sorted(value.keys()):

				if part_key in date_fields:
					ddate = value[part_key]
					if ddate == 0:
						print(("\t%-17s : N/A" % (part_key)))
					else:
						ddate = pyslurm.epoch2date(ddate)
						print(("\t%-17s : %s" % (part_key, ddate)))
				elif ('reason_uid' in part_key and value['reason'] is None):
					print(("\t%-17s :" % part_key))
				else: 
					print(("\t%-17s : %s" % (part_key, value[part_key])))

			print(("-" * 80))

if __name__ == "__main__":

	import pyslurm

	FeNodes = pyslurm.front_end()
	node_dict = FeNodes.get()

	if len(node_dict) > 0:

		display(node_dict)

		print()
		print(("Node IDs - %s" % FeNodes.ids()))
		#print(("Node Find - %s" % FeNodes.find_id("makalu")))

	else:
	
		print("No Nodes found !")

	
