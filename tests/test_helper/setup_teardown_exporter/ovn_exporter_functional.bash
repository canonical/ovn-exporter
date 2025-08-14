setup_file() {
    load test_helper/common.bash
    load test_helper/lxd.bash
    load test_helper/microovn.bash
    load ../.bats/bats-support/load.bash
    load ../.bats/bats-assert/load.bash

    ABS_TOP_TEST_DIRNAME="${BATS_TEST_DIRNAME}/"
    export ABS_TOP_TEST_DIRNAME

    # Set microovn prefix variables needed by helper functions
    MICROOVN_PREFIX_LS=sw
    MICROOVN_PREFIX_LR=lr
    MICROOVN_PREFIX_LRP=lrp-sw
    MICROOVN_SUFFIX_LRP_LSP=lrp

    # Create test deployment (following upgrade.bash pattern)
    TEST_CONTAINERS=$(container_names "$BATS_TEST_FILENAME" 3)
    CENTRAL_CONTAINERS=""
    CHASSIS_CONTAINERS=""

    export TEST_CONTAINERS
    export CENTRAL_CONTAINERS
    export CHASSIS_CONTAINERS

    launch_containers_args \
        "${TEST_LXD_LAUNCH_ARGS:--c security.nesting=true -c security.privileged=true}" $TEST_CONTAINERS
    wait_containers_ready $TEST_CONTAINERS
    install_microovn_from_store "" $TEST_CONTAINERS
    bootstrap_cluster $TEST_CONTAINERS

    # Categorize containers as "CENTRAL" and "CHASSIS" based on the services they run
    local container=""
    for container in $TEST_CONTAINERS; do
        container_services=$(microovn_get_cluster_services "$container")
        if [[ "$container_services" == *"central"* ]]; then
            CENTRAL_CONTAINERS+="$container "
        else
            CHASSIS_CONTAINERS+="$container "
        fi
    done

    # Make sure that microcluster is fully converged before proceeding.
    # Performing further actions before the microcluster is ready may lead to
    # unexpectedly long convergence after a microcluster schema upgrade.
    for container in $TEST_CONTAINERS; do
        wait_microovn_online "$container" 60
    done

    # Copy the built binary to all test containers
    for container in $TEST_CONTAINERS; do
        echo "# Copying ovn-exporter binary to $container" >&3
        lxc_file_replace "$PWD/ovn-exporter" "$container/tmp/ovn-exporter"
        lxc_exec "$container" "chmod +x /tmp/ovn-exporter"
    done

    # Follow upgrade.bash pattern exactly (without upgrade part)
    # Export names used locally on chassis containers for use in teardown_file().
    export FUNCTIONAL_TEST_NS_NAME="upgrade_ns0" 
    export FUNCTIONAL_TEST_VIF_NAME="upgrade_vif0"

    # Set up gateway router, workload and background ping on each chassis.
    # This is the exact same setup as upgrade.bash lines 65-73
    assert [ -n "$CENTRAL_CONTAINERS" ]
    
    # If no chassis containers, use all containers for testing
    if [ -z "$CHASSIS_CONTAINERS" ]; then
        echo "# No chassis-only containers found, using all containers for testing" >&3
        CHASSIS_CONTAINERS="$TEST_CONTAINERS"
    fi
    
    assert [ -n "$CHASSIS_CONTAINERS" ]

    for container in $CHASSIS_CONTAINERS; do
        echo "# Setting up gateway and VIF on chassis container $container" >&3
        local ctn_n
        ctn_n=$(microovn_extract_ctn_n "$container")
        microovn_add_gw_router "$container"
        netns_add "$container" "$FUNCTIONAL_TEST_NS_NAME"
        microovn_add_vif "$container" \
            "$FUNCTIONAL_TEST_NS_NAME" "$FUNCTIONAL_TEST_VIF_NAME"
        ping_start "$container" 10.42.${ctn_n}.1 "$FUNCTIONAL_TEST_NS_NAME"
    done
}

teardown_file() {
    collect_coverage $TEST_CONTAINERS

    if [ -n "$FUNCTIONAL_TEST_NS_NAME" ] && [ -n "$FUNCTIONAL_TEST_VIF_NAME" ]; then
        local container
        for container in $CHASSIS_CONTAINERS; do
            microovn_delete_vif "$container" \
                "$FUNCTIONAL_TEST_NS_NAME" "$FUNCTIONAL_TEST_VIF_NAME"
            netns_delete "$container" "$FUNCTIONAL_TEST_NS_NAME"
            microovn_delete_gw_router "$container"
        done
    fi

    delete_containers $TEST_CONTAINERS
}
