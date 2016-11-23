from __future__ import division, print_function

import pyslurm
import subprocess
from types import *
from time import time, strftime, localtime
from random import randint
from nose.tools import assert_equals, assert_true

from  slurmdb_util import *

def reservation_flags_string(flags) :
#  deduce from reservation_flags_string in common/slurm_protocol_defs.c

    flag_str = ""
    if flags & pyslurm.RESERVE_FLAG_MAINT :
        flag_str += "MAINT"
    if flags & pyslurm.RESERVE_FLAG_NO_MAINT :
        if flag_str != "" :
            flag_str += ","
        flag_str += "NO_MAINT"
    if flags & pyslurm.RESERVE_FLAG_OVERLAP :
        if flag_str != "" :
            flag_str += ","
        flag_str += "OVERLAP"
    if flags & pyslurm.RESERVE_FLAG_IGN_JOBS :
        if flag_str != "" :
            flag_str += ","
        flag_str += "IGNORE_JOBS"
    if flags & pyslurm.RESERVE_FLAG_DAILY :
        if flag_str != "" :
            flag_str += ","
        flag_str += "DAILY"
    if flags & pyslurm.RESERVE_FLAG_NO_DAILY :
        if flag_str != "" :
            flag_str += ","
        flag_str += "NO_DAILY"
    if flags & pyslurm.RESERVE_FLAG_WEEKLY :
        if flag_str != "" :
            flag_str += ","
        flag_str += "WEEKLY"
    if flags & pyslurm.RESERVE_FLAG_NO_WEEKLY :
        if flag_str != "" :
            flag_str += ","
        flag_str += "NO_WEEKLY"
    if flags & pyslurm.RESERVE_FLAG_SPEC_NODES :
        if flag_str != "" :
            flag_str += ","
        flag_str += "SPEC_NODES"
    if flags & pyslurm.RESERVE_FLAG_ALL_NODES :
        if flag_str != "" :
            flag_str += ","
        flag_str += "ALL_NODES"
#    if flags & pyslurm.RESERVE_FLAG_ANY_NODES :
#        if flag_str != "" :
#            flag_str += ","
#        flag_str += "ANY_NODES"
#    if flags & pyslurm.RESERVE_FLAG_NO_ANY_NODES :
#        if flag_str != "" :
#            flag_str += ","
#        flag_str += "NO_ANY_NODES"
#    if flags & pyslurm.RESERVE_FLAG_STATIC :
        if flag_str != "" :
            flag_str += ","
        flag_str += "STATIC"
    if flags & pyslurm.RESERVE_FLAG_NO_STATIC :
        if flag_str != "" :
            flag_str += ","
        flag_str += "NO_STATIC"
    if flags & pyslurm.RESERVE_FLAG_PART_NODES :
        if flag_str != "" :
            flag_str += ","
        flag_str += "PART_NODES"
    if flags & pyslurm.RESERVE_FLAG_NO_PART_NODES :
        if flag_str != "" :
            flag_str += ","
        flag_str += "NO_PART_NODES"
    if flags & pyslurm.RESERVE_FLAG_FIRST_CORES :
        if flag_str != "" :
            flag_str += ","
        flag_str += "FIRST_CORES"
    if flags & pyslurm.RESERVE_FLAG_TIME_FLOAT :
        if flag_str != "" :
            flag_str += ","
        flag_str += "TIME_FLOAT"
    if flags & pyslurm.RESERVE_FLAG_REPLACE :
        if flag_str != "" :
            flag_str += ","
        flag_str += "REPLACE"
    if flags & pyslurm.RESERVE_FLAG_PURGE_COMP :
        if flag_str != "" :
            flag_str += ","
        flag_str += "PURGE_COMP"
    return flag_str;

def setup():
    pass


def teardown():
    pass

def create_dbReservations():
    dbReservations = pyslurm.slurmdb_reservations()
    now = time()
    timeFrom = now - (3600*24*365)
    dbReservations.set_reservation_condition(timeFrom, now)
    return dbReservations

def test_reservation_get():
    dbReservations = create_dbReservations()
    all_dbReservations = dbReservations.get()
    assert_true(isinstance(all_dbReservations, dict))

def test_reservation_ids():
    dbReservations = create_dbReservations()
    all_dbReservations = dbReservations.get()
    all_dbReservation_ids = dbReservations.ids()
    assert_true(isinstance(all_dbReservation_ids, list))


