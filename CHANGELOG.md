# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased on the [25.11.x](https://github.com/PySlurm/pyslurm/tree/25.11.x) branch

### Added

- New Classes to interact with Database Associations (WIP)
    - `pyslurm.db.Association`
    - `pyslurm.db.Associations`
- New Classes to interact with Database QoS (WIP)
    - `pyslurm.db.QualityOfService`
    - `pyslurm.db.QualitiesOfService`

## [25.11.0](https://github.com/PySlurm/pyslurm/releases/tag/v25.11.0) - 2026-02-13

### Added

- Support for Slurm 25.11.x
- Added new member `metrics_type` to `pyslurm.slurmctld.Config`

### Changed

- Split up `prolog_epilog_timeout` in `prolog_timeout` and `epilog_timeout` in `pyslurm.slurmctld.Config`
- Renamed `job_container_type` to `namespace_plugin` in `pyslurm.slurmctld.Config`
- The `uid_to_name` and `gid_to_name` functions that are used in a few places now don't error by default if the user/group doesn't exist anymore
  Now, if the user/group is gone already, the UID/GID is simply returned as a `str`.

### Removed

- Removed member `accounting_storage_user` from `pyslurm.slurmctld.Config`
- Removed `preempt_mode` from deprecated class `pyslurm.qos` - class will be replaced soon.
- Removed deprecated functions from the old API:
  - `pyslurm.slurm_signal_job_step` - use `send_signal()` method on `pyslurm.JobStep`
  - `pyslurm.slurm_complete_job`
  - `pyslurm.slurm_terminate_job_step`
  - `pyslurm.slurm_kill_job_step` - use `cancel()` from `pyslurm.JobStep`
  - `pyslurm.slurm_ping` - use `pyslurm.slurmctld.ping()`, `pyslurm.slurmctld.ping_all()`, `pyslurm.slurmctld.ping_primary()` or `pyslurm.slurmctld.ping_backup()`
  - `pyslurm.reconfigure` - use `pyslurm.slurmctld.reconfigure()`
  - `pyslurm.slurm_shutdown` - use `pyslurm.slurmctld.shutdown()`
  - `pyslurm.slurm_takeover` - use `pyslurm.slurmctld.takeover()`
  - `pyslurm.slurm_set_debug_level` - use `pyslurm.slurmctld.set_log_level()`
  - `pyslurm.slurm_set_debugflags` - use `pyslurm.slurmctld.add_debug_flags()`
  - `pyslurm.slurm_set_schedlog_level` - use `pyslurm.slurmctld.enable_scheduler_logging()`
  - `pyslurm.slurm_suspend` - use `suspend()` method on `pyslurm.Job`
  - `pyslurm.slurm_resume` - use `unsuspend()` method on `pyslurm.Job`
  - `pyslurm.slurm_requeue` - use `requeue()` method on `pyslurm.Job`
  - `pyslurm.slurm_signal_job` - use `send_signal()` method on either `pyslurm.Job` or `pyslurm.JobStep`
  - `pyslurm.slurm_kill_job` - use `send_signal()` or `cancel()` method on either `pyslurm.Job` or `pyslurm.JobStep`
  - `pyslurm.slurm_kill_job2`
  - `pyslurm.slurm_notify_job` - use `notify()` method on `pyslurm.Job`
  - `pyslurm.get_job_state_reason` - access `state_reason` member on a `pyslurm.Job` instance (Job info must be loaded first)
  - `pyslurm.get_job_state` - access `state` member on a `pyslurm.Job` instance (Job info must be loaded first)
  - `pyslurm.get_partition_state` - access `state` member on a `pyslurm.Partition` instance (Partition info must be loaded first)
  - `pyslurm.get_preempt_mode` - run `pyslurm.slurmctld.Config.load()` and access `preempt_mode` member
  - `pyslurm.get_node_state` - access `state` member on a `pyslurm.Node` instance (Node info must be loaded first)
  - `pyslurm.get_debug_flags` - use `pyslurm.slurmctld.get_debug_flags()`
  - `pyslurm.get_node_use` - just returned the node state, which is redundant
  - `pyslurm.get_last_slurm_error` - use `pyslurm.error.get_last_slurm_error()`
  - `pyslurm.mins2time_str` - use `pyslurm.utils.mins_to_timestr`
  - `pyslurm.secs2time_str` - use `pyslurm.utils.secs_to_timestr`
  - `pyslurm.get_private_data_list` - run `pyslurm.slurmctld.Config.load()` and access `private_data` member
