# Nomad and Consul Separate Clusters Example

This folder shows an example of Terraform code to deploy a [Nomad](https://www.nomadproject.io/) cluster that connects 
to a separate [Consul](https://www.consul.io/) cluster in [AWS](https://aws.amazon.com/) (if you want to run Nomad and 
Consul in the same clusters, see the [nomad-consul-colocated-cluster example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/MAIN.md) 
instead). The Nomad cluster consists of two Auto Scaling Groups (ASGs): one with a small number of Nomad server 
nodes, which are responsible for being part of the [consensus 
quorum](https://www.nomadproject.io/docs/internals/consensus.html), and one with a larger number of Nomad client nodes, 
which are used to run jobs:

![Nomad architecture](https://raw.githubusercontent.com/hashicorp/terraform-aws-nomad/master/_docs/architecture-nomad-consul-separate.png)

You will need to create an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
that has Nomad and Consul installed, which you can do using the [nomad-consul-ami example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/nomad-consul-ami)).  

For more info on how the Nomad cluster works, check out the [nomad-cluster](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/nomad-cluster) documentation.




## Quick start

To deploy a Nomad Cluster:

1. `git clone` this repo to your computer.
1. Optional: build a Nomad and Consul AMI. See the [nomad-consul-ami
   example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/nomad-consul-ami) documentation for
   instructions. Make sure to note down the ID of the AMI.
1. Install [Terraform](https://www.terraform.io/).
1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default. If you built a custom AMI, put the AMI ID into the `ami_id` variable. Otherwise, one of our
   public example AMIs will be used by default. These AMIs are great for learning/experimenting, but are NOT
   recommended for production use.
1. Run `terraform init`.
1. Run `terraform apply`.
1. Run the [nomad-examples-helper.sh script](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/nomad-examples-helper/nomad-examples-helper.sh) to print out
   the IP addresses of the Nomad servers and some example commands you can run to interact with the cluster:
   `../nomad-examples-helper/nomad-examples-helper.sh`.
