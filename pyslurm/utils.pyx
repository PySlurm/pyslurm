"""
============
:mod:`utils`
============

The utils extension module replicates slurm functions that are not exported via
libslurm.

"""
from __future__ import absolute_import, division, unicode_literals

from libc.stdint cimport uint32_t, uint64_t
from posix.types cimport uid_t
from cpython.version cimport PY_MAJOR_VERSION
from .slurm_common cimport *
from .c_config cimport *
from .c_trigger cimport *

# 
# PySlurm Helper Functions
#

cdef unicode tounicode(char* s):
    if s == NULL:
        return None
    else:
        return s.decode("UTF-8", "replace")

#
# Slurm functions not externalized
#

DEF FUZZY_EPSILON = 0.00001
cdef fuzzy_equal(v1, v2):
    return (((v1 - v2) > -FUZZY_EPSILON) and ((v1 - v2) < FUZZY_EPSILON))

cdef cpu_freq_to_string(uint32_t cpu_freq):
    """
    Convert a cpu_freq number to its equivalent string.

    Args:
        cpu_freq (int): cpu frequency
    Returns:
        Slurm equivalent cpu frequency string
    """
    if cpu_freq == CPU_FREQ_LOW:
        return "Low"
    elif cpu_freq == CPU_FREQ_MEDIUM:
        return "Medium"
    elif cpu_freq == CPU_FREQ_HIGHM1:
        return "Highm1"
    elif cpu_freq == CPU_FREQ_HIGH:
        return "High"
    elif cpu_freq == CPU_FREQ_CONSERVATIVE:
        return "Conservative"
    elif cpu_freq == CPU_FREQ_PERFORMANCE:
        return "Performance"
    elif cpu_freq == CPU_FREQ_POWERSAVE:
        return "PowerSave"
    elif cpu_freq == CPU_FREQ_USERSPACE:
        return "UserSpace"
    elif cpu_freq == CPU_FREQ_ONDEMAND:
        return "OnDemand"
    elif (cpu_freq & CPU_FREQ_RANGE_FLAG):
        return "Unknown"
    elif fuzzy_equal(cpu_freq, NO_VAL):
        return ""
#    else:
#        convert_num_unit2()

cdef cpu_freq_govlist_to_string(uint32_t govs):
    """
    Convert a composite cpu governor enum to its equivalent string.

    Args:
        govs (int): composite enum of governors
    Returns:
        Slurm equivalient cpu governor string
    """
    govlist = []

    if (govs & CPU_FREQ_CONSERVATIVE) == CPU_FREQ_CONSERVATIVE:
        govlist.append("Conservative")
    if (govs & CPU_FREQ_PERFORMANCE) == CPU_FREQ_PERFORMANCE:
        govlist.append("Performance")
    if (govs & CPU_FREQ_POWERSAVE) == CPU_FREQ_POWERSAVE:
        govlist.append("PowerSave")
    if (govs & CPU_FREQ_ONDEMAND) == CPU_FREQ_ONDEMAND:
        govlist.append("OnDemand")
    if (govs & CPU_FREQ_USERSPACE) == CPU_FREQ_USERSPACE:
        govlist.append("UserSpace")

    if govlist:
        return govlist
    else:
        return ["No Governors defined."]