- Removed the following long deprecated old-api classes:
  - `pyslurm.jobstep` - use `pyslurm.JobStep` and `pyslurm.JobSteps`
  - `pyslurm.statistics` use `pyslurm.slurmctld.diag()` to get `pyslurm.slurmctld.Statistics`
  - `pyslurm.job` - use `pyslurm.Job`, `pyslurm.Jobs` and `pyslurm.JobSubmitDescription`
  - `pyslurm.reservation` - use `pyslurm.Reservation` and `pyslurm.Reservations`

  Reason for the removal: interfering with upgrades, and the fact that they haven't
  been maintained in years anyway and better documented replacement classes are available.
  Also speeds up compilation time.

## [25.5.0](https://github.com/PySlurm/pyslurm/releases/tag/v25.5.0) - 2025-11-04

### Added

- Support for Slurm 25.05.x

### Changed

- Split up `prolog_epilog_timeout` in `prolog_timeout` and `epilog_timeout` in `pyslurm.slurmctld.Config`

### Removed

- `get_environment_timeout` member in `pyslurm.slurmctld.Config` class
- The following long deprecated classes have been removed:
  - `pyslurm.node` (use `pyslurm.Node` instead)
  - `pyslurm.config` (use `pyslurm.slurmctld.Config` instead)
  - `pyslurm.front_end` (no replacement, functionality has been removed from Slurm)
  - `pyslurm.partition` (use `pyslurm.Partition` instead)
  - `pyslurm.topology` (no replacement, this was heavily reworked in 25.05 and needs separate followup)

  Reason for the removal: interfering with the 25.05 upgrade, they haven't
  been maintained in years anyway and better documented replacement classes are available.

## [24.11.0](https://github.com/PySlurm/pyslurm/releases/tag/v24.11.0) - 2024-12-30

### Added

- Support for Slurm 24.11.x

## [24.5.1](https://github.com/PySlurm/pyslurm/releases/tag/v24.5.1) - 2024-12-27

### Added

- Added `stats` attribute to both `pyslurm.Job`, `pyslurm.Jobs` and
  `pyslurm.db.Jobs`
- Added `pids` attribute to `pyslurm.Job` which contains Process-IDs of the Job
  organized by node-name
- Added `load_stats` method to `pyslurm.Job` and `pyslurm.Jobs` classes.
  Together with the `stats` and `pids` attributes mentioned above, it is now
  possible to fetch live statistics (like sstat)
- Switch to link with `libslurmfull.so` instead of `libslurm.so`<br>
  This change really has no impact from a user perspective. Everything will
  keep working the same, except that Slurms more internal library
  `libslurmfull.so` is linked with (which is located alongside the plugins
  inside the `slurm` directory, which itself is next to `libslurm.so`)<br>
  Why the change? Because it will likely make development easier. It allows
  access to more functions that might be needed in some places, without
  completely having to implement them on our own. Implementing the
  live-statistics feature, so basically `sstat`, is for example not possible
  with `libslurm.so` <br>
  You can keep providing the directory where `libslurm.so` resided as
  `$SLURM_LIB_DIR` to pyslurm, and it will automatically find `libslurmfull.so`
  from there.
- Added `run_time_remaining` and `elapsed_cpu_time` attributes to `pyslurm.JobStep`
- Added `run_time_remaining` attribute to `pyslurm.Job`

### Fixed

- Fixed `total_cpu_time`, `system_cpu_time` and `user_cpu_time` not getting
  calculated correctly for Job statistics
- Actually make sure that `avg_cpu_time`, `min_cpu_time`, `total_cpu_time`,
  `system_cpu_time` and `user_cpu_time` are integers, not float.

### Changed

- Breaking: rename `cpu_time` to `elapsed_cpu_time` in `pyslurm.Job` and
  `pyslurm.Jobs` classes
- Breaking: rename attribute `alloc_cpus` to just `cpus` in `pyslurm.JobStep`
- Breaking: removed the following attributes from `pyslurm.db.Jobs`:<br>
    * `consumed_energy`
    * `disk_read`
    * `disk_write`
    * `page_faults`
    * `resident_memory`
    * `virtual_memory`
    * `elapsed_cpu_time`
    * `total_cpu_time`
    * `user_cpu_time`
    * `system_cpu_time`
- The removed attributes above are now all available within the `stats`
  attribute, which is of type `pyslurm.db.JobStatistics`
- Renamed the original class of `pyslurm.db.JobStatistics` to
  `pyslurm.db.JobStepStatistics`.<br>
  All this class contains is really mostly applicable only to Steps, but
  doesn't fully apply at the Job Level.<br>
  Therefore, the new `pyslurm.db.JobStatistics` class only contains all
  statistics that make sense at the Job-level.
