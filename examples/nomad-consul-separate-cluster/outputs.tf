output "num_nomad_servers" {
  value = "${module.nomad_servers.cluster_size}"
}

output "asg_name_nomad_servers" {
  value = "${module.nomad_servers.asg_name}"
}

output "launch_config_name_nomad_servers" {
  value = "${module.nomad_servers.launch_config_name}"
}

output "iam_role_arn_nomad_servers" {
  value = "${module.nomad_servers.iam_role_arn}"
}

output "iam_role_id_nomad_servers" {
  value = "${module.nomad_servers.iam_role_id}"
}

output "security_group_id_nomad_servers" {
  value = "${module.nomad_servers.security_group_id}"
}

output "num_consul_servers" {
  value = "${module.consul_servers.cluster_size}"
}

output "asg_name_consul_servers" {
  value = "${module.consul_servers.asg_name}"
}

output "launch_config_name_consul_servers" {
  value = "${module.consul_servers.launch_config_name}"
}

output "iam_role_arn_consul_servers" {
  value = "${module.consul_servers.iam_role_arn}"
}

output "iam_role_id_consul_servers" {
  value = "${module.consul_servers.iam_role_id}"
}

output "security_group_id_consul_servers" {
  value = "${module.consul_servers.security_group_id}"
}

output "num_nomad_clients" {
  value = "${module.nomad_clients.cluster_size}"
}

output "asg_name_nomad_clients" {
  value = "${module.nomad_clients.asg_name}"
}

output "launch_config_name_nomad_clients" {
  value = "${module.nomad_clients.launch_config_name}"
}

output "iam_role_arn_nomad_clients" {
  value = "${module.nomad_clients.iam_role_arn}"
}

output "iam_role_id_nomad_clients" {
  value = "${module.nomad_clients.iam_role_id}"
}

output "security_group_id_nomad_clients" {
  value = "${module.nomad_clients.security_group_id}"
}

output "aws_region" {
  value = "${var.aws_region}"
}

output "nomad_servers_cluster_tag_key" {
  value = "${module.nomad_servers.cluster_tag_key}"
}

output "nomad_servers_cluster_tag_value" {
  value = "${module.nomad_servers.cluster_tag_value}"
}