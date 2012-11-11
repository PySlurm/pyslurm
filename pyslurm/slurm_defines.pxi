#
# SLURM enums
#

INFINITE = slurm.INFINITE

JOB_PENDING = slurm.JOB_PENDING
JOB_RUNNING = slurm.JOB_RUNNING
JOB_SUSPENDED = slurm.JOB_SUSPENDED
JOB_COMPLETE = slurm.JOB_COMPLETE
JOB_CANCELLED = slurm.JOB_CANCELLED
JOB_FAILED = slurm.JOB_FAILED
JOB_TIMEOUT = slurm.JOB_TIMEOUT
JOB_NODE_FAIL = slurm.JOB_NODE_FAIL
JOB_PREEMPTED = slurm.JOB_PREEMPTED
JOB_END = slurm.JOB_END

JOB_START = slurm.JOB_START
JOB_STEP = slurm.JOB_STEP
JOB_SUSPEND = slurm.JOB_SUSPEND
JOB_TERMINATED = slurm.JOB_TERMINATED

WAIT_NO_REASON = slurm.WAIT_NO_REASON                       # not set or job not pending
WAIT_PRIORITY = slurm.WAIT_PRIORITY                         # higher priority jobs exist
WAIT_DEPENDENCY= slurm.WAIT_DEPENDENCY                      # dependent job has not completed
WAIT_RESOURCES = slurm.WAIT_RESOURCES                       # required resources not available
WAIT_PART_NODE_LIMIT = slurm.WAIT_PART_NODE_LIMIT           # request exceeds partition node limit
WAIT_PART_TIME_LIMIT = slurm.WAIT_PART_TIME_LIMIT           # request exceeds partition time limit
WAIT_PART_DOWN = slurm.WAIT_PART_DOWN                       # requested partition is down
WAIT_PART_INACTIVE = slurm.WAIT_PART_INACTIVE               # requested partition is inactive
WAIT_HELD = slurm.WAIT_HELD                                 # job is held by administrator
WAIT_TIME = slurm.WAIT_TIME                                 # job waiting for specific begin time
WAIT_LICENSES = slurm.WAIT_LICENSES                         # job is waiting for licenses
WAIT_ASSOC_JOB_LIMIT = slurm.WAIT_ASSOC_JOB_LIMIT           # user/bank job limit reached
WAIT_ASSOC_RESOURCE_LIMIT = slurm.WAIT_ASSOC_RESOURCE_LIMIT # user/bank resource limit reached
WAIT_ASSOC_TIME_LIMIT = slurm.WAIT_ASSOC_TIME_LIMIT         # user/bank time limit reached
WAIT_RESERVATION = slurm.WAIT_RESERVATION                   # reservation not available
WAIT_NODE_NOT_AVAIL = slurm.WAIT_NODE_NOT_AVAIL             # required node is DOWN or DRAINED
WAIT_HELD_USER = slurm.WAIT_HELD_USER                       # job is held by user
WAIT_TBD2 = slurm.WAIT_TBD2
FAIL_DOWN_PARTITION = slurm.FAIL_DOWN_PARTITION             # partition for job is DOWN
FAIL_DOWN_NODE = slurm.FAIL_DOWN_NODE                       # some node in the allocation failed
FAIL_BAD_CONSTRAINTS = slurm.FAIL_BAD_CONSTRAINTS           # constraints can not be satisfied
FAIL_SYSTEM = slurm.FAIL_SYSTEM                             # slurm system failure
FAIL_LAUNCH = slurm.FAIL_LAUNCH                             # unable to launch job
FAIL_EXIT_CODE = slurm.FAIL_EXIT_CODE                       # exit code was non-zero
FAIL_TIMEOUT = slurm.FAIL_TIMEOUT                           # reached end of time limit
FAIL_INACTIVE_LIMIT = slurm.FAIL_INACTIVE_LIMIT             # reached slurm InactiveLimit
FAIL_ACCOUNT = slurm.FAIL_ACCOUNT                           # invalid account
FAIL_QOS = slurm.FAIL_QOS                                   # invalid QOS
WAIT_QOS_THRES = slurm.WAIT_QOS_THRES                       # required QOS threshold has been breached
WAIT_QOS_JOB_LIMIT = slurm.WAIT_QOS_JOB_LIMIT               # QOS job limit reached
WAIT_QOS_RESOURCE_LIMIT = slurm.WAIT_QOS_RESOURCE_LIMIT     # QOS resource limit reached
WAIT_QOS_TIME_LIMIT = slurm.WAIT_QOS_TIME_LIMIT             # QOS time limit reached

