# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "security_group_id" {
  description = "The ID of the security group to which we should add the Nomad security group rules"
  type        = string
}

variable "allowed_inbound_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow connections to Nomad"
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "http_port" {
  description = "The port to use for HTTP"
  type        = number
  default     = 4646
}

variable "rpc_port" {
  description = "The port to use for RPC"
  type        = number
  default     = 4647
}

variable "serf_port" {
  description = "The port to use for Serf"
  type        = number
  default     = 4648
}