- return `1` as a value for the `cpus` attribute in `pyslurm.db.Job` when there
  is no value set from Slurm's side.

### Removed

- Removed `pyslurm.version()` function. Should use `__version__` attribute directly.
- Removed `--slurm-lib` and `--slurm-inc` parameters to `setup.py`.<br>
  `SLURM_LIB_DIR` and `SLURM_INCLUDE_DIR` environment variables should be used instead.

## [24.5.0](https://github.com/PySlurm/pyslurm/releases/tag/v24.5.0) - 2024-11-16

### Added

- Support for Slurm 24.5.x
- add `power_down_on_idle` attribute to `pyslurm.Partition` class

### Changed

- bump minimum Cython version to 0.29.37

### Removed

- Removed `power_options` from `JobSubmitDescription`

## [23.11.1](https://github.com/PySlurm/pyslurm/releases/tag/v23.11.1) - 2024-12-28

### Added

- Added `stats` attribute to both `pyslurm.Job`, `pyslurm.Jobs` and
  `pyslurm.db.Jobs`
- Added `pids` attribute to `pyslurm.Job` which contains Process-IDs of the Job
  organized by node-name
- Added `load_stats` method to `pyslurm.Job` and `pyslurm.Jobs` classes.
  Together with the `stats` and `pids` attributes mentioned above, it is now
  possible to fetch live statistics (like sstat)
- Switch to link with `libslurmfull.so` instead of `libslurm.so`<br>
  This change really has no impact from a user perspective. Everything will
  keep working the same, except that Slurms more internal library
  `libslurmfull.so` is linked with (which is located alongside the plugins
  inside the `slurm` directory, which itself is next to `libslurm.so`)<br>
  Why the change? Because it will likely make development easier. It allows
  access to more functions that might be needed in some places, without
  completely having to implement them on our own. Implementing the
  live-statistics feature, so basically `sstat`, is for example not possible
  with `libslurm.so` <br>
  You can keep providing the directory where `libslurm.so` resided as
  `$SLURM_LIB_DIR` to pyslurm, and it will automatically find `libslurmfull.so`
  from there.
- Added `run_time_remaining` and `elapsed_cpu_time` attributes to `pyslurm.JobStep`
- Added `run_time_remaining` attribute to `pyslurm.Job`

### Fixed

- Fixed `total_cpu_time`, `system_cpu_time` and `user_cpu_time` not getting
  calculated correctly for Job statistics
- Actually make sure that `avg_cpu_time`, `min_cpu_time`, `total_cpu_time`,
  `system_cpu_time` and `user_cpu_time` are integers, not float.

### Changed

- Breaking: rename `cpu_time` to `elapsed_cpu_time` in `pyslurm.Job` and
  `pyslurm.Jobs` classes
- Breaking: rename attribute `alloc_cpus` to just `cpus` in `pyslurm.JobStep`
- Breaking: removed the following attributes from `pyslurm.db.Jobs`:<br>
    * `consumed_energy`
    * `disk_read`
    * `disk_write`
    * `page_faults`
    * `resident_memory`
    * `virtual_memory`
    * `elapsed_cpu_time`
    * `total_cpu_time`
    * `user_cpu_time`
    * `system_cpu_time`
- The removed attributes above are now all available within the `stats`
  attribute, which is of type `pyslurm.db.JobStatistics`
- Renamed the original class of `pyslurm.db.JobStatistics` to
  `pyslurm.db.JobStepStatistics`.<br>
  All this class contains is really mostly applicable only to Steps, but
  doesn't fully apply at the Job Level.<br>
  Therefore, the new `pyslurm.db.JobStatistics` class only contains all
  statistics that make sense at the Job-level.
- return `1` as a value for the `cpus` attribute in `pyslurm.db.Job` when there
  is no value set from Slurm's side.

### Removed

- Removed `pyslurm.version()` function. Should use `__version__` attribute directly.
- Removed `--slurm-lib` and `--slurm-inc` parameters to `setup.py`.<br>
  `SLURM_LIB_DIR` and `SLURM_INCLUDE_DIR` environment variables should be used instead.

## [23.11.0](https://github.com/PySlurm/pyslurm/releases/tag/v23.11.0) - 2024-01-27

### Added

- Support for Slurm 23.11.x
- Add `truncate_time` option to `pyslurm.db.JobFilter`, which is the same as -T /
  --truncate from sacct.
- Add new attributes to `pyslurm.db.Jobs` that help gathering statistics for a
  collection of Jobs more convenient.
