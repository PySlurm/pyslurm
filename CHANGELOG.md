# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [22.5.2](https://github.com/PySlurm/pyslurm/releases/tag/v22.5.2) - 2023-05-21

### Added

- Classes to interact with the Job and Submission API ([PR #283](https://github.com/PySlurm/pyslurm/pull/283) by [tazend](https://github.com/tazend))
    - [pyslurm.Job](https://pyslurm.github.io/22.5/reference/job/#pyslurm.Job)
    - [pyslurm.Jobs](https://pyslurm.github.io/22.5/reference/job/#pyslurm.Jobs)
    - [pyslurm.JobStep](https://pyslurm.github.io/22.5/reference/jobstep/#pyslurm.JobStep)
    - [pyslurm.JobSteps](https://pyslurm.github.io/22.5/reference/jobstep/#pyslurm.JobSteps)
    - [pyslurm.JobSubmitDescription](https://pyslurm.github.io/22.5/reference/jobsubmitdescription/#pyslurm.JobSubmitDescription)
- Classes to interact with the Database Job API ([PR #283](https://github.com/PySlurm/pyslurm/pull/283) by [tazend](https://github.com/tazend))
    - [pyslurm.db.Job](https://pyslurm.github.io/22.5/reference/db/job/#pyslurm.db.Job)
    - [pyslurm.db.Jobs](https://pyslurm.github.io/22.5/reference/db/job/#pyslurm.db.Jobs)
    - [pyslurm.db.JobStep](https://pyslurm.github.io/22.5/reference/db/jobstep/#pyslurm.db.JobStep)
    - [pyslurm.db.JobSearchFilter](https://pyslurm.github.io/22.5/reference/db/jobsearchfilter/#pyslurm.db.JobSearchFilter)
- Classes to interact with the Node API ([PR #283](https://github.com/PySlurm/pyslurm/pull/283) by [tazend](https://github.com/tazend))
    - [pyslurm.Node](https://pyslurm.github.io/22.5/reference/node/#pyslurm.Node)
    - [pyslurm.Nodes](https://pyslurm.github.io/22.5/reference/node/#pyslurm.Nodes)
- Exceptions added ([PR #283](https://github.com/PySlurm/pyslurm/pull/283) by [tazend](https://github.com/tazend))
    - [pyslurm.PyslurmError](https://pyslurm.github.io/22.5/reference/exceptions/#pyslurm.PyslurmError)
    - [pyslurm.RPCError](https://pyslurm.github.io/22.5/reference/exceptions/#pyslurm.RPCError)
- [Utility Functions](https://pyslurm.github.io/22.5/reference/utilities/#pyslurm.utils)

### Changes

- Completely overhaul the documentation ([PR #283](https://github.com/PySlurm/pyslurm/pull/283) by [tazend](https://github.com/tazend))
- Switch to mkdocs for generating documentation ([PR #271](https://github.com/PySlurm/pyslurm/pull/271) by [tazend](https://github.com/tazend),[multimeric](https://github.com/multimeric))
- Rework the tests: Split them into unit and integration tests ([PR #283](https://github.com/PySlurm/pyslurm/pull/283) by [tazend](https://github.com/tazend))

### Deprecated

- Following classes are superseded by new ones:
    - [pyslurm.job](https://pyslurm.github.io/22.5/reference/old/job/#pyslurm.job)
    - [pyslurm.node](https://pyslurm.github.io/22.5/reference/old/node/#pyslurm.node)
    - [pyslurm.jobstep](https://pyslurm.github.io/22.5/reference/old/jobstep/#pyslurm.jobstep)
    - [pyslurm.slurmdb_jobs](https://pyslurm.github.io/22.5/reference/old/db/job/#pyslurm.slurmdb_jobs)

## [22.5.1](https://github.com/PySlurm/pyslurm/releases/tag/v22.5.1) - 2023-02-26

### Added

- `wait_finished` method to pyslurm.job class, which blocks until a specified
  job is finished ([PR #242](https://github.com/PySlurm/pyslurm/pull/242) by [JonaOtto](https://github.com/JonaOtto))
- Support updating `end_time` in `slurm_update_reservation` ([PR #255](https://github.com/PySlurm/pyslurm/pull/255) by [pllopsis](https://github.com/pllopis))

### Changes

- Actually retrieve and return the batch script as a string, instead of just
  printing it ([PR #258](https://github.com/PySlurm/pyslurm/pull/258) by [tazend](https://github.com/tazend))
- Raise `ValueError` on `slurm_update_reservation` instead of just returning the
  error code ([PR #257](https://github.com/PySlurm/pyslurm/pull/257) by [pllopsis](https://github.com/pllopis))

### Fixes

- Fix some typos in `pyslurm.job` class ([PR #243](https://github.com/PySlurm/pyslurm/pull/243) by [JonaOtto](https://github.com/JonaOtto), [PR #252](https://github.com/PySlurm/pyslurm/pull/252) by [schluenz](https://github.com/schluenz))
- Fix not being able to create RPMs with `bdist_rpm` ([PR #248](https://github.com/PySlurm/pyslurm/pull/248) by [tazend](https://github.com/tazend))
- Fix formatting error for `reservation_list` example ([PR #256](https://github.com/PySlurm/pyslurm/pull/256) by [pllopsis](https://github.com/pllopis))
- Fix RPC strings, bringing them in sync with slurm 22.05 when getting Slurm
  statistics via the `statistics` class ([PR #261](https://github.com/PySlurm/pyslurm/pull/261) by [wresch](https://github.com/wresch))

## [22.5.0](https://github.com/PySlurm/pyslurm/releases/tag/v22.5.0) - 2022-08-06

### Added

- Support for Slurm 22.05.x ([PR #238](https://github.com/PySlurm/pyslurm/pull/238) by [tazend](https://github.com/tazend))
- A `pyproject.toml` file to ease installation ([PR #239](https://github.com/PySlurm/pyslurm/pull/239) by [tazend](https://github.com/tazend))
- Allow specifying Slurm lib-dir and include-dir via `SLURM_LIB_DIR` and `SLURM_INCLUDE_DIR` environment variables on install ([PR #239](https://github.com/PySlurm/pyslurm/pull/239) by [tazend](https://github.com/tazend))

### Changes

- Now actually link to `libslurm.so` instead of `libslurmfull.so` ([PR #238](https://github.com/PySlurm/pyslurm/pull/238) by [tazend](https://github.com/tazend))

### Removed 

- `stats` key from the job-allocation dictionary itself when doing `slurmdb_jobs.get()` ([PR #238](https://github.com/PySlurm/pyslurm/pull/238) by [tazend](https://github.com/tazend)).
   Support for it was removed upstream [here](https://github.com/SchedMD/slurm/commit/2f5254cd79123b70b489338629ac1a14dcc3b845).
   Note that stats for job-steps are still accessible
