# cython: embedsignature=True
"""
================
:mod:`partition`
================

The partition extension module retrieves information about configured paritions
in Slurm.

Slurm API Functions
-------------------

- slurm_create_partition
- slurm_delete_partition
- slurm_free_partition_info_msg
- slurm_init_part_desc_msg
- slurm_load_partitions
- slurm_print_partition_info_msg
- slurm_print_partition_info
- slurm_update_partition


Partition Objects
-----------------

Functions in this module wrap the ``partition_info_t`` struct found in
`slurm.h`.  The members of this struct are converted to a :class:`Partition`
object.

Each partition in a ``partition_info_msg_t`` struct is converted to a
:class:`Partition` object when calling some of the functions in this module.

"""
from __future__ import absolute_import, print_function, unicode_literals

from cpython cimport bool
from libc.stdio cimport stdout
from .c_partition cimport *
from .c_node cimport *
from .c_hostlist cimport *
from .slurm_common cimport *
from .utils cimport *
from .exceptions import PySlurmError
from collections import defaultdict

include "partition.pxi"
include "node.pxi"

cdef class Partition:
    """An object to wrap `partition_info_t` structs."""
    cdef:
        readonly unicode alloc_nodes
        unicode allow_accounts
        unicode allow_groups
        unicode allow_qos
        readonly unicode alternate
        readonly unicode billing_weights_str
        readonly unicode cluster_name
        readonly uint16_t cr_type
        uint32_t cpu_bind
        uint64_t def_mem_per_cpu
        bool default
        uint32_t default_time
        uint32_t default_time_str
        readonly list deny_accounts
        readonly list deny_qos
        readonly bool disable_root_jobs
        readonly bool exclusive_user
        readonly bool hidden
        readonly uint16_t flags
        readonly uint32_t grace_time
        readonly list job_defaults_list
        readonly list job_defaults
        readonly bool lln
        uint32_t max_cpus_per_node
        uint64_t max_mem_per_cpu
        uint32_t max_nodes
        readonly uint16_t max_share
        uint32_t max_time
        uint32_t max_time_str
        readonly uint32_t min_nodes
        int32_t node_inx
        readonly unicode nodes
        uint16_t over_time_limit
        uint16_t over_subscribe
        readonly unicode partition_name
        readonly uint16_t preempt_mode
        readonly unicode preempt_mode_str
        readonly uint16_t priority_job_factor
        readonly uint16_t priority_tier
        readonly unicode qos
        readonly bool req_resv
        readonly bool root_only
        readonly unicode state
        readonly uint16_t state_up
        readonly uint32_t total_cpus
        readonly uint32_t total_nodes
        readonly unicode tres_billing_weights
        readonly unicode tres_fmt_str

    @property
    def allow_alloc_accounts(self):
        """Comma delimited list of accounts"""
        if not self.allow_accounts:
            return "ALL"
        else:
            return self.allow_accounts.split(",")

    @property
    def allow_accounts(self):
        """Comma delimited list of accounts"""
        if not self.allow_accounts:
            return "ALL"
        else:
            return self.allow_accounts.split(",")

    @property
    def allow_groups(self):
        """Comma delimited list of groups"""
        if self.allow_groups:
            return self.allow_groups.split(",")
        else:
            return "ALL"

    @property
    def allow_qos(self):
        """Comma delimited list of qos"""
        if not self.allow_qos:
            return "ALL"
        else:
            return self.allow_qos.split(",")

    @property
    def cpu_bind(self):
        """Default task binding"""
        cpu_bind_list = slurm_sprint_cpu_bind_type(<cpu_bind_type_t>self.cpu_bind)
        return cpu_bind_list

    @property
    def default_time(self):
        """minutes, NO_VAL or INFINITE"""
        if self.default_time == INFINITE:
            return "UNLIMITED"
        elif self.default_time == NO_VAL:
            return None
        else:
            return self.default_time * 60

    @property
    def default_time_str(self):
        """minutes, NO_VAL or INFINITE"""
        cdef char time_line[32]
        if self.default_time == INFINITE:
            return "UNLIMITED"
        elif self.default_time == NO_VAL:
            return None
        else:
            slurm_secs2time_str(self.default_time * 60, time_line, sizeof(time_line))
            return time_line

    @property
    def def_mem_per_cpu(self):
        """Default MB memory per allocated CPU"""
        if self.def_mem_per_cpu & MEM_PER_CPU:
            if self.def_mem_per_cpu == MEM_PER_CPU:
                return "UNLIMITED"
            else:
                return self.def_mem_per_cpu & (~MEM_PER_CPU)
        else:
            return None

    @property
    def def_mem_per_node(self):
        """Default MB memory per allocated node"""
        if self.def_mem_per_cpu & MEM_PER_CPU:
            return None
        elif self.def_mem_per_cpu == 0:
            return "UNLIMITED"
        else:
            # def_mem_per_node == def_mem_per_cpu
            return self.def_mem_per_cpu

    @property
    def max_cpus_per_node(self):
        """Maximum allocated CPUs per node"""
        if self.max_cpus_per_node == INFINITE:
            return "UNLIMITED"
        else:
            return self.max_cpus_per_node

    @property
    def max_mem_per_cpu(self):
        """Maximum MB memory per allocated CPU"""
        if self.max_mem_per_cpu & MEM_PER_CPU:
            if self.max_mem_per_cpu == MEM_PER_CPU:
                return "UNLIMITED"
            else:
                return self.max_mem_per_cpu & (~MEM_PER_CPU)
        else:
            return None

    @property
    def max_mem_per_node(self):
        """Maximum MB memory per allocated node"""
        if self.max_mem_per_cpu & MEM_PER_CPU:
            return None
        elif self.max_mem_per_cpu == 0:
            return "UNLIMITED"
        else:
            # max_mem_per_node == max_mem_per_cpu
            return self.max_mem_per_cpu

    @property
    def max_nodes(self):
        """per job or INFINITE"""
        if self.max_nodes == INFINITE:
            return "UNLIMITED"
        else:
            return self.max_nodes

    @property
    def max_time(self):
        """minutes or INFINITE"""
        if self.max_time == INFINITE:
            return "UNLIMITED"
        else:
            return self.max_time * 60

    @property
    def max_time_str(self):
        """minutes or INFINITE"""
        cdef char time_line[32]
        if self.max_time == INFINITE:
            return "UNLIMITED"
        else:
            slurm_secs2time_str(self.max_time * 60, time_line, sizeof(time_line))
            return time_line

    @property
    def over_time_limit(self):
        """Job's time limit can be exceeded by this number of minutes before
        cancellation"""
        if self.over_time_limit == NO_VAL16:
            return None
        elif self.over_time_limit == INFINITE16:
            return "UNLIMITED"
        else:
            return self.over_time_limit

    @property
    def select_type_parameters(self):
        """Select Type Parameters."""
        if select_type_param_string(self.cr_type) is not None:
            return select_type_param_string(self.cr_type)
        else:
            return None

    @property
    def over_subscribe(self):
        """is the partition shared"""
        cdef:
            uint16_t force
            uint16_t val

        force = self.max_share & SHARED_FORCE
        val = self.max_share & (~SHARED_FORCE)

        if val == 0:
            return "EXCLUSIVE"
        elif force:
            return "FORCE:%s" % val
        elif val == 1:
            return "NO"
        else:
            return "YES:%s" % val


