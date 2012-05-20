#!/usr/bin/env python

import pyslurm

def display(topo_dict):

	if topo_dict:

		print("-" * 80)
		for key, value in topo_dict.items():

			print("Name: %s" % (key))
			for subkey, new_value in value.items():
				print("\t%-17s : %s" % (subkey, new_value))


if __name__ == "__main__":

	topo = pyslurm.topology()
	topo_dict = topo.get()

	if len(topo_dict) > 0:
		display(topo_dict)
	else:
		print("No Topology found !")