NODE_STATE_UNKNOWN = slurm.NODE_STATE_UNKNOWN
NODE_STATE_DOWN = slurm.NODE_STATE_DOWN
NODE_STATE_IDLE = slurm.NODE_STATE_IDLE
NODE_STATE_ALLOCATED = slurm.NODE_STATE_ALLOCATED
NODE_STATE_ERROR = slurm.NODE_STATE_ERROR
NODE_STATE_MIXED = slurm.NODE_STATE_MIXED
NODE_STATE_FUTURE = slurm.NODE_STATE_FUTURE
NODE_STATE_END = slurm.NODE_STATE_END

SELECT_MESH = slurm.SELECT_MESH
SELECT_TORUS = slurm.SELECT_TORUS
SELECT_NAV = slurm.SELECT_NAV
SELECT_SMALL = slurm.SELECT_SMALL
SELECT_HTC_S = slurm.SELECT_HTC_S
SELECT_HTC_D = slurm.SELECT_HTC_D
SELECT_HTC_V = slurm.SELECT_HTC_V
SELECT_HTC_L = slurm.SELECT_HTC_L

SELECT_COPROCESSOR_MODE = slurm.SELECT_COPROCESSOR_MODE
SELECT_VIRTUAL_NODE_MODE = slurm.SELECT_VIRTUAL_NODE_MODE
SELECT_NAV_MODE = slurm.SELECT_NAV_MODE

RESERVE_FLAG_MAINT = slurm.RESERVE_FLAG_MAINT
RESERVE_FLAG_NO_MAINT = slurm.RESERVE_FLAG_NO_MAINT
RESERVE_FLAG_DAILY = slurm.RESERVE_FLAG_DAILY
RESERVE_FLAG_NO_DAILY = slurm.RESERVE_FLAG_NO_DAILY
RESERVE_FLAG_WEEKLY = slurm.RESERVE_FLAG_WEEKLY
RESERVE_FLAG_NO_WEEKLY = slurm.RESERVE_FLAG_NO_WEEKLY
RESERVE_FLAG_IGN_JOBS = slurm.RESERVE_FLAG_IGN_JOBS
RESERVE_FLAG_NO_IGN_JOB = slurm.RESERVE_FLAG_NO_IGN_JOB
RESERVE_FLAG_LIC_ONLY = slurm.RESERVE_FLAG_LIC_ONLY
RESERVE_FLAG_NO_LIC_ONLY = slurm.RESERVE_FLAG_NO_LIC_ONLY
RESERVE_FLAG_OVERLAP = slurm.RESERVE_FLAG_OVERLAP
RESERVE_FLAG_SPEC_NODES = slurm.RESERVE_FLAG_SPEC_NODES

PRIVATE_DATA_JOBS = slurm.PRIVATE_DATA_JOBS                 # job/step data is private
PRIVATE_DATA_NODES = slurm.PRIVATE_DATA_NODES               # node data is private
PRIVATE_DATA_PARTITIONS = slurm.PRIVATE_DATA_PARTITIONS     # partition data is private
PRIVATE_DATA_USAGE = slurm.PRIVATE_DATA_USAGE               # accounting usage data is private
PRIVATE_DATA_USERS = slurm.PRIVATE_DATA_USERS               # accounting user data is private
PRIVATE_DATA_ACCOUNTS = slurm.PRIVATE_DATA_ACCOUNTS         # accounting account data is private
PRIVATE_DATA_RESERVATIONS = slurm.PRIVATE_DATA_RESERVATIONS # reservation data is private

