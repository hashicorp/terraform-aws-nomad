package test

import (
	"testing"
)

func TestNomadConsulClusterColocatedWithUbuntuAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterColocatedTest(t, "ubuntu16-ami")
}

func TestNomadConsulClusterColocatedAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterColocatedTest(t, "amazon-linux-ami")
}

