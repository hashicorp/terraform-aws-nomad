package test

import "testing"

func TestNomadConsulClusterSeparateWithUbuntuAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterSeparateTest(t, "ubuntu16-ami")
}

func TestNomadConsulClusterSeparateAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runNomadClusterSeparateTest(t, "amazon-linux-ami")
}

