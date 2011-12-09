#!/usr/bin/env python

import pyslurm

b = pyslurm.hostlist()

hosts = "dummy0,dummy1,dummy1,dummy3,dummy4"
print "Creating hostlist ...... with %s" % hosts
if b.create(hosts):

	print "\tHost list count is %s" % b.count()
	print "\tHost %s found at index %s" % ('dummy3', b.find("dummy3"))
	print "\tCalling uniq on current host list"
	b.uniq()

	print "\tNew host list is %s" % b.get()
	print "\tNew host count is %s" % b.count()
	print "\tHost %s at index %s" % ('dummy3', b.find("dummy3"))
	print "\tRanged list is %s" % b.get()

	a = "dummy18"
	print "\tPushing new entry %s" % a
	if b.push("dummy18"):
		print "\t\tSuccess !"
		print "\tNew ranged list is %s" % b.get()
	else:
		print "\t\tFailed !"

	print "\tDropping first host from list"
	name = b.pop()
	if name:
		print "\t\tDropped host %s from list" % name
		print "\t\tNew host count is %s" % b.count()
		print "\t\tNew host list is %s" % b.get()
	else:
		print "\t\tFailed !"

	print "Destroying host list"
	b.destroy()
	print "\tHost count is %s" % b.count()

else:
	print "\tFailed to create initial list !"
