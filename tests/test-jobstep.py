from __future__ import absolute_import, unicode_literals

import pyslurm
import subprocess
from nose.tools import assert_equals, assert_true

#def test_get_jobstep():
#    """Jobstep: Test get_jobstep() return type"""
##    all_jobstep_ids = pyslurm.jobstep.get_jobsteps(ids=True)
##    assert_true(isinstance(all_jobstep_ids, list))
#
##    test_jobstep = all_jobstep_ids[0]
#    test_jobstep_obj = pyslurm.jobstep.get_jobstep(test_jobstep)
#    assert_true(isinstance(test_jobstep_obj, pyslurm.jobstep.Jobstep))


#def test_get_jobsteps():
#    """Jobstep: Test get_jobsteps() and type."""
#    all_jobsteps = pyslurm.jobstep.get_jobsteps()
#    assert_true(isinstance(all_jobsteps, list))
#
##    all_jobstep_ids = pyslurm.jobstep.get_jobsteps(ids=True)
##    assert_true(isinstance(all_jobstep_ids, list))
#
#    # Jobsteps can come and go quickly!
##    assert_equals(len(all_jobsteps), len(all_jobstep_ids))
#
#    first_jobstep = all_jobsteps[0]
#    assert_true(first_jobstep.jobstep_id in all_jobstep_ids)


def test_jobstep_scontrol():
    """Jobstep: Compare scontrol values to PySlurm values."""
#    try:
#        basestring
#    except NameError:
#        basestring = str

#    all_jobstep_ids = pyslurm.jobstep.get_jobsteps(ids=True)
    # TODO: 
    # convert to a function and  use a for loop to get a running jobstep and a
    # drained/downed jobstep as well, mixed and allocated
    # and a non-existent jobstep
#    test_jobstep = all_jobstep_ids[0]
#    assert_equals(isinstance(test_jobstep, basestring)

#    obj = pyslurm.jobstep.get_jobstep(test_jobstep)
#    assert_equals(test_jobstep, obj.jobstep_id)
    obj = pyslurm.jobstep.get_jobsteps()[0]

    scontrol = subprocess.Popen(
        ["scontrol", "-ddo", "show", "step", obj.step_id],
        stdout=subprocess.PIPE
    ).communicate()

    scontrol_stdout = scontrol[0].strip().decode("UTF-8", "replace").split()

    # Convert scontrol show jobstep <jobstep> into a dictionary of key value pairs.
    sctl = {}
    for item in scontrol_stdout:
        kv = item.split("=", 1)
        if kv[1] in ["None", "(null)"]:
            sctl.update({kv[0]: None})
        elif kv[1].isdigit():
            sctl.update({kv[0]: int(kv[1])})
        else:
            sctl.update({kv[0]: kv[1]})

    assert_equals(obj.checkpoint, sctl.get("Checkpoint"))
    assert_equals(obj.checkpoint_dir, sctl.get("CheckpointDir"))
#    assert_equals(obj.cpu_freq_req, sctl.get("cpu_freq_req"))
    assert_equals(obj.cpus, sctl.get("CPUs"))
    assert_equals(obj.dist, sctl.get("Dist"))
    assert_equals(obj.gres, sctl.get("Gres"))
    assert_equals(obj.name, sctl.get("Name"))
    assert_equals(obj.network, sctl.get("Network"))
    assert_equals(obj.node_list, sctl.get("NodeList"))
#    assert_equals(obj.nodes, sctl.get("Nodes"))
    assert_equals(obj.partition, sctl.get("Partition"))
    assert_equals(obj.resv_ports, sctl.get("ResvPorts"))
    assert_equals(obj.start_time_str, sctl.get("StartTime"))
    assert_equals(obj.state, sctl.get("State"))
    assert_equals(obj.step_id, sctl.get("StepId"))
    assert_equals(obj.tasks, sctl.get("Tasks"))
    assert_equals(obj.time_limit, sctl.get("TimeLimit"))
    assert_equals(obj.tres, sctl.get("TRES"))
    assert_equals(obj.user_id, sctl.get("UserId"))
