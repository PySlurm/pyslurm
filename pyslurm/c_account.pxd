# c_account.pxd
# Slurm DB API
#
from libc.stdint cimport uint16_t
from posix.types cimport time_t

cdef extern from "slurm/slurmdb.h" nogil:
    ctypedef struct list:
        pass

    ctypedef list *List

    ctypedef struct slurmdb_assoc_cond_t:
        List acct_list
        List cluster_list
        List def_qos_id_list
        List id_list
        uint16_t only_defs
        List parent_acct_list
        List partition_list
        List qos_list
        time_t usage_end
        time_t usage_start
        List user_list
        uint16_t with_usage
        uint16_t with_deleted
        uint16_t with_raw_qos
        uint16_t with_sub_accts
        uint16_t without_parent_info
        uint16_t without_parent_limits

    ctypedef struct slurmdb_account_cond_t:
        slurmdb_assoc_cond_t *assoc_cond
        List description_list
        List organization_list
        uint16_t with_assocs
        uint16_t with_coords
        uint16_t with_deleted

    void *slurmdb_connection_get()
    int slurmdb_connection_close(void **db_conn)
    List slurmdb_accounts_get(void *db_conn,
                              slurmdb_account_cond_t *acct_cond)
