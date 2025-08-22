setup_file() {
    load test_helper/common.bash
    load test_helper/lxd.bash
    load test_helper/microovn.bash

    TEST_CONTAINERS=$(container_names "$BATS_TEST_FILENAME" 1)
    export TEST_CONTAINERS
    # Launch containers with security.nesting=true for network namespace support
    launch_containers $TEST_CONTAINERS
    wait_containers_ready $TEST_CONTAINERS
    install_microovn_from_store "" $TEST_CONTAINERS
    bootstrap_cluster $TEST_CONTAINERS

    # Copy the built binary to all test containers
    for container in $TEST_CONTAINERS; do
        echo "# Copying ovnexporter binary to $container" >&3
        lxc_file_replace "$PWD/ovnexporter" "$container/tmp/ovnexporter"
        lxc_exec "$container" "chmod +x /tmp/ovnexporter"
    done
}

teardown_file() {
    collect_coverage $TEST_CONTAINERS
    delete_containers $TEST_CONTAINERS
}
