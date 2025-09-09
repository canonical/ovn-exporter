setup_file() {
    load test_helper/common.bash
    load test_helper/lxd.bash
    load test_helper/microovn.bash
    load test_helper/ovn_exporter_common.bash

    TEST_CONTAINERS=$(container_names "$BATS_TEST_FILENAME" 1)
    export TEST_CONTAINERS
    # Launch containers with security.nesting=true for network namespace support
    launch_containers $TEST_CONTAINERS
    wait_containers_ready $TEST_CONTAINERS
    install_microovn_from_store "latest/edge" $TEST_CONTAINERS
    bootstrap_cluster $TEST_CONTAINERS

    # Install OVN Exporter snap to all test containers
    install_ovn_exporter "$PWD/ovn-exporter.snap" $TEST_CONTAINERS
}

teardown_file() {
    collect_coverage $TEST_CONTAINERS
    delete_containers $TEST_CONTAINERS
}
