# pyslurm

The `pyslurm` package is a wrapper around the Slurm C-API


!!! warning
    Please note that the `pyslurm` API is currently being completely reworked.
    Reworked classes and functions that replace functionality of the old API
    will be marked as such, with a link to the documentation of its old
    counterpart.

    Old API functionality that is already replaced is marked as deprecated,
    and will be removed at some point in the future.

    The new reworked classes will be tested thoroughly before making them
    available here, although it is of course still possible that some bugs may
    appear here and there, which we will try to identify as best as possible!

    In addition, since these classes are pretty new, their interface
    (precisely: attribute names, return types) should not yet be considered
    100% stable, and changes may be made in rare cases if it makes sense to do
    so.

    If you are using the new-style API, we would like to know your feedback on
    it!


## Functionality already reworked:

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
    * [pyslurm.db.JobSearchFilter][]
* Node API
    * [pyslurm.Node][]
    * [pyslurm.Nodes][]
* New Exceptions
    * [pyslurm.RPCError][]
    * [pyslurm.PyslurmError][]
* New utility functions
    * [pyslurm.utils][]