cdef debug_flags2str(uint64_t debug_flags):
    """
    Convert a DebugFlags uint64_t to the equivalent string.

    Args:
        debug_flags (int): DebugFlags uint64_t
    Returns:
        Slurm equivalent Debug Flags string
    """
    dflist = []

    if (debug_flags & DEBUG_FLAG_BACKFILL):
        dflist.append("Backfill")
    if (debug_flags & DEBUG_FLAG_BACKFILL_MAP):
        dflist.append("BackfillMap")
    if (debug_flags & DEBUG_FLAG_BG_ALGO):
        dflist.append("BGBlockAlgo")
    if (debug_flags & DEBUG_FLAG_BG_PICK):
        dflist.append("BGBlockPick")
    if (debug_flags & DEBUG_FLAG_BG_WIRES):
        dflist.append("BGBlockWires")
    if (debug_flags & DEBUG_FLAG_BURST_BUF):
        dflist.append("BurstBuffer")
    if (debug_flags & DEBUG_FLAG_CPU_FREQ):
        dflist.append("CpuFrequency")
    if (debug_flags & DEBUG_FLAG_CPU_BIND):
        dflist.append("Cpu_Bind")
    if (debug_flags & DEBUG_FLAG_DB_ARCHIVE):
        dflist.append("DB_Archive")
    if (debug_flags & DEBUG_FLAG_DB_ASSOC):
        dflist.append("DB_Assoc")
    if (debug_flags & DEBUG_FLAG_DB_TRES):
        dflist.append("DB_TRES")
    if (debug_flags & DEBUG_FLAG_DB_EVENT):
        dflist.append("DB_Event")
    if (debug_flags & DEBUG_FLAG_DB_JOB):
        dflist.append("DB_Job")
    if (debug_flags & DEBUG_FLAG_DB_QOS):
        dflist.append("DB_QOS")
    if (debug_flags & DEBUG_FLAG_DB_QUERY):
        dflist.append("DB_Query")
    if (debug_flags & DEBUG_FLAG_DB_RESV):
        dflist.append("DB_Reservation")
    if (debug_flags & DEBUG_FLAG_DB_RES):
        dflist.append("DB_Resource")
    if (debug_flags & DEBUG_FLAG_DB_STEP):
        dflist.append("DB_Step")
    if (debug_flags & DEBUG_FLAG_DB_USAGE):
        dflist.append("DB_Usage")
    if (debug_flags & DEBUG_FLAG_DB_WCKEY):
        dflist.append("DB_WCKey")
    if (debug_flags & DEBUG_FLAG_ESEARCH):
        dflist.append("Elasticsearch")
    if (debug_flags & DEBUG_FLAG_ENERGY):
        dflist.append("Energy")
    if (debug_flags & DEBUG_FLAG_EXT_SENSORS):
        dflist.append("ExtSensors")
    if (debug_flags & DEBUG_FLAG_FILESYSTEM):
        dflist.append("Filesystem")
#    if (debug_flags & DEBUG_FLAG_FEDR):
#        dflist.append("Federation")
    if (debug_flags & DEBUG_FLAG_FRONT_END):
        dflist.append("FrontEnd")
    if (debug_flags & DEBUG_FLAG_GANG):
        dflist.append("Gang")
    if (debug_flags & DEBUG_FLAG_GRES):
        dflist.append("Gres")
#    if (debug_flags & DEBUG_FLAG_INFINIBAND):   #FIXME
#        dflist.append("Infiniband")
    if (debug_flags & DEBUG_FLAG_JOB_CONT):
        dflist.append("JobContainer")
#    if (debug_flags & DEBUG_FLAG_NODE_FEATURES):
#        dflist.append("NodeFeatures")
    if (debug_flags & DEBUG_FLAG_LICENSE):
        dflist.append("License")
    if (debug_flags & DEBUG_FLAG_NO_CONF_HASH):
        dflist.append("NO_CONF_HASH")
    if (debug_flags & DEBUG_FLAG_NO_REALTIME):
        dflist.append("NoRealTime")
    if (debug_flags & DEBUG_FLAG_POWER):
        dflist.append("Power")
    if (debug_flags & DEBUG_FLAG_PRIO):
        dflist.append("Priority")
    if (debug_flags & DEBUG_FLAG_PROFILE):
        dflist.append("Profile")
    if (debug_flags & DEBUG_FLAG_PROTOCOL):
        dflist.append("Protocol")
    if (debug_flags & DEBUG_FLAG_RESERVATION):
        dflist.append("Reservation")
    if (debug_flags & DEBUG_FLAG_ROUTE):
        dflist.append("Route")
    if (debug_flags & DEBUG_FLAG_SELECT_TYPE):
        dflist.append("SelectType")
    if (debug_flags & DEBUG_FLAG_STEPS):
        dflist.append("Steps")
    if (debug_flags & DEBUG_FLAG_SWITCH):
        dflist.append("Switch")
    if (debug_flags & DEBUG_FLAG_TASK):
        dflist.append("Task")
