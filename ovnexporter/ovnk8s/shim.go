package ovnk8s

import (
	"github.com/ovn-org/ovn-kubernetes/go-controller/pkg/metrics"
	"github.com/ovn-org/ovn-kubernetes/go-controller/pkg/util"
	"github.com/rs/zerolog/log"
	kexec "k8s.io/utils/exec"
)

type Register interface {
	SetExec() error
	RegisterStandaloneOvsMetrics(stopChan <-chan struct{})
	RegisterOvnDBMetrics(stopChan <-chan struct{})
	RegisterOvnControllerMetrics(stopChan <-chan struct{})
	RegisterOvnNorthdMetrics(stopChan <-chan struct{})
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

func (s *shim) RegisterStandaloneOvsMetrics(stopChan <-chan struct{}) {
	metrics.RegisterStandaloneOvsMetrics(stopChan)
}

func (s *shim) RegisterOvnDBMetrics(stopChan <-chan struct{}) {
	metrics.RegisterOvnDBMetrics(
		func() bool { return true },
		stopChan,
	)
}

func (s *shim) RegisterOvnControllerMetrics(stopChan <-chan struct{}) {
	metrics.RegisterOvnControllerMetrics(stopChan)
}

func (s *shim) RegisterOvnNorthdMetrics(stopChan <-chan struct{}) {
	metrics.RegisterOvnNorthdMetrics(
		func() bool { return true },
		stopChan,
	)
}
