package test

import (
	"github.com/gruntwork-io/terratest"
	"testing"
	"os"
	terralog "github.com/gruntwork-io/terratest/log"
	"log"
	"github.com/gruntwork-io/terratest/util"
	"time"
	"fmt"
	"path/filepath"
	"net/http"
	"io/ioutil"
	"encoding/json"
)

const REPO_ROOT = "../"

const VAR_AWS_REGION = "aws_region"
const VAR_AMI_ID = "ami_id"

const CLUSTER_COLOCATED_EXAMPLE_PATH = "examples/nomad-consul-colocated-cluster"
const CLUSTER_COLOCATED_EXAMPLE_VAR_CLUSTER_NAME = "cluster_name"
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

const AMI_EXAMPLE_PATH = "../examples/nomad-consul-ami/nomad-consul.json"

// Test the Nomad/Consul colocated cluster example by:
//
// 1. Copying the code in this repo to a temp folder so tests on the Terraform code can run in parallel without the
//    state files overwriting each other.
// 2. Building the AMI in the nomad-consul-ami example with the given build name
// 3. Deploying that AMI using the example Terraform code
// 4. Checking that the Nomad cluster comes up within a reasonable time period and can respond to requests
func runNomadClusterColocatedTest(t *testing.T, testName string, packerBuildName string) {
	rootTempPath := copyRepoToTempFolder(t, REPO_ROOT)
	defer os.RemoveAll(rootTempPath)

	resourceCollection := createBaseRandomResourceCollection(t)
	terratestOptions := createBaseTerratestOptions(t, testName, filepath.Join(rootTempPath, CLUSTER_COLOCATED_EXAMPLE_PATH), resourceCollection)
	defer terratest.Destroy(terratestOptions, resourceCollection)

	logger := terralog.NewLogger(testName)
	amiId := buildAmi(t, AMI_EXAMPLE_PATH, packerBuildName, resourceCollection, logger)

	terratestOptions.Vars = map[string]interface{} {
		VAR_AWS_REGION: resourceCollection.AwsRegion,
		CLUSTER_COLOCATED_EXAMPLE_VAR_CLUSTER_NAME: testName + resourceCollection.UniqueId,
		CLUSTER_COLOCATED_EXAMPLE_VAR_NUM_SERVERS: DEFAULT_NUM_SERVERS,
		CLUSTER_COLOCATED_EXAMPLE_VAR_NUM_CLIENTS: DEFAULT_NUM_CLIENTS,
		VAR_AMI_ID: amiId,
	}

	deploy(t, terratestOptions)
	checkNomadClusterIsWorking(t, CLUSTER_COLOCATED_EXAMPLE_OUTPUT_SERVER_ASG_NAME, terratestOptions, resourceCollection, logger)
}

// Test the Nomad/Consul separate clusters example by:
//
// 1. Copying the code in this repo to a temp folder so tests on the Terraform code can run in parallel without the
//    state files overwriting each other.
// 2. Building the AMI in the nomad-consul-ami example with the given build name
// 3. Deploying that AMI using the example Terraform code
// 4. Checking that the Nomad cluster comes up within a reasonable time period and can respond to requests
func runNomadClusterSeparateTest(t *testing.T, testName string, packerBuildName string) {
	rootTempPath := copyRepoToTempFolder(t, REPO_ROOT)
	defer os.RemoveAll(rootTempPath)

	resourceCollection := createBaseRandomResourceCollection(t)
	terratestOptions := createBaseTerratestOptions(t, testName, filepath.Join(rootTempPath, CLUSTER_SEPARATE_EXAMPLE_PATH), resourceCollection)
	defer terratest.Destroy(terratestOptions, resourceCollection)

	logger := terralog.NewLogger(testName)
	amiId := buildAmi(t, AMI_EXAMPLE_PATH, packerBuildName, resourceCollection, logger)

	terratestOptions.Vars = map[string]interface{} {
		VAR_AWS_REGION: resourceCollection.AwsRegion,
		CLUSTER_SEPARATE_EXAMPLE_VAR_NOMAD_CLUSTER_NAME: "nomad-" + testName + resourceCollection.UniqueId,
		CLUSTER_SEPARATE_EXAMPLE_VAR_CONSUL_CLUSTER_NAME: "consul-" + testName + resourceCollection.UniqueId,
		CLUSTER_SEPARATE_EXAMPLE_VAR_NUM_NOMAD_SERVERS: DEFAULT_NUM_SERVERS,
		CLUSTER_SEPARATE_EXAMPLE_VAR_NUM_CONSUL_SERVERS: DEFAULT_NUM_SERVERS,
		CLUSTER_SEPARATE_EXAMPLE_VAR_NUM_NOMAD_CLIENTS: DEFAULT_NUM_CLIENTS,
		VAR_AMI_ID: amiId,
	}

	deploy(t, terratestOptions)
	checkNomadClusterIsWorking(t, CLUSTER_SEPARATE_EXAMPLE_OUTPUT_NOMAD_SERVER_ASG_NAME, terratestOptions, resourceCollection, logger)
}

// Check that the Nomad cluster comes up within a reasonable time period and can respond to requests
func checkNomadClusterIsWorking(t *testing.T, asgNameOutputVar string, terratestOptions *terratest.TerratestOptions, resourceCollection *terratest.RandomResourceCollection, logger *log.Logger) {
	asgName, err := terratest.Output(terratestOptions, asgNameOutputVar)
	if err != nil {
		t.Fatalf("Could not read output %s due to error: %v", asgNameOutputVar, err)
	}

	nodeIpAddress := getIpAddressOfAsgInstance(t, asgName, resourceCollection.AwsRegion)
	testNomadCluster(t, nodeIpAddress, logger)
}

// Use a Nomad client to connect to the given node and use it to verify that:
//
// 1. The Nomad cluster has deployed
// 2. The cluster has the expected number of server nodes
// 2. The cluster has the expected number of client nodes
func testNomadCluster(t *testing.T, nodeIpAddress string, logger *log.Logger) {
	maxRetries := 60
	sleepBetweenRetries := 10 * time.Second

	response, err := util.DoWithRetry("Check Nomad members", maxRetries, sleepBetweenRetries, logger, func() (string, error) {
		clients, err := callNomadApi(nodeIpAddress, "v1/nodes", logger)
		if err != nil {
			return "", err
		}

		if len(clients) != DEFAULT_NUM_CLIENTS {
			return "", fmt.Errorf("Expected the cluster to have %d clients, but found %d", DEFAULT_NUM_CLIENTS, len(clients))
		}

		servers, err := callNomadApi(nodeIpAddress, "v1/status/peers", logger)
		if err != nil {
			return "", err
		}

		if len(servers) != DEFAULT_NUM_SERVERS {
			return "", fmt.Errorf("Expected the cluster to have %d servers, but found %d", DEFAULT_NUM_SERVERS, len(servers))
		}

		return fmt.Sprintf("Got back expected number of clients (%d) and servers (%d)", len(clients), len(servers)), nil
	})

	if err != nil {
		t.Fatalf("Could not verify Nomad node at %s was working: %v", nodeIpAddress, err)
	}

	logger.Printf("Nomad cluster is properly deployed: %s", response)
}

// A quick, hacky way to call the Nomad HTTP API: https://www.nomadproject.io/docs/http/index.html
func callNomadApi(nodeIpAddress string, path string, logger *log.Logger) ([]interface{}, error) {
	resp, err := http.Get(fmt.Sprintf("http://%s:4646/%s", nodeIpAddress, path))
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	logger.Printf("Response from Nomad: %s", string(body))

	result := []interface{}{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	return result, nil
}
