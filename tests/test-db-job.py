from __future__ import division, print_function

import pyslurm
import subprocess
import json
import time as p_time
from random import randint
from types import *
from nose.tools import assert_equals, assert_true

from  slurmdb_util import *


def setup():
    pass


def teardown():
    pass


def test_job_get():
    """Job: Test slurmdb_jobs().get() return type."""
    all_jobs = pyslurm.slurmdb_jobs().get()
    assert_true(isinstance(all_jobs, dict))


def test_job_ids():
    """Job: Test slurmdb_jobs().get().keys() return type."""
    all_job_ids = pyslurm.slurmdb_jobs().get().keys()
    assert type(all_job_ids) is ListType
    assert_true(isinstance(all_job_ids, list))


def test_job_count():
    """Job: Test slurmdb_jobs count."""
    all_jobs = pyslurm.slurmdb_jobs().get()
    all_job_ids = pyslurm.slurmdb_jobs().get().keys()
    assert_equals(len(all_jobs), len(all_job_ids))

def test_job_sacct():
    """Job: Compare sacct values to Pyslurm slurmdb_jobs values."""
    # see sacct/print.c as reference
    temp = 0
    all_job_ids = pyslurm.slurmdb_jobs().get().keys()
    job_id = all_job_ids[randint(0, len(all_job_ids) - 1)] 
#    job_id = 4422
#    job_id = 5199
    print("  ---> selected job_id : ", job_id)
    job_info = pyslurm.slurmdb_jobs().get([job_id]).values()[0]
    print("  ---> job_info : ", json.dumps(job_info, indent = 18))
    
    # execute sacct cmd

    options = "AllocCPUS, AllocGRES, AllocNodes, AllocTRES, Account, AssocID, AveCPU,  AveCPUFreq, " \
              "AveDiskRead, AveDiskWrite, AvePages, AveRSS, AveVMSize, BlockID, Cluster, Comment, " \
              "ConsumedEnergyRaw, CPUTime, CPUTimeRAW, DerivedExitCode, Elapsed, " \
              "Eligible, End, ExitCode, GID, JobID, JobIDRaw, JobName, Layout, MaxDiskRead, " \
              "MaxDiskReadNode, MaxDiskReadTask, MaxDiskWrite, MaxDiskWriteNode, MaxDiskWriteTask, " \
              "MaxPages, MaxPagesNode, MaxPagesTask, MaxRSS, MaxRSSNode, MaxRSSTask, MaxVMSize, " \
              "MaxVMSizeNode, MaxVMSizeTask, MinCPU, MinCPUNode, MinCPUTask, NNodes, NodeList, " \
              "NTasks, Priority, Partition, QOSRAW, ReqCPUFreq, ReqCPUFreqMin, ReqCPUFreqMax, ReqCPUFreqGov, " \
              "ReqCPUS, ReqGRES, ReqMem, ReqNodes, ReqTRES, Reservation, ReservationId, Reserved, " \
              "ResvCPU, ResvCPURAW, Start, State, Submit, Suspended, SystemCPU, Timelimit, TotalCPU, " \
              "UID, User, UserCPU, WCKey, WCKeyID"