#    if (debug_flags & DEBUG_FLAG_TIME_CRAY):
#        dflist.append("TimeCray")
    if (debug_flags & DEBUG_FLAG_TRACE_JOBS):
        dflist.append("TraceJobs")
    if (debug_flags & DEBUG_FLAG_TRIGGERS):
        dflist.append("Triggers")
    if (debug_flags & DEBUG_FLAG_WIKI):
        dflist.append("Wiki")

    return dflist


cdef health_check_node_state_str(uint32_t node_state):
    """Convert HealthCheckNodeState numeric value to string."""
    nslist = []
    if (node_state & HEALTH_CHECK_CYCLE):
        nslist.append("CYCLE")

    if (node_state & HEALTH_CHECK_NODE_ANY) == HEALTH_CHECK_NODE_ANY:
        nslist.append("ANY")
        return nslist

    if (node_state & HEALTH_CHECK_NODE_IDLE):
        nslist.append("IDLE")

    if (node_state & HEALTH_CHECK_NODE_ALLOC):
        nslist.append("ALLOC")

    if (node_state & HEALTH_CHECK_NODE_MIXED):
        nslist.append("MIXED")

    return nslist


cdef reset_period_str(uint16_t reset_period):
    if reset_period == PRIORITY_RESET_NONE:
        return "NONE"
    elif reset_period == PRIORITY_RESET_NOW:
        return "NOW"
    elif reset_period == PRIORITY_RESET_DAILY:
        return "DAILY"
    elif reset_period == PRIORITY_RESET_WEEKLY:
        return "WEEKLY"
    elif reset_period == PRIORITY_RESET_MONTHLY:
        return "MONTHLY"
    elif reset_period == PRIORITY_RESET_QUARTERLY:
        return "QUARTERLY"
    elif reset_period == PRIORITY_RESET_YEARLY:
        return "YEARLY"
    else:
        return "UNKNOWN"


cdef priority_flags_string(uint16_t priority_flags):
    pflist = []
    if (priority_flags & PRIORITY_FLAGS_ACCRUE_ALWAYS):
        pflist.append("ACCRUE_ALWAYS")
    if (priority_flags & PRIORITY_FLAGS_SIZE_RELATIVE):
        pflist.append("SMALL_RELATIVE_TO_TIME")
    if (priority_flags & PRIORITY_FLAGS_CALCULATE_RUNNING):
        pflist.append("CALCULATE_RUNNING")
    if (priority_flags & PRIORITY_FLAGS_DEPTH_OBLIVIOUS):
        pflist.append("DEPTH_OBLIVIOUS")
    if (priority_flags & PRIORITY_FLAGS_FAIR_TREE):
        pflist.append("FAIR_TREE")
    if (priority_flags & PRIORITY_FLAGS_MAX_TRES):
        pflist.append("MAX_TRES")
    return pflist


cdef prolog_flags2str(uint16_t prolog_flags):
    pflist = []
    if (prolog_flags & PROLOG_FLAG_ALLOC):
        pflist.append("Alloc")
    if (prolog_flags & PROLOG_FLAG_CONTAIN):
        pflist.append("Contain")
    if (prolog_flags & PROLOG_FLAG_NOHOLD):
        pflist.append("NoHold")
    return pflist


cdef reconfig_flags2str(uint16_t reconfig_flags):
    rflist = []
    if (reconfig_flags & RECONFIG_KEEP_PART_INFO):
        rflist.append("KeepPartInfo")
    if (reconfig_flags & RECONFIG_KEEP_PART_STAT):
        rflist.append("KeepPartState")
    return rflist


