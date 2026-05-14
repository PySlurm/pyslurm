---
title: JobStep
---

The `JobStep` class represents a single step within a Slurm job — typically
an `srun` invocation inside a batch script. Steps are automatically populated
on the parent [`Job`][pyslurm.Job] when calling [`Job.load`][pyslurm.Job.load]
for a running job, and are accessible via `job.steps`. See [Job](job.md) for
the parent job API.

::: pyslurm.JobStep
::: pyslurm.JobSteps
