# c_hostlist.pxd
#
cdef extern from "slurm/slurm.h" nogil:
    ctypedef struct hostlist:
        pass

    ctypedef hostlist *hostlist_t

    hostlist_t slurm_hostlist_create(const char *hostlist)
    int slurm_hostlist_count(hostlist_t hl)
    void slurm_hostlist_destroy(hostlist_t hl)
    int slurm_hostlist_find(hostlist_t hl, const char *hostname)
    int slurm_hostlist_push(hostlist_t hl, const char *hosts)
    int slurm_hostlist_push_host(hostlist_t hl, const char *host)
    char *slurm_hostlist_shift(hostlist_t hl)
    void slurm_hostlist_uniq(hostlist_t hl)
    char *slurm_hostlist_ranged_string_malloc(hostlist_t hl)
