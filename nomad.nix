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

  # keys: https://tristanpemble.github.io/nix-nomad/
  # vals: https://developer.hashicorp.com/nomad/api-docs/json-jobs
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

  # https://registry.terraform.io/providers/hashicorp/nomad/latest/docs/
  resource = {

    nomad_job = lib.mapAttrs (k: v: {
      json = true;
      jobspec = lib.strings.toJSON v;
    }) config.nomad.build.apiJob;

  };

}
