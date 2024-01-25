# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased on the [23.11.x](https://github.com/PySlurm/pyslurm/tree/23.11.x) branch

- New Classes to interact with Database Associations (WIP)
    - `pyslurm.db.Association`
    - `pyslurm.db.Associations`
- New Classes to interact with Database QoS (WIP)
    - `pyslurm.db.QualityOfService`
    - `pyslurm.db.QualitiesOfService`

## [23.11.0](https://github.com/PySlurm/pyslurm/releases/tag/v23.11.0) - 2024-01-25

### Added

- Support for Slurm 23.11.0 and 23.11.1
- Add `truncate_time` option to `pyslurm.db.JobFilter`, which is the same as -T /
  --truncate from sacct.
- Add new Attributes to `pyslurm.db.Jobs` that help gathering statistics for a
  collection of Jobs more convenient.

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
