# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the Nomad cluster (e.g. nomad-servers-stage). This variable is used to namespace all resources created by this module."
}

variable "ami_id" {
  description = "The ID of the AMI to run in this cluster. Should be an AMI that had Nomad installed and configured by the install-nomad module."
}

variable "instance_type" {
  description = "The type of EC2 Instances to run for each node in the cluster (e.g. t2.micro)."
}

variable "vpc_id" {
  description = "The ID of the VPC in which to deploy the cluster"
}

variable "allowed_inbound_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow connections to Nomad"
  type        = "list"
}

variable "user_data" {
  description = "A User Data script to execute while the server is booting. We remmend passing in a bash script that executes the run-nomad script, which should have been installed in the AMI by the install-nomad module."
}

variable "min_size" {
  description = "The minimum number of nodes to have in the cluster. If you're using this to run Nomad servers, we strongly recommend setting this to 3 or 5."
}

variable "max_size" {
  description = "The maximum number of nodes to have in the cluster. If you're using this to run Nomad servers, we strongly recommend setting this to 3 or 5."
}

variable "desired_capacity" {
  description = "The desired number of nodes to have in the cluster. If you're using this to run Nomad servers, we strongly recommend setting this to 3 or 5."
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "asg_name" {
  description = "The name to use for the Auto Scaling Group"
  default     = ""
}

variable "subnet_ids" {
  description = "The subnet IDs into which the EC2 Instances should be deployed. We recommend one subnet ID per node in the cluster_size variable. At least one of var.subnet_ids or var.availability_zones must be non-empty."
  type        = "list"
  default     = []
}

variable "availability_zones" {
  description = "The availability zones into which the EC2 Instances should be deployed. We recommend one availability zone per node in the cluster_size variable. At least one of var.subnet_ids or var.availability_zones must be non-empty."
  type        = "list"
  default     = []
}

variable "ssh_key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in this cluster. Set to an empty string to not associate a Key Pair."
  default     = ""
}

variable "allowed_ssh_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow SSH connections"
  type        = "list"
  default     = []
}

variable "cluster_tag_key" {
  description = "Add a tag with this key and the value var.cluster_tag_value to each Instance in the ASG."
  default     = "nomad-servers"
}

variable "cluster_tag_value" {
  description = "Add a tag with key var.cluster_tag_key and this value to each Instance in the ASG. This can be used to automatically find other Consul nodes and form a cluster."
  default     = "auto-join"
}

variable "termination_policies" {
  description = "A list of policies to decide how the instances in the auto scale group should be terminated. The allowed values are OldestInstance, NewestInstance, OldestLaunchConfiguration, ClosestToNextInstanceHour, Default."
  default     = "Default"
}

variable "associate_public_ip_address" {
  description = "If set to true, associate a public IP address with each EC2 Instance in the cluster."
  default     = false
}

variable "tenancy" {
  description = "The tenancy of the instance. Must be one of: default or dedicated."
  default     = "default"
}

variable "root_volume_ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized."
  default     = false
}

variable "root_volume_type" {
  description = "The type of volume. Must be one of: standard, gp2, or io1."
  default     = "standard"
}

variable "root_volume_size" {
  description = "The size, in GB, of the root EBS volume."
  default     = 50
}

variable "root_volume_delete_on_termination" {
  description = "Whether the volume should be destroyed on instance termination."
  default     = true
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. Setting this to '0' causes Terraform to skip all Capacity Waiting behavior."
  default     = "10m"
}

variable "health_check_type" {
  description = "Controls how health checking is done. Must be one of EC2 or ELB."
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Time, in seconds, after instance comes into service before checking health."
  default     = 300
}

variable "instance_profile_path" {
  description = "Path in which to create the IAM instance profile."
  default     = "/"
}

variable "http_port" {
  description = "The port to use for HTTP"
  default     = 4646
}

variable "rpc_port" {
  description = "The port to use for RPC"
  default     = 4647
}

variable "serf_port" {
  description = "The port to use for Serf"
  default     = 4648
}

variable "ssh_port" {
  description = "The port used for SSH connections"
  default     = 22
}

variable "security_groups" {
  description = "Additional security groups to attach to the EC2 instances"
  type        = "list"
  default     = []
}

variable "tags" {
  description = "List of extra tag blocks added to the autoscaling group configuration. Each element in the list is a map containing keys 'key', 'value', and 'propagate_at_launch' mapped to the respective values."
  type        = "list"
  default     = []
}

# Example for a ebs_block_device created from a snapshot and one with a certain size.
# ebs_block_devices = [{
#    "device_name" = "/dev/xvdf"
#    "snapshot_id" = "snap-XYZ"
#  },
#  {
#    "device_name" = "/dev/xvde"
#    "volume_size" = "50"
#  }]
variable "ebs_block_devices" {
  description = "List of ebs volume definitions for those ebs_volumes that should be added to the instances created with the EC2 launch-configuration. Each element in the list is a map containing keys defined for ebs_block_device (see: https://www.terraform.io/docs/providers/aws/r/launch_configuration.html#ebs_block_device."
  type        = "list"
  default     = []
}
