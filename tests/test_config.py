"""Test cases for Slurm Config."""

import subprocess

import pyslurm


def test_config_get():
    """Config: Test config().get() return type."""
    config_info = pyslurm.config().get()
    assert isinstance(config_info, dict)


def test_config_key_pairs():
    """Config: Test config().key_pairs() function and return type."""
    config_key_pairs = pyslurm.config().key_pairs()
    assert isinstance(config_key_pairs, dict)


def test_config_scontrol():
    """Config: Compare scontrol values to PySlurm values."""
    config_info = pyslurm.config().get()

    sctl = subprocess.Popen(
        ["scontrol", "-d", "show", "config"], stdout=subprocess.PIPE
    ).communicate()
    sctl_stdout = sctl[0].strip().decode("UTF-8").split("\n")
    sctl_dict = dict(
        (item.split("=", 1)[0].strip(), item.split("=", 1)[1].strip())
        for item in sctl_stdout
        if "=" in item
    )

    assert config_info["accounting_storage_host"] == sctl_dict["AccountingStorageHost"]
    assert config_info["accounting_storage_port"] == int(
        sctl_dict["AccountingStoragePort"]
    )
    assert config_info["accounting_storage_type"] == sctl_dict["AccountingStorageType"]
    assert config_info["accounting_storage_tres"] == sctl_dict["AccountingStorageTRES"]
    assert config_info["accounting_storage_user"] == sctl_dict["AccountingStorageUser"]
    assert config_info["acct_gather_energy_type"] == sctl_dict["AcctGatherEnergyType"]
    assert (
        config_info["acct_gather_filesystem_type"]
        == sctl_dict["AcctGatherFilesystemType"]
    )

    assert (
        config_info["acct_gather_interconnect_type"]
        == sctl_dict["AcctGatherInterconnectType"]
    )

    assert config_info["acct_gather_profile_type"] == sctl_dict["AcctGatherProfileType"]
    assert config_info["authtype"] == sctl_dict["AuthType"]
    assert config_info["cluster_name"] == sctl_dict["ClusterName"]
    assert config_info["core_spec_plugin"] == sctl_dict["CoreSpecPlugin"]
    assert config_info["ext_sensors_type"] == sctl_dict["ExtSensorsType"]
    assert config_info["first_job_id"] == int(sctl_dict["FirstJobId"])
    assert config_info["job_acct_gather_type"] == sctl_dict["JobAcctGatherType"]
    assert config_info["job_comp_host"] == sctl_dict["JobCompHost"]
    assert config_info["job_comp_loc"] == sctl_dict["JobCompLoc"]
    assert config_info["job_comp_port"] == int(sctl_dict["JobCompPort"])
    assert config_info["job_comp_type"] == sctl_dict["JobCompType"]
    assert config_info["launch_type"] == sctl_dict["LaunchType"]
    assert config_info["mail_prog"] == sctl_dict["MailProg"]
    assert config_info["max_array_sz"] == int(sctl_dict["MaxArraySize"])
    assert config_info["max_job_cnt"] == int(sctl_dict["MaxJobCount"])
    assert config_info["max_job_id"] == int(sctl_dict["MaxJobId"])
    assert config_info["max_step_cnt"] == int(sctl_dict["MaxStepCount"])
    assert config_info["max_step_cnt"] == int(sctl_dict["MaxStepCount"])
    assert config_info["mpi_default"] == sctl_dict["MpiDefault"]
    assert config_info["next_job_id"] == int(sctl_dict["NEXT_JOB_ID"])
    assert config_info["plugindir"] == sctl_dict["PluginDir"]
    # assert config_info["plugstack"] == sctl_dict["PlugStackConfig"]
    assert config_info["preempt_mode"] == sctl_dict["PreemptMode"]
    assert config_info["preempt_type"] == sctl_dict["PreemptType"]
    assert config_info["priority_type"] == sctl_dict["PriorityType"]
    assert config_info["proctrack_type"] == sctl_dict["ProctrackType"]
    assert config_info["propagate_rlimits"] == sctl_dict["PropagateResourceLimits"]
    assert config_info["route_plugin"] == sctl_dict["RoutePlugin"]
    assert config_info["schedtype"] == sctl_dict["SchedulerType"]
    assert config_info["select_type"] == sctl_dict["SelectType"]

    assert (
        config_info["slurm_user_name"] + "(" + str(config_info["slurm_user_id"]) + ")"
        == sctl_dict["SlurmUser"]
    )

    assert config_info["slurmctld_logfile"] == sctl_dict["SlurmctldLogFile"]
    assert config_info["slurmctld_pidfile"] == sctl_dict["SlurmctldPidFile"]
    assert config_info["slurmctld_port"] == int(sctl_dict["SlurmctldPort"])
    assert config_info["slurmd_logfile"] == sctl_dict["SlurmdLogFile"]
    assert config_info["slurmd_pidfile"] == sctl_dict["SlurmdPidFile"]
    assert config_info["slurmd_port"] == int(sctl_dict["SlurmdPort"])
    assert config_info["slurmd_spooldir"] == sctl_dict["SlurmdSpoolDir"]
    assert config_info["slurmd_spooldir"] == sctl_dict["SlurmdSpoolDir"]

    assert (
        config_info["slurmd_user_name"] + "(" + str(config_info["slurmd_user_id"]) + ")"
        == sctl_dict["SlurmdUser"]
    )

    assert config_info["slurm_conf"] == sctl_dict["SLURM_CONF"]
    assert config_info["state_save_location"] == sctl_dict["StateSaveLocation"]
    assert config_info["switch_type"] == sctl_dict["SwitchType"]
    assert config_info["task_plugin"] == sctl_dict["TaskPlugin"]
    assert config_info["topology_plugin"] == sctl_dict["TopologyPlugin"]
    assert config_info["tree_width"] == int(sctl_dict["TreeWidth"])
