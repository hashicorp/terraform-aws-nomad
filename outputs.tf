output "num_nomad_servers" {
  value = module.servers.cluster_size
}

output "asg_name_servers" {
  value = module.servers.asg_name
}

output "launch_config_name_servers" {
  value = module.servers.launch_config_name
}

output "iam_role_arn_servers" {
  value = module.servers.iam_role_arn
}

output "iam_role_id_servers" {
  value = module.servers.iam_role_id
}

output "security_group_id_servers" {
  value = module.servers.security_group_id
}

output "num_clients" {
  value = module.clients.cluster_size
}

output "asg_name_clients" {
  value = module.clients.asg_name
}

output "launch_config_name_clients" {
  value = module.clients.launch_config_name
}

output "iam_role_arn_clients" {
  value = module.clients.iam_role_arn
}

output "iam_role_id_clients" {
  value = module.clients.iam_role_id
}

output "security_group_id_clients" {
  value = module.clients.security_group_id
}

output "aws_region" {
  value = data.aws_region.current.name
}

output "nomad_servers_cluster_tag_key" {
  value = module.servers.cluster_tag_key
}

output "nomad_servers_cluster_tag_value" {
  value = module.servers.cluster_tag_value
}

