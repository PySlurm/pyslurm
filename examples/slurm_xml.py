import pyslurm
import socket
import string
import time
import pwd
import grp
import sys
import os
import os.path

hosts = socket.gethostbyaddr(socket.gethostname())[1]
my_host = hosts[0]

if "makalu" not in my_host:
	sys.exit()

now = int(time.time())
#lock_file = "/var/tmp/slurm_xml.lck"
#if os.path.exists(lock_file):
#  sys.exit()
#else:
#  open(lock_file, 'w').close()

slurm_file = "/var/tmp/slurm.xml"
xml_file = open(slurm_file,'w')

#
# Get the controllers
#

primary, backup = pyslurm.get_controllers()

xml_file.write('<?xml version="1.0" encoding="iso-8859-1" ?>\n')
xml_file.write("<slurm>\n")
xml_file.write("\t<lastUpdate>%s</lastUpdate>\n" % now)

#
# XML output of Jobs
#

a, b = pyslurm.slurm_load_jobs()
jobs = pyslurm.get_job_data(b)

if len(jobs) > 0:

	xml_file.write("\t<jobs>\n")
	for key, value in jobs.iteritems():

		xml_file.write('\t\t<job>\n')
		xml_file.write("\t\t\t<id>%s</id>\n" % key)
		for job_key in sorted(value.iterkeys()):
			xml_file.write("\t\t\t<%s>%s</%s>\n" % (job_key, value[job_key], job_key))

		steps = pyslurm.slurm_get_job_steps(key, 0, 0)
		for job, job_step in sorted(steps.iteritems()):
			xml_file.write('\t\t\t<jobstep>\n')

			for step in sorted(job_step.iterkeys()): 
				xml_file.write("\t\t\t\t<id>%s</id>\n" % step)
				step_info = pyslurm.slurm_job_step_layout_get(int(job), int(step))
				for task in sorted(step_info.iterkeys()):
				xml_file.write('\t\t\t\t<%s>%s</%s>\n' % (task, step_info[task], task))

			xml_file.write('\t\t\t</jobstep>\n')
		
		xml_file.write('\t\t</job>\n')

	xml_file.write("\t</jobs>\n")

	pyslurm.slurm_free_job_info_msg(b)

	#
	# XML output of Nodes
	#

	a, b = pyslurm.slurm_load_node()
	node_dict = pyslurm.get_node_data(b)

	if len(node_dict) > 0:

	xml_file.write( "\t<nodes>\n")
	for key, value in node_dict.iteritems():

		xml_file.write('\t\t<node>\n')
		xml_file.write("\t\t\t<id>%s</id>\n" % key)
		for part_key in sorted(value.iterkeys()):
		xml_file.write("\t\t\t<%s>%s</%s>\n" % (part_key, value[part_key], part_key))

		if key in primary:
			xml_file.write("\t\t\t<controller>Primary</controller>\n")
		elif key in backup: 
			xml_file.write("\t\t\t<controller>backup</controller>\n")
		else:
			xml_file.write("\t\t\t<controller></controller>\n")

		xml_file.write('\t\t</node>\n')
	xml_file.write( "\t</nodes>\n")

	pyslurm.slurm_free_node_info_msg(b)

	#
	# XML output of Partttions
	#

	a, b = pyslurm.slurm_load_partitions()
	part_dict = pyslurm.get_partition_data(b)

	if len(part_dict) > 0:

	xml_file.write("\t<partitions>\n")
	for key, value in part_dict.iteritems():

		xml_file.write('\t\t<partition>\n')
		for part_key, part_value in value.iteritems():
		xml_file.write("\t\t\t<%s>%s</%s>\n" % (part_key, part_value, part_key))

		xml_file.write('\t\t</partition>\n')

	xml_file.write("\t</partitions>\n")

	pyslurm.slurm_free_partition_info_msg(b)

	xml_file.write("</slurm>\n")
	xml_file.flush()
	xml_file.close()

#os.remove(lock_file)