def get_partitions(ids=False):
    """
    """
    return get_partition_info_msg(None, ids)


def get_partition(partition):
    """
    """
    return get_partition_info_msg(partition)


cdef get_partition_info_msg(partition, ids=False):
    """
    Get all slurm partition information

    This function wraps the ``slurm_sprint_partition_info`` function in
    `src/api/partition_info.c`.

    """
    cdef:
        partition_info_msg_t *part_info_msg_ptr
        char tmp[16]
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        uint16_t preempt_mode
        uint32_t cluster_flags = slurmdb_setup_cluster_flags()
        int rc

    rc = slurm_load_partitions(<time_t> NULL, &part_info_msg_ptr, show_flags)

    part_list = []
    if rc == SLURM_SUCCESS:

        for record in part_info_msg_ptr.partition_array[:part_info_msg_ptr.record_count]:

            if partition and (partition != tounicode(record.name)):
                continue

            if ids and (partition is None):
                part_list.append(tounicode(record.name))
                continue

            this_part = Partition()

            # Line 1
            this_part.partition_name = tounicode(record.name)

            # Line 2
            this_part.allow_groups = tounicode(record.allow_groups)

            if record.allow_accounts or not record.deny_accounts:
                this_part.allow_accounts = tounicode(record.allow_accounts)
            else:
                this_part.deny_accounts = tounicode(record.deny_accounts).split(",")

            if record.allow_qos or not record.deny_qos:
                this_part.allow_qos = tounicode(record.allow_qos)
            else:
                this_part.deny_qos = tounicode(record.allow_qos).split(",")

            # Line 3
            if record.allow_alloc_nodes == NULL:
                this_part.alloc_nodes = tounicode("ALL")
            else:
                this_part.alloc_nodes = tounicode(record.allow_alloc_nodes)

            if record.alternate != NULL:
                this_part.alternate = tounicode(record.alternate)

            this_part.flags = record.flags

            if record.flags & PART_FLAG_DEFAULT:
                this_part.default = True
            else:
                this_part.default = False

            if record.cpu_bind:
                this_part.cpu_bind = record.cpu_bind
                
            if record.qos_char:
                this_part.qos = tounicode(record.qos_char)
            else:
                this_part.qos = None

            # Line 4
            this_part.default_time = record.default_time
            this_part.default_time_str = record.default_time

            if record.flags & PART_FLAG_NO_ROOT:
                this_part.disable_root_jobs = True
            else:
                this_part.disable_root_jobs = False

            if record.flags & PART_FLAG_EXCLUSIVE_USER:
                this_part.exclusive_user = True
            else:
                this_part.exclusive_user = False

            this_part.grace_time = record.grace_time

            if record.flags & PART_FLAG_HIDDEN:
                this_part.hidden = True
            else:
                this_part.hidden = False

            # Line 5
            this_part.max_nodes = record.max_nodes
            this_part.max_time = record.max_time
            this_part.max_time_str = record.max_time
            this_part.min_nodes = record.min_nodes

            if record.flags & PART_FLAG_LLN:
                this_part.lln = True
            else:
                this_part.lln = False

            this_part.max_cpus_per_node = record.max_cpus_per_node

            # Line 6
            this_part.nodes = tounicode(record.nodes)

            # Line 7
            this_part.priority_job_factor = record.priority_job_factor
            this_part.priority_tier = record.priority_tier

            if record.flags & PART_FLAG_ROOT_ONLY:
                this_part.root_only = True
            else:
                this_part.root_only = False

            if record.flags & PART_FLAG_REQ_RESV:
                this_part.req_resv = True
            else:
                this_part.req_resv = False

            this_part.max_share = record.max_share

            # Line 8
            this_part.over_time_limit = record.over_time_limit
            this_part.preempt_mode = record.preempt_mode
            preempt_mode = record.preempt_mode

            if preempt_mode == NO_VAL16:
                preempt_mode = slurm_get_preempt_mode()
            this_part.preempt_mode_str = tounicode(
                slurm_preempt_mode_string(preempt_mode)
            )

            # Line 9
            this_part.state_up = record.state_up

            if record.state_up == PARTITION_UP:
                this_part.state = "UP"
            elif record.state_up == PARTITION_DOWN:
                this_part.state = "DOWN"
            elif record.state_up == PARTITION_INACTIVE:
                this_part.state = "INACTIVE"
            elif record.state_up == PARTITION_DRAIN:
                this_part.state = "DRAIN"
            else:
                this_part.state = "UNKNOWN"

            this_part.total_cpus = record.total_cpus
            this_part.total_nodes = record.total_nodes

            # Line 10
            value = job_defaults_str(record.job_defaults_list)
            if value:
                this_part.job_defaults = tounicode(value).split(",")
            else:
                this_part.job_defaults = None

            # Line 11
            this_part.def_mem_per_cpu = record.def_mem_per_cpu
            this_part.max_mem_per_cpu = record.max_mem_per_cpu

            # Line 12
            if record.billing_weights_str:
                this_part.tres_billing_weights = tounicode(
                    record.billing_weights_str
                )

            this_part.tres_fmt_str = tounicode(record.tres_fmt_str)

            part_list.append(this_part)

        slurm_free_partition_info_msg(part_info_msg_ptr)
        part_info_msg_ptr = NULL

        if partition and part_list:
            return part_list[0]
        else:
            return part_list
    else:
            raise PySlurmError(slurm_strerror(rc), rc)


