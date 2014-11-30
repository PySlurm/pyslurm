#!/usr/bin/env python

import pyslurm

b = pyslurm.hostlist()

hosts = "dummy0,dummy1,dummy1,dummy3,dummy4"
print "Creating hostlist ...... with %s" % hosts
if b.create(hosts):

	print
	print "\tHost list count is %s" % b.count()
	node = "dummy3"
	pos = b.find(node)
	if pos == -1:
		print "Failed to find %s in list" % node
	else:
		print "\tHost %s found at position %s" % (node, pos)
	print "\tCalling uniq on current host list"
	b.uniq()

	print "\tNew host list is %s" % b.get()
	print "\tNew host list count is %s" % b.count()
	pos = b.find(node)
	if pos == -1:
		print "Failed to find %s in list" % node
	else:
		print "\tHost %s found at position %s" % (node, pos)

	print "\tRanged host list is %s" % b.get()
	print

	node = "dummy18"
	print "\tPushing new entry %s" % node
	if b.push(node):
		print "\t\tSuccess !"
		print "\tNew ranged list is %s" % b.get()
	else:
		print "\t\tFailed !"
	print

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
	print "\tHost listcount is %s" % b.count()

else:
	print "\tFailed to create initial list !"
