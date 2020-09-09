# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN AUTO SCALING GROUP (ASG) TO RUN NOMAD
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_autoscaling_group" "autoscaling_group" {
  launch_configuration = aws_launch_configuration.launch_configuration.name

  name                = var.asg_name
  availability_zones  = var.availability_zones
  vpc_zone_identifier = var.subnet_ids

  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  termination_policies = [var.termination_policies]

  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  wait_for_capacity_timeout = var.wait_for_capacity_timeout

  protect_from_scale_in = var.protect_from_scale_in

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
  
  tag {
    key                 = var.cluster_tag_key
    value               = var.cluster_tag_value
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.value["key"]
      value               = tag.value["value"]
      propagate_at_launch = tag.value["propagate_at_launch"]
    }
  }
  
  lifecycle {
    # As of AWS Provider 3.x, inline load_balancers and target_group_arns
    # in an aws_autoscaling_group take precedence over attachment resources.
    # Since the consul-cluster module does not define any Load Balancers,
    # it's safe to assume that we will always want to favor an attachment
    # over these inline properties.
    #
    # For further discussion and links to relevant documentation, see
    # https://github.com/hashicorp/terraform-aws-vault/issues/210
    ignore_changes = [load_balancers, target_group_arns]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE LAUNCH CONFIGURATION TO DEFINE WHAT RUNS ON EACH INSTANCE IN THE ASG
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_launch_configuration" "launch_configuration" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  user_data     = var.user_data

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  key_name             = var.ssh_key_name

  security_groups = concat(
    [aws_security_group.lc_security_group.id],
    var.security_groups,
  )
  placement_tenancy           = var.tenancy
  associate_public_ip_address = var.associate_public_ip_address

  ebs_optimized = var.root_volume_ebs_optimized

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = var.root_volume_delete_on_termination
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices

    content {
      device_name           = ebs_block_device.value["device_name"]
      volume_size           = ebs_block_device.value["volume_size"]
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
    }
  }

  # Important note: whenever using a launch configuration with an auto scaling group, you must set
  # create_before_destroy = true. However, as soon as you set create_before_destroy = true in one resource, you must
  # also set it in every resource that it depends on, or you'll get an error about cyclic dependencies (especially when
  # removing resources). For more info, see:
  #
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  # https://terraform.io/docs/configuration/resources.html
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO CONTROL WHAT REQUESTS CAN GO IN AND OUT OF EACH EC2 INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "lc_security_group" {
  name_prefix = var.cluster_name
  description = "Security group for the ${var.cluster_name} launch configuration"
  vpc_id      = var.vpc_id

  # aws_launch_configuration.launch_configuration in this module sets create_before_destroy to true, which means
  # everything it depends on, including this resource, must set it as well, or you'll get cyclic dependency errors
  # when you try to do a terraform destroy.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type        = "ingress"
  from_port   = var.ssh_port
  to_port     = var.ssh_port
  protocol    = "tcp"
  cidr_blocks = var.allowed_ssh_cidr_blocks

  security_group_id = aws_security_group.lc_security_group.id
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.lc_security_group.id
}

# ---------------------------------------------------------------------------------------------------------------------
# THE INBOUND/OUTBOUND RULES FOR THE SECURITY GROUP COME FROM THE NOMAD-SECURITY-GROUP-RULES MODULE
# ---------------------------------------------------------------------------------------------------------------------

module "security_group_rules" {
  source = "../nomad-security-group-rules"

  security_group_id           = aws_security_group.lc_security_group.id
  allowed_inbound_cidr_blocks = var.allowed_inbound_cidr_blocks

  http_port = var.http_port
  rpc_port  = var.rpc_port
  serf_port = var.serf_port
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH AN IAM ROLE TO EACH EC2 INSTANCE
# We can use the IAM role to grant the instance IAM permissions so we can use the AWS CLI without having to figure out
# how to get our secret AWS access keys onto the box.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = var.cluster_name
  path        = var.instance_profile_path
  role        = aws_iam_role.instance_role.name

  # aws_launch_configuration.launch_configuration in this module sets create_before_destroy to true, which means
  # everything it depends on, including this resource, must set it as well, or you'll get cyclic dependency errors
  # when you try to do a terraform destroy.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = var.cluster_name
  assume_role_policy = data.aws_iam_policy_document.instance_role.json

  # aws_iam_instance_profile.instance_profile in this module sets create_before_destroy to true, which means
  # everything it depends on, including this resource, must set it as well, or you'll get cyclic dependency errors
  # when you try to do a terraform destroy.
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