def print_partition_info_msg(int one_liner=False):
    """
    Print information about all partitions to stdout.

    This function outputs information about all Slurm partitions based upon the
    message loaded by ``slurm_load_partitions``. It uses the
    ``slurm_print_partition_info_msg`` function to print to stdout.  The output is
    equivalent to *scontrol show partition*.

    Args:
        one_liner (Optional[bool]): print partitions on one line if True
            (default False)
    Raises:
        PySlurmError: If ``slurm_load_partitions`` is not successful.
    """
    cdef:
        partition_info_msg_t *part_info_msg_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        int rc

    rc = slurm_load_partitions(<time_t>NULL, &part_info_msg_ptr, show_flags)

    if rc == SLURM_SUCCESS:
        slurm_print_partition_info_msg(stdout, part_info_msg_ptr, one_liner)
        slurm_free_partition_info_msg(part_info_msg_ptr)
        part_info_msg_ptr = NULL
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


def print_partition_info(partition, int one_liner=False):
    """
    Print information about a specific partition to stdout.

    This function outputs information about a given Slurm partition based upon the
    message loaded by ``slurm_load_partitions``. It uses the
    ``slurm_print_partition_info`` function to print to stdout.  The output is
    equivalent to *scontrol show partition <partition name>*

    Args:
        partition (str): print single partition
        one_liner (Optional[bool]): print single partition on one line if True
            (default False)
    Raises:
        PySlurmError: If ``slurm_load_partitions`` is not successful.
    """
    cdef:
        partition_info_msg_t *part_info_msg_ptr = NULL
        uint16_t show_flags = SHOW_ALL | SHOW_DETAIL
        uint32_t i
        int rc
        int print_cnt = 0

    b_partition = partition.encode("UTF-8")
    rc = slurm_load_partitions(<time_t>NULL, &part_info_msg_ptr, show_flags)

    if rc == SLURM_SUCCESS:
        for i in range(part_info_msg_ptr.record_count):
            record = &part_info_msg_ptr.partition_array[i]
            if b_partition and (b_partition != record.name):
                continue

            print_cnt += 1
            slurm_print_partition_info(stdout, record, one_liner)
            if partition:
                break

        # FIXME: need to refactor this bit.
        if print_cnt == 0:
            if partition:
                print("Partition %s not found" % b_partition)
                return 1
            else:
                print("No partitions in the system")

        slurm_free_partition_info_msg(part_info_msg_ptr)
        part_info_msg_ptr = NULL
    else:
        raise PySlurmError(slurm_strerror(rc), rc)


