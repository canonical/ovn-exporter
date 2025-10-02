==========================================
Configure a Custom OVN Installation Path
==========================================

This guide shows how to configure OVN Exporter to work with a custom OVN installation
that uses non-standard directory paths.

Use this guide when you have OVN installed outside of MicroOVN, or when your OVN
deployment uses custom directory layouts that differ from the defaults.

Prerequisites
-------------

- OVN Exporter installed as a snap package
- A custom OVN installation with known paths for:
  - OVN run directory
  - OVS run directory
  - OVN database locations

Configure Custom Paths
----------------------

Set the OVN run directory path:

.. code-block:: bash

   sudo snap set ovn-exporter ovn-rundir=/path/to/custom/ovn

Set the OVS run directory path:

.. code-block:: bash

   sudo snap set ovn-exporter ovs-rundir=/path/to/custom/ovs

If your OVN databases are in non-standard locations, configure them:

.. code-block:: bash

   sudo snap set ovn-exporter ovn-nbdb-location=unix:/path/to/nb_db.sock
   sudo snap set ovn-exporter ovn-sbdb-location=unix:/path/to/sb_db.sock

Verify the Configuration
-------------------------

Check that the service restarted successfully:

.. code-block:: bash

   snap services ovn-exporter

The service should show as ``active``.

View the current configuration:

.. code-block:: bash

   snap get ovn-exporter

Confirm the service is using the new paths by checking the logs:

.. code-block:: bash

   snap logs ovn-exporter.ovn-exporter

You should see log entries indicating the custom paths were loaded.

Test metrics collection:

.. code-block:: bash

   curl http://localhost:9310/metrics

The metrics endpoint should return OVN metrics successfully.

Next Steps
----------

For a complete list of configuration options, see :doc:`/reference/configuration-options`.
