# Nomad and Consul AMI

This folder shows an example of how to use the [install-nomad module](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/install-nomad) from this Module and
the [install-consul module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-consul)
from the Consul AWS Module with [Packer](https://www.packer.io/) to create [Amazon Machine Images
(AMIs)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) that have Nomad and Consul installed on top of:

1. Ubuntu 16.04
1. Ubuntu 18.04
1. Amazon Linux 2

These AMIs will have [Consul](https://www.consul.io/) and [Nomad](https://www.nomadproject.io/) installed and
configured to automatically join a cluster during boot-up.

To see how to deploy this AMI, check out the [nomad-consul-colocated-cluster
example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/root-example). For more info on Nomad installation and configuration, check out
the [install-nomad](https://github.com/hashicorp/terraform-aws-nomad/tree/master/modules/install-nomad) documentation.



## Quick start

To build the Nomad and Consul AMI:

1. `git clone` this repo to your computer.
1. Install [Packer](https://www.packer.io/).
1. Configure your AWS credentials using one of the [options supported by the AWS
   SDK](http://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html). Usually, the easiest option is to
   set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.
1. Update the `variables` section of the `nomad-consul.json` Packer template to configure the AWS region and Nomad version
   you wish to use.
1. Run `packer build nomad-consul.json`.

When the build finishes, it will output the IDs of the new AMIs. To see how to deploy one of these AMIs, check out the
[nomad-consul-colocated-cluster example](https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/root-example).




## Creating your own Packer template for production usage

When creating your own Packer template for production usage, you can copy the example in this folder more or less
exactly, except for one change: we recommend replacing the `file` provisioner with a call to `git clone` in the `shell`
provisioner. Instead of:

```json
{
  "provisioners": [{
    "type": "file",
    "source": "{{template_dir}}/../../../terraform-aws-nomad",
    "destination": "/tmp"
  },{
    "type": "shell",
    "inline": [
      "/tmp/terraform-aws-nomad/modules/install-nomad/install-nomad --version {{user `nomad_version`}}"
    ],
    "pause_before": "30s"
  }]
}
```

Your code should look more like this:

```json
{
  "provisioners": [{
    "type": "shell",
    "inline": [
      "git clone --branch <module_VERSION> https://github.com/hashicorp/terraform-aws-nomad.git /tmp/terraform-aws-nomad",
      "/tmp/terraform-aws-nomad/modules/install-nomad/install-nomad --version {{user `nomad_version`}}"
    ],
    "pause_before": "30s"
  }]
}
```

You should replace `<module_VERSION>` in the code above with the version of this module that you want to use (see
the [Releases Page](../../releases) for all available versions). That's because for production usage, you should always
use a fixed, known version of this Module, downloaded from the official Git repo. On the other hand, when you're
just experimenting with the Module, it's OK to use a local checkout of the Module, uploaded from your own
computer.
