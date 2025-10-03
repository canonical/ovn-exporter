=====================
Configuration Options
=====================

This reference lists all configuration options available for OVN Exporter when installed as a snap package.

Path Configuration
------------------

``ovn-rundir``
   OVN run directory path. Override the default location where OVN stores runtime files
   like sockets and PID files.

``ovs-rundir``
   OVS run directory path. Override the default location where OVS stores runtime files.

Database Configuration
----------------------

``ovn-nbdb-location``
   OVN northbound database location. Specify the socket or connection string for the
   northbound database.

``ovn-sbdb-location``
   OVN southbound database location. Specify the socket or connection string for the
   southbound database.

Default Behavior
----------------

When no configuration options are set, OVN Exporter uses default paths from the OVN-Kubernetes
library for locating OVN and OVS components.

For MicroOVN deployments, the snap connections (``ovn-chassis`` and ``ovn-central-data``)
automatically provide access to the necessary OVN/OVS directories without requiring explicit
configuration.

When to Use Configuration Overrides
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Configuration overrides are typically only needed for:

- Custom OVN/OVS installations outside of MicroOVN
- Non-standard directory layouts
