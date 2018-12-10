# c_account.pxd
#
from libc.stdint cimport uint16_t
from posix.types cimport time_t

from ..slurm_common cimport List

cdef extern from "slurm/slurmdb.h" nogil:
    ctypedef struct slurmdb_assoc_cond_t:
        List acct_list
        List cluster_list
        List def_qos_id_list
        List format_list
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

    ctypedef struct slurmdb_account_rec_t:
        List assoc_list
        List coordinators
        char *description
        char *name
        char *organization

    ctypedef struct slurmdb_coord_rec_t:
        char *name
        uint16_t direct

    int slurmdb_accounts_add(void *db_conn, List acct_list)
    List slurmdb_accounts_get(void *db_conn, slurmdb_account_cond_t *acct_cond)

    List slurmdb_accounts_modify(
        void *db_conn,
        slurmdb_account_cond_t *acct_cond,
        slurmdb_account_rec_t *acct
    )

    List slurmdb_accounts_remove(void *db_conn, slurmdb_account_cond_t *acct_cond)
    void slurmdb_destroy_account_cond(void *object)
