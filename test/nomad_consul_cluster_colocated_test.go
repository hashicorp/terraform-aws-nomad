package test

import (
	"testing"
)

func TestNomadConsulClusterColocatedWithUbuntuAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterColocatedTest(t, "TestNomadColoUbuntu", "ubuntu-16-ami")
}

func TestNomadConsulClusterColocatedAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterColocatedTest(t, "TestNomadColoAmznLnx", "amazon-linux-ami")
}

