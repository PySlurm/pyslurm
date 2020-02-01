#!/usr/bin/env python

"""
Set a trigger

Trigger ID                : 3
offset                    : 0
program                   : /tmp/test.sh
res_id                    : *
res_type                  : node
trig_type                 : down
user_id                   : root

#define TRIGGER_RES_TYPE_JOB            0x0001
#define TRIGGER_RES_TYPE_NODE           0x0002
#define TRIGGER_RES_TYPE_SLURMCTLD      0x0003
#define TRIGGER_RES_TYPE_SLURMDBD       0x0004
#define TRIGGER_RES_TYPE_DATABASE       0x0005a

#define TRIGGER_TYPE_UP                 0x00000001
#define TRIGGER_TYPE_DOWN               0x00000002
#define TRIGGER_TYPE_FAIL               0x00000004
#define TRIGGER_TYPE_TIME               0x00000008
#define TRIGGER_TYPE_FINI               0x00000010
#define TRIGGER_TYPE_RECONFIG           0x00000020
#define TRIGGER_TYPE_BLOCK_ERR          0x00000040
#define TRIGGER_TYPE_IDLE               0x00000080
#define TRIGGER_TYPE_DRAINED            0x00000100
#define TRIGGER_TYPE_PRI_CTLD_FAIL      0x00000200
#define TRIGGER_TYPE_PRI_CTLD_RES_OP    0x00000400
#define TRIGGER_TYPE_PRI_CTLD_RES_CTRL  0x00000800
#define TRIGGER_TYPE_PRI_CTLD_ACCT_FULL 0x00001000
#define TRIGGER_TYPE_BU_CTLD_FAIL       0x00002000
#define TRIGGER_TYPE_BU_CTLD_RES_OP     0x00004000
#define TRIGGER_TYPE_BU_CTLD_AS_CTRL    0x00008000
#define TRIGGER_TYPE_PRI_DBD_FAIL       0x00010000
#define TRIGGER_TYPE_PRI_DBD_RES_OP     0x00020000
#define TRIGGER_TYPE_PRI_DB_FAIL        0x00040000
#define TRIGGER_TYPE_PRI_DB_RES_OP      0x00080000

ctypedef struct trigger_info:
    uint32_t trig_id
    uint16_t res_type
    char *   res_id
    uint16_t trig_type
    uint16_t offset
    uint32_t user_id
    char *   program
"""

from __future__ import print_function

import pyslurm

trigDict = {
    "res_type": "node",
    "res_id": "makalu",
    "offset": 0,
    "event": "down",
    "program": "/tmp/test.sh",
}

try:
    a = pyslurm.trigger()
    a.set(trigDict)
except ValueError as value_error:
    print("Trigger set failed - {0}".format(value_error.args[0]))
else:
    print("Trigger set !")