- Add new attribute `gres_tasks_per_sharing` to `pyslurm.Job` and
  `pyslurm.JobSubmitDescription`

### Fixed

- Fix `allocated_gres` attribute in the `pyslurm.Node` Class returning nothing.
- Add new `idle_memory` and `allocated_tres` attributes to `pyslurm.Node` class
- Fix Node State being displayed as `ALLOCATED` when it should actually be
  `MIXED`.
- Fix crash for the `gres_per_node` attribute of the `pyslurm.Job` class when
  the GRES String received from Slurm contains no count.

### Removed

- `route_plugin`, `job_credential_private_key` and `job_credential_public_certificate`
  keys are removed from the output of `pyslurm.config().get()`
- Some deprecated and unused Slurm constants

## [23.2.3](https://github.com/PySlurm/pyslurm/releases/tag/v23.2.3) - 2025-01-03

### Added

- Add `truncate_time` option to `pyslurm.db.JobFilter`, which is the same as -T /
  --truncate from sacct.
- Add new Attributes to `pyslurm.db.Jobs` that help gathering statistics for a
  collection of Jobs more convenient.
- Add new `idle_memory` and `allocated_tres` attributes to `pyslurm.Node` class
- Added `stats` attribute to both `pyslurm.Job`, `pyslurm.Jobs` and
  `pyslurm.db.Jobs`
- Added `pids` attribute to `pyslurm.Job` which contains Process-IDs of the Job
  organized by node-name
- Added `load_stats` method to `pyslurm.Job` and `pyslurm.Jobs` classes.
  Together with the `stats` and `pids` attributes mentioned above, it is now
  possible to fetch live statistics (like sstat)
- Switch to link with `libslurmfull.so` instead of `libslurm.so`<br>
  This change really has no impact from a user perspective. Everything will
  keep working the same, except that Slurms more internal library
  `libslurmfull.so` is linked with (which is located alongside the plugins
  inside the `slurm` directory, which itself is next to `libslurm.so`)<br>
  Why the change? Because it will likely make development easier. It allows
  access to more functions that might be needed in some places, without
  completely having to implement them on our own. Implementing the
  live-statistics feature, so basically `sstat`, is for example not possible
  with `libslurm.so` <br>
  You can keep providing the directory where `libslurm.so` resided as
  `$SLURM_LIB_DIR` to pyslurm, and it will automatically find `libslurmfull.so`
  from there.
- Added `run_time_remaining` and `elapsed_cpu_time` attributes to `pyslurm.JobStep`
- Added `run_time_remaining` attribute to `pyslurm.Job`

### Fixed

- Fix `allocated_gres` attribute in the `pyslurm.Node` Class returning nothing.
- Fix Node State being displayed as `ALLOCATED` when it should actually be
  `MIXED`.
- Fix crash for the `gres_per_node` attribute of the `pyslurm.Job` class when
  the GRES String received from Slurm contains no count.
- Fixed `total_cpu_time`, `system_cpu_time` and `user_cpu_time` not getting
  calculated correctly for Job statistics
- Actually make sure that `avg_cpu_time`, `min_cpu_time`, `total_cpu_time`,
  `system_cpu_time` and `user_cpu_time` are integers, not float.

### Changed

- Breaking: rename `cpu_time` to `elapsed_cpu_time` in `pyslurm.Job` and
  `pyslurm.Jobs` classes
- Breaking: rename attribute `alloc_cpus` to just `cpus` in `pyslurm.JobStep`
- Breaking: removed the following attributes from `pyslurm.db.Jobs`:<br>
    * `consumed_energy`
    * `disk_read`
    * `disk_write`
    * `page_faults`
    * `resident_memory`
    * `virtual_memory`
    * `elapsed_cpu_time`
    * `total_cpu_time`
    * `user_cpu_time`
    * `system_cpu_time`
- The removed attributes above are now all available within the `stats`
  attribute, which is of type `pyslurm.db.JobStatistics`
- Renamed the original class of `pyslurm.db.JobStatistics` to
  `pyslurm.db.JobStepStatistics`.<br>
  All this class contains is really mostly applicable only to Steps, but
  doesn't fully apply at the Job Level.<br>
  Therefore, the new `pyslurm.db.JobStatistics` class only contains all
  statistics that make sense at the Job-level.
- return `1` as a value for the `cpus` attribute in `pyslurm.db.Job` when there
  is no value set from Slurm's side.

### Removed

- Removed `pyslurm.version()` function. Should use `__version__` attribute directly.
- Removed `--slurm-lib` and `--slurm-inc` parameters to `setup.py`.<br>
  `SLURM_LIB_DIR` and `SLURM_INCLUDE_DIR` environment variables should be used instead.

