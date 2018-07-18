from __future__ import division, print_function

import pyslurm
import subprocess
from types import *
from time import time, localtime, strftime
from datetime import datetime
from nose.tools import assert_equals, assert_true
import json

from  slurmdb_util import *

def slurmdb_cluster_flags_2_str(flags_in) :
#  deduce from slurmdb_cluster_flags_2_str in common/working_cluster.c
    cluster_flags = ""
    if flags_in & pyslurm.CLUSTER_FLAG_BG :
        cluster_flags += "Bluegene"
    if flags_in & pyslurm.CLUSTER_FLAG_BGQ :
        if cluster_flags != "" :
            cluster_flags += ","
        cluster_flags += "BGQ"
    if flags_in & pyslurm.CLUSTER_FLAG_CRAY_A :
        if cluster_flags != "" :
            cluster_flags += ","
        cluster_flags += "AlpsCray"
    if flags_in & pyslurm.CLUSTER_FLAG_FE :
        if cluster_flags != "" :
            cluster_flags += ","
        cluster_flags += "FrontEnd"
    if flags_in & pyslurm.CLUSTER_FLAG_MULTSD :
        if cluster_flags != "" :
            cluster_flags += ","
        cluster_flags += "MultipleSlurmd"
    if flags_in & pyslurm.CLUSTER_FLAG_CRAY_N :
        if cluster_flags != "" :
            cluster_flags += ","
        cluster_flags += "Cray"
    if cluster_flags == "" :
        cluster_flags = "None"
    return cluster_flags;


def setup():
    pass


def teardown():
    pass

def test_cluster_get():
    """Cluster: Test slurmdb_clusters().get() return type."""
    all_db_clusters = pyslurm.slurmdb_clusters().get()
    assert_true(isinstance(all_db_clusters, dict))


def test_cluster_count():
    """Cluster: Test slurmdb_clusters().get() count."""
    all_db_clusters = pyslurm.slurmdb_clusters().get()
    assert len(all_db_clusters) >= 1


def test_cluster_name():
    """Cluster: Test cluster name."""
    all_db_clusters = pyslurm.slurmdb_clusters().get()
    slurm_config = pyslurm.config().get()
    assert_true(slurm_config.has_key('cluster_name'))
    cluster_name = slurm_config['cluster_name']
    assert_true(all_db_clusters.has_key(cluster_name))
    specific_cluster = all_db_clusters[cluster_name]
    assert_true(specific_cluster.has_key('name'))
    assert_equals(specific_cluster['name'], cluster_name)


def test_cluster_sacctmgr():
    """Cluster: Test sacctmgr values to Pyslurm values."""
    all_db_clusters = pyslurm.slurmdb_clusters().get()
    slurm_config = pyslurm.config().get()
    assert_true(slurm_config.has_key('cluster_name'))
    cluster_name = slurm_config['cluster_name']
    assert_true( all_db_clusters.has_key(cluster_name))
    specific_cluster = all_db_clusters[cluster_name]
    fields = "ControlHost,Cluster,Classification,ControlPort,RPC,Flags,"    \
             "TRES,NodeCount,NodeNames,PluginIDSelect"
    fields_list = fields.split(',')
    scmd = subprocess.Popen(["sacctmgr", "-nP", "list", "cluster",          \
             "format="+fields], stdout=subprocess.PIPE).communicate()
    scmd_stdout = scmd[0].strip().split('|')

    # check control_host
    assert_equals(specific_cluster['control_host'],                         \
                  scmd_stdout[fields_list.index("ControlHost")])
    # check name
    assert_equals(specific_cluster['name'],                                 \
                  scmd_stdout[fields_list.index("Cluster")])
    # check classification
    if specific_cluster['classification'] == 0:
        assert_equals(scmd_stdout[fields_list.index("Classification")], '')
    else:
        assert_equals(specific_cluster['classification'],                   \
                      int(scmd_stdout[fields_list.index("Classification")]))
    # check control_port
    assert_equals(specific_cluster['control_port'],                         \
                  int(scmd_stdout[fields_list.index("ControlPort")]))
    # check rpc_version
    assert_equals(specific_cluster['rpc_version'],                          \
                  int(scmd_stdout[fields_list.index("RPC")]))
    # check flags
    assert_equals(slurmdb_cluster_flags_2_str(specific_cluster['flags']),   \
                  scmd_stdout[fields_list.index("Flags")])
    # check tres
    assert_equals(convert_tres_str(specific_cluster['tres']),               \
                  scmd_stdout[fields_list.index("TRES")])
    # check nodes
    if specific_cluster['nodes']:
        hl = pyslurm.hostlist()
        hl.create(specific_cluster['nodes'])
        assert_equals(hl.count(),                                           \
                  int(scmd_stdout[fields_list.index("NodeCount")]))
        hl.destroy()
    assert_equals(specific_cluster['plugin_id_select'],                     \
                  int(scmd_stdout[fields_list.index("PluginIDSelect")]))
    # check dimensions : not finded by sacctmgr 
    # check accounting in function "test_cluster_sreport" 


