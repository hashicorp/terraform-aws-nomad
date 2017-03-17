package test

import "testing"

func TestNomadConsulClusterSeparateWithUbuntuAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterSeparateTest(t, "TestNomadSepUbuntu", "ubuntu-16-ami")
}

func TestNomadConsulClusterSeparateAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterSeparateTest(t, "TestNomadSepAmznLnx", "amazon-linux-ami")
}

