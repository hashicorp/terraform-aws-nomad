# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# or
# AWS_PROFILE
# or
# Beside this it is as well possible to make use of the provided variable "aws_profile".
# Either specifiy it in your tfvars configuration or as configuration parameter:
#  "terraform plan -var 'aws_profile=<local_profile_name>'"

# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

# None

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "ami_id" {
  description = "The ID of the AMI to run in the cluster. This should be an AMI built from the Packer template under examples/nomad-consul-ami/nomad-consul.json. If no AMI is specified, the template will 'just work' by using the example public AMIs. WARNING! Do not use the example AMIs in a production setting!"
  default = ""
}

variable "aws_profile" {
  description = "Specify the local AWS profile configuration to use."
  default     = "default"
}

variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)."
  default     = "us-east-1"
}

variable "nomad_cluster_name" {
  description = "What to name the Nomad cluster and all of its associated resources"
  default     = "nomad-example"
}

variable "consul_cluster_name" {
  description = "What to name the Consul cluster and all of its associated resources"
  default     = "consul-example"
}

variable "num_nomad_servers" {
  description = "The number of Nomad server nodes to deploy. We strongly recommend using 3 or 5."
  default     = 3
}

variable "num_nomad_clients" {
  description = "The number of Nomad client nodes to deploy. You can deploy as many as you need to run your jobs."
  default     = 6
}

variable "num_consul_servers" {
  description = "The number of Consul server nodes to deploy. We strongly recommend using 3 or 5."
  default     = 3
}

variable "cluster_tag_key" {
  description = "The tag the Consul EC2 Instances will look for to automatically discover each other and form a cluster."
  default     = "consul-servers"
}

variable "ssh_key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in this cluster. Set to an empty string to not associate a Key Pair."
  default     = ""
}
