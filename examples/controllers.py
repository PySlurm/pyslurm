import pyslurm
import socket
import sys


def controller_up(controller=1):

	rc = pyslurm.slurm_ping(controller)
	if rc != 0:
		rc = pyslurm.slurm_get_errno()
		print "\t\tFailed - %s" % pyslurm.slurm_strerror(rc)
	else:
		print "\t\tSuccess"


if __name__ == "__main__":

	print "\n"
	print "PySLURM\t%s" % (pyslurm.version())
	print "SLURM\t%s-%s-%s\n" % (pyslurm.slurm_api_version())

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
		print "\tPrimary .....\r"
		controller_up()

	if backup:
		print "\tBackup .....\r"
		controller_up(2)


