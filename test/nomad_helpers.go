package test

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"path/filepath"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
)

const REPO_ROOT = "../"

const ENV_VAR_AWS_REGION = "AWS_DEFAULT_REGION"

const VAR_AMI_ID = "ami_id"

const CLUSTER_COLOCATED_EXAMPLE_PATH = "/"
const CLUSTER_COLOCATED_EXAMPLE_VAR_CLUSTER_NAME = "cluster_name"
const CLUSTER_COLOCATED_EXAMPLE_VAR_CLUSTER_TAG_VALUE = "cluster_tag_value"
const CLUSTER_COLOCATED_EXAMPLE_VAR_NUM_SERVERS = "num_servers"
const CLUSTER_COLOCATED_EXAMPLE_VAR_NUM_CLIENTS = "num_clients"
const CLUSTER_COLOCATED_EXAMPLE_OUTPUT_SERVER_ASG_NAME = "asg_name_servers"

const CLUSTER_SEPARATE_EXAMPLE_PATH = "examples/nomad-consul-separate-cluster"
const CLUSTER_SEPARATE_EXAMPLE_VAR_NOMAD_CLUSTER_NAME = "nomad_cluster_name"
const CLUSTER_SEPARATE_EXAMPLE_VAR_CONSUL_CLUSTER_NAME = "consul_cluster_name"
const CLUSTER_SEPARATE_EXAMPLE_VAR_NUM_NOMAD_SERVERS = "num_nomad_servers"
const CLUSTER_SEPARATE_EXAMPLE_VAR_NUM_CONSUL_SERVERS = "num_consul_servers"
const CLUSTER_SEPARATE_EXAMPLE_VAR_NUM_NOMAD_CLIENTS = "num_nomad_clients"
const CLUSTER_SEPARATE_EXAMPLE_OUTPUT_NOMAD_SERVER_ASG_NAME = "asg_name_nomad_servers"

const DEFAULT_NUM_SERVERS = 3
const DEFAULT_NUM_CLIENTS = 6

const SAVED_AWS_REGION = "AwsRegion"
const SAVED_UNIQUE_ID = "UniqueId"

// Test the Nomad/Consul colocated cluster example by:
//
// 1. Copying the code in this repo to a temp folder so tests on the Terraform code can run in parallel without the
//    state files overwriting each other.
// 2. Building the AMI in the nomad-consul-ami example with the given build name
// 3. Deploying that AMI using the example Terraform code
// 4. Checking that the Nomad cluster comes up within a reasonable time period and can respond to requests
func runNomadClusterColocatedTest(t *testing.T, packerBuildName string) {
	examplesDir := test_structure.CopyTerraformFolderToTemp(t, REPO_ROOT, CLUSTER_COLOCATED_EXAMPLE_PATH)

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.Destroy(t, terraformOptions)

		amiId := test_structure.LoadAmiId(t, examplesDir)
		awsRegion := test_structure.LoadString(t, examplesDir, SAVED_AWS_REGION)
		aws.DeleteAmi(t, awsRegion, amiId)
	})

	test_structure.RunTestStage(t, "setup_ami", func() {
		awsRegion := getRandomRegion(t)
		test_structure.SaveString(t, examplesDir, SAVED_AWS_REGION, awsRegion)

		uniqueId := random.UniqueId()
		test_structure.SaveString(t, examplesDir, SAVED_UNIQUE_ID, uniqueId)

		amiId := buildAmi(t, filepath.Join(examplesDir, "examples", "nomad-consul-ami", "nomad-consul.json"), packerBuildName, awsRegion, uniqueId)
		test_structure.SaveAmiId(t, examplesDir, amiId)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		amiId := test_structure.LoadAmiId(t, examplesDir)
		awsRegion := test_structure.LoadString(t, examplesDir, SAVED_AWS_REGION)
		uniqueId := test_structure.LoadString(t, examplesDir, SAVED_UNIQUE_ID)

		terraformOptions := &terraform.Options{
			TerraformDir: examplesDir,
			Vars: map[string]interface{}{
				CLUSTER_COLOCATED_EXAMPLE_VAR_CLUSTER_NAME:      fmt.Sprintf("test-%s", uniqueId),
				CLUSTER_COLOCATED_EXAMPLE_VAR_CLUSTER_TAG_VALUE: fmt.Sprintf("auto-join-%s", uniqueId),
				CLUSTER_COLOCATED_EXAMPLE_VAR_NUM_SERVERS:       DEFAULT_NUM_SERVERS,
				CLUSTER_COLOCATED_EXAMPLE_VAR_NUM_CLIENTS:       DEFAULT_NUM_CLIENTS,
				VAR_AMI_ID: amiId,
			},
			EnvVars: map[string]string{
				ENV_VAR_AWS_REGION: awsRegion,
			},
		}
		test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)

		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		awsRegion := test_structure.LoadString(t, examplesDir, SAVED_AWS_REGION)

		checkNomadClusterIsWorking(t, CLUSTER_COLOCATED_EXAMPLE_OUTPUT_SERVER_ASG_NAME, terraformOptions, awsRegion)
	})
}

