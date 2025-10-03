package config

import "fmt"

type Config struct {
	LogLevel        string `mapstructure:"loglevel"`
	Host            string `mapstructure:"host"`
	Port            string `mapstructure:"port"`
	OvnRundir       string `mapstructure:"ovn-rundir"`
	OvsRundir       string `mapstructure:"ovs-rundir"`
	OvnNbdbLocation string `mapstructure:"ovn-nbdb-location"`
	OvnSbdbLocation string `mapstructure:"ovn-sbdb-location"`
}

func (c *Config) BindAddress() string {
	return fmt.Sprintf("%s:%s", c.Host, c.Port)
}

func (c *Config) HasOvnKubernetesOverrides() bool {
	return c.OvnRundir != "" || c.OvsRundir != "" || c.OvnNbdbLocation != "" || c.OvnSbdbLocation != ""
}