##    'account'
##    'allocated_gres'
##    'allocated_nodes'
#    'array_job_id'
#    'array_max_tasks'
#    'array_task_id'
#    'array_task_str'
##    'associd'
##    'blockid'
##    'cluster'
##    'derived_ec'
##    'derived_es'
##    'elapsed'
##    'eligible'
##    'end'
##    'exit_code'
##    'gid'
##    'jobid'
##    'jobname'
#    'lft'
##    'partition'
##    'nodes'
##    'priority'
##    'qosid'
##    'req_cpus'
##    'req_gres'
## ?    'req_mem'
##    'requid'       # if state = 'CANCELLED' give the uid of requestor
##    'resvid'
##    'resv_name'
##    'start'
##    'state'
#    'steps'
#    'stat_actual_cpufreq'
##    'stat_cpu_ave'
##    'stat_consumed_energy'
##    'stat_cpu_min'
##    'stat_cpu_min_taskid'
##    'stat_disk_read_ave'
##    'stat_disk_read_max'
##    'stat_cpu_min_node'
##    'stat_disk_read_max_node'
##    'stat_disk_write_max_node'
##    'stat_pages_max_node'
##    'stat_rss_max_node'
##    'stat_vsize_max_node'
##    'stat_disk_read_max_taskid'
##    'stat_disk_write_ave'
##    'stat_disk_write_max'
##    'stat_disk_write_max_taskid'
##    'stat_pages_ave'
##    'stat_pages_max'
##    'stat_pages_max_taskid'
##    'stat_rss_ave'
##    'stat_rss_max'
##    'stat_rss_max_taskid'
##    'stat_vsize_ave'
##    'stat_vsize_max'
##    'stat_vsize_max_taskid'
##    'submit'
##    'suspended'
##    'sys_cpu_sec'
##    'sys_cpu_usec'
##    'timelimit'
##    'tot_cpu_sec'
##    'tot_cpu_usec'
#    'track_steps'
##    'tres_alloc_str'
##    'tres_req_str'
##    'uid'
#    'used_gres'
##    'user'
##    'user_cpu_sec'
##    'user_cpu_usec'
##    'wckey'
##    'wckeyid'

    cmd = "sacct -lp -j " + str(job_id) +" -o " + options
    sacct = subprocess.Popen(["sacct", "-l", "-p", "-j", str(job_id), "-o", options],
                             stdout=subprocess.PIPE).communicate()
    sacct_stdout = sacct[0].split("|")
    i = 0
    sacct_dict = {}
    lg = (len(sacct_stdout) - 1)
    mid = int(lg / 2)
    while (i < mid):
        sacct_dict[sacct_stdout[i]] = sacct_stdout[mid + i]
        i += 1
    print(" sacct: ", json.dumps(sacct_dict, indent=18))

    if job_info['state'] == 'PENDING' or job_info['state'] == 'CANCELLED' or job_info['state'] == 'FAILED':
        pass
    else:
        assert_equals(tres_to_resource(job_info["tres_alloc_str"], 'cpu'), sacct_dict["AllocCPUS"])
        assert_equals(tres_to_resource(job_info["tres_alloc_str"], 'gres/gpu'), sacct_dict["AllocGRES"])
        assert_equals(tres_to_resource(job_info["tres_alloc_str"], 'node'), str(sacct_dict["AllocNodes"]))
        assert_equals(convert_tres_str(job_info["tres_alloc_str"]), sacct_dict["AllocTRES"])
    if len(sacct_dict["Account"]) > 0 :
        assert_equals(job_info["account"], sacct_dict["Account"])
    assert_equals(job_info["associd"], int(sacct_dict["AssocID"]))
    if job_info['stat_cpu_ave'] == 0 and len(sacct_dict["AveCPU"]) == 0:
        assert_equals(sacct_dict["AveCPU"], '')
    else :
        assert_equals(cpu_elapsed_time(job_info["stat_cpu_ave"], 0), sacct_dict["AveCPU"])
    # check 'AveCPUFreq'
    if sacct_dict["AveDiskRead"] == '':
        sacct_dict["AveDiskRead"] = 0
    assert_equals("{:.1f}".format(float(job_info["stat_disk_read_ave"])), "{:.1f}".format(float(sacct_dict["AveDiskRead"])))
    if sacct_dict["AveDiskWrite"] == '':
        sacct_dict["AveDiskWrite"] = '0M'
    assert_equals("{:.1f}".format(float(job_info['stat_disk_write_ave'])), "{:.1f}".format(float(sacct_dict["AveDiskWrite"][:-1])))
    assert_equals("{:.1f}".format(float(job_info["stat_pages_ave"])), "{:.1f}".format(float(sacct_dict["AvePages"])))
    if  len(sacct_dict["AveRSS"]) > 0 :
        assert_equals(job_info["stat_rss_ave"], sacct_dict["AveRSS"])
    if  len(sacct_dict["AveVMSize"]) > 0 :
        assert_equals(job_info["stat_vsize_ave"], sacct_dict["AveVMSize"])
    if len(sacct_dict["BlockID"]) :
        assert_equals(job_info["blockid"], sacct_dict["BlockID"])
    assert_equals(job_info["cluster"], sacct_dict["Cluster"])
    if len(sacct_dict["Comment"]) > 0 :
        assert_equals(job_info["derived_es"], sacct_dict["Comment"])
    if len(sacct_dict["ConsumedEnergyRaw"]) > 0 and sacct_dict["ConsumedEnergyRaw"] != '0' :
        assert_equals(job_info["stat_consumed_energy"], float(sacct_dict["ConsumedEnergyRaw"]))
    # check 'CPUTime'
    # check 'CPUTimeRAW'
    assert job_info["derived_ec"] == sacct_dict["DerivedExitCode"]
    assert_equals(secs2time_str(job_info["elapsed"]), sacct_dict["Elapsed"]) 
    assert_equals( p_time.strftime('%Y-%m-%dT%H:%M:%S', p_time.localtime(float(job_info["eligible"]))), sacct_dict["Eligible"] )
    if float(job_info["end"]) > 0 :
        assert_equals( p_time.strftime('%Y-%m-%dT%H:%M:%S', p_time.localtime(float(job_info["end"]))), sacct_dict["End"] )
    assert job_info["exit_code"] == sacct_dict["ExitCode"]
    assert_equals(str(job_info["gid"]), sacct_dict["GID"]) 
    assert_equals(str(job_info["jobid"]), sacct_dict["JobID"]) 
    assert_equals(str(job_info["jobid"]), sacct_dict["JobIDRaw"]) 
    assert_equals(job_info["jobname"], sacct_dict["JobName"]) 
    # check 'Layout'
    assert_equals(":.1f".format(float(job_info["stat_disk_read_max"])), ":.1f".format(float(sacct_dict["MaxDiskRead"])))
    if len(sacct_dict["MaxDiskReadNode"]) > 0 :
        assert_equals(job_info["stat_disk_read_max_node"], sacct_dict["MaxDiskReadNode"]) 
    if len(sacct_dict["MaxDiskReadTask"]) > 0 :
        assert_equals(job_info["stat_disk_read_max_taskid"], int(sacct_dict["MaxDiskReadTask"]))
    assert_equals(":.1f".format(float(job_info["stat_disk_read_max"])), ":.1f".format(float(sacct_dict["MaxDiskRead"])))
    if len(sacct_dict["MaxDiskWriteNode"]) > 0 :
        assert_equals(job_info["stat_disk_write_max_node"], sacct_dict["MaxDiskWriteNode"]) 
    if len(sacct_dict["MaxDiskWriteTask"]) > 0 :
        assert_equals(job_info["stat_disk_write_max_taskid"], int(sacct_dict["MaxDiskWriteTask"]))
    if len(sacct_dict["MaxPages"]) > 0 :
        assert_equals(int(job_info["stat_pages_max"]), int(sacct_dict["MaxPages"]))
    if len(sacct_dict["MaxPagesNode"]) > 0 :
        assert_equals(job_info["stat_pages_max_node"], sacct_dict["MaxPagesNode"]) 
    if len(sacct_dict["MaxPagesTask"]) > 0 :
         assert_equals(job_info["stat_pages_max_taskid"], int(sacct_dict["MaxPagesTask"]))
    if len(sacct_dict["MaxRSS"]) > 0 :
        assert_equals(job_info["stat_rss_max"], sacct_dict["MaxRSS"])
    if len(sacct_dict["MaxRSSNode"]) > 0 :
        assert_equals(job_info["stat_rss_max_node"], sacct_dict["MaxRSSNode"]) 
    if len(sacct_dict["MaxRSSTask"]) > 0 :
        assert_equals(job_info["stat_rss_max_taskid"], int(sacct_dict["MaxRSSTask"]))
    if len(sacct_dict["MaxVMSize"]) > 0 :
        assert_equals(job_info["stat_vsize_max"], sacct_dict["MaxVMSize"])
    if len(sacct_dict["MaxVMSizeNode"]) > 0 :
        assert_equals(job_info["stat_vsize_max_node"], sacct_dict["MaxVMSizeNode"]) 
    if len(sacct_dict["MaxVMSizeTask"]) > 0 :
        assert_equals(job_info["stat_vsize_max_taskid"], int(sacct_dict["MaxVMSizeTask"]))
    if len(sacct_dict["MinCPU"]) > 0 :
        assert_equals( p_time.strftime('%H:%M:%S', p_time.gmtime(float(job_info["stat_cpu_min"]))), sacct_dict["MinCPU"] )
    assert job_info["stat_cpu_min_node"] == sacct_dict["MinCPUNode"]
    if len(sacct_dict["MinCPUTask"]) > 0 :
        assert_equals(job_info["stat_cpu_min_taskid"], int(sacct_dict["MinCPUTask"]))
    # check 'NNodes'
    assert_equals(job_info["nodes"], sacct_dict["NodeList"])
    # check 'NTasks'
    assert_equals(job_info["priority"], int(sacct_dict["Priority"]))
    assert_equals(job_info["partition"], sacct_dict["Partition"])
    assert_equals(job_info["qosid"], int(sacct_dict["QOSRAW"]))
    # check 'ReqCPUFreq'
    # check 'ReqCPUFreqMin'
    # check 'ReqCPUFreqMax'
    # check 'ReqCPUFreqGov'
    assert_equals(job_info["req_cpus"], int(sacct_dict["ReqCPUS"]))
    assert_equals(job_info["req_gres"], sacct_dict["ReqGRES"])
    # check 'ReqMem'
    assert_equals(convert_tres_str(job_info["tres_req_str"]), sacct_dict["ReqTRES"])
    assert job_info["resv_name"] == sacct_dict["Reservation"]
    assert_equals(job_info["resvid"], sacct_dict["ReservationId"])
    # check 'Reserved'
    # check 'ResvCPU'
    # check 'ResvCPURAW'
    # check 'Start'
    assert_equals(p_time.strftime('%Y-%m-%dT%H:%M:%S', p_time.localtime(float(job_info["start"]))), sacct_dict["Start"])
    if job_info["state"] == "CANCELLED" :
        msg = "CANCELLED by " + str(job_info["requid"])
        assert_equals(msg, sacct_dict["State"])
    else:
        assert_equals(job_info["state"], sacct_dict["State"])
    assert_equals(p_time.strftime('%Y-%m-%dT%H:%M:%S', p_time.localtime(job_info["submit"])), sacct_dict["Submit"])
    assert_equals(p_time.strftime("%H:%M:%S", p_time.gmtime((int(job_info["suspended"])))), sacct_dict["Suspended"])
    if sacct_dict["SystemCPU"] == '' :
        assert_equals(cpu_elapsed_time(job_info["sys_cpu_sec"], job_info["sys_cpu_usec"]), "00:00:00")
    else :
        assert_equals(cpu_elapsed_time(job_info["sys_cpu_sec"], job_info["sys_cpu_usec"]), sacct_dict["SystemCPU"])
    assert_equals(job_info["timelimit"], sacct_dict["Timelimit"])
    assert_equals(cpu_elapsed_time(job_info["tot_cpu_sec"], job_info["tot_cpu_usec"]), sacct_dict["TotalCPU"])
    assert_equals(int(job_info["uid"]), int(sacct_dict["UID"]))
    assert_equals(job_info["user"], sacct_dict["User"])
    if sacct_dict["UserCPU"] == '' :
        assert_equals(cpu_elapsed_time(job_info["user_cpu_sec"], job_info["user_cpu_usec"]), "00:00:00")
    else :
        assert_equals(cpu_elapsed_time(job_info["user_cpu_sec"], job_info["user_cpu_usec"]), sacct_dict["UserCPU"])
    assert_equals(job_info["wckey"], sacct_dict["WCKey"])
    assert_equals(int(job_info["wckeyid"]), int(sacct_dict["WCKeyID"]))

                  

