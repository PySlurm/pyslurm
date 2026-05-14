---
title: Partition
---

The `Partition` class represents a Slurm partition (queue), which is a logical
grouping of nodes with shared scheduling policies and resource limits. Jobs are
submitted to a partition. Use [`Partitions.load`][pyslurm.Partitions.load] to
fetch all partitions. For the nodes within a partition, see [Node](node.md).

::: pyslurm.Partition
::: pyslurm.Partitions
