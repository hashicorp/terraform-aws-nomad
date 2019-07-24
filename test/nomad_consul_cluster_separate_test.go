package test

import "testing"

func TestNomadConsulClusterSeparateWith18UbuntuAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterSeparateTest(t, "ubuntu18-ami")
}

func TestNomadConsulClusterSeparateWithUbuntu16Ami(t *testing.T) {
	t.Parallel()
	runNomadClusterSeparateTest(t, "ubuntu16-ami")
}

func TestNomadConsulClusterSeparateAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterSeparateTest(t, "amazon-linux-ami")
}
