============================
Getting started with MicroOVN
============================

This tutorial will guide you through installing and configuring MicroOVN and OVN Exporter
using snap packages, and setting up the necessary snap connections to enable metrics collection.

Prerequisites
-------------

- A system running Ubuntu 20.04 LTS or later
- Snap daemon installed (pre-installed on Ubuntu)
- Root or sudo access to the system

Install MicroOVN
----------------

MicroOVN provides a self-contained OVN (Open Virtual Network) deployment with clustering support.

Install the MicroOVN snap:

.. code-block:: bash

   sudo snap install microovn

After installation, verify that MicroOVN is installed:

.. code-block:: bash

   snap list microovn

Initialize MicroOVN
-------------------

Initialize MicroOVN to set up the OVN cluster:

.. code-block:: bash

   sudo microovn.microovn cluster bootstrap

This will create a single-node cluster. You can verify the cluster status:

.. code-block:: bash

   sudo microovn.microovn cluster list

Install OVN Exporter
--------------------

Install the OVN Exporter snap:

.. code-block:: bash

   sudo snap install ovn-exporter

After installation, verify that OVN Exporter is installed:

.. code-block:: bash

   snap list ovn-exporter

Connect Snap Interfaces
------------------------

OVN Exporter needs access to MicroOVN's data directories to collect metrics. This is achieved
through snap content interfaces.

Connect the ``ovn-chassis`` interface
--------------------------------------

This interface provides access to OVN chassis runtime data (switch and controller information):

.. code-block:: bash

   sudo snap connect ovn-exporter:ovn-chassis microovn:ovn-chassis

Connect the ``ovn-central-data`` interface
-------------------------------------------

This interface provides access to OVN central database data (northbound and southbound databases):

.. code-block:: bash

   sudo snap connect ovn-exporter:ovn-central-data microovn:ovn-central-data

Verify the connections
-----------------------

Check that the interfaces are properly connected:

.. code-block:: bash

   snap connections ovn-exporter

You should see both ``ovn-chassis`` and ``ovn-central-data`` listed as connected to MicroOVN.

Start OVN Exporter
------------------

The OVN Exporter service should start automatically after the snap connections are established.
You can verify its status:

.. code-block:: bash

   snap services ovn-exporter

If the service is not running, start it manually:

.. code-block:: bash

   sudo snap start ovn-exporter.ovn-exporter

Verify Metrics Collection
--------------------------

OVN Exporter exposes Prometheus metrics on port 9310 by default. You can verify that metrics
are being collected:

.. code-block:: bash

   curl http://localhost:9310/metrics

You should see Prometheus-formatted metrics output, including OVN-specific metrics like:

- ``ovs_*`` - OVS (Open vSwitch) metrics (build info, bridge stats, datapath info)
- ``ovn_controller_*`` - OVN Controller metrics (southbound connection, integration bridge)
- ``ovn_db_*`` - OVN Database metrics (database size, cluster status, monitors)
- ``ovn_northd_*`` - OVN Northd metrics (connection status, logical flow statistics)
- Standard Go runtime metrics

View Logs (Optional)
--------------------

If you encounter any issues, you can view the OVN Exporter logs:

.. code-block:: bash

   snap logs ovn-exporter.ovn-exporter

To follow logs in real-time:

.. code-block:: bash

   snap logs -f ovn-exporter.ovn-exporter

Troubleshooting
---------------

Service fails to start
----------------------

If the OVN Exporter service fails to start, check that:

1. Both snap connections are properly established
2. MicroOVN is running and initialized
3. Check logs for specific error messages

No metrics available
--------------------

If the metrics endpoint is not responding:

1. Verify the service is running: ``snap services ovn-exporter``
2. Check if the default port (9310) is accessible
3. Verify MicroOVN databases are accessible through the snap connections

Connection errors
-----------------

If you see connection errors in logs:

1. Ensure MicroOVN central services are running:

   .. code-block:: bash

      snap services microovn

2. Verify the snap connections are active:

   .. code-block:: bash

      snap connections ovn-exporter

3. Check that the database sockets are available in the shared directories
