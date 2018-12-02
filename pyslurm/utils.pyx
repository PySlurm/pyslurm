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
from .slurm_common cimport *
from .c_config cimport *
from .utils cimport *

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
    if (cpu_bind_type & CPU_BIND_OFF):
        cbtlist.append("off")
    return cbtlist


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
