# pyslurm

The `pyslurm` package is a wrapper around the Slurm C-API

!!! note
    The pyslurm API was fully reworked in v25.11.0. If you are upgrading from
    an older version, see the [Migration Guide](../migration.md).


## Reworked Classes

* Job API
    * [pyslurm.Job][]
    * [pyslurm.JobStep][]
    * [pyslurm.JobSteps][]
    * [pyslurm.Jobs][]
    * [pyslurm.JobSubmitDescription][]
* Database Job API
    * [pyslurm.db.Job][]
    * [pyslurm.db.JobStep][]
    * [pyslurm.db.Jobs][]
    * [pyslurm.db.JobFilter][]
* Node API
    * [pyslurm.Node][]
    * [pyslurm.Nodes][]
* Partition API
    * [pyslurm.Partition][]
    * [pyslurm.Partitions][]
* New Exceptions
    * [pyslurm.RPCError][]
    * [pyslurm.PyslurmError][]
* New utility functions
    * [pyslurm.utils][]
