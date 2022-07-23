Contents
--------

* `Overview`_
* `Directory Structure`_
* `Requirements`_
* `Generating Code`_
* `Compiling, Updating, Testing`_

Overview
--------

This small guide shows how to update PySlurm to a new Major Slurm Release - specifically it shows
how to translate the C-API Headers into an appropriate file with cython definitions.

Directory Structure
-------------------

All the Cython definitions for Slurm can be found in the directory :code:`pyslurm/slurm/`
Essentially, the two most important files are :code:`header.pxi` and :code:`extra.pxi`.
The first one contains all auto-generated definitions, the latter one contains definitions not found in the headers directly, but exported in `libslurm.so`.

The Idea here is to simply have one branch for each Major release, e.g. `20.11`, `21.08`, `22.05` and so on.

Requirements
------------

- `autopxd2 <https://pypi.org/project/autopxd2/>`_
- C-Preprocessor (*cpp*, *clang*)
- Slurm headers (*slurm.h*, *slurmdb.h*, *slurm_errno.h*)
- Cython compiler (latest stable)

Generating Code
---------------

The script in :code:`scripts/pyslurm_bindgen.py` basically generates all of the needed definitions from the Header files.
Inside the script, `autopxd2` is used which helps to create Cython specific definitions for all structs and functions.
In addition, also all constants from the headers (`#define`) are made available with their appropriate data types.

First of all, checkout a new branch in the Repository, and give it the name
of the major release to target, for example:

.. code-block:: bash

    git checkout -b 22.05

Then, simply generate the header definitions like in this example:

.. code-block:: bash

    scripts/pyslurm_bindgen.py -D /directoy/with/slurm/headers > pyslurm/slurm/header.pxi

The script outputs everything to `stdout`. Simply redirect the output to the file: :code:`pyslurm/slurm/header.pxi`.

Now, 99% of the work is done for generating the headers. For the 1% left, you now need to open the generated file, search for the two follwowing statements and comment them out:

- `slurm_addr_t control_addr`
- `phtread_mutex_t lock`

The compiler will otherwise complain that these are incomplete type definitions.

Compiling, Updating, Testing
----------------------------

Now with the generated headers, you can try and build pyslurm (e.g. by having a slurm installation in a virtual machine):

.. code-block:: bash

    python3 setup.py build

This will likely give you a bunch of errors, since usually a few things have changed in between major releases.
Usually it is rather straightforward to adapt the code. Often only a few constants have been deleted/renamed. If no more errors are showing and it compiles, everything is done.
