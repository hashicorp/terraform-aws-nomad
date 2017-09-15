# Nomad Run Script

This folder contains a script for configuring and running Nomad on an [AWS](https://aws.amazon.com/) server. This 
script has been tested on the following operating systems:

* Ubuntu 16.04
* Amazon Linux

There is a good chance it will work on other flavors of Debian, CentOS, and RHEL as well.




## Quick start

This script assumes you installed it, plus all of its dependencies (including Nomad itself), using the [install-nomad 
module](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/install-nomad). The default install path is `/opt/nomad/bin`, so to start Nomad in server mode, you 
run:

```
/opt/nomad/bin/run-nomad --server --num-servers 3
```

To start Nomad in client mode, you run:

```
/opt/nomad/bin/run-nomad --client
```

This will:

1. Generate a Nomad configuration file called `default.hcl` in the Nomad config dir (default: `/opt/nomad/config`).
   See [Nomad configuration](#nomad-configuration) for details on what this configuration file will contain and how
   to override it with your own configuration.
   
1. Generate a [Supervisor](http://supervisord.org/) configuration file called `run-nomad.conf` in the Supervisor
   config dir (default: `/etc/supervisor/conf.d`) with a command that will run Nomad:  
   `nomad agent -config=/opt/nomad/config -data-dir=/opt/nomad/data`.

1. Tell Supervisor to load the new configuration file, thereby starting Nomad.

We recommend using the `run-nomad` command as part of [User 
Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts), so that it executes
when the EC2 Instance is first booting. If you are running Consul on the same server, make sure to use this script 
*after* Consul has booted. After running `run-nomad` on that initial boot, the `supervisord` configuration 
will automatically restart Nomad if it crashes or the EC2 instance reboots.

See the [nomad-consul-colocated-cluster example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/MAIN.md) and 
[nomad-consul-separate-cluster example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/nomad-consul-separate-cluster example) for fully-working sample code.




## Command line Arguments

The `run-nomad` script accepts the following arguments:

* `server` (optional): If set, run in server mode. At least one of `--server` or `--client` must be set.
* `client` (optional): If set, run in client mode. At least one of `--server` or `--client` must be set.
* `num-servers` (optional): The number of servers to expect in the Nomad cluster. Required if `--server` is set. 
* `config-dir` (optional): The path to the Nomad config folder. Default is to take the absolute path of `../config`, 
  relative to the `run-nomad` script itself.
* `data-dir` (optional): The path to the Nomad config folder. Default is to take the absolute path of `../data`, 
  relative to the `run-nomad` script itself.
* `user` (optional): The user to run Nomad as. Default is to use the owner of `config-dir`.
* `use-sudo` (optional): Nomad clients make use of operating system primitives for resource isolation that require 
  elevated (root) permissions (see [the 
  docs](https://www.nomadproject.io/intro/getting-started/running.html) for more info). If you set this flag, Nomad
  will run with root-level privileges. If you don't, it'll still work, but certain task drivers will not be available. 
  By default, this flag is enabled if `--client` is set and disabled if `--server` is set (server nodes don't need 
  root-level privileges).
* `skip-nomad-config`: If this flag is set, don't generate a Nomad configuration file. This is useful if you have
  a custom configuration file and don't want to use any of of the default settings from `run-nomad`. 

Example:

```
/opt/nomad/bin/run-nomad --server --num-servers 3
```




## Nomad configuration

`run-nomad` generates a configuration file for Nomad called `default.hcl` that tries to figure out reasonable 
defaults for a Nomad cluster in AWS. Check out the [Nomad Configuration Files 
documentation](https://www.nomadproject.io/docs/agent/configuration/index.html) for what configuration settings are
available.
  
  
### Default configuration

`run-nomad` sets the following configuration values by default:

* [advertise](https://www.nomadproject.io/docs/agent/configuration/index.html#advertise): All the advertise addresses
  are set to the Instance's private IP address, as fetched from  
  [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).
  
* [bind_addr](https://www.nomadproject.io/docs/agent/configuration/index.html#bind_addr): Set to 0.0.0.0.
  
* [client](https://www.nomadproject.io/docs/agent/configuration/client.html): This config is only set of `--client` is
  set.
  
    * [enabled](https://www.nomadproject.io/docs/agent/configuration/client.html#enabled): `true`.
  
* [consul](https://www.nomadproject.io/docs/agent/configuration/consul.html): By default, set the Consul address to
  `127.0.0.1:8500`, with the assumption that the Consul agent is running on the same server. 

* [datacenter](https://www.nomadproject.io/docs/agent/configuration/index.html#datacenter): Set to the current 
  availability zone, as fetched from 
  [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).

* [name](https://www.nomadproject.io/docs/agent/configuration/index.html#name): Set to the instance id, as fetched from 
  [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).     

* [region](https://www.nomadproject.io/docs/agent/configuration/index.html#region): Set to the current AWS region, as 
  fetched from [Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).
                                                                                      
* [server](https://www.nomadproject.io/docs/agent/configuration/server.html): This config is only set if `--server` is
  set.

    * [enabled](https://www.nomadproject.io/docs/agent/configuration/server.html#enabled): `true`.
    * [bootstrap_expect](https://www.nomadproject.io/docs/agent/configuration/server.html#bootstrap_expect): Set to the
      `--num-servers` parameter.


### Overriding the configuration

To override the default configuration, simply put your own configuration file in the Nomad config folder (default: 
`/opt/nomad/config`), but with a name that comes later in the alphabet than `default.hcl` (e.g. 
`my-custom-config.hcl`). Nomad will load all the `.hcl` configuration files in the config dir and 
[merge them together in alphabetical 
order](https://www.nomadproject.io/docs/agent/configuration/index.html#load-order-and-merging), so that settings in 
files that come later in the alphabet will override the earlier ones. 

For example, to override the default `name` setting, you could create a file called `tags.hcl` with the
contents:

```hcl
name = "my-custom-name"
```

If you want to override *all* the default settings, you can tell `run-nomad` not to generate a default config file
at all using the `--skip-nomad-config` flag:

```
/opt/nomad/bin/run-nomad --server --num-servers 3 --skip-nomad-config
```




## How do you handle encryption?

Nomad can encrypt all of its network traffic (see the [encryption docs for 
details](https://www.nomadproject.io/docs/agent/encryption.html)), but by default, encryption is not enabled in this 
Module. To enable encryption, you need to do the following:

1. [Gossip encryption: provide an encryption key](#gossip-encryption-provide-an-encryption-key)
1. [RPC encryption: provide TLS certificates](#rpc-encryption-provide-tls-certificates)
1. [Consul encryption](#consul-encryption)


### Gossip encryption: provide an encryption key

To enable Gossip encryption, you need to provide a 16-byte, Base64-encoded encryption key, which you can generate using
the [nomad keygen command](https://www.nomadproject.io/docs/commands/keygen.html). You can put the key in a Nomad 
configuration file (e.g. `encryption.hcl`) in the Nomad config dir (default location: `/opt/nomad/config`):

```hcl
server {
  encrypt = "cg8StVXbQJ0gPvMd9o7yrg=="
}
```


### RPC encryption: provide TLS certificates

To enable RPC encryption, you need to provide the paths to the CA and signing keys ([here is a tutorial on generating 
these keys](http://russellsimpkins.blogspot.com/2015/10/consul-adding-tls-using-self-signed.html)). You can specify 
these paths in a Nomad configuration file (e.g. `encryption.hcl`) in the Nomad config dir (default location: 
`/opt/nomad/config`):

```hcl
tls {
  # Enable encryption on incoming HTTP and RPC endpoints
  http = true
  rpc  = true
  
  # Verify server hostname for outgoing TLS connections
  verify_server_hostname = true

  # Specify the CA and signing key paths
  ca_file   = "/opt/nomad/tls/certs/ca-bundle.crt",
  cert_file = "/opt/nomad/tls/certs/my.crt",
  key_file  = "/opt/nomad/tls/private/my.key"
}
```


### Consul encryption

Note that Nomad relies on Consul, and enabling encryption for Consul requires a separate process. Check out the
[official Consul encryption docs](https://www.consul.io/docs/agent/encryption.html) and the Consul AWS Module
[How do you handle encryption
docs](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/run-consul#how-do-you-handle-encryption)
for more info.



