package main

import (
	"fmt"
	"os"
	"sync"

	"github.com/canonical/ovnexporter/ovnexporter/config"
	"github.com/canonical/ovnexporter/ovnexporter/ovnk8s"
	"github.com/rs/zerolog/log"
	"github.com/spf13/viper"

	"github.com/spf13/cobra"
)

var cfg config.Config

var rootCmd = &cobra.Command{
	Use:               config.AppName,
	RunE:              run,
	Short:             config.ShortDesc,
	PersistentPreRunE: persistentPreRun,
}

func init() {
	rootCmd.Flags().String("loglevel", "debug", "log level")
	rootCmd.Flags().String("host", "0.0.0.0", "prometheus server host")
	rootCmd.Flags().String("port", "9310", "prometheus server port")
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}

func persistentPreRun(cmd *cobra.Command, args []string) error {
	viper.AutomaticEnv()
	viper.SetEnvPrefix(config.EnvPrefix)
	if err := viper.BindPFlags(cmd.Flags()); err != nil {
		return fmt.Errorf("unable to bind flags: %w", err)
	}
	if err := viper.Unmarshal(&cfg); err != nil {
		return fmt.Errorf("unable to decode config")
	}
	log.Debug().Msgf("config %#v", cfg)
	return nil
}

func run(cmd *cobra.Command, args []string) error {
	stopChan := make(chan struct{})
	wg := sync.WaitGroup{}

	ovnK8sShim := ovnk8s.NewOvnK8sShim()

	if err := ovnK8sShim.SetExec(); err != nil {
		return err
	}

	ovnK8sShim.RegisterOvsMetricsWithOvnMetrics(stopChan)
	ovnK8sShim.RegisterOvnDBMetrics(stopChan)
	ovnK8sShim.RegisterOvnControllerMetrics(stopChan)
	ovnK8sShim.RegisterOvnNorthdMetrics(stopChan)

	ovnK8sShim.StartOVNMetricsServer(
		cfg.BindAddress(), "", "", stopChan, &wg,
	)
	wg.Wait()
	close(stopChan)
	return nil
}