def cpu_elapsed_time(secs, usecs) :
    NO_VAL = 0xfffffffe
    subsec = 0
    if secs < 0 or secs == NO_VAL :
        return None
    while usecs >= 1000000 :
        secs += 1
        usecs -= 1000000
    if usecs > 0 :
        #/* give me 3 significant digits to tack onto the sec */
        subsec = int(usecs / 1000)
    seconds = int(secs) % 60
    minutes = int(secs / 60)   % 60
    hours   = int(secs / 3600) % 24
    days    = int(secs / 86400)

    if days > 0 :
        str = "{}-{:02}:{:02}:{:02}.{:03}".format(days, hours,minutes, seconds, subsec)
    elif hours > 0 :
        str = "{:02}:{:02}:{:02}.{:03}".format(hours,minutes, seconds, subsec)
    elif subsec > 0 :
        str = "{:02}:{:02}.{:03}".format(minutes, seconds, subsec)
    else:
        str = "00:{:02}:{:02}".format(minutes, seconds)
    return str;


def secs2time_str(time):
    u"""Convert seconds to Slurm string format.

    This method converts time in seconds (86400) to Slurm's string format
    (1-00:00:00).

    :param int time: time in seconds
    :returns: time string
    :rtype: `str`
    """
    INFINITE = 0xffffffff
    if time == INFINITE:
        time_str = "UNLIMITED"
    else:
        seconds = int(time) % 60
        minutes = int(time / 60) % 60
        hours =   int(time / 3600) % 24
        days =    int(time / 86400)

        if days < 0 or  hours < 0 or minutes < 0 or seconds < 0:
            time_str = "INVALID"
        elif days:
            return u"%ld-%2.2ld:%2.2ld:%2.2ld" % (days, hours,
                                                  minutes, seconds)
        else:
            return u"%2.2ld:%2.2ld:%2.2ld" % (hours, minutes, seconds)
