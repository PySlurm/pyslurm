#!/usr/bin/env python
"""
List Slurm information as XML
"""

import socket
import sys
import time

import pyslurm

my_host = socket.gethostname()

if "ernie" not in my_host:
    sys.exit()

now = int(time.time())

SLURM_FILE = "/tmp/slurm.xml"
xml_file = open(SLURM_FILE, "w", encoding="iso-8859-1")

##################
# Get controllers
##################

primary, backup = pyslurm.get_controllers()
xml_file.write('<?xml version="1.0" encoding="iso-8859-1" ?>\n')
xml_file.write("<slurm>\n")
xml_file.write(f"\t<lastUpdate>{now}</lastUpdate>\n")

####################
# XML output of Jobs
####################

a = pyslurm.job()
jobs = a.get()

xml_file.write("\t<jobs>\n")
for key, value in jobs.items():

    xml_file.write("\t\t<job>\n")
    xml_file.write(f"\t\t\t<id>{key}</id>\n")
    for job_key in sorted(value.items()):
        xml_file.write(f"\t\t\t<{job_key[0]}>{job_key[1]}</{job_key[0]}>\n")

    b = pyslurm.jobstep(key, 0, 0)
    steps = b.get()
    for job, job_step in sorted(steps.items()):
        xml_file.write("\t\t\t<jobstep>\n")

        for step in sorted(job_step.items()):
            xml_file.write(f"\t\t\t\t<id>{step}</id>\n")
            step_info = pyslurm.slurm_job_step_layout_get(int(job), int(step))
            for task in sorted(step_info.items()):
                xml_file.write(f"\t\t\t\t<{task[0]}>{task[1]}</{task[0]}>\n")

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
    xml_file.write(f"\t\t\t<id>{key}</id>\n")
    for part_key in sorted(value.items()):
        xml_file.write(f"\t\t\t<{part_key[0]}>{part_key[1]}</{part_key[0]}>\n")

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
        xml_file.write(f"\t\t\t<{part_key}>{part_value}</{part_key}>\n")
    xml_file.write("\t\t</partition>\n")
xml_file.write("\t</partitions>\n")

xml_file.write("</slurm>\n")
xml_file.flush()
xml_file.close()
