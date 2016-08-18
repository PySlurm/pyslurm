# c_topology.pxd
#
from libc.stdint cimport uint16_t, uint32_t
from libc.stdio cimport FILE

cdef extern from "slurm/slurm.h" nogil:
    ctypedef struct topo_info_t:
        uint16_t level
        uint32_t link_speed
        char *name
        char *nodes
        char *switches

    ctypedef struct topo_info_response_msg_t:
        uint32_t record_count
        topo_info_t *topo_array


    int slurm_load_topo(topo_info_response_msg_t **topo_info_msg_pptr)
    void slurm_free_topo_info_msg(topo_info_response_msg_t *msg)

    void slurm_print_topo_info_msg(FILE *out,
                                   topo_info_response_msg_t *topo_info_msg_ptr,
                                   int one_liner)

    void slurm_print_topo_record(FILE *out, topo_info_t *topo_ptr,
                                 int one_liner)
