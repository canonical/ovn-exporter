======================
Contribute to our code
======================

This page covers topics on how to make/build/test your changes to
the OVN Exporter source code.

Get the source code
-------------------

OVN Exporter development happens on GitHub. You can find, and contribute to,
its source code in in `our GitHub repository`_.

Build and install OVN Exporter from source
-------------------------------------------

Build requirements
~~~~~~~~~~~~~~~~~~

OVN Exporter is distributed as a snap and the only requirements for building it
are ``Make`` and ``snapcraft``. You can install them with:

.. code-block:: none

   sudo apt install make
   sudo snap install snapcraft --classic

Snapcraft requires ``LXD`` to build snaps. So if your system does not have LXD
installed and initiated, you can check out either `LXD getting started
guides`_ or go with following default setup:

.. code-block:: none

   sudo snap install lxd
   lxd init --auto

Build OVN Exporter
~~~~~~~~~~~~~~~~~~

To build OVN Exporter, go into the repository's root directory and run:

.. code-block:: none

   make build

This will produce the ``ovn-exporter.snap`` file that can be then used to install
OVN Exporter on your system.

Install OVN Exporter
~~~~~~~~~~~~~~~~~~~~

Using the ``ovn-exporter.snap`` file created in the previous section, you can
install OVN Exporter in this way:

.. code-block:: none

   sudo snap install --dangerous ./ovn-exporter.snap

Tests
-----

The tests mainly focus on functional validation of OVN Exporter and how it
integrates with OVN components.

We expect Go unit tests for pure functions.

For impure functions, i.e. functions with side effects, if you find yourself
redesigning interfaces or figuring out how to mock something to support unit
tests, then stop and consider the following strategies instead:

#. Extract the logic you want to test into pure functions.  When done right the
   side effect would be increased composability, setting you up for future code
   reuse.
#. Contain the remaining functions with side effects in logical units that
   can be thoroughly tested in the integration test suite.

OVN Exporter has two types of tests, linter checks and functional tests and this
page will show how to run them.

Linter checks
~~~~~~~~~~~~~

Go code
^^^^^^^

We make use of standard Go linting tools and you can run them with:

.. code-block:: none

   make check-lint-go

This will run ``go fmt`` and ``go vet`` on the codebase.

Test code
^^^^^^^^^

The prerequisites for running linting on the test code are:

* ``make``
* ``shellcheck``
* ``shfmt``

You can install them with:

.. code-block:: none

   sudo apt install make shellcheck
   sudo snap install shfmt

To perform linting, go into the repository's root directory and run:

.. code-block:: none

   make check-lint

Functional tests
~~~~~~~~~~~~~~~~

These tests build the OVN Exporter snap and use it to deploy OVN Exporter
in LXD containers. This setup is then used for running functional test
suites.

Satisfy the test requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

There is no need to run tests in dedicated VMs or in isolated environments as
all functional tests run inside containers and no changes are made to the host
running them.

OVN Exporter reuses MicroOVN as a git submodule to leverage its BATS test
infrastructure. If you cloned the OVN Exporter repository with submodules
(using ``--recurse-submodules`` flag), you are all set and you will have the
following **non-empty** directories:

* ``microovn/``
* ``microovn/.bats/bats-assert/``
* ``microovn/.bats/bats-core/``
* ``microovn/.bats/bats-support/``

If they are empty, you can fetch the submodules with:

.. code-block:: none

   git submodule update --init --recursive

Run functional tests
^^^^^^^^^^^^^^^^^^^^

Once you have your environment set up, running tests is just a matter of
invoking the appropriate ``make`` target. To run all available test suites,
use the ``check-system`` make target:

.. code-block:: none

   make check-system

To run individual test suites you can execute:

.. code-block:: none

   make tests/<name_of_the_test_suite>.bats

.. tip::

   If your hardware can handle it, you can run test suites in parallel by
   supplying ``make`` with ``-j`` argument (e.g. ``make check-system -j4``).
   To avoid interleaving output from these parallel test suites, you can
   specify the ``-O`` argument as well.

Control test environment
........................

By default, functional tests run in LXD containers based on ``ubuntu:lts``
image. This can be changed by exporting environment variable
``MICROOVN_TEST_CONTAINER_IMAGE`` and setting it to a valid LXD image name.

For example:

.. code-block:: none

    export MICROOVN_TEST_CONTAINER_IMAGE="ubuntu:jammy"
    make check-system

Run tests on remote LXD server
..............................

Making use of `LXD remotes`_ to spawn containers on a remote cluster or server
is supported through the use of the ``LXC_REMOTE`` `LXD environment`_ variable.

.. code-block:: none

   export LXC_REMOTE=microcloud
   make check-system

Clean up
^^^^^^^^

Functional test suites will attempt to clean up their containers. However, if
a test crashes, or if it's forcefully killed, you may need to do some manual
cleanup.

If you suspect that tests did not clean up properly, you can list all
containers with:

.. code-block:: none

   lxc list

Any leftover containers will be named according to:
``ovn-exporter-<test_suite_name>-<number>``. You can remove them with:

.. code-block:: none

   lxc delete --force <container_name>


.. LINKS

.. _Bash Automated Testing System (BATS): https://bats-core.readthedocs.io/en/stable/
.. _LXD environment: https://documentation.ubuntu.com/lxd/en/latest/environment/
.. _LXD getting started guides: https://documentation.ubuntu.com/lxd/en/latest/getting_started/
.. _LXD remotes: https://documentation.ubuntu.com/lxd/en/latest/remotes/
.. _our GitHub repository: https://github.com/canonical/ovn-exporter
