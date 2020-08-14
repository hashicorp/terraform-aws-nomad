package test

import (
	"fmt"
	"testing"
	"github.com/gruntwork-io/terratest/modules/packer"
)

const CONSUL_AMI_TEMPLATE_VAR_REGION = "aws_region"
const CONSUL_AMI_TEMPLATE_VAR_AMI_PREFIX = "ami_name_prefix"

// Use Packer to build the AMI in the given packer template, with the given build name, and return the AMI's ID
func buildAmi(t *testing.T, packerTemplatePath string, packerBuildName string, awsRegion string, uniqueId string) string {
	options := &packer.Options{
		Template: packerTemplatePath,
		Only:     packerBuildName,
		Vars: map[string]string{
			CONSUL_AMI_TEMPLATE_VAR_REGION:     awsRegion,
			CONSUL_AMI_TEMPLATE_VAR_AMI_PREFIX: fmt.Sprintf("nomad-consul-%s", uniqueId),
		},
	}

	return packer.BuildAmi(t, options)
}