def test_cluster_sreport():
    """Cluster: Test sreport values to Pyslurm values."""
    end = time()
    start = end - (24*60*60)  # 1 Day before
    start_str = strftime('%Y-%m-%d', localtime(start))
    end_str = strftime('%Y-%m-%d', localtime(end))
    modified_start = int(datetime.strptime(                                 \
                         start_str, '%Y-%m-%d').strftime("%s"))
    modified_end = int(datetime.strptime(                                   \
                         end_str, '%Y-%m-%d').strftime("%s"))
    print("   start : ", start_str)
    print("   end   :   ", end_str)
    db_cluster = pyslurm.slurmdb_clusters()
    db_cluster.set_cluster_condition(modified_start, modified_end)
    all_db_clusters = db_cluster.get()
    slurm_config = pyslurm.config().get()
    assert_true(slurm_config.has_key('cluster_name'))
    cluster_name = slurm_config['cluster_name']
    assert_true(all_db_clusters.has_key(cluster_name))
    specific_cluster = all_db_clusters[cluster_name]
    specific_cluster_acct = {'alloc_secs': 0, 'down_secs': 0,               \
                            'idle_secs': 0, 'resv_secs': 0, 'over_secs': 0, \
                            'pdown_secs': 0, 'tres_count': 0,               \
                            'tres_rec_count': 0, 'tres_alloc_secs': 0}
    if len(specific_cluster['accounting']) > 0:
        specific_cluster_acct = specific_cluster['accounting'][1][0]
    fields = "Cluster,Allocate,Down,PlanDow,Idle,Reserved,Reported"
    fields_list = fields.split(',')
    scmd = subprocess.Popen(["sreport", "-nP", "cluster", "utilization",    \
           "-t", "Seconds", "start="+start_str, "end="+end_str],            \
           stdout=subprocess.PIPE).communicate()
    scmd_stdout = scmd[0].strip().split('|')
    total_reported_secs = specific_cluster_acct['alloc_secs'] +             \
                          specific_cluster_acct['down_secs'] +              \
                          specific_cluster_acct['pdown_secs'] +             \
                          specific_cluster_acct['idle_secs'] +              \
                          specific_cluster_acct['resv_secs']

     # check cluster name
    assert_equals(cluster_name, scmd_stdout[fields_list.index("Cluster")])
    # check Allocate   
    assert_equals(specific_cluster_acct['alloc_secs'],                      \
                  long(scmd_stdout[fields_list.index('Allocate')]))
    # check Down
    assert_equals(specific_cluster_acct['down_secs'],                       \
                  long(scmd_stdout[fields_list.index("Down")]))
    # check PlanDow
    assert_equals(specific_cluster_acct['pdown_secs'],                      \
                  long(scmd_stdout[fields_list.index("PlanDow")]))
    # check Idle
    assert_equals(specific_cluster_acct['idle_secs'],                       \
                  long(scmd_stdout[fields_list.index("Idle")]))
    # check Reserved
    assert_equals(specific_cluster_acct['resv_secs'],                       \
                  long(scmd_stdout[fields_list.index("Reserved")]))
    # check Reported
    assert_equals(total_reported_secs,                                      \
                  long(scmd_stdout[fields_list.index("Reported")]))

