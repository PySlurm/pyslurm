# c_license.pxd
#
from libc.stdint cimport uint8_t, uint16_t, uint32_t
from posix.types cimport time_t

cdef extern from "slurm/slurm.h" nogil:
    ctypedef struct slurm_license_info_t:
        char *name
        uint32_t total
        uint32_t in_use
        uint32_t available
        uint8_t remote

    ctypedef struct license_info_msg_t:
        time_t last_update
        uint32_t num_lic
        slurm_license_info_t *lic_array

    int slurm_load_licenses(time_t t, license_info_msg_t **lic_info,
                            uint16_t show_flags)
    void slurm_free_license_info_msg(license_info_msg_t *lic_ptr)
