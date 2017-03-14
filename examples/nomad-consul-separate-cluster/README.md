# Nomad Cluster and Consul Cluster Example

This folder shows an example of Terraform code that uses the [nomad-cluster module](/modules/nomad-cluster) from this
Blueprint to deploy a [Nomad](https://www.nomadproject.io/) cluster across an Auto Scaling Group in 
[AWS](https://aws.amazon.com/) and the [consul-cluster 
module](https://github.com/gruntwork-io/consul-aws-blueprint/tree/master/modules/consul-cluster) from the Consul AWS
Blueprint to deploy a separate [Consul](https://www.consul.io/) cluster across an Auto Scaling Group in 
[AWS](https://aws.amazon.com/). If you want to run Nomad and Consul on the same cluster, see the 
[nomad-consul-colocated-cluster example](/examples/nomad-consul-colocated-cluster) instead. 

![Nomad architecture](/_docs/architecture.png)

You will need to create one [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
that has Nomad installed, which you can do using the [nomad-only-ami example](/examples/nomad-only-ami)), and another
AMI that has Consul installed, which you can do using the [consul-ami 
example](https://github.com/gruntwork-io/consul-aws-blueprint/tree/master/examples/consul-ami).  

For more info on how the Nomad cluster works, check out the [nomad-cluster](/modules/nomad-cluster) documentation.



## Quick start

To deploy a Nomad Cluster:

1. `git clone` this repo to your computer.
1. Build a Nomad AMI. See the [nomad-only-ami example](/examples/nomad-only-ami) documentation for instructions. Make 
   sure to note down the ID of the AMI.
1. Build a Consul AMI. See the [consul-ami 
   example](https://github.com/gruntwork-io/consul-aws-blueprint/tree/master/examples/consul-ami) documentation for 
   instructions. Make sure to note down the ID of the AMI.
1. Install [Terraform](https://www.terraform.io/).
1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default, including putting your AMI IDs into the `nomad_ami_id` and `consul_ami_id` variables.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

After the `apply` command finishes, a Nomad and Consul cluster will boot up and discover each other.
 
To see how to connect to the cluster and start reading/writing data, head over to the [How do you connect to the Nomad 
cluster?](/modules/nomad-cluster#how-do-you-connect-to-the-nomad-cluster) docs.
