{ config, lib, pkgs, options, specialArgs, ... }:

let
  var = options.variable;
in rec {

  provider = {

    # Configure the Hetzner Cloud Provider
    hcloud.token = lib.tfRef "var.hcloud_token";

  };

  resource = {

  };

  # Set the variable value in *.tfvars file
  # or using -var="hetzner_token=..." CLI option
  variable = {

    hcloud_token = {
      type = "string";
      description = "Hetzner Cloud API Token";
      sensitive = true;
    };

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
