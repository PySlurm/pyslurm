#!/usr/bin/env python
"""
Display Slurm node information in XML
"""

import argparse
import os
import os.path
import pwd
import re
import socket
import sys
import time

import pyslurm

re_meminfo_parser = re.compile(r"^(?P<key>\S*):\s*(?P<value>\d*)\s*kB")
stdout_orig = sys.stdout


def loadavg(load_host, rrd=""):
    """Get Slurm load average"""
    load_proc = "/proc/loadavg"
    load_rrd = f"{rrd}/{load_host}_loadavg.rrd"

    try:
        load_data = open(load_proc, "r", encoding="latin-1").readline().strip()
    except IOError:
        return (-1, -1, -1, -1, -1)

    load_data = load_data.split()

    avg1min, avg5min, avg15min = map(float, load_data[:3])
    running, total = map(int, load_data[3].split("/"))

    if rrd != "":
        if not os.path.exists(load_rrd):
            os.system(
                f"/usr/bin/rrdtool create {load_rrd} --step 60 \
                    DS:loadl1:GAUGE:120:0:U \
                    DS:loadl5:GAUGE:120:0:U \
                    DS:loadl15:GAUGE:120:0:U \
                    RRA:AVERAGE:0.5:1:2160 \
                    RRA:AVERAGE:0.5:5:2016 \
                    RRA:AVERAGE:0.5:15:2880 \
                    RRA:AVERAGE:0.5:60:8760"
            )

        os.system(
            f"/usr/bin/rrdtool update {load_rrd} N:{avg1min}:{avg5min}:{avg15min}"
        )

    return avg1min, avg5min, avg15min, running, total


def uptime():
    """Get Slurm uptime"""
    uptime_proc = "/proc/uptime"

    try:
        uptime_val = open(uptime_proc, "r", encoding="latin-1").readline().strip()
    except IOError:
        return (-1, -1)

    uptime_val = uptime_val.split()

    return uptime_val


def meminfo():
    """Get Slurm memory information"""
    result = {}
    meminfo_proc = "/proc/meminfo"

    try:
        meminfo_val = open(meminfo_proc, "r", encoding="latin-1").readlines()
    except IOError:
        return result

    for values in meminfo_val:
        match = re_meminfo_parser.match(values)
        if not match:
            continue
        mem_key, mem_value = match.groups(["key", "value"])
        result[mem_key] = int(mem_value)

    return result


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Slurm Node XML Output")
    parser.add_argument(
        "-o",
        "--stdout",
        dest="output",
        action="store_true",
        default=False,
        help="Write to standard output",
    )
    parser.add_argument(
        "-d",
        "--dir",
        dest="directory",
        action="store",
        default=os.getcwd(),
        help="Directory to write data to",
    )
    parser.add_argument(
        "-r",
        "--rrd",
        dest="rrd",
        action="store_true",
        default=False,
        help="Write rrd data",
    )
    options = parser.parse_args()

    hosts = socket.gethostbyaddr(socket.gethostname())
    my_host = hosts[0]

    LOCK_FILE = "/var/tmp/slurm_node_xml.lck"
    if os.path.exists(LOCK_FILE):
        print(f"Previous lock file ({LOCK_FILE}) exists !")
        sys.exit()
    else:
        open(LOCK_FILE, "w", encoding="latin-1").close()

    RRD = ""
    if options.rrd:
        RRD = options.directory

    node_file = f"{options.directory}/{my_host}.xml"
    if not options.output:
        stdout_orig = sys.stdout
        sys.stdout = open(node_file, "w", encoding="iso-8859-1")

    now = int(time.time())
    sys.stdout.write('<?xml version="1.0" encoding="iso-8859-1" ?>\n')
    sys.stdout.write("<node>\n")
    sys.stdout.write(f"\t<name>{my_host}</name>\n")
    sys.stdout.write("\t<lastUpdate>{now}</lastUpdate>\n")

    Average = loadavg(my_host, RRD)
    sys.stdout.write(f"\t<loadAvg>{Average[0]},{Average[1]},{Average[2]}</loadAvg>\n")

    Uptime = uptime()
    sys.stdout.write(f"\t<upTime>{Uptime[0]},{Uptime[1]}</upTime>\n")

    Memory = meminfo()
    sys.stdout.write(f"\t<memTotal>{Memory['MemTotal']}</memTotal>\n")
    sys.stdout.write(f"\t<memFree>{Memory['MemFree']}</memFree>\n")
    sys.stdout.write(f"\t<cached>{Memory['Cached']}</cached>\n")
    sys.stdout.write(f"\t<buffers>{Memory['Buffers']}</buffers>\n")

    a = pyslurm.slurm_load_slurmd_status()
    if a:
        for host, data in a.items():
            sys.stdout.write("\t<slurmd>\n")
            for key, value in data.items():
                sys.stdout.write(f"\t\t<{key}>{value}</{key}>\n")
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
                f"/bin/ps --noheaders -u {userid} -o pid,ppid,size,rss,vsize,pcpu,args",
                "r",
            )
            for lines in a:
                line = lines.split()
                COMMAND = " ".join(line[6:])
                newline = [
                    line[0],
                    line[1],
                    line[2],
                    line[3],
                    line[4],
                    line[5],
                    COMMAND,
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
            sys.stdout.write(f"\t\t\t<id>{job}</id>\n")
            for pid in value:
                sys.stdout.write("\t\t\t<process>\n")
                sys.stdout.write(f"\t\t\t\t<pid>{pid[0]}</pid>\n")
                sys.stdout.write(f"\t\t\t\t<ppid>{pid[1]}</ppid>\n")
                sys.stdout.write(f"\t\t\t\t<size>{pid[2]}</size>\n")
                sys.stdout.write(f"\t\t\t\t<rss>{pid[3]}</rss>\n")
                sys.stdout.write(f"\t\t\t\t<vsize>{pid[4]}</vsize>\n")
                sys.stdout.write(f"\t\t\t\t<pcpu>{pid[5]}</pcpu>\n")
                sys.stdout.write(f"\t\t\t\t<args><![CDATA[{pid[6]}]]></args>\n")
                sys.stdout.write("\t\t\t</process>\n")
            sys.stdout.write("\t\t</job>\n")

        sys.stdout.write("\t</jobs>\n")

    sys.stdout.write("</node>\n")
    sys.stdout.flush()

    if not options.output:
        sys.stdout.close()
        sys.stdout = stdout_orig
        os.chmod(node_file, 0o644)

    os.remove(LOCK_FILE)
