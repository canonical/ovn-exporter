OVN Exporter
============

``OVN Exporter`` is a Prometheus metrics exporter for OVN (Open Virtual Network) components.

It provides comprehensive monitoring capabilities for OVN deployments by exposing metrics
from OVN Northbound and Southbound databases, enabling observability and alerting through
Prometheus and compatible monitoring systems.

``OVN Exporter`` is built in Go and integrates with OVN-Kubernetes libraries to collect
metrics from OVN databases. It's designed to work seamlessly with MicroOVN deployments
and can be deployed as a snap package for easy installation and management.

The exporter provides visibility into OVN cluster health, database operations, and
network topology, making it an essential tool for operators managing OVN-based
networking infrastructure.

---------

In this documentation
---------------------

..  grid:: 1 1 2 2

   ..  grid-item:: :doc:`Tutorial <tutorial/index>`

       **Start here**: a hands-on introduction to OVN Exporter for new users

   ..  grid-item:: :doc:`How-to guides <how-to/index>`

      **Step-by-step guides** covering key operations and common tasks

.. grid:: 1 1 2 2

   .. grid-item:: :doc:`Reference <reference/index>`

      **Technical information** - specifications, APIs, architecture

---------

Project and community
---------------------

OVN Exporter is a member of the Ubuntu family. It's an open source project that
warmly welcomes community projects, contributions, suggestions, fixes and
constructive feedback.

* We follow the Ubuntu community `Code of conduct`_
* Contribute to the project on `GitHub`_ (documentation contributions go under
  the :file:`docs` directory)
* GitHub is also used as our bug tracker

.. toctree::
   :hidden:
   :maxdepth: 2

   tutorial/index
   how-to/index
   reference/index

.. LINKS
.. _Code of conduct: https://ubuntu.com/community/ethos/code-of-conduct
.. _GitHub: https://github.com/canonical/ovn-exporter
