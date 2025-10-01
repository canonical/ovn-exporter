=============================
Configure OVN Exporter (Snap)
=============================

This guide shows how to configure OVN Exporter when installed as a snap package.

Overview
========

OVN Exporter supports configuration through snap configuration options, which allow you to
customize paths for OVN/OVS components and database locations. This is particularly useful
when integrating with non-standard OVN deployments.

Configuration Options
=====================

The following configuration options are available:

Path Configuration
------------------

``ovn-rundir``
   OVN run directory path. Override the default location where OVN stores runtime files
   like sockets and PID files.

``ovs-rundir``
   OVS run directory path. Override the default location where OVS stores runtime files.

``ovs-vswitchd-pid``
   Path to the OVS vswitchd PID file. Used to monitor the OVS vswitchd process.

``ovsdb-server-pid``
   Path to the OVSDB server PID file. Used to monitor the OVSDB server process.

Database Configuration
----------------------

``ovn-nbdb-location``
   OVN northbound database location. Specify the socket or connection string for the
   northbound database.

``ovn-sbdb-location``
   OVN southbound database location. Specify the socket or connection string for the
   southbound database.

Setting Configuration Options
==============================

Use the ``snap set`` command to configure OVN Exporter:

.. code-block:: bash

   sudo snap set ovn-exporter <option>=<value>

The service will automatically restart when configuration changes are detected.

Viewing Configuration
=====================

View all configuration options
-------------------------------

To see all configured options:

.. code-block:: bash

   snap get ovn-exporter

Verifying Configuration Changes
================================

After changing configuration, verify the service restarted successfully:

.. code-block:: bash

   snap services ovn-exporter

Check the logs to confirm the new configuration is in use:

.. code-block:: bash

   snap logs ovn-exporter.ovn-exporter

You should see log entries indicating the configuration was loaded and the service started
with the new settings.

Default Behavior
================

When no configuration options are set, OVN Exporter uses default paths from the OVN-Kubernetes
library for locating OVN and OVS components.

For MicroOVN deployments, the snap connections (``ovn-chassis`` and ``ovn-central-data``)
automatically provide access to the necessary OVN/OVS directories without requiring explicit
configuration.

When to Use Configuration Overrides
------------------------------------

Configuration overrides are typically only needed for:

- Custom OVN/OVS installations outside of MicroOVN
- Non-standard directory layouts
