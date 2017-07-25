==================================
PySlurm: Python Bindings for Slurm
==================================

.. image:: https://travis-ci.org/PySlurm/pyslurm.svg?branch=dev-17.02-props
   :target: https://travis-ci.org/PySlurm/pyslurm
   :alt: Build Status

.. image:: https://img.shields.io/badge/status-development-orange.svg
   :target: https://github.com/PySlurm/pyslurm
   :alt: Project Status

.. image:: https://img.shields.io/badge/api%20version-v2-blue.svg
   :target: https://github.com/PySlurm/pyslurm
   :alt: API Version

.. image:: https://img.shields.io/badge/license-GPLv2-blue.svg
   :target: https://github.com/PySlurm/pyslurm
   :alt: License

PySlurm is a Cython wrapper around functions and data structures exposed in
`Slurm's C API <https://slurm.schedmd.com/api.html>`_.

=============
Prerequisites
=============

To build PySlurm, you need:

- `Slurm <https://slurm.schedmd.com>`_
- `Python <https://www.python.org>`_
- `Cython <http://cython.org>`_

=============
Slurm Support
=============

+-----------------+-----------------+
| Slurm Tag       | PySlurm Branch  |
+=================+=================+
| slurm-17-02-0-1 | dev-17.02-props |
+-----------------+-----------------+
| slurm-17-02-1-1 | dev-17.02-props |
+-----------------+-----------------+
| slurm-17-02-1-2 | dev-17.02-props |
+-----------------+-----------------+
| slurm-17-02-2-1 | dev-17.02-props |
+-----------------+-----------------+
| slurm-17-02-3-1 | dev-17.02-props |
+-----------------+-----------------+
| slurm-17-02-4-1 | dev-17.02-props |
+-----------------+-----------------+
| slurm-17-02-5-1 | dev-17.02-props |
+-----------------+-----------------+
| slurm-17-02-6-1 | dev-17.02-props |
+-----------------+-----------------+


=============
Example Usage
=============

Node
====

.. code-block:: python

    >>> import pyslurm
    >>> pyslurm.node.get_node("c1")
    <pyslurm.node.Node object at 0x1ff8a50>
    >>> this_node = pyslurm.node.get_node("c1")
    >>> dir(this_node)
    ['__class__', '__delattr__', '__doc__', '__format__', '__getattribute__',
    '__hash__', '__init__', '__new__', '__reduce__', '__reduce_ex__', '__repr__',
    '__setattr__', '__sizeof__', '__str__', '__subclasshook__', 'active_features',
    'alloc_mem', 'arch', 'available_features', 'boards', 'boot_time',
    'boot_time_str', 'cap_watts', 'consumed_joules', 'core_spec_cnt',
    'cores_per_socket', 'cpu_alloc', 'cpu_err', 'cpu_load', 'cpu_spec_list',
    'cpu_tot', 'current_watts', 'ext_sensors_joules', 'ext_sensors_temp',
    'ext_sensors_watts', 'free_mem', 'gres', 'gres_drain', 'gres_used',
    'lowest_joules', 'mem_spec_limit', 'node_addr', 'node_host_name', 'node_name',
    'os', 'owner', 'rack_midplane', 'real_memory', 'reason', 'reason_str',
    'reason_time', 'reason_time_str', 'reason_uid', 'reason_user',
    'slurmd_start_time', 'slurmd_start_time_str', 'sockets', 'state',
    'threads_per_core', 'tmp_disk', 'version', 'weight']
    >>>
    >>> this_node.cores_per_socket
    2
    >>> this_node.real_memory
    126822
    >>> a.slurmd_start_time
    1478695716
    >>> a.slurmd_start_time_str
    u'2016-11-09T07:48:36'

Job
===

.. code-block:: python

    >>> pyslurm.job.get_job(28727858)
    <pyslurm.job.Job object at 0x1316560>
    >>> this_job = pyslurm.job.get_job(28727858)
    >>> dir(this_job)
    ['__class__', '__delattr__', '__doc__', '__format__', '__getattribute__',
    '__hash__', '__init__', '__new__', '__reduce__', '__reduce_ex__', '__repr__',
    '__setattr__', '__sizeof__', '__str__', '__subclasshook__', 'account',
    'alloc_node', 'alloc_sid', 'array_job_id', 'array_task_id', 'array_task_str',
    'batch_flag', 'batch_host', 'batch_script', 'boards_per_node', 'burst_buffer',
    'command', 'comment', 'contiguous', 'core_spec', 'cores_per_socket',
    'cpus_per_task', 'dependency', 'derived_exit_code', 'eligible_time',
    'eligible_time_str', 'end_time', 'end_time_str', 'exc_midplane_list',
    'exc_node_list', 'exit_code', 'features', 'gres', 'group_id', 'group_name',
    'job_id', 'job_name', 'job_state', 'kill_o_in_invalid_dependent', 'licenses',
    'mcs_label', 'midplane_list', 'min_cpus_node', 'network', 'nice', 'node_list',
    'ntasks_per_board', 'ntasks_per_core', 'ntasks_per_node', 'ntasks_per_socket',
    'num_cpus', 'num_nodes', 'over_subscribe', 'partition', 'power',
    'preempt_time', 'preempt_time_str', 'priority', 'qos', 'reason', 'reboot',
    'req_midplane_list', 'req_node_list', 'req_switch', 'requeue', 'reservation',
    'resize_time', 'resize_time_str', 'restarts', 'run_time', 'run_time_str',
    'sched_midplane_list', 'sched_node_list', 'secs_pre_suspend',
    'sockets_per_board', 'socks_per_node', 'start_time', 'start_time_str',
    'std_err', 'std_in', 'std_out', 'submit_time', 'submit_time_str',
    'suspend_time', 'suspend_time_str', 'switches', 'thread_spec',
    'threads_per_core', 'time_limit', 'time_limit_str', 'time_min', 'time_min_str',
    'tres', 'user_id', 'user_name', 'wait4switch', 'wckey', 'work_dir']
    >>>
    >>> this_job.time_limit
    120
    >>> this_job.time_limit_str
    u'02:00:00'
    >>> this_job.cpus_per_task
    1
    >>> this_job.start_time_str
    u'2016-12-12T21:50:16'
    >>> this_job.start_time
    1481597416
    >>> this_job.run_time
    13
    >>> this_job.run_time_str
    u'00:00:13'
    >>> this_job.job_name
    u'wrap'

============
How to Build
============

You will need to instruct the setup.py script where either the Slurm install root 
directory or where the Slurm libraries and Slurm include files are :


#. Slurm default directory (/usr):

    * python setup.py build
    * python setup.py install

#. Indicate Blue Gene type (L/P/Q) on build line:

    * --bgl or --bgp or --bgq

#. Slurm root directory (Alternate installation directory):

    * python setup.py build --slurm=PATH_TO_SLURM_DIR
    * python setup.py install

#. Separate Slurm library and include directory paths:

    * python setup.py build --slurm-lib=PATH_TO_SLURM_LIB --slurm-inc=PATH_TO_SLURM_INC
    * python setup.py install

#. Remove temporary build files by running:

    * python setup.py clean --all

=============
Documentation 
=============

============
Contributing
============

=======
Authors
=======

Mark Roberts and Giovanni Torres

====
Help
====

Ask questions on the `PySlurm Google group <https://groups.google.com/forum/#!forum/pyslurm>`_.
