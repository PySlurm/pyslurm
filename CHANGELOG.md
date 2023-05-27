# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased on the [23.2.x](https://github.com/PySlurm/pyslurm/tree/23.2.x) branch

### Added

- Ability to modify Database Jobs
- New classes to interact with the Partition API
    - [pyslurm.Partition](https://pyslurm.github.io/23.2/reference/partition/#pyslurm.Partition)
    - [pyslurm.Partitions](https://pyslurm.github.io/23.2/reference/partition/#pyslurm.Partitions)
- New attributes for a Database Job:
    - extra
    - failed_node
- Now possible to initialize a pyslurm.db.Jobs collection with existing job
  ids or pyslurm.db.Job objects

### Fixed

- Fixes a problem that prevented loading specific Jobs from the Database if
  the following two conditions were met:
    - no start/end time was specified
    - the Job was older than a day

## [23.2.1](https://github.com/PySlurm/pyslurm/releases/tag/v23.2.1) - 2023-05-18

### Added

- Classes to interact with the Job and Submission API
    - [pyslurm.Job](https://pyslurm.github.io/23.2/reference/job/#pyslurm.Job)
    - [pyslurm.Jobs](https://pyslurm.github.io/23.2/reference/job/#pyslurm.Jobs)
    - [pyslurm.JobStep](https://pyslurm.github.io/23.2/reference/jobstep/#pyslurm.JobStep)
    - [pyslurm.JobSteps](https://pyslurm.github.io/23.2/reference/jobstep/#pyslurm.JobSteps)
    - [pyslurm.JobSubmitDescription](https://pyslurm.github.io/23.2/reference/jobsubmitdescription/#pyslurm.JobSubmitDescription)
- Classes to interact with the Database Job API
    - [pyslurm.db.Job](https://pyslurm.github.io/23.2/reference/db/job/#pyslurm.db.Job)
    - [pyslurm.db.Jobs](https://pyslurm.github.io/23.2/reference/db/job/#pyslurm.db.Jobs)
    - [pyslurm.db.JobStep](https://pyslurm.github.io/23.2/reference/db/jobstep/#pyslurm.db.JobStep)
    - [pyslurm.db.JobSearchFilter](https://pyslurm.github.io/23.2/reference/db/jobsearchfilter/#pyslurm.db.JobSearchFilter)
- Classes to interact with the Node API
    - [pyslurm.Node](https://pyslurm.github.io/23.2/reference/node/#pyslurm.Node)
    - [pyslurm.Nodes](https://pyslurm.github.io/23.2/reference/node/#pyslurm.Nodes)
- Exceptions added:
    - [pyslurm.PyslurmError](https://pyslurm.github.io/23.2/reference/exceptions/#pyslurm.PyslurmError)
    - [pyslurm.RPCError](https://pyslurm.github.io/23.2/reference/exceptions/#pyslurm.RPCError)
- [Utility Functions](https://pyslurm.github.io/23.2/reference/utilities/#pyslurm.utils)

### Changes

- Completely overhaul the documentation, switch to mkdocs
- Rework the tests: Split them into unit and integration tests

### Deprecated

- Following classes are superseded by new ones:
    - [pyslurm.job](https://pyslurm.github.io/23.2/reference/old/job/#pyslurm.job)
    - [pyslurm.node](https://pyslurm.github.io/23.2/reference/old/node/#pyslurm.node)
    - [pyslurm.jobstep](https://pyslurm.github.io/23.2/reference/old/jobstep/#pyslurm.jobstep)
    - [pyslurm.slurmdb_jobs](https://pyslurm.github.io/23.2/reference/old/db/job/#pyslurm.slurmdb_jobs)

## [23.2.0](https://github.com/PySlurm/pyslurm/releases/tag/v23.2.0) - 2023-04-07

### Added

- Support for Slurm 23.02.x ([f506d63](https://github.com/PySlurm/pyslurm/commit/f506d63634a9b20bfe475534589300beff4a8843))

### Removed

- `Elasticsearch` debug flag from `get_debug_flags`
- `launch_type`, `launch_params` and `slurmctld_plugstack` keys from the
  `config.get()` output
- Some constants (mostly `ESLURM_*` constants that do not exist
  anymore)