// Test the Nomad/Consul separate clusters example by:
//
// 1. Copying the code in this repo to a temp folder so tests on the Terraform code can run in parallel without the
//    state files overwriting each other.
// 2. Building the AMI in the nomad-consul-ami example with the given build name
// 3. Deploying that AMI using the example Terraform code
// 4. Checking that the Nomad cluster comes up within a reasonable time period and can respond to requests
func runNomadClusterSeparateTest(t *testing.T, packerBuildName string) {
	examplesDir := test_structure.CopyTerraformFolderToTemp(t, REPO_ROOT, "/")

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		terraform.Destroy(t, terraformOptions)

		amiId := test_structure.LoadAmiId(t, examplesDir)
		awsRegion := test_structure.LoadString(t, examplesDir, SAVED_AWS_REGION)
		aws.DeleteAmi(t, awsRegion, amiId)
	})

	test_structure.RunTestStage(t, "setup_ami", func() {
		awsRegion := getRandomRegion(t)
		test_structure.SaveString(t, examplesDir, SAVED_AWS_REGION, awsRegion)

		uniqueId := random.UniqueId()
		test_structure.SaveString(t, examplesDir, SAVED_UNIQUE_ID, uniqueId)

		amiId := buildAmi(t, filepath.Join(examplesDir, "examples", "nomad-consul-ami", "nomad-consul.json"), packerBuildName, awsRegion, uniqueId)
		test_structure.SaveAmiId(t, examplesDir, amiId)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		amiId := test_structure.LoadAmiId(t, examplesDir)
		awsRegion := test_structure.LoadString(t, examplesDir, SAVED_AWS_REGION)
		uniqueId := test_structure.LoadString(t, examplesDir, SAVED_UNIQUE_ID)

		terraformOptions := &terraform.Options{
			TerraformDir: filepath.Join(examplesDir, "examples", "nomad-consul-separate-cluster"),
			Vars: map[string]interface{}{
				CLUSTER_SEPARATE_EXAMPLE_VAR_NOMAD_CLUSTER_NAME:  fmt.Sprintf("test-%s", uniqueId),
				CLUSTER_SEPARATE_EXAMPLE_VAR_CONSUL_CLUSTER_NAME: fmt.Sprintf("test-%s", uniqueId),
				CLUSTER_SEPARATE_EXAMPLE_VAR_NUM_NOMAD_SERVERS:   DEFAULT_NUM_SERVERS,
				CLUSTER_SEPARATE_EXAMPLE_VAR_NUM_CONSUL_SERVERS:  DEFAULT_NUM_SERVERS,
				CLUSTER_SEPARATE_EXAMPLE_VAR_NUM_NOMAD_CLIENTS:   DEFAULT_NUM_CLIENTS,
				VAR_AMI_ID: amiId,
			},
			EnvVars: map[string]string{
				ENV_VAR_AWS_REGION: awsRegion,
			},
		}
		test_structure.SaveTerraformOptions(t, examplesDir, terraformOptions)

		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, examplesDir)
		awsRegion := test_structure.LoadString(t, examplesDir, SAVED_AWS_REGION)

		checkNomadClusterIsWorking(t, CLUSTER_SEPARATE_EXAMPLE_OUTPUT_NOMAD_SERVER_ASG_NAME, terraformOptions, awsRegion)
	})
}

// Check that the Nomad cluster comes up within a reasonable time period and can respond to requests
func checkNomadClusterIsWorking(t *testing.T, asgNameOutputVar string, terraformOptions *terraform.Options, awsRegion string) {
	asgName := terraform.Output(t, terraformOptions, asgNameOutputVar)
	nodeIpAddress := getIpAddressOfAsgInstance(t, asgName, awsRegion)
	testNomadCluster(t, nodeIpAddress)
}

// Use a Nomad client to connect to the given node and use it to verify that:
//
// 1. The Nomad cluster has deployed
// 2. The cluster has the expected number of server nodes
// 2. The cluster has the expected number of client nodes
func testNomadCluster(t *testing.T, nodeIpAddress string) {
	maxRetries := 90
	sleepBetweenRetries := 10 * time.Second

	response := retry.DoWithRetry(t, "Check Nomad cluster has expected number of servers and clients", maxRetries, sleepBetweenRetries, func() (string, error) {
		clients, err := callNomadApi(t, nodeIpAddress, "v1/nodes")
		if err != nil {
			return "", err
		}

		if len(clients) != DEFAULT_NUM_CLIENTS {
			return "", fmt.Errorf("Expected the cluster to have %d clients, but found %d", DEFAULT_NUM_CLIENTS, len(clients))
		}

		servers, err := callNomadApi(t, nodeIpAddress, "v1/status/peers")
		if err != nil {
			return "", err
		}

		if len(servers) != DEFAULT_NUM_SERVERS {
			return "", fmt.Errorf("Expected the cluster to have %d servers, but found %d", DEFAULT_NUM_SERVERS, len(servers))
		}

		return fmt.Sprintf("Got back expected number of clients (%d) and servers (%d)", len(clients), len(servers)), nil
	})

	logger.Logf(t, "Nomad cluster is properly deployed: %s", response)
}

// A quick, hacky way to call the Nomad HTTP API: https://www.nomadproject.io/docs/http/index.html
func callNomadApi(t *testing.T, nodeIpAddress string, path string) ([]interface{}, error) {
	url := fmt.Sprintf("http://%s:4646/%s", nodeIpAddress, path)
	logger.Logf(t, "Making an HTTP GET to URL %s", url)

	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	logger.Logf(t, "Response from Nomad for URL %s: %s", url, string(body))

	result := []interface{}{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	return result, nil
}
