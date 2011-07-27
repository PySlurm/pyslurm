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

if "yogi" not in my_host:
  sys.exit()

now = int(time.time())
lock_file = "/var/tmp/slurm_xml.lck"
if os.path.exists(lock_file):
  sys.exit()
else:
  open(lock_file, 'w').close()

slurm_file = "/var/tmp/slurm.xml"
xml_file = open(slurm_file,'w')

a, ptr = pyslurm.slurm_load_ctl_conf()
controllers = pyslurm.get_ctl_data(ptr)
pyslurm.slurm_free_ctl_conf(ptr)

xml_file.write('<?xml version="1.0" encoding="iso-8859-1" ?>\n')
xml_file.write("<slurm>\n")
xml_file.write("\t<lastUpdate>%s</lastUpdate>\n" % now)

a, b = pyslurm.slurm_load_jobs()
jobs = pyslurm.get_job_data(b)
if len(jobs) > 0:
  xml_file.write("\t<jobs>\n")
  for key, value in jobs.iteritems():

     xml_file.write('\t\t<job>\n')
     xml_file.write("\t\t\t<id>%s</id>\n" % value[1])
     xml_file.write("\t\t\t<lastUpdate>%s</lastUpdate>\n" % value[0])
     xml_file.write("\t\t\t<name>%s</name>\n" % value[2])
     xml_file.write("\t\t\t<batch>%s</batch>\n" % value[3])
     xml_file.write("\t\t\t<userId>%s</userId>\n" % pwd.getpwuid(value[4])[0])
     xml_file.write("\t\t\t<userName>%s</userName>\n" % pwd.getpwuid(value[4])[4])
     xml_file.write("\t\t\t<groupId>%s</groupId>\n" % grp.getgrgid(value[5])[0])
     xml_file.write("\t\t\t<state>%s</state>\n" % value[6])
     xml_file.write("\t\t\t<wcl>%s</wcl>\n" % value[7])
     xml_file.write("\t\t\t<submitTime>%s</submitTime>\n" % value[8])
     xml_file.write("\t\t\t<startTime>%s</startTime>\n" % value[9])
     xml_file.write("\t\t\t<endTime>%s</endTime>\n" % value[10])
     xml_file.write("\t\t\t<suspendTime>%s</suspendTime>\n" % value[11])
     xml_file.write("\t\t\t<psuspendTime>%s</psuspendTime>\n" % value[12])
     xml_file.write("\t\t\t<priority>%s</priority>\n" % value[13])
     xml_file.write("\t\t\t<nodes>%s</nodes>\n" % value[14])
     xml_file.write("\t\t\t<partition>%s</partition>\n" % value[15])
     xml_file.write("\t\t\t<numProcs>%s</numProcs>\n" % value[16])
     #xml_file.write("\t\t\t<numNodes>%s</numNodes>\n" % value[17])
     xml_file.write("\t\t\t<numNodes>%s</numNodes>\n" % len(string.split(value[14],',')))
     xml_file.write("\t\t\t<execNodes>%s</execNodes>\n" % value[18])
     xml_file.write("\t\t\t<shared>%s</shared>\n" % value[19])
     xml_file.write("\t\t\t<contigous>%s</contigous>\n" % value[20])
     xml_file.write("\t\t\t<cpusPerTask>%s</cpusPerTask>\n" % value[21])
     xml_file.write("\t\t\t<account>%s</account>\n" % value[22])
     xml_file.write("\t\t\t<comment>%s</comment>\n" % value[23])
     xml_file.write("\t\t\t<reason>%s</reason>\n" % value[24])

     steps = pyslurm.slurm_get_job_steps(value[1], 0, 0)
     for jobstep in steps:
       xml_file.write('\t\t\t<jobstep>\n')
       xml_file.write('\t\t\t\t<id>%s</id>\n' % jobstep[1])
       xml_file.write('\t\t\t\t<partition>%s</partition>\n' % jobstep[4])
       xml_file.write('\t\t\t\t<name>%s</name>\n' % jobstep[6])
       step_info = pyslurm.slurm_job_step_layout_get(value[1], jobstep[1])
       nodes = []
       for task_info in step_info:
         nodes.append( '%s*%d' % (task_info[0], len(task_info[1]) ) )

       xml_file.write('\t\t\t\t<tasks>%s</tasks>\n' % string.join(nodes,','))
       xml_file.write('\t\t\t</jobstep>\n')
     
     xml_file.write('\t\t</job>\n')

  xml_file.write("\t</jobs>\n")

