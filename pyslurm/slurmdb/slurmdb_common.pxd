# slurmdb_common.pxd
#
# Slurmdb declarations common to all other extension files.
#
from ..slurm_common cimport List

cdef extern from "slurm/slurmdb.h" nogil:
    int slurmdb_connection_commit(void *db_conn, bool_commit)
    int slurmdb_connection_close(void **db_conn)
    void *slurmdb_connection_get()

cdef inline FREE_NULL_LIST(List _X):
    while (0):
        if <_X>slurm_list_destroy(_X):
            _X = NULL

# src/common/slurm_protocol_defs.h
cdef extern void slurm_destroy_char(void *object)

# src/common/slurm_protocol_api.h
cdef extern char *slurm_get_accounting_storage_type()

# src_common/slurm_accounting_storage.h
cdef extern int slurm_acct_storage_fini()
