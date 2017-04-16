# Nomad Examples Helper

This folder contains two helpers for working with the 
[nomad-consul-colocated-cluster](/examples/nomad-consul-colocated-cluster) and
[nomad-consul-separate-cluster](/examples/nomad-consul-separate-cluster) examples:

1. `nomad-examples-helper.sh`: A script you can run after deploying the examples to a) wait for the Nomad server 
   cluster to come up, b) print out the IP addresses of the Nomad servers, c) print out some example commands you can 
   run against your Nomad servers.

1. `example.nomad`: An example Nomad job you can run in your Nomad cluster. This job simply echoes "Hello, World!"

