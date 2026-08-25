---
title: Node
---

The `Node` class represents a compute node registered with the Slurm controller.
Use [`Nodes.load`][pyslurm.Nodes.load] to fetch all nodes or
[`Node.load`][pyslurm.Node.load] for a single node by name.
Nodes can be drained, modified, created, or deleted using the write methods.
For partition membership, see [Partition](partition.md).

::: pyslurm.Node
::: pyslurm.Nodes
