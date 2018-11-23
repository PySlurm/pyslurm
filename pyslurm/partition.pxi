# Actual partition states based up state flags
PARTITION_SUBMIT   = 0x01
PARTITION_SCHED    = 0x02
PARTITION_DOWN     = PARTITION_SUBMIT
PARTITION_UP       = PARTITION_SUBMIT | PARTITION_SCHED
PARTITION_DRAIN    = PARTITION_SCHED
PARTITION_INACTIVE = 0x00

# Current partition state information.  Used to set partition options using
# slurm_update_partition()
PART_FLAG_DEFAULT        = 0x0001
PART_FLAG_HIDDEN         = 0x0002
PART_FLAG_NO_ROOT        = 0x0004
PART_FLAG_ROOT_ONLY      = 0x0008
PART_FLAG_REQ_RESV       = 0x0010
PART_FLAG_LLN            = 0x0020
PART_FLAG_EXCLUSIVE_USER = 0x0040

# Used with slurm_update_partition() to clear flags associated with existing
# partitions. For example, if a partition is currently hidden and you want to
# make it visible then set flags to PART_FLAG_HIDDEN_CLR and call
# slurm_update_partition().
PART_FLAG_DEFAULT_CLR   = 0x0100
PART_FLAG_HIDDEN_CLR    = 0x0200
PART_FLAG_NO_ROOT_CLR   = 0x0400
PART_FLAG_ROOT_ONLY_CLR = 0x0800
PART_FLAG_REQ_RESV_CLR  = 0x1000
PART_FLAG_LLN_CLR       = 0x2000
PART_FLAG_EXC_USER_CLR  = 0x4000
