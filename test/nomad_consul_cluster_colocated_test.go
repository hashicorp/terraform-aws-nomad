package test

import (
	"testing"
)

func TestNomadConsulClusterColocatedWithUbuntuAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterColocatedTest(t, "NomadColoUbuntu", "ubuntu16-ami")
}

func TestNomadConsulClusterColocatedAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterColocatedTest(t, "NomadColoAmznLnx", "amazon-linux-ami")
}

