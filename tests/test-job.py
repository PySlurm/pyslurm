from __future__ import division, print_function

import pyslurm
import subprocess
from types import *

def setup():
    pass


def teardown():
    pass


def test_job_get():
    all_jobs = pyslurm.job().get()
    assert type(all_jobs) is DictType


def test_job_ids():
    all_job_ids = pyslurm.job().ids()
    assert type(all_job_ids) is ListType


def test_job_count():
    all_jobs = pyslurm.job().get()
    all_job_ids = pyslurm.job().ids()
    assert len(all_jobs) == len(all_job_ids)


def test_job_scontrol():
    all_job_ids = pyslurm.job().ids()
    # Make sure job is running first
    test_job = all_job_ids[0]
    #assert type(test_job) is IntType

    test_job_info = pyslurm.job().find_id(str(test_job))[0]
    assert test_job == test_job_info["job_id"]

    scontrol = subprocess.Popen(["scontrol", "-d", "show", "job",
                                str(test_job)],
                                stdout=subprocess.PIPE).communicate()
    scontrol_stdout = scontrol[0].strip().split()
    scontrol_dict = {value.split("=")[0]: value.split("=")[1]
                     for value in scontrol_stdout}

    #'Account': '(null)',
    #'AllocNode:Sid': 'sms:32207',
    assert test_job_info["batch_flag"] == int(scontrol_dict["BatchFlag"])
    assert test_job_info["batch_host"] == scontrol_dict["BatchHost"]
    assert test_job_info["cpus_per_task"] == int(scontrol_dict["CPUs/Task"])
    assert test_job_info["command"] == scontrol_dict["Command"]
    # This is a bool.
    assert test_job_info["contiguous"] == int(scontrol_dict["Contiguous"])
    #'CoreSpec': '*',
    # 'Dependency': '(null)',
    # 'EligibleTime': '2016-03-31T00:25:32',
    # 'EndTime': '2016-04-01T00:25:33',
    # 'ExcNodeList': '(null)',
    assert test_job_info["exit_code"] == scontrol_dict["ExitCode"]
    # 'Features': '(null)',
    # 'Gres': '(null)',
    # 'GroupId': 'giovanni(1002)',
    assert test_job_info["job_id"] == int(scontrol_dict["JobId"])
    assert test_job_info["name"] == scontrol_dict["JobName"]
    assert test_job_info["job_state"] == scontrol_dict["JobState"]
    # 'Licenses': '(null)',
    # 'MinCPUsNode': '1',
    # 'MinMemoryNode': '100M',
    # 'MinTmpDiskNode': '0',     # Missing?
    # 'Network': '(null)',
    assert test_job_info["nice"] == int(scontrol_dict["Nice"])
    # 'NodeList': 'c1',
    # 'NtasksPerN:B:S:C': '0:0:*:*',
    assert test_job_info["num_cpus"] == int(scontrol_dict["NumCPUs"])
    assert test_job_info["num_nodes"] == int(scontrol_dict["NumNodes"])
    assert test_job_info["partition"] == scontrol_dict["Partition"]
    # 'Power': '',
    # 'PreemptTime': 'None',
    assert test_job_info["priority"] == int(scontrol_dict["Priority"])
    # 'QOS': '(null)',
    assert test_job_info["state_reason"] == scontrol_dict["Reason"]
    assert test_job_info["reboot"] == int(scontrol_dict["Reboot"])
    # 'ReqB:S:C:T': '0:0:*:*',
    # 'ReqNodeList': '(null)',
    # This is another bool
    assert test_job_info["requeue"] == int(scontrol_dict["Requeue"])
    # 'Reservation': '(null)',
    assert test_job_info["restart_cnt"] == int(scontrol_dict["Restarts"])
    assert test_job_info["run_time_str"] == scontrol_dict["RunTime"]
    assert test_job_info["sicp_mode"] == int(scontrol_dict["SICP"])
    # 'SecsPreSuspend': '0',
    assert test_job_info["shared"] == scontrol_dict["Shared"] # 'Shared': '0',
    # 'Socks/Node': '*',
    # 'StartTime': '2016-03-31T00:25:33',
    assert test_job_info["std_err"] == scontrol_dict["StdErr"]
    assert test_job_info["std_in"] == scontrol_dict["StdIn"]
    assert test_job_info["std_out"] == scontrol_dict["StdOut"]
    # 'SubmitTime': '2016-03-31T00:25:32',
    # 'SuspendTime': 'None',
    # 'TRES': 'cpu',            # Missing ?
    assert test_job_info["time_limit_str"] == scontrol_dict["TimeLimit"]
    # 'TimeMin': 'N/A',
    # 'UserId': 'giovanni(1002)',
    assert test_job_info["work_dir"] == scontrol_dict["WorkDir"]
