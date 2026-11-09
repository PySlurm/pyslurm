---
title: Migrating from the Old API
---

# Migrating from the Old API

PySlurm 25.11 removed the long-deprecated legacy API classes. This page lists
each removed class and its replacement.

## Removed classes and their replacements

| Removed | Replacement |
|---------|-------------|
| `pyslurm.job` | [`pyslurm.Job`][pyslurm.Job], [`pyslurm.Jobs`][pyslurm.Jobs], [`pyslurm.JobSubmitDescription`][pyslurm.JobSubmitDescription] |
| `pyslurm.node` | [`pyslurm.Node`][pyslurm.Node], [`pyslurm.Nodes`][pyslurm.Nodes] |
| `pyslurm.jobstep` | [`pyslurm.JobStep`][pyslurm.JobStep], [`pyslurm.JobSteps`][pyslurm.JobSteps] |
| `pyslurm.partition` | [`pyslurm.Partition`][pyslurm.Partition], [`pyslurm.Partitions`][pyslurm.Partitions] |
| `pyslurm.reservation` | [`pyslurm.Reservation`][pyslurm.Reservation], [`pyslurm.Reservations`][pyslurm.Reservations] |
| `pyslurm.statistics` | `pyslurm.slurmctld.diag()` → [`pyslurm.slurmctld.Statistics`][pyslurm.slurmctld.Statistics] |
| `pyslurm.front_end` | Removed from Slurm — no replacement |
| `pyslurm.config` | [`pyslurm.slurmctld.Config`][pyslurm.slurmctld.Config] |

## Loading data

Old API used `get_*()` module-level functions. The new API uses classmethods:

```python
# Old
import pyslurm
jobs = pyslurm.job().get()

# New
import pyslurm
jobs = pyslurm.Jobs.load()
```

## Iterating

```python
# Old
for job_id, attrs in pyslurm.job().get().items():
    print(job_id, attrs["job_state"])

# New
for job in pyslurm.Jobs.load().values():
    print(job.id, job.state)
```

## Submitting a job

```python
# Old
import pyslurm
job_id = pyslurm.job().submit_batch_job(0, {"name": "myjob", "script": "#!/bin/bash\nhostname"})

# New
import pyslurm
desc = pyslurm.JobSubmitDescription(name="myjob", script="#!/bin/bash\nhostname")
job_id = desc.submit()
```
