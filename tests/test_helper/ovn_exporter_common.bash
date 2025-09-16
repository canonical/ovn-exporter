# Common functions for OVN Exporter tests

# install_ovn_exporter SNAP_FILE CONTAINER1 [CONTAINER2 ...]
#
# Install OVN Exporter snap from local snap file in all CONTAINERs.
# This follows the same pattern as install_microovn() function.
function install_ovn_exporter() {
    local snap_file=$1; shift
    local containers=$*

    for container in $containers; do
        echo "# Deploying OVN Exporter to $container" >&3
        lxc_file_push "$snap_file" "$container/tmp/ovn-exporter.snap"
        echo "# Installing OVN Exporter in container $container" >&3
        lxc_exec "$container" "snap install /tmp/ovn-exporter.snap --dangerous"
        echo "# Connecting plugs in container $container" >&3
        # Connect OVN interfaces to microovn
        lxc_exec "$container" "snap connect ovn-exporter:ovn-central-data microovn:ovn-central-data"
        lxc_exec "$container" "snap connect ovn-exporter:ovn-chassis microovn:ovn-chassis"
    done
}

# Start OVN exporter service
start_ovn_exporter() {
    local container=$1
    
    echo "# Starting ovn-exporter service in $container" >&3
    
    # Check if service is already active
    if lxc_exec "$container" "snap services ovn-exporter | awk 'NR>1 {print \$3}' | grep -q '^active$'" 2>/dev/null; then
        echo "# ovn-exporter service already active in $container" >&3
        return 0
    fi
    
    # Start the service
    if ! lxc_exec "$container" "snap start ovn-exporter"; then
        echo "# Error: Failed to start ovn-exporter service in $container" >&3
        return 1
    fi
}

# Wait for exporter service to be active
wait_for_exporter_active() {
    local container=$1
    local max_attempts=${2:-10}
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        # Check if snap service is active
        if lxc_exec "$container" "snap services ovn-exporter | awk 'NR>1 {print \$3}' | grep -q '^active$'" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    return 1
}

# Wait for metrics endpoint to be accessible
wait_for_metrics_endpoint() {
    local container=$1
    local max_attempts=${2:-15}
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if lxc_exec "$container" "curl -s http://localhost:9310/metrics" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    return 1
}

# Clean up exporter process
cleanup_exporter() {
    local container=$1
    echo "# Stopping ovn-exporter service in $container" >&3
    if ! lxc_exec "$container" "snap stop ovn-exporter" 2>/dev/null; then
        echo "# Warning: Failed to stop ovn-exporter service in $container" >&3
        return 1
    fi
}

# Basic metrics validation - check for Prometheus format
validate_prometheus_format() {
    local container=$1
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
    assert_success
}

# Basic OVS metrics validation with retry
validate_basic_ovs_metrics() {
    local container=$1

    # Define basic OVS metrics patterns to wait for
    local basic_ovs_patterns=(
        'ovs_build_info'
        'ovs_vswitchd_bridge'
        'ovs_vswitchd_process_'
        'ovs_db_process_'
    )

    # Use structured retry for basic OVS metrics
    validate_metrics_with_retry "$container" "${basic_ovs_patterns[@]}"
}

# Generic retry mechanism for metrics validation
# Usage: retry_metrics_check <container> <metric_pattern> <description>
retry_metrics_check() {
    local container=$1
    local metric_pattern=$2
    local description=$3
    # The long attempts is because the metrics refresh ticker is 30 seconds.
    local max_attempts=150
    local attempt=1

    echo "# $container: Waiting for $description..." >&3
    while [ $attempt -le $max_attempts ]; do
        local metrics_output
        metrics_output=$(lxc_exec "$container" "curl -s http://localhost:9310/metrics" 2>/dev/null)

        if [[ $metrics_output == *"$metric_pattern"* ]]; then
            echo "# $container: $description found (attempt $attempt)" >&3
            return 0
        fi

        if [ $((attempt % 5)) -eq 0 ]; then
            echo "# $container: Still waiting for $description (attempt $attempt/$max_attempts)" >&3
        fi
        sleep 2
        attempt=$((attempt + 1))
    done

    echo "# $container: ERROR - $description not found after $max_attempts attempts" >&3
    return 1
}

# Validate multiple metrics patterns with retry
# Usage: validate_metrics_with_retry <container> <pattern1> <pattern2> ...
validate_metrics_with_retry() {
    local container=$1
    shift
    local patterns=("$@")

    # Wait for all patterns to be available
    for pattern in "${patterns[@]}"; do
        retry_metrics_check "$container" "$pattern" "metric pattern: $pattern" || return 1
    done

    # Final validation with assert
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
    assert_success

    for pattern in "${patterns[@]}"; do
        assert_output --partial "$pattern"
    done
}

