{
  lib,
  pkgs,
  inputs,
  tf,
  # outputs,
  # resources,
  ...
}: let
  inherit
    (import ./lib/default.nix {inherit lib pkgs;})
      dirContents
      inNamespace
      setNames
    ;
in {
  meta = {
    nixpkgs = pkgs;
  };
  defaults = _: {
    deployment.targetEnv = "hcloud";
    deployment.hcloud = {
      server_type = "cax11"; # arm
      location = "nbg1";
    };
    # cannot update yet: https://github.com/elitak/nixos-infect/issues/207
    system.stateVersion = "23.11";
  };
  # servers
  manual = {pkgs, ...}: import ./servers/manual/configuration.nix {inherit lib pkgs inputs;};

  # https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs

  terraform = {
    cloud = {
      hostname = "app.terraform.io";
      organization = "bij1";
      workspaces = {
        name = "hcloud";
      };
    };
  };

  # Set the variable value in *.tfvars file
  # or using -var="hcloud_api_token=..." CLI option
  variable = {
    tf_cloud_token = {
      type = "string";
      description = "[Terraform Cloud](https://app.terraform.io/) token";
      sensitive = true;
    };
    hcloud_api_token = {
      type = "string";
      description = "[Hetzner Cloud API Token](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token)";
      sensitive = true;
    };
  };

  provider = {
    hcloud = {
      token = tf.ref "var.hcloud_api_token";
    };
  };

  resource =
    inNamespace "hcloud"
    {
      ssh_key =
        setNames
        (
          lib.mapAttrs
          (_: v: {public_key = v;})
          (dirContents ".pub" ./ssh-keys)
        );
    };
}
