# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased on the [24.5.x](https://github.com/PySlurm/pyslurm/tree/24.5.x) branch

- New Classes to interact with Database Associations (WIP)
    - `pyslurm.db.Association`
    - `pyslurm.db.Associations`
- New Classes to interact with Database QoS (WIP)
    - `pyslurm.db.QualityOfService`
    - `pyslurm.db.QualitiesOfService`

## [24.5.0](https://github.com/PySlurm/pyslurm/releases/tag/v24.5.0) - 2024-11-16

### Added

- Support for Slurm 24.5.x
- add `power_down_on_idle` attribute to `pyslurm.Partition` class

### Changed

- bump minimum Cython version to 0.29.37

### Removed

- Removed `power_options` from `JobSubmitDescription`
