# OVN Exporter

## Environment Variables

### OVN-Kubernetes Environment Variables

The underlying OVN-Kubernetes libraries also read these environment variables directly:

| Environment Variable | Default Value | Description |
|---------------------|---------------|-------------|
| `OVS_RUNDIR` | "/var/run/openvswitch/" | OVS run directory |
| `OVN_RUNDIR` | "/var/run/ovn/" | OVN run directory |
| `OVS_VSWITCHD_PID` | "/var/run/openvswitch/ovs-vswitchd.pid" | OVS vSwitchd PID file path |
| `OVSDB_SERVER_PID` | "/var/run/openvswitch/ovsdb-server.pid" | OVSDB server PID file path |
| `OVN_NBDB_LOCATION` | "/var/lib/openvswitch/ovnnb_db.db" | OVN northbound database location |
| `OVN_SBDB_LOCATION` | "/var/lib/openvswitch/ovnsb_db.db" | OVN southbound database location |
