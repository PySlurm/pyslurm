from __future__ import division, print_function

import pyslurm
import subprocess
from types import *
from time import time, strftime, localtime
from random import randint
from nose.tools import assert_equals, assert_true

from  slurmdb_util import *

def setup():
    pass


def teardown():
    pass

def create_dbEvents():
    dbEvents = pyslurm.slurmdb_events()
    now = time()
    timeFrom = now - (3600*24*365)
    dbEvents.set_event_condition(timeFrom, now)
    return dbEvents

def test_event_get():
    """Event: Test slurmdb_events.get() return type."""
    dbEvents = create_dbEvents()
    all_dbEvents = dbEvents.get()
    assert_true(isinstance(all_dbEvents, dict))


def test_event_ids():
    """Event: Test slurmdb_events.get().ids() return type."""
    dbEvents = create_dbEvents()
    dbEvents = create_dbEvents()
    all_dbEvents = dbEvents.get()
    all_dbEvents_ids = dbEvents.ids()
    assert_true(isinstance(all_dbEvents_ids, list))


def test_event_count():
    """Event: Test slurmdb_events count."""
    dbEvents = create_dbEvents()
    dbEvents = create_dbEvents()
    all_dbEvents = dbEvents.get()
    all_dbEvents_ids = dbEvents.ids()
    assert_equals(len(all_dbEvents), len(all_dbEvents_ids))


def test_event_sacctmgr():
    """Event: Test sacctmgr values to Pyslurm values"""
    dbEvents = create_dbEvents()
#typedef struct {
##        char *cluster;          /* Name of associated cluster */
##        char *cluster_nodes;    /* node list in cluster during time
##                                 * period (only set in a cluster event) */
##        uint16_t event_type;    /* type of event (slurmdb_event_type_t) */
##        char *node_name;        /* Name of node (only set in a node event) */
##        time_t period_end;      /* End of period */
##        time_t period_start;    /* Start of period */
##        char *reason;           /* reason node is in state during time
##                                   period (only set in a node event) */
#        uint32_t reason_uid;    /* uid of that who set the reason */
##        uint16_t state;         /* State of node during time
#                                   period (only set in a node event) */
#        char *tres_str;         /* TRES touched by this event */
#} slurmdb_event_rec_t;

    dbEvents = create_dbEvents()
    all_dbEvents = dbEvents.get()
    all_dbEvents_ids = dbEvents.ids()
    # select one event in the response
    dbEventsInfo = all_dbEvents[all_dbEvents_ids[randint(0,                 \
                                                len(all_dbEvents_ids)-1)]]
    assert_true(dbEventsInfo.has_key('time_start'))
    fromTime = strftime('%Y-%m-%d', localtime(dbEventsInfo['time_start']))
    startTime = strftime('%Y-%m-%dT%H:%M:%S', localtime(                    \
                                              dbEventsInfo['time_start']))

    fields = "Start,EventRaw,State,ClusterNodes,End,NodeName,Cluster,"      \
             "Event,Reason,StateRaw,TRES,user"
    fieldsList = fields.split(',')
    cmd = "sacctmgr list event start=" + fromTime +" format=" + fields
    scmd = subprocess.Popen(["sacctmgr", "-nP", "list", "event",            \
                            "start="+fromTime, "format="+fields],           \
                            stdout=subprocess.PIPE ).communicate()
    scmd_stdout = scmd[0].strip()
    outLines = scmd[0].strip().split('\n')
    # the sacctmgr response must containt the event selected  in pyslurm response
    eventIsFinded = False
    for outL in outLines:
        outFields = outL.split('|')
        assert_equals(len(outFields), len(fieldsList)) 

        #check  startTime
        if startTime == outFields[fieldsList.index("Start")]:
            #check  cluster name
            if dbEventsInfo['cluster'] != outFields[fieldsList.index("Cluster")]:
                continue
            #check  event_type
            if dbEventsInfo['event_type'] != int(outFields[fieldsList.index("EventRaw")]):
                continue
            else:
                if dbEventsInfo['event_type'] == pyslurm.SLURMDB_EVENT_CLUSTER :
                    #check cluster nodes
                    if dbEventsInfo['cluster_nodes'] != outFields[fieldsList.index("ClusterNodes")]:
                        continue
                if dbEventsInfo['event_type'] == pyslurm.SLURMDB_EVENT_NODE :
                    #check  node_name
                    if dbEventsInfo['node_name'] != outFields[fieldsList.index("NodeName")]:
                        continue
                    #check  reason
                    if outFields[fieldsList.index("Reason")] not in dbEventsInfo['reason'] :
                        continue
                    #check  state
                    assert_equals(pyslurm.get_node_state(dbEventsInfo['state']), outFields[fieldsList.index("State")])
                    #check  reason_uid
                    if str(dbEventsInfo['reason_uid']) not in outFields[fieldsList.index("user")]:
                        continue
            #check  endTime
            if dbEventsInfo['time_end'] == 0 :
                endTime = "Unknown"
            else:
                endTime = strftime('%Y-%m-%dT%H:%M:%S', localtime(dbEventsInfo['time_end']))
            if endTime != outFields[fieldsList.index("End")]:
                continue
            #check  tres_str  -TODO-
            if convert_tres_str(dbEventsInfo['tres_str']) != outFields[fieldsList.index("TRES")]:
                continue
            eventIsFinded = True
            break
    assert_true(eventIsFinded)
