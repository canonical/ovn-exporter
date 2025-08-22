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

teardown() {
    # Clean up any exporter processes
    for container in $TEST_CONTAINERS; do
        cleanup_exporter "$container"
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
        
        # Test modules in sequence - focus on metrics only
        test_exporter_startup "$container"
        
        wait_for_metrics_endpoint "$container"
        validate_ovs_metrics_comprehensive "$container"
        validate_ovn_controller_metrics_comprehensive "$container"  
        validate_ovn_database_metrics_comprehensive "$container"
        validate_ovn_northd_metrics_comprehensive "$container"
        
        # Cleanup for next container
        cleanup_exporter_process "$container"
        echo "# Completed functional test on $container" >&3
    done
}


# Start the OVN exporter process
test_exporter_startup() {
    local container=$1
    
    # Start ovn exporter in background with MicroOVN environment
    start_ovn_exporter "$container"
    
    # Wait for exporter process to start
    wait_for_exporter_process "$container"
    
    # Verify exporter process is running
    run lxc_exec "$container" "pgrep -f ovnexporter"
    assert_success
    echo "# $container: Exporter process started successfully"
}


# Clean up exporter process
cleanup_exporter_process() {
    local container=$1
    
    cleanup_exporter "$container"
    echo "# $container: Exporter process cleaned up"
}
