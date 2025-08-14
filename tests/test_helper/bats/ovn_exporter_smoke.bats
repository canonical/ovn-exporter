# This is a bash shell fragment -*- bash -*-

load "${ABS_TOP_TEST_DIRNAME}test_helper/setup_teardown_exporter/$(basename "${BATS_TEST_FILENAME//.bats/.bash}")"

setup() {
    load ${ABS_TOP_TEST_DIRNAME}test_helper/common.bash
    load ${ABS_TOP_TEST_DIRNAME}test_helper/lxd.bash
    load ${ABS_TOP_TEST_DIRNAME}test_helper/microovn.bash
    load ${ABS_TOP_TEST_DIRNAME}test_helper/ovn_exporter_common.bash
    load ${ABS_TOP_TEST_DIRNAME}../.bats/bats-support/load.bash
    load ${ABS_TOP_TEST_DIRNAME}../.bats/bats-assert/load.bash

    # Ensure TEST_CONTAINERS is populated, otherwise the tests below will
    # provide false positive results.
    assert [ -n "$TEST_CONTAINERS" ]
}

@test "Testing OVN exporter functionality" {
    ovn_exporter_tests
}

@test "Testing OVN exporter metrics endpoint" {
    ovn_exporter_metrics_tests
}

ovn_exporter_tests() {
    for container in $TEST_CONTAINERS; do
        # Test that ovn-exporter can start successfully
        run lxc_exec "$container" "timeout 10s /tmp/ovn-exporter --help"
        assert_success
        assert_output --partial "Usage:"

        # Test that ovn-exporter can connect to microovn with proper environment
        start_ovn_exporter "$container"
        
        # Wait for exporter to be running and accessible
        wait_for_exporter_process "$container"
        wait_for_metrics_endpoint "$container"
        
        # Test metrics endpoint accessibility
        run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
        assert_success
        
        # Clean up
        cleanup_exporter "$container"
    done
}

ovn_exporter_metrics_tests() {
    for container in $TEST_CONTAINERS; do
        # Start ovn-exporter in background
        start_ovn_exporter "$container"
        
        # Wait for exporter to be ready
        wait_for_exporter_process "$container" 10
        wait_for_metrics_endpoint "$container" 15
        
        echo "# $container: Exporter process is running"
        
        # Test that metrics endpoint returns Prometheus format and has basic OVS metrics
        validate_prometheus_format "$container"
        validate_basic_ovs_metrics "$container"
        
        echo "# $container: OVS metrics verification passed"
        
        # Clean up
        cleanup_exporter "$container"
    done
}