def find_partitions(partattr, pattern, ids=False):
    pass


cdef update_part_msg(action, part_dict):
    """
    Request update or creation of a new partition.

    Notes:
        #. This method requires **root** privileges.
        #. Use :func:`get_errno` to translate return code if not 0.
        #. Partition name must be set for the call to succeed.

    """
    cdef:
        update_part_msg_t update_part_msg
        int rc

    if not part_dict:
        raise PySlurmError("You must provide a partition create dictionary")

    slurm_init_part_desc_msg(&update_part_msg)

    if "AllocNodes" in part_dict:
        update_part_msg.allow_alloc_nodes = part_dict["AllocNodes"]

    if "AllowAccounts" in part_dict:
        # should this be comma separated list or string?
        # The output of get_partition is a list.
        # Or take both?
#        if isinstance(part_dict["AllowAccounts"], list):
#            update_part_msg.allow_accounts = ",".join(part_dict["AllowAccounts"])
#        else:
#            update_part_msg.allow_accounts = part_dict["AllowAccounts"]
         update_part_msg.allow_accounts = part_dict["AllowAccounts"]

    if "AllowGroups" in part_dict:
        update_part_msg.allow_groups = part_dict["AllowGroups"]

    if "AllowQoS" in part_dict:
        update_part_msg.allow_qos = part_dict["AllowQos"]

    if "Name" in part_dict:
        update_part_msg.name = part_dict["Name"]

    if "State" in part_dict:
        update_part_msg.state_up = part_dict["State"]

    if action == "create":
        rc = slurm_create_partition(&update_part_msg)
        return rc
    elif action == "update":
        rc = slurm_update_partition(&update_part_msg)
        return rc


def create_partition(part_dict):
    """
    Request creation of a new partition.

    Notes:
        #. This method requires **root** privileges.
        #. Use :func:`get_errno` to translate return code if not 0.
        #. Partition name must be set for the call to succeed.

    """
    update_part_msg("create", part_dict)


def update_partition(part_dict):
    """
    Request to update the configuration of a partition.

    Notes:
        #. This method requires **root** privileges.
        #. Use :func:`get_errno` to translate return code if not 0.
        #. Most, but not all, parameters of a partition may be changed by this function.

    """
    update_part_msg("update", part_dict)


def delete_partition(partition):
    """
    Delete a Slurm partition.

    Notes:
        #. This method requires **root** privileges.
        #. Use :func:`get_errno` to translate return code if not 0.

    """
    cdef:
        delete_part_msg_t delete_part_msg
        int rc
        int errno

    b_partition = partition.encode("UTF-8", "replace")
    rc = slurm_delete_partition(&delete_part_msg)

    return rc
# Should this actually raise an error here?  or just return the error code and
# have the user get the errno/string
#
#    if rc != SLURM_SUCCESS:
#        errno = slurm_get_errno()
#        raise PySlurmError
#    return rc
#
# Should make a note for the user to check:
# if rc == -1:
#     errno = slurm_get_errno(rc)
#     print(slurm_strerror(errno), errno)