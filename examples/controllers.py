#!/usr/bin/env python

import pyslurm
import socket
import sys

def controller_up(controller=1):

	try:
		pyslurm.slurm_ping(controller)
	except valueError as e:
		print "Failed - %s" % (e)
	else:
		print "Success"

if __name__ == "__main__":

	print "\n"
	print "PySLURM   : %s" % (pyslurm.version())
	print "SLURM API : %s-%s-%s\n" % (pyslurm.slurm_api_version())

	host = socket.gethostname()
	print "Checking host.....%s\n" % host

	try:
		a = pyslurm.is_controller(host)
		print "\tHost is controller (%s)\n" % a

		print "Querying SLURM controllers\n"
		primary, backup = pyslurm.get_controllers()

		print "\tPrimary - %s" % primary
		print "\tBackup  - %s" % backup

		print "\nPinging SLURM controllers\n"

		if primary:
			print "\tPrimary .....",
			controller_up()

		if backup:
			print "\tBackup .....",
			controller_up(2)
	except ValueError as e:
		print 'Error - %s' % (e)
