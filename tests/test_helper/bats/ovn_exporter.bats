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
        lxc_exec "$container" "
            export OVS_RUNDIR='/var/snap/microovn/common/run/switch'
            export OVN_RUNDIR='/var/snap/microovn/common/run/ovn'
            export OVS_VSWITCHD_PID='/var/snap/microovn/common/run/switch/ovs-vswitchd.pid'
            export OVSDB_SERVER_PID='/var/snap/microovn/common/run/switch/ovsdb-server.pid'
            export OVN_NBDB_LOCATION='/var/snap/microovn/common/data/central/db/ovnnb_db.db'
            export OVN_SBDB_LOCATION='/var/snap/microovn/common/data/central/db/ovnsb_db.db'
            timeout 5s /tmp/ovn-exporter --loglevel info
        " &
        
        # Give exporter time to start
        sleep 3
        
        # Verify exporter is running
        run lxc_exec "$container" "pgrep -f ovn-exporter"
        assert_success
        
        # Test health endpoint
        run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
        assert_success
        
        # Clean up using pkill
        lxc_exec "$container" "pkill -f ovn-exporter" || true
        sleep 1
    done
}

ovn_exporter_metrics_tests() {
    for container in $TEST_CONTAINERS; do
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
        sleep 5
        
        # Verify exporter is running
        run lxc_exec "$container" "pgrep -f ovn-exporter"
        assert_success
        echo "# $container: Exporter process is running"
        
        # Test that metrics endpoint returns Prometheus format
        run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
        assert_success
        assert_output --partial "# HELP"
        assert_output --partial "# TYPE"
        
        # Test that specific OVS metrics are present
        run lxc_exec "$container" "curl -s http://localhost:9310/metrics"
        assert_success
        
        # Check for core OVS metrics
        assert_output --partial "ovs_build_info"
        assert_output --partial "ovs_vswitchd_bridge"
        assert_output --partial "ovs_vswitchd_process_"
        assert_output --partial "ovs_db_process_"
        
        # Test specific metric patterns
        run lxc_exec "$container" "curl -s http://localhost:9310/metrics | grep -E '(ovs_build_info|ovs_vswitchd_bridge_total|ovs_vswitchd_process_cpu_seconds_total|ovs_db_process_cpu_seconds_total)'"
        assert_success
        
        echo "# $container: OVS metrics verification passed"
        
        # Clean up using pkill
        lxc_exec "$container" "pkill -f ovn-exporter" || true
        sleep 1
    done
}
