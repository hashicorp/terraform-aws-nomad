package test

import "testing"

func TestNomadClusterSSHAccess(t *testing.T) {
	t.Parallel()
	runNomadClusterSSHTest(t, "amazon-linux-2-amd64-ami", "ec2-user")
}
