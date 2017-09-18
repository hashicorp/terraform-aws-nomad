# Nomad AWS Module

This repo contains a Module for how to deploy a [Nomad](https://www.nomadproject.io/) cluster on 
[AWS](https://aws.amazon.com/) using [Terraform](https://www.terraform.io/). Nomad is a distributed, highly-available 
data-center aware scheduler. A Nomad cluster typically includes a small number of server nodes, which are responsible 
for being part of the [concensus protocol](https://www.nomadproject.io/docs/internals/consensus.html), and a larger 
number of client nodes, which are used for running jobs:

![Nomad architecture](https://raw.githubusercontent.com/hashicorp/terraform-aws-nomad/master/_docs/architecture.png)

This Module includes:

* [install-nomad](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/install-nomad): This module can be used to install Nomad. It can be used in a 
  [Packer](https://www.packer.io/) template to create a Nomad 
  [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html).

* [run-nomad](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/run-nomad): This module can be used to configure and run Nomad. It can be used in a 
  [User Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts) 
  script to fire up Nomad while the server is booting.

* [nomad-cluster](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/nomad-cluster): Terraform code to deploy a cluster of Nomad servers using an [Auto Scaling 
  Group](https://aws.amazon.com/autoscaling/).
    
  



## What's a Module?

A Module is a canonical, reusable, best-practices definition for how to run a single piece of infrastructure, such 
as a database or server cluster. Each Module is created primarily using [Terraform](https://www.terraform.io/), 
includes automated tests, examples, and documentation, and is maintained both by the open source community and 
companies that provide commercial support. 

Instead of having to figure out the details of how to run a piece of infrastructure from scratch, you can reuse 
existing code that has been proven in production. And instead of maintaining all that infrastructure code yourself, 
you can leverage the work of the Module community and maintainers, and pick up infrastructure improvements through
a version number bump.
 
 
 
## Who maintains this Module?

This Module is maintained by [Gruntwork](http://www.gruntwork.io/). If you're looking for help or commercial 
support, send an email to [modules@gruntwork.io](mailto:modules@gruntwork.io?Subject=Nomad%20Module). 
Gruntwork can help with:

* Setup, customization, and support for this Module.
* Modules for other types of infrastructure, such as VPCs, Docker clusters, databases, and continuous integration.
* Modules that meet compliance requirements, such as HIPAA.
* Consulting & Training on AWS, Terraform, and DevOps.



## How do you use this Module?

Each Module has the following folder structure:

* [root](https://github.com/hashicorp/terraform-aws-nomad/tree/master): This folder shows an example of Terraform code to deploy a [Nomad](https://www.nomadproject.io/) cluster co-located 
            with a [Consul](https://www.consul.io/) cluster in [AWS](https://aws.amazon.com/)
* [modules](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules): This folder contains the reusable code for this Module, broken down into one or more modules.
* [examples](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples): This folder contains examples of how to use the modules.
* [test](https://github.com/hashicorp/terraform-aws-nomad/tree/master/test): Automated tests for the modules and examples.

Click on each of the modules above for more details.

<!-- TODO: update the consul-aws-module URL to the final URL -->

To run a Nomad cluster, you need to deploy a small number of server nodes (typically 3), which are responsible 
for being part of the [concensus protocol](https://www.nomadproject.io/docs/internals/consensus.html), and a larger 
number of client nodes, which are used for running jobs. You must also have a [Consul](https://www.consul.io/) cluster 
deployed (see the [Consul AWS Module](https://github.com/hashicorp/terraform-aws-consul)) in one of the following 
configurations:

1. [Deploy Nomad and Consul in the same cluster](#deploy-nomad-and-consul-in-the-same-cluster)
1. [Deploy Nomad and Consul in separate clusters](#deploy-nomad-and-consul-in-separate-clusters)


### Deploy Nomad and Consul in the same cluster

1. Use the [install-consul 
   module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-consul) from the Consul AWS
   Module and the [install-nomad module](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/install-nomad) from this Module in a Packer template to create 
   an AMI with Consul and Nomad. 
   
   If you are just experimenting with this Module, you may find it more convenient to use one of our official public AMIs:
   - [Latest Ubuntu 16 AMIs](https://github.com/hashicorp/terraform-aws-nomad/tree/master/_docs/ubuntu16-ami-list.md).
   - [Latest Amazon Linux AMIs](https://github.com/hashicorp/terraform-aws-nomad/tree/master/_docs/amazon-linux-ami-list.md).
   
   **WARNING! Do NOT use these AMIs in your production setup. In production, you should build your own AMIs in your own 
   AWS account.**
   
1. Deploy a small number of server nodes (typically, 3) using the [consul-cluster 
   module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/consul-cluster). Execute the 
   [run-consul script](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/run-consul) and the
   [run-nomad script](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/run-nomad) on each node during boot, setting the `--server` flag in both 
   scripts.
1. Deploy as many client nodes as you need using the [nomad-cluster module](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/nomad-cluster). Execute the 
   [run-consul script](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/run-consul) and the
   [run-nomad script](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/run-nomad) on each node during boot, setting the `--client` flag in both 
   scripts.

Check out the [nomad-consul-colocated-cluster example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/MAIN.md) for working
sample code.


### Deploy Nomad and Consul in separate clusters

1. Deploy a standalone Consul cluster by following the instructions in the [Consul AWS 
   Module](https://github.com/hashicorp/terraform-aws-consul).
1. Use the scripts from the [install-nomad module](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/install-nomad) in a Packer template to create a Nomad AMI.
1. Deploy a small number of server nodes (typically, 3) using the [nomad-cluster module](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/nomad). Execute the    
   [run-nomad script](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/run-nomad) on each node during boot, setting the `--server` flag. You will 
   need to configure each node with the connection details for your standalone Consul cluster.   
1. Deploy as many client nodes as you need using the [nomad-cluster module](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/nomad). Execute the 
   [run-nomad script](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/run-nomad) on each node during boot, setting the `--client` flag.

Check out the [nomad-consul-separate-cluster example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/nomad-consul-separate-cluster) for working
sample code.

 



## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/hashicorp/terraform-aws-nomad/tree/master/CONTRIBUTING.md) for instructions.



## How is this Module versioned?

This Module follows the principles of [Semantic Versioning](http://semver.org/). You can find each new release, 
along with the changelog, in the [Releases Page](../../releases). 

During initial development, the major version will be 0 (e.g., `0.x.y`), which indicates the code does not yet have a 
stable API. Once we hit `1.0.0`, we will make every effort to maintain a backwards compatible API and use the MAJOR, 
MINOR, and PATCH versions on each release to indicate any incompatibilities. 



## License

This code is released under the Apache 2.0 License. Please see [LICENSE](https://github.com/hashicorp/terraform-aws-nomad/tree/master/LICENSE) and [NOTICE](https://github.com/hashicorp/terraform-aws-nomad/tree/master/NOTICE) for more details.

Copyright &copy; 2017 Gruntwork, Inc.