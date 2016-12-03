PySlurm
=======

:Version: |version|
:Date: |today|

PySlurm is a set of Python/Cython extension modules that wrap the `Slurm
<http://slurm.schedmd.com>`_ C API.  Slurm is typically used on HPC clusters of
varying sizes, from clusters with a few nodes to clusters such as those listed
on the `TOP500 <https://www.top500.org>`_.

Examples
--------

Examples on how to use the PySlurm submodules.

.. toctree::
   :maxdepth: 2

   examples/index

Developer's Guide
-----------------

How to contribute to PySlurm, and some explanation of API design choices.

.. toctree::
   :maxdepth: 1

   dev/index

API Reference
-------------

A description of all functions and classes, which are also the docstrings found
in the source.  This includes the arguments and return types for each function.

.. toctree::
   :maxdepth: 1
   :glob:

   api/*
