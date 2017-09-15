# Nomad Examples Helper

This folder contains a helper script called `nomad-examples-helper.sh` for working with the 
[nomad-consul-colocated-cluster](https://github.com/hashicorp/terraform-aws-nomad/tree/master/MAIN.md) and
[nomad-consul-separate-cluster](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/nomad-consul-separate-cluster) examples. After running `terraform apply` on
the examples, if you run `nomad-examples-helper.sh`, it will automatically:

1. Wait for the Nomad server cluster to come up.
1. Print out the IP addresses of the Nomad servers.
1. Print out some example commands you can run against your Nomad servers.

This folder also contains an example Nomad job called `example.nomad` that you can run in your Nomad cluster. This job 
simply echoes "Hello, World!"

