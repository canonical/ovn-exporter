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

@test "Testing OVN exporter functionality and metrics" {
    for container in $TEST_CONTAINERS; do
        echo "# Starting comprehensive test on $container" >&3
        
        # Test help command
        test_exporter_help "$container"
        
        # Test basic metrics functionality (includes startup, endpoint, validation)  
        test_exporter_basic_metrics "$container"
        
        echo "# Completed comprehensive test on $container" >&3
    done
}
