package ovnk8s

import (
	"os"
	"path/filepath"
	"sync"

	"github.com/canonical/ovn-exporter/ovn-exporter/config"
	libovsdbclient "github.com/ovn-kubernetes/libovsdb/client"
	ovnconfig "github.com/ovn-org/ovn-kubernetes/go-controller/pkg/config"
	"github.com/ovn-org/ovn-kubernetes/go-controller/pkg/libovsdb"
	"github.com/ovn-org/ovn-kubernetes/go-controller/pkg/metrics"
	"github.com/ovn-org/ovn-kubernetes/go-controller/pkg/util"
	"github.com/rs/zerolog/log"
	kexec "k8s.io/utils/exec"
)

type Register interface {
	SetExec() error
	ApplyConfigOverrides(cfg *config.Config) error
	NewOVSClient(stopChan <-chan struct{}) (libovsdbclient.Client, error)
	RegisterOvsMetricsWithOvnMetrics(ovsDBClient libovsdbclient.Client, metricsScrapeInterval int, stopChan <-chan struct{})
	RegisterOvnDBMetrics(stopChan <-chan struct{})
	RegisterOvnControllerMetrics(ovsDBClient libovsdbclient.Client, metricsScrapeInterval int, stopChan <-chan struct{})
	RegisterOvnNorthdMetrics(stopChan <-chan struct{})
	StartOVNMetricsServer(bindAddress, certFile, keyFile string, stopChan <-chan struct{}, wg *sync.WaitGroup)
}

type OvnK8sShim interface {
	Register
}

type shim struct{}

func NewOvnK8sShim() OvnK8sShim {
	return &shim{}
}

func (s *shim) SetExec() error {
	if err := util.SetExec(kexec.New()); err != nil {
		log.Error().Err(err).Msg("SetExec error")
		return err
	}
	return nil
}

func (s *shim) NewOVSClient(stopChan <-chan struct{}) (libovsdbclient.Client, error) {
	// Construct OVS DB socket path from configured run directory
	ovsDbSockPath := "unix:" + filepath.Join(ovnconfig.OvsPaths.RunDir, "db.sock")

	cfg := ovnconfig.OvnAuthConfig{
		Scheme:  ovnconfig.OvnDBSchemeUnix,
		Address: ovsDbSockPath,
	}

	log.Debug().Str("ovs-db-socket", ovsDbSockPath).Msg("Creating OVS client")
	return libovsdb.NewOVSClientWithConfig(cfg, stopChan)
}

func (s *shim) ApplyConfigOverrides(cfg *config.Config) error {
	log.Debug().
		Str("ovn-rundir", cfg.OvnRundir).
		Str("ovs-rundir", cfg.OvsRundir).
		Str("ovn-nbdb-location", cfg.OvnNbdbLocation).
		Str("ovn-sbdb-location", cfg.OvnSbdbLocation).
		Msg("Received configuration values")

	if !cfg.HasOvnKubernetesOverrides() {
		log.Debug().Msg("No OVN/OVS configuration overrides provided")
		return nil
	}

	log.Info().Msg("Applying OVN/OVS configuration overrides")

	if cfg.OvnRundir != "" {
		log.Info().Str("ovn-rundir", cfg.OvnRundir).Msg("Overriding OVN RunDir")
		ovnconfig.OvnNorth.RunDir = cfg.OvnRundir
		ovnconfig.OvnSouth.RunDir = cfg.OvnRundir
	}

	if cfg.OvsRundir != "" {
		log.Info().Str("ovs-rundir", cfg.OvsRundir).Msg("Overriding OVS RunDir")
		ovnconfig.OvsPaths.RunDir = cfg.OvsRundir
	}

	if cfg.OvnNbdbLocation != "" {
		log.Info().Str("ovn-nbdb-location", cfg.OvnNbdbLocation).Msg("Overriding OVN northbound DB location")
		ovnconfig.OvnNorth.DbLocation = cfg.OvnNbdbLocation
	}

	if cfg.OvnSbdbLocation != "" {
		log.Info().Str("ovn-sbdb-location", cfg.OvnSbdbLocation).Msg("Overriding OVN southbound DB location")
		ovnconfig.OvnSouth.DbLocation = cfg.OvnSbdbLocation
	}

	// Set environment variables for OVS tools
	if cfg.OvsRundir != "" {
		log.Info().Str("OVS_RUNDIR", cfg.OvsRundir).Msg("Setting OVS_RUNDIR environment variable")
		os.Setenv("OVS_RUNDIR", cfg.OvsRundir)
	}

	if cfg.OvnRundir != "" {
		log.Info().Str("OVN_RUNDIR", cfg.OvnRundir).Msg("Setting OVN_RUNDIR environment variable")
		os.Setenv("OVN_RUNDIR", cfg.OvnRundir)
	}

	log.Debug().
		Str("final-ovn-north-rundir", ovnconfig.OvnNorth.RunDir).
		Str("final-ovn-south-rundir", ovnconfig.OvnSouth.RunDir).
		Str("final-ovs-rundir", ovnconfig.OvsPaths.RunDir).
		Str("final-ovn-nb-location", ovnconfig.OvnNorth.DbLocation).
		Str("final-ovn-sb-location", ovnconfig.OvnSouth.DbLocation).
		Msg("Final ovn-kubernetes configuration after overrides")

	return nil
}

func (s *shim) RegisterOvnDBMetrics(stopChan <-chan struct{}) {
	metrics.RegisterOvnDBMetrics(
		func() bool { return true },
		stopChan,
	)
}

func (s *shim) RegisterOvnControllerMetrics(ovsDBClient libovsdbclient.Client, metricsScrapeInterval int, stopChan <-chan struct{}) {
	metrics.RegisterOvnControllerMetrics(ovsDBClient, metricsScrapeInterval, stopChan)
}

func (s *shim) RegisterOvnNorthdMetrics(stopChan <-chan struct{}) {
	metrics.RegisterOvnNorthdMetrics(
		func() bool { return true },
		stopChan,
	)
}

func (s *shim) RegisterOvsMetricsWithOvnMetrics(ovsDBClient libovsdbclient.Client, metricsScrapeInterval int, stopChan <-chan struct{}) {
	metrics.RegisterOvsMetricsWithOvnMetrics(ovsDBClient, metricsScrapeInterval, stopChan)
}

func (s *shim) StartOVNMetricsServer(bindAddress, certFile, keyFile string, stopChan <-chan struct{}, wg *sync.WaitGroup) {
	metrics.StartOVNMetricsServer(bindAddress, certFile, keyFile, stopChan, wg)
}