def test_reservation_count():
    dbReservations = create_dbReservations()
    all_dbReservations = dbReservations.get()
    all_dbReservation_ids = dbReservations.ids()
    assert_equals(len(all_dbReservations), len(all_dbReservation_ids))

def test_event_sacctmgr():
#typedef struct {
#        char *assocs; /* comma separated list of associations */
#        char *cluster; /* cluster reservation is for */
#        uint32_t flags; /* flags for reservation. */
#        uint32_t id;   /* id of reservation. */
#        char *name; /* name of reservation */
#        char *nodes; /* list of nodes in reservation */
#        char *node_inx; /* node index of nodes in reservation */
#        time_t time_end; /* end time of reservation */
#        time_t time_start; /* start time of reservation */
#        time_t time_start_prev; /* If start time was changed this is
#                                 * the pervious start time.  Needed
#                                 * for accounting */
#        char *tres_str;
#        List tres_list; /* list of slurmdb_tres_rec_t, only set when
#                         * job usage is requested.
#                         */
#} slurmdb_reservation_rec_t;
    dbReservation = create_dbReservations()
    all_dbReservation = dbReservation.get()
    all_dbReservation_ids = dbReservation.ids()
    # select one event in the response
    print("  ---> all_dbReservation_ids / len(all_dbReservation): ", all_dbReservation_ids, " / ", len(all_dbReservation))
    print("  ")
    id = all_dbReservation_ids[randint(0, len(all_dbReservation_ids) - 1)] 
    dbReservationInfo = all_dbReservation[id]
    print("  ---> dbReservationInfo: ", dbReservationInfo)
    print("  ")

    fields = "Association,Cluster,Flags,id,Name,Nodename,End,Start,TRES"
    fieldsList = fields.split(',')
    print("  ---> fieldsList: ", fieldsList)
    print("  ")
    cmd = "sacctmgr list reservation id=" + str(id) +" format="+fields
    print("  ---> cmd: ", cmd)
    scmd = subprocess.Popen(["sacctmgr", "-np", "list", "reservation", "id="+str(id), "format="+fields],
                                stdout=subprocess.PIPE ).communicate()
    scmd_stdout = scmd[0].strip()
    outLines = scmd[0].strip().split('\n')
    if len(outLines) != 1 :
        print("  ---> outLines: ",  outLines)
        scmd = subprocess.Popen(["sacctmgr", "-np", "list", "reservation", "name="+str(dbReservationInfo['name']),
            "format="+fields], stdout=subprocess.PIPE).communicate()
        scmd_stdout = scmd[0].strip()
        outLines = scmd[0].strip().split('\n')
    assert_equals( len(outLines), 1)
    outFields = outLines[0].split('|')
    print("  ---> outFields: ",  outFields)
    print("  ")

    # check assocs
    assert_equals( dbReservationInfo['associations'], outFields[fieldsList.index("Association")])

    # check cluster
    assert_equals( dbReservationInfo['cluster'], outFields[fieldsList.index("Cluster")])

    # check flags; /* flags for reservation. */
    assert_equals( reservation_flags_string(dbReservationInfo['flags']), outFields[fieldsList.index("Flags")])

    # check id;   /* id of reservation. */
    assert_equals( dbReservationInfo['reservation_id'], int(outFields[fieldsList.index("id")]))

    # check name; /* name of reservation */
    assert_equals( dbReservationInfo['name'], outFields[fieldsList.index("Name")])

    # check nodes; /* list of nodes in reservation */
    assert_equals( dbReservationInfo['nodes'], outFields[fieldsList.index("Nodename")])

    # check node_inx; /* node index of nodes in reservation */

    # check time_end
    endTime = strftime('%Y-%m-%dT%H:%M:%S', localtime(dbReservationInfo['time_end']))
    assert_equals( endTime, outFields[fieldsList.index("End")])

    # check time_start
    startTime = strftime('%Y-%m-%dT%H:%M:%S', localtime(dbReservationInfo['time_start']))
    assert_equals( startTime, outFields[fieldsList.index("Start")])

    ## check time_start_prev : not finded by sacctmgr 

    # check tres_str
    assert_equals( convert_tres_str(dbReservationInfo['tres_str']), outFields[fieldsList.index("TRES")])

    ## check tres_list : not finded by sacctmgr 
