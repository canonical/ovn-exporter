# This is a bash shell fragment -*- bash -*-

load "${ABS_TOP_TEST_DIRNAME}test_helper/setup_teardown_exporter/$(basename "${BATS_TEST_FILENAME//.bats/.bash}")"

setup() {
    load ${ABS_TOP_TEST_DIRNAME}test_helper/common.bash
    load ${ABS_TOP_TEST_DIRNAME}test_helper/lxd.bash
    load ${ABS_TOP_TEST_DIRNAME}test_helper/microovn.bash
    load ${ABS_TOP_TEST_DIRNAME}../.bats/bats-support/load.bash
    load ${ABS_TOP_TEST_DIRNAME}../.bats/bats-assert/load.bash

    # Ensure TEST_CONTAINERS is populated, otherwise the tests below will
    # provide false positive results.
    assert [ -n "$TEST_CONTAINERS" ]
}

teardown() {
    # Clean up any exporter processes
    for container in $TEST_CONTAINERS; do
        lxc_exec "$container" "pkill -f ovn-exporter" || true
    done
}

@test "OVN exporter functional test with active network topology and connectivity verification" {
    ovn_exporter_functional_test
}

# Main test orchestrator - coordinates all test modules
ovn_exporter_functional_test() {
    # Run tests on chassis containers where we set up the gateway and VIF
    for container in $CHASSIS_CONTAINERS; do
        echo "# Starting functional test on $container" >&3
        
        # Test modules in sequence
        test_network_topology_setup "$container"
        test_exporter_startup "$container"
        test_metrics_endpoint_basic "$container"
        test_ovs_metrics "$container"
        test_ovn_controller_metrics "$container"  
        test_ovn_database_metrics "$container"
        test_ovn_northd_metrics "$container"
        test_network_connectivity "$container"
        test_exporter_stability "$container"
        test_network_integrity "$container"
        
        # Cleanup for next container
        cleanup_exporter_process "$container"
        echo "# Completed functional test on $container" >&3
    done
}

# Verify the network topology created in setup_file exists
test_network_topology_setup() {
    local container=$1
    local expected_ls_name="sw-${container}"
    local expected_lr_name="lr-${container}"
    
    run lxc_exec "$container" "microovn.ovn-nbctl ls-list"
    assert_success
    assert_output --partial "$expected_ls_name"
    
    run lxc_exec "$container" "microovn.ovn-nbctl lr-list" 
    assert_success
    assert_output --partial "$expected_lr_name"
    
    echo "# $container: Network topology verified (logical switch: $expected_ls_name, router: $expected_lr_name)"
}

# Start the OVN exporter process
test_exporter_startup() {
    local container=$1
    
    # Start ovn-exporter in background with MicroOVN environment
    lxc_exec "$container" "
        export OVS_RUNDIR='/var/snap/microovn/common/run/switch'
        export OVN_RUNDIR='/var/snap/microovn/common/run/ovn'
        export OVS_VSWITCHD_PID='/var/snap/microovn/common/run/switch/ovs-vswitchd.pid'
        export OVSDB_SERVER_PID='/var/snap/microovn/common/run/switch/ovsdb-server.pid'
        export OVN_NBDB_LOCATION='/var/snap/microovn/common/data/central/db/ovnnb_db.db'
        export OVN_SBDB_LOCATION='/var/snap/microovn/common/data/central/db/ovnsb_db.db'
        /tmp/ovn-exporter --loglevel info --host 0.0.0.0 --port 9310
    " &
    
    # Give exporter time to start and collect metrics
    sleep 7
    
    # Verify exporter process is running
    run lxc_exec "$container" "pgrep -f ovn-exporter"
    assert_success
    echo "# $container: Exporter process started successfully"
}

# Test basic metrics endpoint functionality
test_metrics_endpoint_basic() {
    local container=$1
    
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
    assert_success
    assert_output --partial "# HELP"
    assert_output --partial "# TYPE"
    
    # Count total metrics
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics | wc -l"
    assert_success
    local metrics_count
    metrics_count=$(echo "$output" | tr -d ' ')
    assert [ "$metrics_count" -gt 50 ]
    
    echo "# $container: Metrics endpoint serving $metrics_count lines of metrics"
}

# Test OVS-specific metrics
test_ovs_metrics() {
    local container=$1
    
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
    assert_success
    
    # Build info
    assert_output --partial 'ovs_build_info{version="3.3.0"} 1'
    
    # Bridge metrics
    assert_output --partial 'ovs_vswitchd_bridge{bridge="br-int"} 1'
    assert_output --partial "ovs_vswitchd_bridge_total 1"
    
    # Port count verification
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics | grep 'ovs_vswitchd_bridge_ports_total{bridge=\"br-int\"}'"
    assert_success
    local port_count
    port_count=$(echo "$output" | grep -o '[0-9]\+$')
    assert [ "$port_count" -ge 4 ]
    echo "# $container: OVS bridge has $port_count ports (expected >= 4)"
    
    # OpenFlow rules verification
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics | grep 'ovs_vswitchd_bridge_flows_total{bridge=\"br-int\"}'"
    assert_success
    local flow_count
    flow_count=$(echo "$output" | grep -o '[0-9]\+$')
    assert [ "$flow_count" -gt 0 ]
    echo "# $container: OVS bridge has $flow_count OpenFlow rules"
    
    # Process metrics
    assert_output --partial "ovs_vswitchd_process_cpu_seconds_total"
    assert_output --partial "ovs_db_process_cpu_seconds_total"
    
    echo "# $container: OVS metrics verification passed"
}

# Test OVN Controller metrics
test_ovn_controller_metrics() {
    local container=$1
    
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
    assert_success
    
    # Build info and connectivity
    assert_output --partial 'ovn_controller_build_info{ovs_lib_version="3.3.0",version="24.03.2"} 1'
    assert_output --partial "ovn_controller_southbound_database_connected 1"
    assert_output --partial "ovn_controller_integration_bridge_geneve_ports"
    
    # Geneve tunnel verification
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics | grep 'ovn_controller_integration_bridge_geneve_ports'"
    assert_success
    local geneve_count
    geneve_count=$(echo "$output" | grep -o '[0-9]\+$')
    assert [ "$geneve_count" -ge 3 ]
    echo "# $container: OVN Controller has $geneve_count geneve tunnel ports"
}

# Test OVN Database metrics
test_ovn_database_metrics() {
    local container=$1
    
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
    assert_success
    
    # Build info
    assert_output --partial 'ovn_db_build_info{nb_schema_version="7.3.0",sb_schema_version="20.33.0",version="3.3.0"} 1'
    assert_output --partial "ovn_db_db_size_bytes{db_name=\"OVN_Northbound\"}"
    assert_output --partial "ovn_db_db_size_bytes{db_name=\"OVN_Southbound\"}"
    
    # Database size verification
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics | grep 'ovn_db_db_size_bytes{db_name=\"OVN_Northbound\"}'"
    assert_success
    local nb_size
    nb_size=$(echo "$output" | grep -o '[0-9]\+$')
    assert [ "$nb_size" -gt 1000 ]
    echo "# $container: NB database size: $nb_size bytes"
    
    # Cluster health verification
    assert_output --partial "ovn_db_cluster_server_status"
    assert_output --partial "cluster member"
    assert_output --partial "ovn_db_cluster_server_role"
    
    # JSONRPC sessions verification
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics | grep 'ovn_db_jsonrpc_server_sessions{db_name=\"OVN_Northbound\"}'"
    assert_success
    local nb_sessions
    nb_sessions=$(echo "$output" | grep -o '[0-9]\+$')
    assert [ "$nb_sessions" -gt 0 ]
    echo "# $container: NB database has $nb_sessions active sessions"
}

# Test OVN Northd metrics
test_ovn_northd_metrics() {
    local container=$1
    
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
    assert_success
    
    assert_output --partial 'ovn_northd_build_info{ovs_lib_version="3.3.0",version="24.03.2"} 1'
    assert_output --partial "ovn_northd_nb_connection_status 1"
    assert_output --partial "ovn_northd_sb_connection_status 1"
    
    echo "# $container: OVN Northd metrics verification passed"
}

# Test network connectivity via ping
test_network_connectivity() {
    local container=$1
    local ctn_n
    ctn_n=$(microovn_extract_ctn_n "$container")
    
    # Test direct ping in VIF namespace
    run lxc_exec "$container" "ip netns exec $FUNCTIONAL_TEST_NS_NAME ping -c 3 10.42.${ctn_n}.1"
    assert_success
    echo "# $container: VIF ping connectivity verified (3 packets sent successfully)"
    
    # Check background ping packet loss
    local n_lost
    n_lost=$(ping_packets_lost "$container" 10.42.${ctn_n}.1 "$FUNCTIONAL_TEST_NS_NAME") || true
    echo "# $container: Background ping packets lost so far: ${n_lost:-0}"
}

# Test exporter stability over time
test_exporter_stability() {
    local container=$1
    
    # Wait and verify exporter continues serving metrics
    sleep 3
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics | wc -l"
    assert_success
    local metrics_count
    metrics_count=$(echo "$output" | tr -d ' ')
    assert [ "$metrics_count" -gt 50 ]
    
    echo "# $container: Exporter stability verified - still serving $metrics_count metrics after delay"
}

# Verify network integrity (exporter didn't interfere with network objects)
test_network_integrity() {
    local container=$1
    local expected_ls_name="sw-${container}"
    local expected_lr_name="lr-${container}"
    
    run lxc_exec "$container" "microovn.ovn-nbctl ls-list | grep -c '$expected_ls_name'"
    assert_success
    assert [ "$output" -eq 1 ]
    
    run lxc_exec "$container" "microovn.ovn-nbctl lr-list | grep -c '$expected_lr_name'"
    assert_success
    assert [ "$output" -eq 1 ]
    
    echo "# $container: Network integrity verified - topology unchanged"
}

# Clean up exporter process
cleanup_exporter_process() {
    local container=$1
    
    lxc_exec "$container" "pkill -f ovn-exporter" || true
    sleep 1
    echo "# $container: Exporter process cleaned up"
}