# cython: embedsignature=True
# cython: c_string_type=unicode, c_string_encoding=utf8
"""
============
:mod:`block`
============

The block extension module is used to get Slurm BlueGene block information.

Slurm API Functions
-------------------

This module declares and wraps the following Slurm API functions:

- slurm_print_block_info_msg
- slurm_print_block_info
- slurm_load_block_info
- slurm_free_block_info_msg
- slurm_update_block
- slurm_init_update_block_msg

Block Object
------------

Functions in this module wrap the ``block_info_t`` struct found in `slurm.h`.
The members of this struct are converted to a :class:`Block` object, which
implements Python properties to retrieve the value of each attribute.

Each block record in a ``block_info_msg_t`` struct is converted to a
:class:`Block` object when calling some of the functions in this module.

"""
from __future__ import absolute_import, unicode_literals

from libc.stdio cimport stdout

from .c_block cimport *
from .slurm_common cimport *
from .exceptions import PySlurmError

cdef class Block:
    """An object to wrap `block_info_t` structs."""
    cdef:
        readonly unicode bg_block_id
        readonly unicode blrts_image
        readonly unicode cnload_image
        readonly unicode conn_type
        readonly unicode ioload_image
        List job_list
        readonly unicode linux_image
        readonly unicode mid_planes
        readonly unicode mloader_image
        readonly unicode ramdisk_image
        readonly unicode reason
        readonly unicode state
        readonly unicode total_nodes

    @property
    def job_list(self):
        cdef:
            int j
            block_job_info_t *block_job

        j = 0
        j = slurm_list_count(self.job_list)

        if not j:
            return "NONE"
        # FIXME: Cannot assign type 'void *' to 'block_job_info_t *'
#        elif j == 1:
#            block_job = <block_job_info_t *>slurm_list_peek(self.job_list)
#            return block_job.job_id
        else:
            return "Multiple"


def get_blocks(ids=False):
    """
    Return a list of all blocks as :class:`Block` objects.  This function calls
    ``slurm_load_block_info`` to retrieve information for all blocks.

    Args:
        ids (Optional[bool]): Return list of only block ids if True
            (default: False).

    Returns:
        list: A list of :class:`Block` objects, one for each block.

    Raises:
        PySlurmError: if ``slurm_load_block_info`` is unsuccessful.

    """
    return get_block_info_msg(None, ids)


def get_block(block):
    """
    Return a single :class:`Block` object for the given block.  This
    function calls ``slurm_load_block_info`` to retrieve information for all
    blocks, but the response only includes the specified block.

    Args:
        block (str): block name to query

    Returns:
        Block: A single :class:`Block` object

    Raises:
        PySlurmError: if ``slurm_load_block_info`` is unsuccessful.
    """
    return get_block_info_msg(block)


cdef get_block_info_msg(block, ids=False):
    cdef:
        block_info_msg_t *block_info_msg_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        uint32_t cluster_flags = slurmdb_setup_cluster_flags()
        int rc
        int j
        char tmp1[16]
        char tmp2[16]

    rc = slurm_load_block_info(<time_t> NULL, &block_info_msg_ptr, show_flags)

    block_list = []
    if rc == SLURM_SUCCESS:
        for record in block_info_msg_ptr.block_array[:block_info_msg_ptr.record_count]:
            if block:
                if block and (block != <unicode>record.bg_block_id):
                    continue

            if ids and block is None:
                if record.bg_block_id:
                    block_list.append(record.bg_block_id)
                continue

            this_block = Block()

            # Line 1
            slurm_convert_num_unit(<float>record.cnode_cnt, tmp1, sizeof(tmp1),
                                   UNIT_NONE, NO_VAL, CONVERT_NUM_UNIT_EXACT)

            if (cluster_flags & CLUSTER_FLAG_BGQ):
                slurm_convert_num_unit(<float>record.cnode_err_cnt, tmp2,
                                       sizeof(tmp2), UNIT_NONE, NO_VAL,
                                       CONVERT_NUM_UNIT_EXACT)
                this_block.total_nodes = "%s/%s" % (tmp1, tmp2)
            else:
                this_block.total_nodes = tmp1

            if record.bg_block_id:
                this_block.block_name = record.bg_block_id

            this_block.state = slurm_bg_block_state_string(record.state)

            # Line 2
            this_block.job_list = record.job_list
            this_block.conn_type = slurm_conn_type_string_full(record.conn_type)

            # Line 3
            if record.ionode_str and record.mp_str:
                this_block.mid_planes = "%s[%s]" % (record.mp_str, record.ionode_str)
            else:
                this_block.mid_planes = record.mp_str

            #TODO: MPIndices

            # Line 4
            if record.mloaderimage:
                this_block.mloader_image = record.mloaderimage

            if record.reason:
                this_block.reason = record.reason

            block_list.append(this_block)

        slurm_free_block_info_msg(block_info_msg_ptr)
        block_info_msg_ptr = NULL

        if block and block_list:
            return block_list[0]
        else:
            return block_list
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


cpdef print_block_info_msg(int one_liner=False):
    """
    Print information about all blocks to stdout.

    This function outputs information about all Slurm blocks based upon the
    message loaded by ``slurm_load_block_info``. It uses the
    ``slurm_print_block_info_msg`` function to print to stdout.  The output is
    equivalent to *scontrol show block*.

    Args:
        one_liner (Optional[bool]): print partitions on one line if True
            (default False)
    Raises:
        PySlurmError: If ``slurm_load_partitions`` is not successful.
    """
    cdef:
        block_info_msg_t *block_info_msg_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        int rc

    rc = slurm_load_block_info(<time_t> NULL, &block_info_msg_ptr, show_flags)

    if rc == SLURM_SUCCESS:
        slurm_print_block_info_msg(stdout, block_info_msg_ptr, one_liner)
        slurm_free_block_info_msg(block_info_msg_ptr)
        block_info_msg_ptr = NULL
    else:
        raise PySlurmError(slurm_strerror(rc), rc)
