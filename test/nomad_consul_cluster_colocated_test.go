package test

import (
	"testing"
)

func TestNomadConsulClusterColocatedWithUbuntu18Ami(t *testing.T) {
	t.Parallel()
	runNomadClusterColocatedTest(t, "ubuntu18-ami")
}

func TestNomadConsulClusterColocatedWithUbuntu16Ami(t *testing.T) {
	t.Parallel()
	runNomadClusterColocatedTest(t, "ubuntu16-ami")
}

func TestNomadConsulClusterColocatedAmazonLinux2Amd64Ami(t *testing.T) {
	t.Parallel()
	runNomadClusterColocatedTest(t, "amazon-linux-2-amd64-ami")
}
