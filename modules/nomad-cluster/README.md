# Nomad Cluster

This folder contains a [Terraform](https://www.terraform.io/) module that can be used to deploy a
[Nomad](https://www.nomadproject.io/) cluster in [AWS](https://aws.amazon.com/) on top of an Auto Scaling Group. This
module is designed to deploy an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
that had Nomad installed via the [install-nomad](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/install-nomad) module in this Module.

Note that this module assumes you have a separate [Consul](https://www.consul.io/) cluster already running. If you want
to run Consul and Nomad in the same cluster, instead of using this module, see the [Deploy Nomad and Consul in the same
cluster documentation](https://github.com/hashicorp/terraform-aws-nomad/tree/master/README.md#deploy-nomad-and-consul-in-the-same-cluster).

## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "nomad_cluster" {
  # TODO: update this to the final URL
  # Use version v0.0.1 of the nomad-cluster module
  source = "github.com/hashicorp/terraform-aws-nomad//modules/nomad-cluster?ref=v0.0.1"

  # Specify the ID of the Nomad AMI. You should build this using the scripts in the install-nomad module.
  ami_id = "ami-abcd1234"

  # Configure and start Nomad during boot. It will automatically connect to the Consul cluster specified in its
  # configuration and form a cluster with other Nomad nodes connected to that Consul cluster.
  user_data = <<-EOF
              #!/bin/bash
              /opt/nomad/bin/run-nomad --server --num-servers 3
              EOF

  # ... See variables.tf for the other parameters you must define for the nomad-cluster module
}
```

Note the following parameters:

- `source`: Use this parameter to specify the URL of the nomad-cluster module. The double slash (`//`) is intentional
  and required. Terraform uses it to specify subfolders within a Git repo (see [module
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in
  this repo. That way, instead of using the latest version of this module from the `master` branch, which
  will change every time you run Terraform, you're using a fixed version of the repo.

- `ami_id`: Use this parameter to specify the ID of a Nomad [Amazon Machine Image
  (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) to deploy on each server in the cluster. You
  should install Nomad in this AMI using the scripts in the [install-nomad](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/install-nomad) module.

- `user_data`: Use this parameter to specify a [User
  Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts) script that each
  server will run during boot. This is where you can use the [run-nomad script](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/run-nomad) to configure and
  run Nomad. The `run-nomad` script is one of the scripts installed by the [install-nomad](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/install-nomad)
  module.

You can find the other parameters in [variables.tf](variables.tf).

Check out the [nomad-consul-separate-cluster example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/nomad-consul-separate-cluster) example for working
sample code. Note that if you want to run Nomad and Consul on the same cluster, see the [nomad-consul-colocated-cluster
example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/MAIN.md) example instead.

## How do you connect to the Nomad cluster?

### Using the Node agent from your own computer

If you want to connect to the cluster from your own computer, [install
Nomad](https://www.nomadproject.io/docs/install/index.html) and execute commands with the `-address` parameter set to
the IP address of one of the servers in your Nomad cluster. Note that this only works if the Nomad cluster is running
in public subnets and/or your default VPC (as in both [examples](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples)), which is OK for testing and
experimentation, but NOT recommended for production usage.

To use the HTTP API, you first need to get the public IP address of one of the Nomad Instances. If you deployed the
[nomad-consul-colocated-cluster](https://github.com/hashicorp/terraform-aws-nomad/tree/master/MAIN.md) or
[nomad-consul-separate-cluster](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/nomad-consul-separate-cluster) example, the
[nomad-examples-helper.sh script](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/nomad-examples-helper/nomad-examples-helper.sh) will do the tag lookup for
you automatically (note, you must have the [AWS CLI](https://aws.amazon.com/cli/),
[jq](https://stedolan.github.io/jq/), and the [Nomad agent](https://www.nomadproject.io/) installed locally):

```
> ../nomad-examples-helper/nomad-examples-helper.sh

Your Nomad servers are running at the following IP addresses:

34.204.85.139
52.23.167.204
54.236.16.38
```

Copy and paste one of these IPs and use it with the `-address` argument for any [Nomad
command](https://www.nomadproject.io/docs/commands/index.html). For example, to see the status of all the Nomad
servers:

```
> nomad server members -address=http://<INSTANCE_IP_ADDR>:4646

ip-172-31-23-140.global  172.31.23.140  4648  alive   true    2         0.5.4  dc1         global
ip-172-31-23-141.global  172.31.23.141  4648  alive   true    2         0.5.4  dc1         global
ip-172-31-23-142.global  172.31.23.142  4648  alive   true    2         0.5.4  dc1         global
```

To see the status of all the Nomad agents:

```
> nomad node status -address=http://<INSTANCE_IP_ADDR>:4646

ID        DC          Name                 Class   Drain  Status
ec2796cd  us-east-1e  i-0059e5cafb8103834  <none>  false  ready
ec2f799e  us-east-1d  i-0a5552c3c375e9ea0  <none>  false  ready
ec226624  us-east-1b  i-0d647981f5407ae32  <none>  false  ready
ec2d4635  us-east-1a  i-0c43dcc509e3d8bdf  <none>  false  ready
ec232ea5  us-east-1d  i-0eff2e6e5989f51c1  <none>  false  ready
ec2d4bd6  us-east-1c  i-01523bf946d98003e  <none>  false  ready
```

And to submit a job called `example.nomad`:

```
> nomad run -address=http://<INSTANCE_IP_ADDR>:4646 example.nomad

==> Monitoring evaluation "0d159869"
    Evaluation triggered by job "example"
    Allocation "5cbf23a1" created: node "1e1aa1e0", group "example"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "0d159869" finished with status "complete"
```

### Using the Nomad agent on another EC2 Instance

For production usage, your EC2 Instances should be running the [Nomad
agent](https://www.nomadproject.io/docs/agent/index.html). The agent nodes should discover the Nomad server nodes
automatically using Consul. Check out the [Service Discovery
documentation](https://www.nomadproject.io/docs/service-discovery/index.html) for details.

## What's included in this module?

This module creates the following architecture:

![Nomad architecture](https://raw.githubusercontent.com/hashicorp/terraform-aws-nomad/master/_docs/architecture.png)

This architecture consists of the following resources:

- [Auto Scaling Group](#auto-scaling-group)
- [Security Group](#security-group)
- [IAM Role and Permissions](#iam-role-and-permissions)

### Auto Scaling Group

This module runs Nomad on top of an [Auto Scaling Group (ASG)](https://aws.amazon.com/autoscaling/). Typically, you
should run the ASG with 3 or 5 EC2 Instances spread across multiple [Availability
Zones](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). Each of the EC2
Instances should be running an AMI that has had Nomad installed via the [install-nomad](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/install-nomad)
module. You pass in the ID of the AMI to run using the `ami_id` input parameter.

### Security Group

Each EC2 Instance in the ASG has a Security Group that allows:

- All outbound requests
- All the inbound ports specified in the [Nomad
  documentation](https://www.nomadproject.io/docs/agent/configuration/index.html#ports)

The Security Group ID is exported as an output variable if you need to add additional rules.

Check out the [Security section](#security) for more details.

### IAM Role and Permissions

Each EC2 Instance in the ASG has an [IAM Role](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) attached.
We give this IAM role a small set of IAM permissions that each EC2 Instance can use to automatically discover the other
Instances in its ASG and form a cluster with them.

The IAM Role ARN is exported as an output variable if you need to add additional permissions.

## How do you roll out updates?

If you want to deploy a new version of Nomad across the cluster, the best way to do that is to:

1. Build a new AMI.
1. Set the `ami_id` parameter to the ID of the new AMI.
1. Run `terraform apply`.

This updates the Launch Configuration of the ASG, so any new Instances in the ASG will have your new AMI, but it does
NOT actually deploy those new instances. To make that happen, you should do the following:

1. Issue an API call to one of the old Instances in the ASG to have it leave gracefully. E.g.:

   ```
   nomad server force-leave -address=<OLD_INSTANCE_IP>:4646
   ```

1. Once the instance has left the cluster, terminate it:

   ```
   aws ec2 terminate-instances --instance-ids <OLD_INSTANCE_ID>
   ```

1. After a minute or two, the ASG should automatically launch a new Instance, with the new AMI, to replace the old one.

1. Wait for the new Instance to boot and join the cluster.

1. Repeat these steps for each of the other old Instances in the ASG.

We will add a script in the future to automate this process (PRs are welcome!).

## What happens if a node crashes?

There are two ways a Nomad node may go down:

1. The Nomad process may crash. In that case, `systemd` should restart it automatically.
1. The EC2 Instance running Nomad dies. In that case, the Auto Scaling Group should launch a replacement automatically.
   Note that in this case, since the Nomad agent did not exit gracefully, and the replacement will have a different ID,
   you may have to manually clean out the old nodes using the [server force-leave
   command](https://www.nomadproject.io/docs/commands/server-force-leave.html). We may add a script to do this
   automatically in the future. For more info, see the [Nomad Outage
   documentation](https://www.nomadproject.io/guides/outage.html).

## How do you connect load balancers to the Auto Scaling Group (ASG)?

You can use the [`aws_autoscaling_attachment`](https://www.terraform.io/docs/providers/aws/r/autoscaling_attachment.html) resource.

For example, if you are using the new application or network load balancers:

```hcl
resource "aws_lb_target_group" "test" {
  // ...
}

# Create a new Nomad Cluster
module "nomad" {
  source ="..."
  // ...
}

# Create a new load balancer attachment
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = module.nomad.asg_name
  alb_target_group_arn   = aws_alb_target_group.test.arn
}
```

If you are using a "classic" load balancer:

```hcl
# Create a new load balancer
resource "aws_elb" "bar" {
  // ...
}

# Create a new Nomad Cluster
module "nomad" {
  source ="..."
  // ...
}

# Create a new load balancer attachment
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = module.nomad.asg_name
  elb                    = aws_elb.bar.id
}
```

## Security

Here are some of the main security considerations to keep in mind when using this module:

1. [Encryption in transit](#encryption-in-transit)
1. [Encryption at rest](#encryption-at-rest)
1. [Dedicated instances](#dedicated-instances)
1. [Security groups](#security-groups)
1. [SSH access](#ssh-access)

### Encryption in transit

Nomad can encrypt all of its network traffic. For instructions on enabling network encryption, have a look at the
[How do you handle encryption documentation](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/run-nomad#how-do-you-handle-encryption).

### Encryption at rest

The EC2 Instances in the cluster store all their data on the root EBS Volume. To enable encryption for the data at
rest, you must enable encryption in your Nomad AMI. If you're creating the AMI using Packer (e.g. as shown in
the [nomad-consul-ami example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/nomad-consul-ami)), you need to set the [encrypt_boot
parameter](https://www.packer.io/docs/builders/amazon-ebs.html#encrypt_boot) to `true`.

### Dedicated instances

If you wish to use dedicated instances, you can set the `tenancy` parameter to `"dedicated"` in this module.

### Security groups

This module attaches a security group to each EC2 Instance that allows inbound requests as follows:

- **Nomad**: For all the [ports used by Nomad](https://www.nomadproject.io/docs/agent/configuration/index.html#ports),
  you can use the `allowed_inbound_cidr_blocks` parameter to control the list of
  [CIDR blocks](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) that will be allowed access.

- **SSH**: For the SSH port (default: 22), you can use the `allowed_ssh_cidr_blocks` parameter to control the list of
  [CIDR blocks](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) that will be allowed access.

Note that all the ports mentioned above are configurable via the `xxx_port` variables (e.g. `http_port`). See
[variables.tf](variables.tf) for the full list.

### SSH access

You can associate an [EC2 Key Pair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) with each
of the EC2 Instances in this cluster by specifying the Key Pair's name in the `ssh_key_name` variable. If you don't
want to associate a Key Pair with these servers, set `ssh_key_name` to an empty string.

## What's NOT included in this module?

This module does NOT handle the following items, which you may want to provide on your own:

- [Consul](#consul)
- [Monitoring, alerting, log aggregation](#monitoring-alerting-log-aggregation)
- [VPCs, subnets, route tables](#vpcs-subnets-route-tables)
- [DNS entries](#dns-entries)

### Consul

This module assumes you already have Consul deployed in a separate cluster. If you want to run Nomad and Consul on the
same cluster, instead of using this module, see the [Deploy Nomad and Consul in the same cluster
documentation](https://github.com/hashicorp/terraform-aws-nomad/tree/master/README.md#deploy-nomad-and-consul-in-the-same-cluster).

### Monitoring, alerting, log aggregation

This module does not include anything for monitoring, alerting, or log aggregation. All ASGs and EC2 Instances come
with limited [CloudWatch](https://aws.amazon.com/cloudwatch/) metrics built-in, but beyond that, you will have to
provide your own solutions.

### VPCs, subnets, route tables

This module assumes you've already created your network topology (VPC, subnets, route tables, etc). You will need to
pass in the the relevant info about your network topology (e.g. `vpc_id`, `subnet_ids`) as input variables to this
module.

### DNS entries

This module does not create any DNS entries for Nomad (e.g. in Route 53).
