# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A NOMAD CLUSTER AND A SEPARATE CONSUL CLUSTER IN AWS
# These templates show an example of how to use the nomad-cluster module to deploy a Nomad cluster in AWS. This cluster
# connects to Consul running in a separate cluster.
#
# We deploy two Auto Scaling Groups (ASGs) for Nomad: one with a small number of Nomad server nodes and one with a
# larger number of Nomad client nodes. Note that these templates assume that the AMI you provide via the
# nomad_ami_id input variable is built from the examples/nomad-consul-ami/nomad-consul.json Packer template.
#
# We also deploy one ASG for Consul which has a small number of Consul server nodes. Note that these templates assume
# that the AMI you provide via the consul_ami_id input variable is built from the examples/consul-ami/consul.json
# Packer template in the Consul AWS Module.
# ---------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  # This module is now only being tested with Terraform 1.0.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 1.0.x code.
  required_version = ">= 0.12.26"
}

# ---------------------------------------------------------------------------------------------------------------------
# AUTOMATICALLY LOOK UP THE LATEST PRE-BUILT AMI
# This repo contains a CircleCI job that automatically builds and publishes the latest AMI by building the Packer
# template at /examples/nomad-consul-ami upon every new release. The Terraform data source below automatically looks up
# the latest AMI so that a simple "terraform apply" will just work without the user needing to manually build an AMI and
# fill in the right value.
#
# !! WARNING !! These exmaple AMIs are meant only convenience when initially testing this repo. Do NOT use these example
# AMIs in a production setting because it is important that you consciously think through the configuration you want
# in your own production AMI.
#
# NOTE: This Terraform data source must return at least one AMI result or the entire template will fail. See
# /_ci/publish-amis-in-new-account.md for more information.
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ami" "nomad_consul" {
  most_recent = true

  # If we change the AWS Account in which test are run, update this value.
  owners = ["562637147889"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "is-public"
    values = ["true"]
  }

  filter {
    name   = "name"
    values = ["nomad-consul-ubuntu-*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE NOMAD SERVER NODES
# ---------------------------------------------------------------------------------------------------------------------

module "nomad_servers" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "github.com/hashicorp/terraform-aws-nomad//modules/nomad-cluster?ref=v0.1.0"
  source = "../../modules/nomad-cluster"

  cluster_name  = "${var.nomad_cluster_name}-server"
  cluster_size  = var.num_nomad_servers
  instance_type = "t2.micro"

  ami_id    = var.ami_id == null ? data.aws_ami.nomad_consul.image_id : var.ami_id
  user_data = data.template_file.user_data_nomad_server.rendered

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # To make testing easier, we allow requests from any IP address here but in a production deployment, we strongly
  # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  ssh_key_name                = var.ssh_key_name
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM POLICIES FOR CONSUL
# To allow our server Nodes to automatically discover the Consul servers, we need to give them the IAM permissions from
# the Consul AWS Module's consul-iam-policies module.
# ---------------------------------------------------------------------------------------------------------------------

module "consul_iam_policies_servers" {
  source = "github.com/hashicorp/terraform-aws-consul//modules/consul-iam-policies?ref=v0.8.0"

  iam_role_id = module.nomad_servers.iam_role_id
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH NOMAD SERVER NODE WHEN IT'S BOOTING
# This script will configure and start Nomad
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_nomad_server" {
  template = file("${path.module}/user-data-nomad-server.sh")

  vars = {
    num_servers       = var.num_nomad_servers
    cluster_tag_key   = var.cluster_tag_key
    cluster_tag_value = var.consul_cluster_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL SERVER NODES
# ---------------------------------------------------------------------------------------------------------------------

module "consul_servers" {
  source = "github.com/hashicorp/terraform-aws-consul//modules/consul-cluster?ref=v0.8.0"

  cluster_name  = "${var.consul_cluster_name}-server"
  cluster_size  = var.num_consul_servers
  instance_type = "t2.micro"

  # The EC2 Instances will use these tags to automatically discover each other and form a cluster
  cluster_tag_key   = var.cluster_tag_key
  cluster_tag_value = var.consul_cluster_name

  ami_id    = var.ami_id == null ? data.aws_ami.nomad_consul.image_id : var.ami_id
  user_data = data.template_file.user_data_consul_server.rendered

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  ssh_key_name                = var.ssh_key_name
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH CONSUL SERVER EC2 INSTANCE WHEN IT'S BOOTING
# This script will configure and start Consul
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_consul_server" {
  template = file("${path.module}/user-data-consul-server.sh")

  vars = {
    cluster_tag_key   = var.cluster_tag_key
    cluster_tag_value = var.consul_cluster_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE NOMAD CLIENT NODES
# ---------------------------------------------------------------------------------------------------------------------

module "nomad_clients" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "github.com/hashicorp/terraform-aws-nomad//modules/nomad-cluster?ref=v0.0.1"
  source = "../../modules/nomad-cluster"

  cluster_name  = "${var.nomad_cluster_name}-client"
  cluster_size  = var.num_clients
  instance_type = "t2.micro"

  # Give the clients a different tag so they don't try to join the server cluster
  cluster_tag_key   = "nomad-clients"
  cluster_tag_value = var.nomad_cluster_name

  ami_id           = var.ami_id == null ? data.aws_ami.nomad_consul.image_id : var.ami_id
  user_data        = data.template_file.user_data_nomad_client.rendered
  vpc_id           = data.aws_vpc.default.id
  subnet_ids       = data.aws_subnet_ids.default.ids

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks     = ["0.0.0.0/0"]
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  ssh_key_name                = var.ssh_key_name
  ebs_block_devices = [
    {
      "device_name" = "/dev/xvde"
      "volume_size" = "10"
    },
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM POLICIES FOR CONSUL
# To allow our client Nodes to automatically discover the Consul servers, we need to give them the IAM permissions from
# the Consul AWS Module's consul-iam-policies module.
# ---------------------------------------------------------------------------------------------------------------------

module "consul_iam_policies_clients" {
  source = "github.com/hashicorp/terraform-aws-consul//modules/consul-iam-policies?ref=v0.8.0"

  iam_role_id = module.nomad_clients.iam_role_id
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH CLIENT NODE WHEN IT'S BOOTING
# This script will configure and start Consul and Nomad
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_nomad_client" {
  template = file("${path.module}/user-data-nomad-client.sh")

  vars = {
    cluster_tag_key   = var.cluster_tag_key
    cluster_tag_value = var.consul_cluster_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CLUSTER IN THE DEFAULT VPC AND SUBNETS
# Using the default VPC and subnets makes this example easy to run and test, but it means Consul and Nomad are
# accessible from the public Internet. In a production deployment, we strongly recommend deploying into a custom VPC
# and private subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_region" "current" {
}
