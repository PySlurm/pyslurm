#!/usr/bin/env python

from optparse import OptionParser

import pyslurm
import socket
import time
import pwd
import grp
import os
import re
import sys
import os.path

re_meminfo_parser = re.compile(r'^(?P<key>\S*):\s*(?P<value>\d*)\s*kB')
stdout_orig = sys.stdout

def loadavg(host, rrd=""):

	loadavg = "/proc/loadavg"
	load_rrd = '%s/%s_loadavg.rrd' % (rrd, host)

	try:
		f = open(loadavg, 'r').readline().strip()
	except IOError:
		return (-1, -1, -1, -1, -1)

	data = f.split()

	avg1min, avg5min, avg15min = map(float, data[:3])
	running, total = map(int, data[3].split('/'))

	if rrd != "":
		if not os.path.exists(load_rrd):
			os.system('/usr/bin/rrdtool create %s --step 60 \
					DS:loadl1:GAUGE:120:0:U \
					DS:loadl5:GAUGE:120:0:U \
					DS:loadl15:GAUGE:120:0:U \
					RRA:AVERAGE:0.5:1:2160 \
					RRA:AVERAGE:0.5:5:2016 \
					RRA:AVERAGE:0.5:15:2880 \
					RRA:AVERAGE:0.5:60:8760' % load_rrd)

		os.system('/usr/bin/rrdtool update %s N:%s:%s:%s' % (load_rrd, avg1min, avg5min, avg15min))

	return avg1min, avg5min, avg15min, running, total

def uptime(host, rrd=""):

	uptime = "/proc/uptime"

	try:
		f = open(uptime, 'r').readline().strip()
	except IOError:
		return (-1,-1)

	data = f.split()

	return data

def meminfo(host, rrd=""):

	result = {}
	meminfo = "/proc/meminfo"
	try:
		f = open(meminfo, 'r').readlines()
	except IOError:
		return result

	for line in f:
		match = re_meminfo_parser.match(line)
		if not match:
			continue
		key, value = match.groups(['key', 'value'])
		result[key] = int(value)

	return result

if __name__ == '__main__':

	usage = "Usage: %prog [options] arg"
	parser = OptionParser(usage)

	parser.add_option("-o", "--stdout", dest="output",
						action="store_true", default=False,
						help="Write to standard output")
	parser.add_option("-d", "--dir", dest="directory",
						action="store", default=os.getcwd(),
						help="Directory to write data to")
	parser.add_option("-r", "--rrd", dest="rrd", default=False,
						action="store_true", help="Write rrd data")

	(options, args) = parser.parse_args()

	hosts = socket.gethostbyaddr(socket.gethostname())[2]
	my_host = hosts[0]

	lock_file = "/var/tmp/slurm_node_xml.lck"
	if os.path.exists(lock_file):
		print ("Lock file " +  "/var/tmp/slurm_node_xml.lck" + " exists, exiting")
		sys.exit(1)
	else:
		open(lock_file,'w').close()

	rrd = ""
	if options.rrd:
		rrd = options.directory

	node_file = r'%s/%s.xml' % (options.directory, my_host)
	if not options.output:
		stdout_orig = sys.stdout
		sys.stdout = open(node_file, 'w')
		
	now = int(time.time())
	sys.stdout.write('<?xml version="1.0" encoding="iso-8859-1" ?>\n')
	sys.stdout.write("<node>\n")
	sys.stdout.write("\t<name>%s</name>\n" % my_host)
	sys.stdout.write("\t<lastUpdate>%s</lastUpdate>\n" % now)

	Average = loadavg(my_host, rrd)
	sys.stdout.write("\t<loadAvg>%s,%s,%s</loadAvg>\n" % (Average[0], Average[1], Average[2]))

	Uptime = uptime(my_host, rrd)
	sys.stdout.write("\t<upTime>%s,%s</upTime>\n" % (Uptime[0], Uptime[1]))

	Memory = meminfo(my_host, rrd)
	sys.stdout.write("\t<memTotal>%s</memTotal>\n" % Memory['MemTotal'])
	sys.stdout.write("\t<memFree>%s</memFree>\n" % Memory['MemFree'])
	sys.stdout.write("\t<cached>%s</cached>\n" % Memory['Cached'])
	sys.stdout.write("\t<buffers>%s</buffers>\n" % Memory['Buffers'])

	a = pyslurm.slurm_load_slurmd_status()
	print a
	if len(a) > 0:
		sys.stdout.write("\t<slurmd>\n")
		sys.stdout.write("\t\t<booted>%s</booted>\n" % a[0])
		sys.stdout.write("\t\t<lastCtldUpdate>%s</lastCtldUpdate>\n" % a[1])
		sys.stdout.write("\t\t<pid>%s</pid>\n" % a[2])
		sys.stdout.write("\t\t<jobSteps>%s</jobSteps>\n" % a[3])
		sys.stdout.write("\t\t<version>%s</version>\n" % a[4])
		sys.stdout.write("\t</slurmd>\n")

	aux = pyslurm.job()

	jobs = aux.get()

	now = int(time.time())
	PiDs = {}
	for jobid, jobinfo  in jobs.iteritems():

		if jobinfo['job_state'][1] == "RUNNING":
			userid = pwd.getpwuid(jobinfo['user_id']).pw_name
			nodes = jobinfo['alloc_node'].split(',')

			if my_host in nodes:
				PiDs[jobid] = []

			a = os.popen('/bin/ps --noheaders -u %s -o pid,ppid,size,rss,vsize,pcpu,args' %(userid), 'r')
			for lines in a:
				line = lines.split()
				command = " ".join(line[6:])
				newline = [ line[0], line[1], line[2], line[3], line[4], line[5], command ]
				pid = int(line[0])
				rc, slurm_jobid = pyslurm.slurm_pid2jobid(pid)
				if rc == 0:
					if PiDs.has_key(slurm_jobid):
						PiDs[slurm_jobid].append(newline)
			a.close()

	if len(PiDs) > 0:

		sys.stdout.write("\t<jobs>\n")
		for job, value in PiDs.iteritems():
			sys.stdout.write("\t\t<job>\n")
			sys.stdout.write("\t\t\t<id>%s</id>\n" % job)
			for pid in value:
				sys.stdout.write("\t\t\t<process>\n")
				sys.stdout.write("\t\t\t\t<pid>%s</pid>\n" % pid[0])
				sys.stdout.write("\t\t\t\t<ppid>%s</ppid>\n" % pid[1])
				sys.stdout.write("\t\t\t\t<size>%s</size>\n" % pid[2])
				sys.stdout.write("\t\t\t\t<rss>%s</rss>\n" % pid[3])
				sys.stdout.write("\t\t\t\t<vsize>%s</vsize>\n" % pid[4])
				sys.stdout.write("\t\t\t\t<pcpu>%s</pcpu>\n" % pid[5])
				sys.stdout.write("\t\t\t\t<args><![CDATA[%s]]></args>\n" % pid[6])
				sys.stdout.write("\t\t\t</process>\n")
			sys.stdout.write("\t\t</job>\n")

		sys.stdout.write("\t</jobs>\n")

	sys.stdout.write("</node>\n")
	sys.stdout.flush()

	aux.__free()

	if not options.output:
		sys.stdout.close()
		sys.stdout = stdout_orig
		os.chmod(node_file, 0644)

	os.remove(lock_file)
