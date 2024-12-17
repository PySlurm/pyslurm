# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased on the [24.5.x](https://github.com/PySlurm/pyslurm/tree/24.5.x) branch

### Added

- New Classes to interact with Database Associations (WIP)
    - `pyslurm.db.Association`
    - `pyslurm.db.Associations`
- New Classes to interact with Database QoS (WIP)
    - `pyslurm.db.QualityOfService`
    - `pyslurm.db.QualitiesOfService`
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

### Fixed

- Fixed `total_cpu_time`, `system_cpu_time` and `user_cpu_time` not getting
  calculated correctly for Job statistics
- Actually make sure that `avg_cpu_time`, `min_cpu_time`, `total_cpu_time`,
  `system_cpu_time` and `user_cpu_time` are integers, not float.

### Changed

- Breaking: rename `cpu_time` to `elapsed_cpu_time` in `pyslurm.Job` and
  `pyslurm.Jobs` classes
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

## [24.5.0](https://github.com/PySlurm/pyslurm/releases/tag/v24.5.0) - 2024-11-16

### Added

- Support for Slurm 24.5.x
- add `power_down_on_idle` attribute to `pyslurm.Partition` class

### Changed

- bump minimum Cython version to 0.29.37

### Removed

- Removed `power_options` from `JobSubmitDescription`
