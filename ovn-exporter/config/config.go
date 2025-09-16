package config

import "fmt"

type Config struct {
	LogLevel         string `mapstructure:"loglevel"`
	Host             string `mapstructure:"host"`
	Port             string `mapstructure:"port"`
	OvnRundir        string `mapstructure:"ovn-rundir"`
	OvsRundir        string `mapstructure:"ovs-rundir"`
	OvsVswitchdPid   string `mapstructure:"ovs-vswitchd-pid"`
	OvsdbServerPid   string `mapstructure:"ovsdb-server-pid"`
	OvnNbdbLocation  string `mapstructure:"ovn-nbdb-location"`
	OvnSbdbLocation  string `mapstructure:"ovn-sbdb-location"`
}

func (c *Config) BindAddress() string {
	return fmt.Sprintf("%s:%s", c.Host, c.Port)
}

func (c *Config) HasOvnKubernetesOverrides() bool {
	return c.OvnRundir != "" || c.OvsRundir != "" || c.OvsVswitchdPid != "" ||
		c.OvsdbServerPid != "" || c.OvnNbdbLocation != "" || c.OvnSbdbLocation != ""
}