pyslurm.slurm_free_job_info_msg(b)

a, b = pyslurm.slurm_load_node()
nodes = pyslurm.get_node_data(b)
if len(nodes) > 0:
  xml_file.write("\t<nodes>\n")
  for key, value in nodes.iteritems():
     xml_file.write('\t\t<node>\n')
     xml_file.write("\t\t\t<id>%s</id>\n" % key)
     xml_file.write("\t\t\t<lastUpdate>%s</lastUpdate>\n" % value[0])
     xml_file.write("\t\t\t<state>%s</state>\n" % value[1])
     xml_file.write("\t\t\t<cpus>%s</cpus>\n" % value[2])
     xml_file.write("\t\t\t<sockets>%s</sockets>\n" % value[3])
     xml_file.write("\t\t\t<cores>%s</cores>\n" % value[4])
     xml_file.write("\t\t\t<threads>%s</threads>\n" % value[5])
     xml_file.write("\t\t\t<realMem>%s</realMem>\n" % value[6])
     xml_file.write("\t\t\t<tmpDisk>%s</tmpDisk>\n" % value[7])
     xml_file.write("\t\t\t<weight>%s</weight>\n" % value[8])
     xml_file.write("\t\t\t<features>%s</features>\n" % value[9])

     if key in controllers[0]:
       xml_file.write("\t\t\t<controller>Primary</controller>\n")
     elif key in controllers[1]:
       xml_file.write("\t\t\t<controller>Secondary</controller>\n")
     else:
       xml_file.write("\t\t\t<controller></controller>\n")

     xml_file.write("\t\t\t<reason>%s</reason>\n" % value[10])
     xml_file.write('\t\t</node>\n')
  xml_file.write( "\t</nodes>\n")
pyslurm.slurm_free_node_info_msg(b)

a, b = pyslurm.slurm_load_partitions()
partitions = pyslurm.get_partition_data(b)
if len(partitions) > 0:
  xml_file.write("\t<partitions>\n")
  for key, value in partitions.iteritems():
     xml_file.write('\t\t<partition>\n')
     xml_file.write("\t\t\t<id>%s</id>\n" % key)
     xml_file.write("\t\t\t<lastUpdate>%s</lastUpdate>\n" % value[0])
     xml_file.write("\t\t\t<maxTime>%s</maxTime>\n" % value[1])
     xml_file.write("\t\t\t<maxNodes>%s</maxNodes>\n" % value[2])
     xml_file.write("\t\t\t<minNodes>%s</minNodes>\n" % value[3])
     xml_file.write("\t\t\t<totalNodes>%s</totalNodes>\n" % value[4])
     xml_file.write("\t\t\t<totalCpus>%s</totalCpus>\n" % value[5])
     xml_file.write("\t\t\t<nodeScaling>%s</nodeScaling>\n" % value[6])
     xml_file.write("\t\t\t<defaultPartition>%s</defaultPartition>\n" % value[7])
     xml_file.write("\t\t\t<hidden>%s</hidden>\n" % value[8])
     xml_file.write("\t\t\t<rootOnly>%s</rootOnly>\n" % value[9])
     xml_file.write("\t\t\t<shared>%s</shared>\n" % value[10])
     xml_file.write("\t\t\t<stateUp>%s</stateUp>\n" % value[11])
     xml_file.write("\t\t\t<nodes>%s</nodes>\n" % value[12])
     xml_file.write("\t\t\t<allowGroups>%s</allowGroups>\n" % value[13])
     xml_file.write('\t\t</partition>\n')
  xml_file.write("\t</partitions>\n")
pyslurm.slurm_free_partition_info_msg(b)

xml_file.write("</slurm>\n")
xml_file.flush()
xml_file.close()

os.remove(lock_file)
