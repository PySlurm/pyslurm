Upgrading PySlurm to a new Slurm Release
========================================

Contents
--------

* `Overview`_
* `Requirements`_
* `1. Create the branch`_
* `2. Validate the generator`_
* `3. Regenerate the bindings`_
* `4. Audit extra.pxi`_
* `5. Build and fix call sites`_
* `6. Test`_
* `7. Update version metadata`_

Overview
--------

PySlurm tracks Slurm major releases one-for-one: branch ``26.05.x`` targets
Slurm 26.05, ``25.11.x`` targets 25.11, and so on. Upgrading means pointing the
Cython definitions at the new C headers and repairing whatever the new release
broke.

The definitions live in :code:`pyslurm/slurm/`:

* :code:`slurm.h.pxi`, :code:`slurmdb.h.pxi`, :code:`slurm_errno.h.pxi` are
  **generated** from the Slurm headers by :code:`scripts/pyslurm_bindgen.py`.
  Never edit them by hand.
* :code:`extra.pxi` is **hand-maintained**. It declares internal structs and
  functions that are exported by ``libslurmfull.so`` but absent from the public
  headers. This file is where upgrades go wrong quietly - see step 4.

Requirements
------------

* `autopxd2 <https://pypi.org/project/autopxd2/>`_ **2.5.0**. Pin it. The 3.x
  series changed the API that :code:`pyslurm_bindgen.py` calls into.
* A C preprocessor (*cpp* or *clang*)
* Slurm headers for the target release (*slurm.h*, *slurmdb.h*, *slurm_errno.h*)
* Cython (latest stable)

Work inside a container or VM that has the target Slurm release installed, so
that the headers, ``libslurmfull.so``, and a running ``slurmctld`` all match.

1. Create the branch
--------------------

Name it after the Slurm major release:

.. code-block:: bash

    git checkout -b 26.05.x

2. Validate the generator
-------------------------

Before generating anything you intend to keep, run the generator against the
**previous** release's headers and diff the result against what is already
committed:

.. code-block:: bash

    scripts/pyslurm_bindgen.py -D /path/to/25.11/include/slurm -o /tmp/check
    diff pyslurm/slurm/slurm.h.pxi /tmp/check/slurm.h.pxi

Ignore the ``Generated on`` timestamp; everything else should be identical. If
it is not, your autopxd2 version or toolchain differs from the one that produced
the committed files, and every diff you see in step 3 will be noise. Fix that
first.

3. Regenerate the bindings
--------------------------

.. code-block:: bash

    scripts/pyslurm_bindgen.py -D /path/to/26.05/include/slurm

The script writes one :code:`<header>.pxi` per header into
:code:`pyslurm/slurm/` (override with :code:`-o`, or use :code:`-s` to print to
stdout instead). It also translates ``#define`` macros into typed constants.

Now diff against the previous release's generated output. That diff *is* the
API change list: renamed functions, changed signatures, added and removed struct
members, new and deleted enum values. Read all of it. Anything that only changes
a struct member will compile cleanly and fail at runtime.

If the generator crashes, the new headers contain a construct autopxd2 cannot
parse. Prefer patching :code:`scripts/pyslurm_bindgen.py` over editing generated
output - see ``_patch_autopxd_enum_casts()`` there for an example, added when
26.05 started using ``SLURM_BIT()`` (which expands to a cast) for enum values.

Fix the fallout in :code:`pyslurm/pydefines/*.pxi`, which reference constants by
name and break loudly when one disappears.

4. Audit extra.pxi
------------------

**Do not skip this step.** The structs in :code:`extra.pxi` are declared as
plain ``ctypedef struct``, not inside a ``cdef extern`` block, so Cython emits
its own C definition rather than deferring to a header. If a member is added
upstream and not mirrored here, every following member reads from the wrong
offset. Nothing warns you: the build succeeds and unit tests pass.

Fetch the matching Slurm sources and compare each declaration field by field:

.. code-block:: bash

    curl -O https://download.schedmd.com/slurm/slurm-26.05.2.tar.bz2
    tar xf slurm-26.05.2.tar.bz2

The structs and their homes:

===========================  ==========================================
Declaration                  Slurm source
===========================  ==========================================
``job_resources``            ``src/common/job_resources.h``
``slurm_msg_t``              ``src/common/slurm_protocol_defs.h``
``forward_t``                ``src/common/slurm_protocol_defs.h``
``forward_struct_t``         ``src/common/slurm_protocol_defs.h``
``job_id_msg_t``             ``src/common/slurm_protocol_defs.h``
``return_code_msg_t``        ``src/common/slurm_protocol_defs.h``
``persist_conn_t``           ``src/common/persist_conn.h``
``persist_msg_t``            ``src/common/persist_conn.h``
``buf_t``                    ``src/common/pack.h``
``slurm_msg_type_t``         ``src/common/msg_type.h``
``tres_types_t``             ``src/common/slurmdb_defs.h``
===========================  ==========================================

Check for three things:

* **Added or removed members.** Order matters. A ``void *`` standing in for a
  concrete pointer type is fine; a missing member is not.
* **Structs embedded by value.** ``forward_t`` sits inside ``slurm_msg_t``, so a
  change to it silently resizes ``slurm_msg_t``.
* **Hardcoded enum values.** :code:`extra.pxi` pins a few ``slurm_msg_type_t``
  members to literal numbers. Slurm reuses retired RPC slots between releases,
  so recompute them from the new ``msg_type.h``.

Also check memory ownership. Slurm occasionally switches an API from returning
``strdup``-allocated memory to ``xmalloc``-allocated memory (26.05 did this to
``slurm_create_reservation``). Calling libc ``free()`` on an ``xmalloc`` pointer
corrupts the heap. Grepping the release's ``src/api/*.c`` for changes in the
``caller must free`` / ``caller must xfree`` comments catches these cheaply.

5. Build and fix call sites
---------------------------

.. code-block:: bash

    scripts/build.sh -j8 -d

Iterate until it compiles. Most breakage is mechanical: renamed functions,
changed argument types, deleted constants. A clean build means the code
*compiles* against the new API - it says nothing about steps 3 and 4 being
complete.

6. Test
-------

.. code-block:: bash

    scripts/run_tests.sh          # unit + integration

Integration tests need a running Slurm of the target version; they are what
catch the struct layout and memory ownership problems that the build cannot.
Run them before opening the PR.

7. Update version metadata
--------------------------

Set :code:`pyslurm/version.py` to ``<major>.<minor>.0``. ``setup.py`` derives
the required Slurm version from it and refuses to build against a mismatched
``slurm_version.h``.

Then update the remaining references:

* :code:`pyslurm.spec` - ``Version``, ``BuildRequires: slurm-devel``, ``%changelog``
* :code:`README.md` - requirements line and compatibility table
* :code:`CLAUDE.md` - required Slurm version
* :code:`CHANGELOG.md` - new section for the branch
* :code:`docker-compose.yml` - default image tag
* :code:`.github/workflows/pyslurm.yml` - image tags in the test matrix
