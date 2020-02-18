#!/usr/bin/env python
"""
Display Slurm node information in XML
"""
from __future__ import print_function

import os
import os.path
import pwd
import re
import socket
import sys
import time
from optparse import OptionParser

import pyslurm

re_meminfo_parser = re.compile(r"^(?P<key>\S*):\s*(?P<value>\d*)\s*kB")
stdout_orig = sys.stdout


def loadavg(host, rrd=""):
    """Get Slurm load average"""
    loadavg = "/proc/loadavg"
    load_rrd = "{0}/{1}_loadavg.rrd".format(rrd, host)

    try:
        f = open(loadavg, "r").readline().strip()
    except IOError:
        return (-1, -1, -1, -1, -1)

    data = f.split()

    avg1min, avg5min, avg15min = map(float, data[:3])
    running, total = map(int, data[3].split("/"))

    if rrd != "":
        if not os.path.exists(load_rrd):
            os.system(
                "/usr/bin/rrdtool create {0} --step 60 \
                    DS:loadl1:GAUGE:120:0:U \
                    DS:loadl5:GAUGE:120:0:U \
                    DS:loadl15:GAUGE:120:0:U \
                    RRA:AVERAGE:0.5:1:2160 \
                    RRA:AVERAGE:0.5:5:2016 \
                    RRA:AVERAGE:0.5:15:2880 \
                    RRA:AVERAGE:0.5:60:8760".format(
                    load_rrd
                )
            )

        os.system(
            "/usr/bin/rrdtool update {0} N:{1}:{2}:{3}".format(
                load_rrd, avg1min, avg5min, avg15min
            )
        )

    return avg1min, avg5min, avg15min, running, total


def uptime():
    """Get Slurm uptime"""
    uptime = "/proc/uptime"

    try:
        f = open(uptime, "r").readline().strip()
    except IOError:
        return (-1, -1)

    data = f.split()

    return data


def meminfo():
    """Get Slurm memory information"""
    result = {}
    meminfo = "/proc/meminfo"
    try:
        f = open(meminfo, "r").readlines()
    except IOError:
        return result

    for line in f:
        match = re_meminfo_parser.match(line)
        if not match:
            continue
        key, value = match.groups(["key", "value"])
        result[key] = int(value)

    return result


if __name__ == "__main__":

    usage = "Usage: %prog [options] arg"
    parser = OptionParser(usage)

    parser.add_option(
        "-o",
        "--stdout",
        dest="output",
        action="store_true",
        default=False,
        help="Write to standard output",
    )
    parser.add_option(
        "-d",
        "--dir",
        dest="directory",
        action="store",
        default=os.getcwd(),
        help="Directory to write data to",
    )
    parser.add_option(
        "-r",
        "--rrd",
        dest="rrd",
        default=False,
        action="store_true",
        help="Write rrd data",
    )

    (options, args) = parser.parse_args()

    hosts = socket.gethostbyaddr(socket.gethostname())[1]
    my_host = hosts[0]

    lock_file = "/var/tmp/slurm_node_xml.lck"
    if os.path.exists(lock_file):
        print("Previous lock file ({0}) exists !".format(lock_file))
        sys.exit()
    else:
        open(lock_file, "w").close()

    rrd = ""
    if options.rrd:
        rrd = options.directory

    node_file = r"{0}/{1}.xml".format(options.directory, my_host)
    if not options.output:
        stdout_orig = sys.stdout
        sys.stdout = open(node_file, "w")

    now = int(time.time())
    sys.stdout.write('<?xml version="1.0" encoding="iso-8859-1" ?>\n')
    sys.stdout.write("<node>\n")
    sys.stdout.write("\t<name>{0}</name>\n".format(my_host))
    sys.stdout.write("\t<lastUpdate>{0}</lastUpdate>\n".format(now))

    Average = loadavg(my_host, rrd)
    sys.stdout.write(
        "\t<loadAvg>{0},{1},{2}</loadAvg>\n".format(Average[0], Average[1], Average[2])
    )

    Uptime = uptime()
    sys.stdout.write("\t<upTime>{0},{1}</upTime>\n".format(Uptime[0], Uptime[1]))

    Memory = meminfo()
    sys.stdout.write("\t<memTotal>{0}</memTotal>\n".format(Memory["MemTotal"]))
    sys.stdout.write("\t<memFree>{0}</memFree>\n".format(Memory["MemFree"]))
    sys.stdout.write("\t<cached>{0}</cached>\n".format(Memory["Cached"]))
    sys.stdout.write("\t<buffers>{0}</buffers>\n".format(Memory["Buffers"]))

    a = pyslurm.slurm_load_slurmd_status()
    if a:
        for host, data in a.items():
            sys.stdout.write("\t<slurmd>\n")
            for key, value in data.items():
                sys.stdout.write("\t\t<{0}>{1}</{0}>\n".format(key, value, key))
                sys.stdout.write("\t</slurmd>\n")

    a = pyslurm.job()
    jobs = a.get()

    now = int(time.time())
    PiDs = {}
    for key, value in jobs.items():

        jobid = key
        if value["job_state"] == "RUNNING":
            userid = pwd.getpwuid(value[4])[0]
            nodes = value["alloc_node"].split(",")

            if my_host in nodes:
                PiDs[jobid] = []

            a = os.popen(
                "/bin/ps --noheaders -u {0} -o pid,ppid,size,rss,vsize,pcpu,args".format(
                    userid
                ),
                "r",
            )
            for lines in a:
                line = lines.split()
                command = " ".join(line[6:])
                newline = [
                    line[0],
                    line[1],
                    line[2],
                    line[3],
                    line[4],
                    line[5],
                    command,
                ]
                pid = int(line[0])
                rc, slurm_jobid = pyslurm.slurm_pid2jobid(pid)
                if rc == 0:
                    if slurm_jobid in PiDs:
                        PiDs[slurm_jobid].append(newline)
            a.close()

    if PiDs:
        sys.stdout.write("\t<jobs>\n")
        for job, value in PiDs.items():
            sys.stdout.write("\t\t<job>\n")
            sys.stdout.write("\t\t\t<id>{0}</id>\n".format(job))
            for pid in value:
                sys.stdout.write("\t\t\t<process>\n")
                sys.stdout.write("\t\t\t\t<pid>{0}</pid>\n".format(pid[0]))
                sys.stdout.write("\t\t\t\t<ppid>{0}</ppid>\n".format(pid[1]))
                sys.stdout.write("\t\t\t\t<size>{0}</size>\n".format(pid[2]))
                sys.stdout.write("\t\t\t\t<rss>{0}</rss>\n".format(pid[3]))
                sys.stdout.write("\t\t\t\t<vsize>{0}</vsize>\n".format(pid[4]))
                sys.stdout.write("\t\t\t\t<pcpu>{0}</pcpu>\n".format(pid[5]))
                sys.stdout.write(
                    "\t\t\t\t<args><![CDATA[{0}]]></args>\n".format(pid[6])
                )
                sys.stdout.write("\t\t\t</process>\n")
            sys.stdout.write("\t\t</job>\n")

        sys.stdout.write("\t</jobs>\n")

    sys.stdout.write("</node>\n")
    sys.stdout.flush()

    if not options.output:
        sys.stdout.close()
        sys.stdout = stdout_orig
        os.chmod(node_file, 0o644)

    os.remove(lock_file)
