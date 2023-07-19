# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased on the [21.8.x](https://github.com/PySlurm/pyslurm/tree/21.8.x) branch

### Added

- New Classes to interact with Database Associations (WIP)
    - `pyslurm.db.Association`
    - `pyslurm.db.Associations`
- New Classes to interact with Database QoS (WIP)
    - `pyslurm.db.QualityOfService`
    - `pyslurm.db.QualitiesOfService`

## [21.8.1](https://github.com/PySlurm/pyslurm/releases/tag/v21.8.1) - 2023-07-19

### Added

- A `pyproject.toml` file to ease installation ([PR #239](https://github.com/PySlurm/pyslurm/pull/239) by [tazend](https://github.com/tazend))
- Allow specifying Slurm lib-dir and include-dir via `SLURM_LIB_DIR` and `SLURM_INCLUDE_DIR` environment variables on install ([PR #239](https://github.com/PySlurm/pyslurm/pull/239) by [tazend](https://github.com/tazend))
- `wait_finished` method to pyslurm.job class, which blocks until a specified
  job is finished ([PR #242](https://github.com/PySlurm/pyslurm/pull/242) by [JonaOtto](https://github.com/JonaOtto))
- Support updating `end_time` in `slurm_update_reservation` ([PR #255](https://github.com/PySlurm/pyslurm/pull/255) by [pllopsis](https://github.com/pllopis))
- Classes to interact with the Job and Submission API ([PR #283](https://github.com/PySlurm/pyslurm/pull/283) by [tazend](https://github.com/tazend))
    - [pyslurm.Job][]
    - [pyslurm.Jobs][]
    - [pyslurm.JobStep][]
    - [pyslurm.JobSteps][]
    - [pyslurm.JobSubmitDescription][]
- Classes to interact with the Database Job API ([PR #283](https://github.com/PySlurm/pyslurm/pull/283) by [tazend](https://github.com/tazend))
    - [pyslurm.db.Job][]
    - [pyslurm.db.Jobs][]
    - [pyslurm.db.JobStep][]
    - [pyslurm.db.JobFilter][]
- Classes to interact with the Node API ([PR #283](https://github.com/PySlurm/pyslurm/pull/283) by [tazend](https://github.com/tazend))
    - [pyslurm.Node][]
    - [pyslurm.Nodes][]
- Exceptions added ([PR #283](https://github.com/PySlurm/pyslurm/pull/283) by [tazend](https://github.com/tazend))
    - [pyslurm.PyslurmError][]
    - [pyslurm.RPCError][]
- [Utility Functions][pyslurm.utils]
- New classes to interact with the Partition API
    - [pyslurm.Partition][]
    - [pyslurm.Partitions][]
- Added a new Base Class [MultiClusterMap][pyslurm.xcollections.MultiClusterMap] that some Collections inherit from.
- Added `to_json` function to all Collections

### Fixed

- Fix some typos in `pyslurm.job` class ([PR #243](https://github.com/PySlurm/pyslurm/pull/243) by [JonaOtto](https://github.com/JonaOtto), [PR #252](https://github.com/PySlurm/pyslurm/pull/252) by [schluenz](https://github.com/schluenz))
- Fix not being able to create RPMs with `bdist_rpm` ([PR #248](https://github.com/PySlurm/pyslurm/pull/248) by [tazend](https://github.com/tazend))
- Fix formatting error for `reservation_list` example ([PR #256](https://github.com/PySlurm/pyslurm/pull/256) by [pllopsis](https://github.com/pllopis))
- Fix RPC strings, bringing them in sync with slurm 21.08 when getting Slurm
  statistics via the `statistics` class ([PR #261](https://github.com/PySlurm/pyslurm/pull/261) by [wresch](https://github.com/wresch))

### Changed

- Now actually link to `libslurm.so` instead of `libslurmfull.so` ([PR #239](https://github.com/PySlurm/pyslurm/pull/239) by [tazend](https://github.com/tazend))
- Actually retrieve and return the batch script as a string, instead of just
  printing it ([PR #258](https://github.com/PySlurm/pyslurm/pull/258) by [tazend](https://github.com/tazend))
- Raise `ValueError` on `slurm_update_reservation` instead of just returning the
  error code ([PR #257](https://github.com/PySlurm/pyslurm/pull/257) by [pllopsis](https://github.com/pllopis))
- Completely overhaul the documentation ([PR #283](https://github.com/PySlurm/pyslurm/pull/283) by [tazend](https://github.com/tazend))
- Switch to mkdocs for generating documentation ([PR #271](https://github.com/PySlurm/pyslurm/pull/271) by [tazend](https://github.com/tazend), [multimeric](https://github.com/multimeric))
- Rework the tests: Split them into unit and integration tests ([PR #283](https://github.com/PySlurm/pyslurm/pull/283) by [tazend](https://github.com/tazend))

### Deprecated

- Following classes are superseded by new ones:
    - [pyslurm.job](https://pyslurm.github.io/22.5/reference/old/job/#pyslurm.job)
    - [pyslurm.node](https://pyslurm.github.io/22.5/reference/old/node/#pyslurm.node)
    - [pyslurm.jobstep](https://pyslurm.github.io/22.5/reference/old/jobstep/#pyslurm.jobstep)
    - [pyslurm.slurmdb_jobs](https://pyslurm.github.io/22.5/reference/old/db/job/#pyslurm.slurmdb_jobs)

## [21.8.0](https://github.com/PySlurm/pyslurm/releases/tag/v21.8.0) - 2022-03-01

### Added

- Support for Slurm 21.8.x ([PR #227](https://github.com/PySlurm/pyslurm/pull/227) by [rezib](https://github.com/rezib), [njcarriero](https://github.com/njcarriero))

### Fixed

- Fixed typo in slurmdb job dict: `user_cpu_sec` -> `user_cpu_usec` ([3c5ffad](https://github.com/PySlurm/pyslurm/pull/227/commits/3c5ffad8e177a3386f9aeecb3dacceb77d08a760) in [PR #227](https://github.com/PySlurm/pyslurm/pull/227) by [rezib](https://github.com/rezib))
