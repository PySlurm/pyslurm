---
title: Getting Started
---

# Getting Started

## Prerequisites

- Slurm 25.11.x running with `slurmctld` accessible from the host
- Python 3.6+
- PySlurm installed (`pip install pyslurm` or [built from source](index.md))

## List all jobs

```python
import pyslurm

jobs = pyslurm.Jobs.load()
for job_id, job in jobs.items():
    print(f"{job_id}: {job.name} [{job.state}] user={job.user_name}")
```

## Load a single job

```python
import pyslurm

job = pyslurm.Job.load(12345)
print(job.name, job.state, job.allocated_nodes)
```

## Submit a job

```python
import pyslurm

desc = pyslurm.JobSubmitDescription(
    name="myjob",
    script="#!/bin/bash\nhostname",
    time_limit="01:00:00",
    ntasks=4,
)
job_id = desc.submit()
print(f"Submitted job {job_id}")
```

## List nodes

```python
import pyslurm

nodes = pyslurm.Nodes.load()
for name, node in nodes.items():
    print(f"{name}: {node.state} cpus={node.total_cpus} mem={node.real_memory}MB")
```

## List partitions

```python
import pyslurm

partitions = pyslurm.Partitions.load()
for name, part in partitions.items():
    print(f"{name}: {part.state} nodes={part.total_nodes}")
```

## Error handling

All Slurm RPC calls raise [`pyslurm.RPCError`][pyslurm.RPCError] on failure:

```python
import pyslurm

try:
    job = pyslurm.Job.load(99999)
except pyslurm.RPCError as e:
    print(f"Failed: {e}")
```

## Next steps

- [Job API](reference/job.md)
- [Node API](reference/node.md)
- [Partition API](reference/partition.md)
- [Database API](reference/db/index.md)
- [slurmctld API](reference/slurmctld.md)
