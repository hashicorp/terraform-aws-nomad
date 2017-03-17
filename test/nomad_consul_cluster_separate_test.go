package test

import "testing"

func TestNomadConsulClusterSeparateWithUbuntuAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterSeparateTest(t, "NomadSepUbuntu", "ubuntu-16-ami")
}

func TestNomadConsulClusterSeparateAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterSeparateTest(t, "NomadSepAmznLnx", "amazon-linux-ami")
}

