from __future__ import absolute_import, unicode_literals

import pyslurm
import subprocess
from nose.tools import assert_equals, assert_true

def test_get_job():
    """Job: Test get_job() return type"""
    all_job_ids = pyslurm.job.get_jobs(ids=True)
    assert_true(isinstance(all_job_ids, list))

    test_job = all_job_ids[0]
    test_job_obj = pyslurm.job.get_job(test_job)
    assert_true(isinstance(test_job_obj, pyslurm.job.Job))


def test_get_jobs():
    """Job: Test get_jobs() and type."""
    all_jobs = pyslurm.job.get_jobs()
    assert_true(isinstance(all_jobs, list))

    all_job_ids = pyslurm.job.get_jobs(ids=True)
    assert_true(isinstance(all_job_ids, list))

    # Jobs can come and go quickly!
#    assert_equals(len(all_jobs), len(all_job_ids))

    first_job = all_jobs[0]
    assert_true(first_job.job_id in all_job_ids)


def test_job_scontrol():
    """Job: Compare scontrol values to PySlurm values."""
#    try:
#        basestring
#    except NameError:
#        basestring = str

    all_job_ids = pyslurm.job.get_jobs(ids=True)
    # TODO: 
    # convert to a function and  use a for loop to get a running job and a
    # drained/downed job as well, mixed and allocated
    # and a non-existent job
    test_job = all_job_ids[0]
#    assert_equals(isinstance(test_job, basestring)

    obj = pyslurm.job.get_job(test_job)
    assert_equals(test_job, obj.job_id)

    scontrol = subprocess.Popen(
        ["scontrol", "-ddo", "show", "job", str(test_job)],
        stdout=subprocess.PIPE
    ).communicate()

    scontrol_stdout = scontrol[0].strip().decode("UTF-8", "replace").split()

    # Convert scontrol show job <job> into a dictionary of key value pairs.
    sctl = {}
    for item in scontrol_stdout:
        kv = item.split("=", 1)
        if kv[1] in ["None", "(null)"]:
            sctl.update({kv[0]: None})
        elif kv[1].isdigit():
            sctl.update({kv[0]: int(kv[1])})
        else:
            sctl.update({kv[0]: kv[1]})

    # TODO: change all dict queries to .get()
    assert_equals(obj.account, sctl["Account"])
    assert_equals(obj.alloc_node + ":" + str(obj.alloc_sid) , sctl["AllocNode:Sid"])
    assert_equals(obj.batch_flag, sctl["BatchFlag"])
    assert_equals(obj.batch_host, sctl["BatchHost"])
    assert_equals(obj.command, sctl["Command"])
    assert_equals(obj.contiguous, sctl["Contiguous"])
    assert_equals(obj.core_spec, sctl.get("CoreSpec"))
    # FIXME
    #assert_equals(obj.core_spec, sctl.get("ThreadSpec"))
    assert_equals(obj.cpus_per_task, sctl["CPUs/Task"])
    assert_equals(obj.dependency, sctl["Dependency"])
    assert_equals(obj.eligible_time_str, sctl["EligibleTime"])
    assert_equals(obj.end_time_str, sctl["EndTime"])
    assert_equals(obj.exc_node_list, sctl.get("ExcNodeList"))
    assert_equals(obj.exc_midplane_list, sctl.get("ExcMidplaneList"))
    # FIXME
#    assert_equals(obj.exit_code, sctl["ExitCode"])
    assert_equals(obj.features, sctl.get("Features"))
    assert_equals(obj.gres, sctl.get("gres"))
    assert_equals(obj.group_name + "(" + str(obj.group_id) + ")", sctl["GroupId"])
    assert_equals(obj.job_id, sctl["JobId"])
    assert_equals(obj.job_name, sctl["JobName"])
    assert_equals(obj.job_state, sctl["JobState"])
    assert_equals(obj.licenses, sctl.get("Licenses"))
    assert_equals(obj.min_cpus_node, sctl.get("MinCPUsNode"))

    if obj.mem_per_cpu:
        assert "MinMemoryCPU" in sctl.keys()

    if obj.mem_per_node:
        assert "MinMemoryNode" in sctl.keys()

    assert_equals(obj.min_memory_cpu, sctl.get("MinMemoryCPU"))
    assert_equals(obj.min_memory_node, sctl.get("MinMemoryNode"))
    assert_equals(obj.min_tmp_disk_node, sctl.get("MinTmpDiskNode"))
    assert_equals(obj.network, sctl.get("Network"))
    assert_equals(obj.nice, sctl.get("Nice"))
    assert_equals(obj.node_list, sctl.get("NodeList"))
    assert_equals(
        str(obj.ntasks_per_node) + ":" + str(obj.ntasks_per_board) + ":" +
        str(obj.ntasks_per_socket) + ":" + str(obj.ntasks_per_core),
        sctl.get("NtasksPerN:B:S:C")
    )
    assert_equals(obj.num_cpus, sctl.get("NumCPUs"))
    assert_equals(obj.num_nodes, sctl.get("NumNodes"))
    assert_equals(obj.num_tasks, sctl.get("NumTasks"))
    assert_equals(obj.partition, sctl.get("Partition"))
    assert_equals(obj.power, sctl.get("Power"))
    assert_equals(obj.preempt_time_str, sctl.get("PreemptTime", "None"))
    assert_equals(obj.priority, sctl.get("Priority"))
    assert_equals(obj.qos, sctl.get("QOS"))
    assert_equals(obj.reason, sctl.get("Reason"))
    assert_equals(obj.reboot, sctl.get("Reboot"))
    assert_equals(
        str(obj.boards_per_node) + ":" + str(obj.sockets_per_board) + ":" +
        str(obj.cores_per_socket) + ":" + str(obj.threads_per_core),
        sctl.get("ReqB:S:C:T")
    )
    assert_equals(obj.req_node_list, sctl.get("ReqNodeList"))
    assert_equals(obj.req_midplane_list, sctl.get("ReqMidplaneList"))
    assert_equals(obj.requeue, sctl.get("Requeue"))
    assert_equals(obj.reservation, sctl.get("Reservation"))
    assert_equals(obj.restarts, sctl.get("Restarts"))
    # Run times can be off by a second or two if this function doesn't execute
    # quickly
#    assert_equals(obj.run_time_str, sctl.get("RunTime"))
    assert_equals(obj.secs_pre_suspend, sctl.get("SecsPreSuspend"))
    assert_equals(obj.over_subscribe, sctl.get("OverSubscribe"))
    assert_equals(obj.socks_per_node, sctl.get("Socks/Node"))
    assert_equals(obj.start_time_str, sctl.get("StartTime"))
    assert_equals(obj.std_err, sctl.get("StdErr"))
    assert_equals(obj.std_in, sctl.get("StdIn"))
    assert_equals(obj.std_out, sctl.get("StdOut"))
    assert_equals(obj.submit_time_str, sctl.get("SubmitTime"))
    assert_equals(obj.suspend_time_str, sctl.get("SuspendTime"))
    assert_equals(obj.time_limit_str, sctl.get("TimeLimit"))
    assert_equals(obj.time_min_str, sctl.get("TimeMin"))
    assert_equals(obj.tres, sctl.get("TRES"))
    assert_equals(obj.user_name + "(" + str(obj.user_id) + ")", sctl.get("UserId"))
    assert_equals(obj.work_dir, sctl.get("WorkDir"))
