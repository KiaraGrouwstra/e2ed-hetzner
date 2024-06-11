{ config, options, lib, ... }:

let

  var = options.variable;

  my-lib = import ./lib/default.nix { inherit lib; };

in
{

  terraform.required_providers.nomad.source = "registry.terraform.io/hashicorp/nomad";

  # https://developer.hashicorp.com/nomad/docs/job-specification/hcl2/variables
  # https://developer.hashicorp.com/nomad/docs/runtime/interpolation
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
          args = [ "hello" ];
        };
      };
    };
  };

  # https://registry.terraform.io/providers/hashicorp/nomad/latest/docs/
  resource = {

    nomad_job =
      # nix jobs
      lib.mapAttrs
        (_: v: {
          json = true;
          jobspec = lib.strings.toJSON v;
        })
        config.nomad.build.apiJob
      # hcl jobs
      // lib.mapAttrs
        (_: v: {
          jobspec = v;
        })
        (my-lib.dirContents ".nomad.hcl" ./jobs);

  };

}
