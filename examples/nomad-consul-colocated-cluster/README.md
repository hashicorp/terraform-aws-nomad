# Nomad and Consul Co-located Cluster Example

This folder shows an example of Terraform code to deploy a [Nomad](https://www.nomadproject.io/) cluster co-located 
with a [Consul](https://www.consul.io/) cluster in [AWS](https://aws.amazon.com/) (if you want to run Nomad and Consul 
on separate clusters, see the [nomad-consul-separate-cluster example](/examples/nomad-consul-separate-cluster) 
instead). The cluster consists of two Auto Scaling Groups (ASGs): one with a small number of Nomad and Consul server 
nodes, which are responsible for being part of the [concensus 
protocol](https://www.nomadproject.io/docs/internals/consensus.html), and one with a larger number of Nomad and Consul 
client nodes, which are used to run jobs:

![Nomad architecture](/_docs/architecture-nomad-consul-colocated.png)

You will need to create an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
that has Nomad and Consul installed, which you can do using the [nomad-consul-ami example](/examples/nomad-consul-ami)).  

For more info on how the Nomad cluster works, check out the [nomad-cluster](/modules/nomad-cluster) documentation.




## Quick start

To deploy a Nomad Cluster:

1. `git clone` this repo to your computer.
1. Build a Nomad and Consul AMI. See the [nomad-consul-ami example](/examples/nomad-consul-ami) documentation for 
   instructions. Make sure to note down the ID of the AMI.
1. Install [Terraform](https://www.terraform.io/).
1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default, including putting your AMI ID into the `ami_id` variable.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

After the `apply` command finishes, the EC2 Instances will start, discover each other, and form a cluster.
 
To see how to connect to the cluster and start running jobs, head over to the [How do you connect to the Nomad 
cluster?](/modules/nomad-cluster#how-do-you-connect-to-the-nomad-cluster) docs.
