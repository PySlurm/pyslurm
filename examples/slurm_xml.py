#!/usr/bin/env python
"""
List Slurm information as XML
"""
from __future__ import print_function

import socket
import sys
import time

import pyslurm

my_host = socket.gethostname()

if "ernie" not in my_host:
    sys.exit()

now = int(time.time())

slurm_file = "/tmp/slurm.xml"
xml_file = open(slurm_file, "w")

##################
# Get controllers
##################

primary, backup = pyslurm.get_controllers()
xml_file.write('<?xml version="1.0" encoding="iso-8859-1" ?>\n')
xml_file.write("<slurm>\n")
xml_file.write("\t<lastUpdate>{0}</lastUpdate>\n".format(now))

####################
# XML output of Jobs
####################

a = pyslurm.job()
jobs = a.get()

xml_file.write("\t<jobs>\n")
for key, value in jobs.items():

    xml_file.write("\t\t<job>\n")
    xml_file.write("\t\t\t<id>{0}</id>\n".format(key))
    for job_key in sorted(value.items()):
        xml_file.write(
            "\t\t\t<{0}>{1}</{2}>\n".format(job_key[0], job_key[1], job_key[0])
        )

    b = pyslurm.jobstep(key, 0, 0)
    steps = b.get()
    for job, job_step in sorted(steps.items()):
        xml_file.write("\t\t\t<jobstep>\n")

        for step in sorted(job_step.items()):
            xml_file.write("\t\t\t\t<id>{0}</id>\n".format(step))
            step_info = pyslurm.slurm_job_step_layout_get(int(job), int(step))
            for task in sorted(step_info.items()):
                xml_file.write(
                    "\t\t\t\t<{0}>{1}</{2}>\n".format(task[0], task[1], task[0])
                )

        xml_file.write("\t\t\t</jobstep>\n")

    xml_file.write("\t\t</job>\n")

xml_file.write("\t</jobs>\n")

############################
# XML output of Nodes
#############################

a = pyslurm.node()
node_dict = a.get()

xml_file.write("\t<nodes>\n")
for key, value in node_dict.items():

    xml_file.write("\t\t<node>\n")
    xml_file.write("\t\t\t<id>{0}</id>\n".format(key))
    for part_key in sorted(value.items()):
        xml_file.write(
            "\t\t\t<{0}>{1}</{2}>\n".format(part_key[0], part_key[1], part_key[0])
        )

    if primary and key in primary:
        xml_file.write("\t\t\t<controller>Primary</controller>\n")
    elif backup and key in backup:
        xml_file.write("\t\t\t<controller>backup</controller>\n")
    else:
        xml_file.write("\t\t\t<controller></controller>\n")

    xml_file.write("\t\t</node>\n")
xml_file.write("\t</nodes>\n")

###########################
# XML output of Partttions
###########################

a = pyslurm.partition()
part_dict = a.get()

xml_file.write("\t<partitions>\n")
for key, value in part_dict.items():
    xml_file.write("\t\t<partition>\n")
    for part_key, part_value in value.items():
        xml_file.write("\t\t\t<{0}>{1}</{2}>\n".format(part_key, part_value, part_key))
    xml_file.write("\t\t</partition>\n")
xml_file.write("\t</partitions>\n")

xml_file.write("</slurm>\n")
xml_file.flush()
xml_file.close()
