from __future__ import absolute_import, unicode_literals

import pyslurm
import subprocess
from nose.tools import assert_equals, assert_true

from common import scontrol_show

def test_config_get():
    """Config: Test config().get() return type."""
    config_info = pyslurm.config().get()
    assert_true(isinstance(config_info, dict))


def test_config_key_pairs():
    """Config: Test config().key_pairs() function and return type."""
    config_key_pairs = pyslurm.config().key_pairs()
    assert_true(isinstance(config_key_pairs, dict))


def test_config_scontrol():
    """Config: Compare scontrol values to PySlurm values."""
    config_info = pyslurm.config().get()

    sctl = subprocess.Popen(["scontrol", "-d", "show", "config"],
                            stdout=subprocess.PIPE).communicate()
    sctl_stdout = sctl[0].strip().decode("UTF-8").split("\n")
    sctl_dict = dict(
        (item.split("=", 1)[0].strip(), item.split("=", 1)[1].strip())
        for item in sctl_stdout
        if "=" in item
    )

    assert_equals(config_info["accounting_storage_host"], sctl_dict["AccountingStorageHost"])
    assert_equals(config_info["accounting_storage_port"], int(sctl_dict["AccountingStoragePort"]))
    assert_equals(config_info["accounting_storage_type"], sctl_dict["AccountingStorageType"])
    assert_equals(config_info["accounting_storage_tres"], sctl_dict["AccountingStorageTRES"])
    assert_equals(config_info["accounting_storage_user"], sctl_dict["AccountingStorageUser"])
    assert_equals(config_info["acct_gather_energy_type"], sctl_dict["AcctGatherEnergyType"])
    assert_equals(config_info["acct_gather_filesystem_type"], sctl_dict["AcctGatherFilesystemType"])

    assert_equals(
        config_info["acct_gather_interconnect_type"], sctl_dict["AcctGatherInterconnectType"]
    )

    assert_equals(config_info["acct_gather_profile_type"], sctl_dict["AcctGatherProfileType"])
    assert_equals(config_info["authtype"], sctl_dict["AuthType"])
    assert_equals(config_info["checkpoint_type"], sctl_dict["CheckpointType"])
    assert_equals(config_info["cluster_name"], sctl_dict["ClusterName"])
    assert_equals(config_info["core_spec_plugin"], sctl_dict["CoreSpecPlugin"])
    assert_equals(config_info["ext_sensors_type"], sctl_dict["ExtSensorsType"])
    assert_equals(config_info["first_job_id"], int(sctl_dict["FirstJobId"]))
    assert_equals(config_info["job_acct_gather_type"], sctl_dict["JobAcctGatherType"])
    assert_equals(config_info["job_ckpt_dir"], sctl_dict["JobCheckpointDir"])
    assert_equals(config_info["job_comp_host"], sctl_dict["JobCompHost"])
    assert_equals(config_info["job_comp_loc"], sctl_dict["JobCompLoc"])
    assert_equals(config_info["job_comp_port"], int(sctl_dict["JobCompPort"]))
    assert_equals(config_info["job_comp_type"], sctl_dict["JobCompType"])
    assert_equals(config_info["launch_type"], sctl_dict["LaunchType"])
    assert_equals(config_info["mail_prog"], sctl_dict["MailProg"])
    assert_equals(config_info["max_array_sz"], int(sctl_dict["MaxArraySize"]))
    assert_equals(config_info["max_job_cnt"], int(sctl_dict["MaxJobCount"]))
    assert_equals(config_info["max_job_id"], int(sctl_dict["MaxJobId"]))
    assert_equals(config_info["max_step_cnt"], int(sctl_dict["MaxStepCount"]))
    assert_equals(config_info["max_step_cnt"], int(sctl_dict["MaxStepCount"]))
    assert_equals(config_info["mpi_default"], sctl_dict["MpiDefault"])
    assert_equals(config_info["next_job_id"], int(sctl_dict["NEXT_JOB_ID"]))
    assert_equals(config_info["plugindir"], sctl_dict["PluginDir"])
    assert_equals(config_info["plugstack"], sctl_dict["PlugStackConfig"])
    assert_equals(config_info["preempt_mode"], sctl_dict["PreemptMode"])
    assert_equals(config_info["preempt_type"], sctl_dict["PreemptType"])
    assert_equals(config_info["priority_type"], sctl_dict["PriorityType"])
    assert_equals(config_info["proctrack_type"], sctl_dict["ProctrackType"])
    assert_equals(config_info["propagate_rlimits"], sctl_dict["PropagateResourceLimits"])
    assert_equals(config_info["route_plugin"], sctl_dict["RoutePlugin"])
    assert_equals(config_info["schedtype"], sctl_dict["SchedulerType"])
    assert_equals(config_info["select_type"], sctl_dict["SelectType"])

    assert_equals(
        config_info["slurm_user_name"] + "(" + str(config_info["slurm_user_id"]) + ")",
        sctl_dict["SlurmUser"]
    )

    assert_equals(config_info["slurmctld_logfile"], sctl_dict["SlurmctldLogFile"])
    assert_equals(config_info["slurmctld_pidfile"], sctl_dict["SlurmctldPidFile"])
    assert_equals(config_info["slurmctld_port"], int(sctl_dict["SlurmctldPort"]))
    assert_equals(config_info["slurmd_logfile"], sctl_dict["SlurmdLogFile"])
    assert_equals(config_info["slurmd_pidfile"], sctl_dict["SlurmdPidFile"])
    assert_equals(config_info["slurmd_port"], int(sctl_dict["SlurmdPort"]))
    assert_equals(config_info["slurmd_spooldir"], sctl_dict["SlurmdSpoolDir"])
    assert_equals(config_info["slurmd_spooldir"], sctl_dict["SlurmdSpoolDir"])

    assert_equals(
        config_info["slurmd_user_name"] + "(" + str(config_info["slurmd_user_id"]) + ")",
        sctl_dict["SlurmdUser"]
    )

    assert_equals(config_info["slurm_conf"], sctl_dict["SLURM_CONF"])
    assert_equals(config_info["state_save_location"], sctl_dict["StateSaveLocation"])
    assert_equals(config_info["switch_type"], sctl_dict["SwitchType"])
    assert_equals(config_info["task_plugin"], sctl_dict["TaskPlugin"])
    assert_equals(config_info["topology_plugin"], sctl_dict["TopologyPlugin"])
    assert_equals(config_info["tree_width"], int(sctl_dict["TreeWidth"]))