# Comprehensive OVS metrics validation with retry
validate_ovs_metrics_comprehensive() {
    local container=$1

    # Define all OVS metrics patterns to wait for
    local ovs_patterns=(
        'ovs_build_info'
        'ovs_vswitchd_bridge{bridge="br-int"} 1'
        'ovs_vswitchd_bridge_total 1'
        'ovs_vswitchd_bridge_flows_total{bridge="br-int"}'
        'ovs_vswitchd_bridge_ports_total{bridge="br-int"}'
        'ovs_vswitchd_dp{datapath="ovs-system",type="system"} 1'
        'ovs_vswitchd_dp_total 1'
        'ovs_vswitchd_interfaces_total'
        'ovs_vswitchd_handlers_total'
        'ovs_vswitchd_revalidators_total'
        'ovs_vswitchd_process_cpu_seconds_total'
        'ovs_db_process_cpu_seconds_total'
    )

    # Use structured retry for all OVS metrics
    validate_metrics_with_retry "$container" "${ovs_patterns[@]}"

    echo "# $container: OVS metrics verification passed"
}

# Comprehensive OVN Controller metrics validation with retry
validate_ovn_controller_metrics_comprehensive() {
    local container=$1

    # Define all OVN Controller metrics patterns to wait for
    local controller_patterns=(
        'ovn_controller_build_info'
        'ovn_controller_southbound_database_connected 1'
        'ovn_controller_integration_bridge_geneve_ports'
        'ovn_controller_integration_bridge_openflow_total'
        'ovn_controller_integration_bridge_patch_ports'
        'ovn_controller_encap_ip{ipaddress='
        'ovn_controller_encap_type{type="geneve"} 1'
        'ovn_controller_sb_connection_method{connection_method='
        'ovn_controller_monitor_all'
        'ovn_controller_lflow_run'
    )

    # Use structured retry for all OVN Controller metrics
    validate_metrics_with_retry "$container" "${controller_patterns[@]}"

    echo "# $container: OVN Controller metrics verification passed"
}

# Comprehensive OVN Database metrics validation with retry
validate_ovn_database_metrics_comprehensive() {
    local container=$1

    # Define all OVN Database metrics patterns to wait for
    local database_patterns=(
        'ovn_db_build_info'
        'ovn_db_db_size_bytes{db_name="OVN_Northbound"}'
        'ovn_db_db_size_bytes{db_name="OVN_Southbound"}'
        'ovn_db_ovsdb_monitors{db_name="OVN_Northbound"}'
        'ovn_db_ovsdb_monitors{db_name="OVN_Southbound"}'
        'ovn_db_cluster_server_id{cluster_id='
        'ovn_db_cluster_server_role{cluster_id='
        'ovn_db_cluster_server_status{cluster_id='
    )

    # Use structured retry for all OVN Database metrics
    validate_metrics_with_retry "$container" "${database_patterns[@]}"

    echo "# $container: OVN Database metrics verification passed"
}

# Comprehensive OVN Northd metrics validation with retry
validate_ovn_northd_metrics_comprehensive() {
    local container=$1

    # Define all OVN Northd metrics patterns to wait for
    local northd_patterns=(
        'ovn_northd_build_info'
        'ovn_northd_nb_connection_status 1'
        'ovn_northd_sb_connection_status 1'
        'ovn_northd_status'
        'ovn_northd_build_lflows_95th_percentile'
        'ovn_northd_build_lflows_total_samples'
        'ovn_northd_lflows_datapaths_95th_percentile'
        'ovn_northd_lflows_datapaths_total_samples'
        'ovn_northd_ovn_northd_loop_95th_percentile'
        'ovn_northd_ovn_northd_loop_total_samples'
    )

    # Use structured retry for all OVN Northd metrics
    validate_metrics_with_retry "$container" "${northd_patterns[@]}"

    echo "# $container: OVN Northd metrics verification passed"
}

# Common test functions

# Test that exporter can start and show help
test_exporter_help() {
    local container=$1
    
    echo "# $container: Testing exporter help command" >&3
    run lxc_exec "$container" "timeout 10s snap run ovn-exporter --help"
    assert_success
    assert_output --partial "Usage:"
}

# Test exporter startup and verify it's running
test_exporter_startup() {
    local container=$1

    echo "# $container: Testing exporter startup" >&3
    # Start ovn exporter service
    start_ovn_exporter "$container"

    # Wait for exporter service to start
    wait_for_exporter_active "$container"

    # Verify exporter service is running
    run lxc_exec "$container" "snap services ovn-exporter | awk 'NR>1 {print \$3}' | grep '^active$'"
    assert_success
    echo "# $container: Exporter service started successfully" >&3
}

# Test basic metrics functionality
test_exporter_basic_metrics() {
    local container=$1
    
    echo "# $container: Testing basic metrics functionality" >&3
    # Start exporter service
    start_ovn_exporter "$container"
    
    # Wait for exporter to be ready
    wait_for_exporter_active "$container" 10
    wait_for_metrics_endpoint "$container" 15
    
    # Test metrics endpoint accessibility
    run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
    assert_success
    
    # Test Prometheus format and basic OVS metrics
    validate_prometheus_format "$container"
    validate_basic_ovs_metrics "$container"
    
    echo "# $container: Basic metrics verification passed" >&3
}
