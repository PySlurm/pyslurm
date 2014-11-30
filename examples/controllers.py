#!/usr/bin/env python

import pyslurm
import socket
import sys


def controller_up(controller=1):

	rc = pyslurm.slurm_ping(controller)
	if rc != 0:
		rc = pyslurm.slurm_get_errno()
		print "Failed - %s" % pyslurm.slurm_strerror(rc)
	else:
		print "Success"


if __name__ == "__main__":

	print "\n"
	print "PySlurm\t%s" % (pyslurm.version())
	print "Slurm\t%s-%s-%s\n" % (pyslurm.slurm_api_version())

	host = socket.gethostname()
	print "Checking host.....%s\n" % host

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

