{ config, options, lib, ... }:

let

  var = options.variable;

in
{

  terraform.required_providers.nomad.source = "registry.terraform.io/hashicorp/nomad";

  variable = {

    nomad_host = {
      type = "string";
      description = "host of the nomad instance, defaults to local";
      default = "http://127.0.0.1";
    };

  };

  provider.nomad.address = "${lib.tfRef "var.nomad_host"}:4646";

  # https://github.com/tristanpemble/nix-nomad
  # https://tristanpemble.github.io/nix-nomad/
  # https://github.com/hetznercloud/csi-driver/blob/main/docs/nomad/README.md#getting-started
  job = {
    bar = {
      type = "batch";
      group.bar.task.bar = {
        driver = "raw_exec";
        config = {
          command = "echo";
          args    = ["hello"];
        };
      };
    };
  };

  resource = {

    nomad_job.foo = {
      jobspec = lib.strings.toJSON config.nomad.build.apiJob.bar;
      json = true;
    };

  };

}
