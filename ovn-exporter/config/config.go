package config

import "fmt"

type Config struct {
	LogLevel string
	Host     string
	Port     string
}

func (c *Config) BindAddress() string {
	return fmt.Sprintf("%s:%s", c.Host, c.Port)
}
