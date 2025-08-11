load "${ABS_TOP_TEST_DIRNAME}test_helper/setup_teardown/$(basename "${BATS_TEST_FILENAME//.bats/.bash}")"

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

ovn_exporter_register_test_functions() {
    bats_test_function \
        --description "Testing OVN exporter functionality" \
        -- ovn_exporter_tests
    bats_test_function \
        --description "Testing OVN exporter metrics endpoint" \
        -- ovn_exporter_metrics_tests
}

ovn_exporter_tests() {
    for container in $TEST_CONTAINERS; do
        # Test that ovn-exporter can start successfully
        run lxc_exec "$container" "timeout 10s /snap/bin/ovn-exporter --help"
        assert_success
        assert_output --partial "Usage:"

        # Test that ovn-exporter can connect to microovn
        run lxc_exec "$container" "timeout 5s /snap/bin/ovn-exporter --loglevel info" &
        EXPORTER_PID=$!
        
        # Give exporter time to start
        sleep 2
        
        # Test health endpoint
        run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
        assert_success
        
        # Clean up
        kill $EXPORTER_PID 2>/dev/null || true
    done
}

ovn_exporter_metrics_tests() {
    for container in $TEST_CONTAINERS; do
        # Start ovn-exporter in background
        lxc_exec "$container" "/snap/bin/ovn-exporter --loglevel info" &
        EXPORTER_PID=$!
        
        # Give exporter time to start and collect metrics
        sleep 3
        
        # Test that metrics endpoint returns Prometheus format
        run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
        assert_success
        assert_output --partial "# HELP"
        assert_output --partial "# TYPE"
        
        # Test that OVS metrics are present
        run lxc_exec "$container" "curl -s http://localhost:9310/metrics | grep -i ovs"
        assert_success
        
        # Clean up
        kill $EXPORTER_PID 2>/dev/null || true
    done
}