cdef select_type_param_string(uint16_t select_type_param):
    stplist = []
    if (select_type_param & CR_CPU) and (select_type_param & CR_MEMORY):
        stplist.append("CR_CPU_MEMORY")
    elif (select_type_param & CR_CORE) and (select_type_param & CR_MEMORY):
        stplist.append("CR_CORE_MEMORY")
    elif (select_type_param & CR_SOCKET) and (select_type_param & CR_MEMORY):
        stplist.append("CR_SOCKET_MEMORY")
    elif (select_type_param & CR_CPU):
        stplist.append("CR_CPU")
    elif (select_type_param & CR_CORE):
        stplist.append("CR_CORE")
    elif (select_type_param & CR_SOCKET):
        stplist.append("CR_SOCKET")
    elif (select_type_param & CR_MEMORY):
        stplist.append("CR_MEMORY")

    if (select_type_param & CR_OTHER_CONS_RES):
        stplist.append("OTHER_CONS_RES")

    if (select_type_param & CR_NHC_NO):
        stplist.append("NHC_NO")
    elif (select_type_param & CR_NHC_STEP_NO):
        stplist.append("NHC_STEP_NO")

    if (select_type_param & CR_ONE_TASK_PER_CORE):
        stplist.append("CR_ONE_TASK_PER_CORE")

    if (select_type_param & CR_CORE_DEFAULT_DIST_BLOCK):
        stplist.append("CR_CORE_DEFAULT_DIST_BLOCK")

    if (select_type_param & CR_LLN):
        stplist.append("CR_LLN")

    if (select_type_param & CR_PACK_NODES):
        stplist.append("CR_PACK_NODES")

    if not stplist:
        return ["NONE"]

    return stplist


cdef log_num2string(uint16_t inx):
    if inx == 0:
        return "quiet"
    if inx == 1:
        return "fatal"
    if inx == 2:
        return "error"
    if inx == 3:
        return "info"
    if inx == 4:
        return "verbose"
    if inx == 5:
        return "debug"
    if inx == 6:
        return "debug2"
    if inx == 7:
        return "debug3"
    if inx == 8:
        return "debug4"
    if inx == 9:
        return "debug5"
    return "unknown"


# TODO: Review
cdef slurm_sprint_cpu_bind_type(cpu_bind_type_t cpu_bind_type):
    cbtlist = []

    if (cpu_bind_type & CPU_BIND_VERBOSE):
        cbtlist.append("verbose")
    if (cpu_bind_type & CPU_BIND_TO_THREADS):
        cbtlist.append("threads")
    if (cpu_bind_type & CPU_BIND_TO_CORES):
        cbtlist.append("cores")
    if (cpu_bind_type & CPU_BIND_TO_SOCKETS):
        cbtlist.append("sockets")
    if (cpu_bind_type & CPU_BIND_TO_LDOMS):
        cbtlist.append("ldoms")
    if (cpu_bind_type & CPU_BIND_TO_BOARDS):
        cbtlist.append("boards")
    if (cpu_bind_type & CPU_BIND_NONE):
        cbtlist.append("none")
    if (cpu_bind_type & CPU_BIND_RANK):
        cbtlist.append("rank")
    if (cpu_bind_type & CPU_BIND_MAP):
        cbtlist.append("map_cpu")
    if (cpu_bind_type & CPU_BIND_MASK):
        cbtlist.append("mask_cpu")
    if (cpu_bind_type & CPU_BIND_LDRANK):
        cbtlist.append("rank_ldom")
    if (cpu_bind_type & CPU_BIND_LDMAP):
        cbtlist.append("map_ldom")
    if (cpu_bind_type & CPU_BIND_LDMASK):
        cbtlist.append("mask_ldom")
    if (cpu_bind_type & CPU_BIND_CPUSETS):
        cbtlist.append("cpusets")
    if (cpu_bind_type & CPU_BIND_ONE_THREAD_PER_CORE):
        cbtlist.append("one_thread")
    if (cpu_bind_type & CPU_AUTO_BIND_TO_THREADS):
        cbtlist.append("autobind=threads")
    if (cpu_bind_type & CPU_AUTO_BIND_TO_CORES):
        cbtlist.append("autobind=cores")
    if (cpu_bind_type & CPU_AUTO_BIND_TO_SOCKETS):
        cbtlist.append("autobind=sockets")
    return cbtlist


