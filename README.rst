PySlurm: Python Bindings for Slurm
==================================

WARNING: This is for development only.  Do not use this in production.

Examples
========

.. highlight:: python

    >>> from pyslurm import node
    >>> a = node.get_node("c1")
    >>> a
    >>> [<pyslurm.node.Node object at 0x27bf950>]
    >>> dir(a[0])
    >>> ['__class__', '__delattr__', '__doc__', '__format__',
    '__getattribute__', '__hash__', '__init__', '__new__', '__reduce__',
    '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__',
    '__subclasshook__', 'alloc_mem', 'arch', 'available_features', 'boards',
    'boot_time', 'boot_time_str', 'core_spec_cnt', 'cores_per_socket',
    'cpu_alloc', 'cpu_err', 'cpu_load', 'cpu_spec_list', 'cpu_tot', 'free_mem',
    'gres', 'gres_drain', 'gres_used', 'mem_spec_limit', 'name', 'node_addr',
    'node_hostname', 'os', 'owner', 'real_memory', 'slurmd_start_time',
    'slurmd_start_time_str', 'sockets', 'state', 'threads_per_core',
    'tmp_disk', 'version', 'weight']
    >>> a[0].state
    u'MIXED'
    >>>

