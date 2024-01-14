{ config, lib, pkgs, options, specialArgs, ... }:

let
  var = options.variable;
in rec {

  provider = {

    # Configure the Hetzner Cloud Provider
    hcloud.token = lib.mkForce (lib.tfRef "var.hcloud_api_token");

  };

  resource = {

  };

  # Set the variable value in *.tfvars file
  # or using -var="hcloud_api_token=..." CLI option
  variable = {

    hcloud_api_token = {
      type = "string";
      description = "Hetzner Cloud API Token";
      sensitive = true;
    };

  };

  # https://github.com/terranix/terranix-hcloud/blob/main/options.md
  hcloud = {
    enable = true;
    # can also be specified with the TF_VAR_hcloud_api_token environment variable
    provider.token = builtins.getEnv "TF_VAR_hcloud_api_token";
    export.nix = "hetzner.nix";

  };

  data = {

    hcloud_ssh_keys."all_keys" = {};

  };

  output = {

    "keys_output" = {
      value = lib.tfRef "data.hcloud_ssh_keys.all_keys";
    };

  };

}