## [23.2.2](https://github.com/PySlurm/pyslurm/releases/tag/v23.2.2) - 2023-07-18

### Added

- Ability to modify Database Jobs
- New classes to interact with the Partition API
    - [pyslurm.Partition][]
    - [pyslurm.Partitions][]
- New attributes for a Database Job:
    - `extra`
    - `failed_node`
- Added a new Base Class [MultiClusterMap][pyslurm.xcollections.MultiClusterMap] that some Collections inherit from.
- Added `to_json` function to all Collections

### Fixed

- Fixes a problem that prevented loading specific Jobs from the Database if
  the following two conditions were met:
    - no start/end time was specified
    - the Job was older than a day

### Changed

- Improved Docs
- Renamed `JobSearchFilter` to [pyslurm.db.JobFilter][]
- Renamed `as_dict` function of some classes to `to_dict`

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
    - [pyslurm.db.JobFilter](https://pyslurm.github.io/23.2/reference/db/jobsearchfilter/#pyslurm.db.JobFilter)
- Classes to interact with the Node API
    - [pyslurm.Node](https://pyslurm.github.io/23.2/reference/node/#pyslurm.Node)
    - [pyslurm.Nodes](https://pyslurm.github.io/23.2/reference/node/#pyslurm.Nodes)
- Exceptions added:
    - [pyslurm.PyslurmError](https://pyslurm.github.io/23.2/reference/exceptions/#pyslurm.PyslurmError)
    - [pyslurm.RPCError](https://pyslurm.github.io/23.2/reference/exceptions/#pyslurm.RPCError)
- [Utility Functions](https://pyslurm.github.io/23.2/reference/utilities/#pyslurm.utils)

### Changed

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

## [22.5.3](https://github.com/PySlurm/pyslurm/releases/tag/v22.5.3) - 2023-07-19

### Added

- Ability to modify Database Jobs
- New classes to interact with the Partition API
    - [pyslurm.Partition][]
    - [pyslurm.Partitions][]
- New attributes for a Database Job:
    - `extra`
    - `failed_node`
- Added a new Base Class [MultiClusterMap][pyslurm.xcollections.MultiClusterMap] that some Collections inherit from.
- Added `to_json` function to all Collections

### Fixed

- Fixes a problem that prevented loading specific Jobs from the Database if
  the following two conditions were met:
    - no start/end time was specified
    - the Job was older than a day

### Changed

- Improved Docs
- Renamed `JobSearchFilter` to [pyslurm.db.JobFilter][]
- Renamed `as_dict` function of some classes to `to_dict`

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

### Changed

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

### Changed

- Actually retrieve and return the batch script as a string, instead of just
  printing it ([PR #258](https://github.com/PySlurm/pyslurm/pull/258) by [tazend](https://github.com/tazend))
- Raise `ValueError` on `slurm_update_reservation` instead of just returning the
  error code ([PR #257](https://github.com/PySlurm/pyslurm/pull/257) by [pllopsis](https://github.com/pllopis))

### Fixed

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

### Changed

- Now actually link to `libslurm.so` instead of `libslurmfull.so` ([PR #238](https://github.com/PySlurm/pyslurm/pull/238) by [tazend](https://github.com/tazend))

### Removed

- `stats` key from the job-allocation dictionary itself when doing `slurmdb_jobs.get()` ([PR #238](https://github.com/PySlurm/pyslurm/pull/238) by [tazend](https://github.com/tazend)).
   Support for it was removed upstream [here](https://github.com/SchedMD/slurm/commit/2f5254cd79123b70b489338629ac1a14dcc3b845).
   Note that stats for job-steps are still accessible

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
    - [pyslurm.job][]
    - [pyslurm.node][]
    - [pyslurm.jobstep][]
    - [pyslurm.slurmdb_jobs][]

## [21.8.0](https://github.com/PySlurm/pyslurm/releases/tag/v21.8.0) - 2022-03-01

### Added

- Support for Slurm 21.8.x ([PR #227](https://github.com/PySlurm/pyslurm/pull/227) by [rezib](https://github.com/rezib), [njcarriero](https://github.com/njcarriero))

### Fixed

- Fixed typo in slurmdb job dict: `user_cpu_sec` -> `user_cpu_usec` ([3c5ffad](https://github.com/PySlurm/pyslurm/pull/227/commits/3c5ffad8e177a3386f9aeecb3dacceb77d08a760) in [PR #227](https://github.com/PySlurm/pyslurm/pull/227) by [rezib](https://github.com/rezib))