cdef trigger_res_type(uint16_t res_type):
    if res_type == TRIGGER_RES_TYPE_JOB:
        return "job"
    elif res_type == TRIGGER_RES_TYPE_NODE:
        return "node"
    elif res_type == TRIGGER_RES_TYPE_SLURMCTLD:
        return "slurmctld"
    elif res_type == TRIGGER_RES_TYPE_SLURMDBD:
        return "slurmdbd"
    elif res_type == TRIGGER_RES_TYPE_DATABASE:
        return "database"
    elif res_type == TRIGGER_RES_TYPE_FRONT_END:
        return "front_end"
    else:
        return "unknown"


cdef trigger_type(uint32_t trig_type):
    if trig_type == TRIGGER_TYPE_UP:
        return "up"
    elif trig_type == TRIGGER_TYPE_DOWN:
        return "down"
    elif trig_type == TRIGGER_TYPE_DRAINED:
        return "drained"
    elif trig_type == TRIGGER_TYPE_FAIL:
        return "fail"
    elif trig_type == TRIGGER_TYPE_IDLE:
        return "idle"
    elif trig_type == TRIGGER_TYPE_TIME:
        return "time"
    elif trig_type == TRIGGER_TYPE_FINI:
        return "fini"
    elif trig_type == TRIGGER_TYPE_RECONFIG:
        return "reconfig"
    elif trig_type == TRIGGER_TYPE_PRI_CTLD_FAIL:
        return "primary_slurmctld_failure"
    elif trig_type == TRIGGER_TYPE_PRI_CTLD_RES_OP:
        return "primary_slurmctld_resumed_operation"
    elif trig_type == TRIGGER_TYPE_PRI_CTLD_RES_CTRL:
        return "primary_slurmctld_resumed_control"
    elif trig_type == TRIGGER_TYPE_PRI_CTLD_ACCT_FULL:
        return "primary_slurmctld_acct_buffer_full"
    elif trig_type == TRIGGER_TYPE_BU_CTLD_FAIL:
        return "backup_slurmctld_failure"
    elif trig_type == TRIGGER_TYPE_BU_CTLD_RES_OP:
        return "backup_slurmctld_resumed_operation"
    elif trig_type == TRIGGER_TYPE_BU_CTLD_AS_CTRL:
        return "backup_slurmctld_assumed_control"
    elif trig_type == TRIGGER_TYPE_PRI_DBD_FAIL:
        return "primary_slurmdbd_failure"
    elif trig_type == TRIGGER_TYPE_PRI_DBD_RES_OP:
        return "primary_slurmdbd_resumed_operation"
    elif trig_type == TRIGGER_TYPE_PRI_DB_FAIL:
        return "primary_database_failure"
    elif trig_type == TRIGGER_TYPE_PRI_DB_RES_OP:
        return "primary_database_resumed_operation"
#    elif trig_type == TRIGGER_TYPE_BLOCK_ERR:    # FIXME
#        return "block_err"
# NOTE: missing in slurm.h... bug?
#    elif trig_type == TRIGGER_TYPE_BURST_BUFFER:
#        return "burst_buffer"
    else:
        return "unknown"

cdef trig_offset(uint16_t offset):
    cdef int rc
    rc = offset
    rc -= 0x8000
    return rc

cdef trig_flags(uint16_t flags):
    if (flags & TRIGGER_FLAG_PERM):
        return "PERM"
    return ""

cdef _job_def_name(uint16_t job_type):
    if job_type == JOB_DEF_CPU_PER_GPU:
        return "DefCpuPerGPU"
    if job_type == JOB_DEF_MEM_PER_GPU:
        return "DefMemPerGPU"
    return "Unknown(%s)" % job_type

cdef job_defaults_str(List in_list):
    cdef:
        job_defaults_t *in_default
        ListIterator itr
        char *out_str = NULL
        char *sep = ""
        int i

    if in_list is NULL:
        return None

    itr = slurm_list_iterator_create(in_list)

    for i in range(slurm_list_count(in_list)):
        in_default = <job_defaults_t *>slurm_list_next(itr)
        out_str += "%s%s=%s" % (sep, _job_def_name(in_default.type), in_default.value)
        sep = ","

    slurm_list_iterator_destroy(itr)

    return out_str