PRIORITY_RESET_NONE = slurm.PRIORITY_RESET_NONE           # never clear
PRIORITY_RESET_NOW = slurm.PRIORITY_RESET_NOW             # clear now (when slurmctld restarts)
PRIORITY_RESET_DAILY = slurm.PRIORITY_RESET_DAILY         # clear daily at midnight
PRIORITY_RESET_WEEKLY = slurm.PRIORITY_RESET_WEEKLY       # clear weekly at Sunday 00:00
PRIORITY_RESET_MONTHLY = slurm.PRIORITY_RESET_MONTHLY     # clear monthly on first at 00:00
PRIORITY_RESET_QUARTERLY = slurm.PRIORITY_RESET_QUARTERLY # clear quarterly on first at 00:00
PRIORITY_RESET_YEARLY = slurm.PRIORITY_RESET_YEARLY       # clear yearly on first at 00:00

DEBUG_FLAG_SELECT_TYPE = slurm.DEBUG_FLAG_SELECT_TYPE
DEBUG_FLAG_STEPS = slurm.DEBUG_FLAG_STEPS
DEBUG_FLAG_TRIGGERS = slurm.DEBUG_FLAG_TRIGGERS
DEBUG_FLAG_CPU_BIND = slurm.DEBUG_FLAG_CPU_BIND
DEBUG_FLAG_WIKI = slurm.DEBUG_FLAG_WIKI
DEBUG_FLAG_NO_CONF_HASH = slurm.DEBUG_FLAG_NO_CONF_HASH
DEBUG_FLAG_GRES = slurm.DEBUG_FLAG_GRES
DEBUG_FLAG_BG_PICK = slurm.DEBUG_FLAG_BG_PICK
DEBUG_FLAG_BG_WIRES = slurm.DEBUG_FLAG_BG_WIRES
DEBUG_FLAG_BG_ALGO = slurm.DEBUG_FLAG_BG_ALGO
DEBUG_FLAG_BG_ALGO_DEEP = slurm.DEBUG_FLAG_BG_ALGO_DEEP
DEBUG_FLAG_PRIO = slurm.DEBUG_FLAG_PRIO
DEBUG_FLAG_BACKFILL = slurm.DEBUG_FLAG_BACKFILL
DEBUG_FLAG_GANG = slurm.DEBUG_FLAG_GANG
DEBUG_FLAG_RESERVATION = slurm.DEBUG_FLAG_RESERVATION
DEBUG_FLAG_FRONT_END = slurm.DEBUG_FLAG_FRONT_END

PREEMPT_MODE_OFF = slurm.PREEMPT_MODE_OFF
PREEMPT_MODE_SUSPEND = slurm.PREEMPT_MODE_SUSPEND
PREEMPT_MODE_REQUEUE = slurm.PREEMPT_MODE_REQUEUE
PREEMPT_MODE_CHECKPOINT = slurm.PREEMPT_MODE_CHECKPOINT
PREEMPT_MODE_CANCEL = slurm.PREEMPT_MODE_CANCEL
PREEMPT_MODE_GANG = slurm.PREEMPT_MODE_GANG

TRIGGER_RES_TYPE_JOB = slurm.TRIGGER_RES_TYPE_JOB
TRIGGER_RES_TYPE_NODE = slurm.TRIGGER_RES_TYPE_NODE
TRIGGER_RES_TYPE_SLURMCTLD = slurm.TRIGGER_RES_TYPE_SLURMCTLD
TRIGGER_RES_TYPE_SLURMDBD = slurm.TRIGGER_RES_TYPE_SLURMDBD
TRIGGER_RES_TYPE_DATABASE = slurm.TRIGGER_RES_TYPE_DATABASE
TRIGGER_RES_TYPE_FRONT_END = slurm.TRIGGER_RES_TYPE_FRONT_END

#
# Blue Gene Type Block Settings for pyslurm
#

BLOCK_FREE = 0
BLOCK_RECREATE = 1
IF BGL == 1:
	BLOCK_READY = 2
	BLOCK_BUSY = 3
ELSE:
	BLOCK_REBOOTING = 2
	BLOCK_READY = 3
BLOCK_RESUME = 4
BLOCK_ERROR = 5
BLOCK_REMOVE = 6
