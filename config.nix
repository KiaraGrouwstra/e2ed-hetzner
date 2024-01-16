{ config, lib, inputs, pkgs, options, specialArgs, ... }:

let
  var = options.variable;

  my-lib = import ./lib/default.nix { inherit lib; };

  # (k: k + k) -> { a = 1; } -> { aa = 1; }
  mapKeys = f: lib.mapAttrs' (k: v: lib.nameValuePair (f k) v);

  # (v: 2 * v) -> { a = 1; } -> { a = 2; }
  mapVals = f: lib.mapAttrs (_: f);

  # { b = 0; } -> { c = { a = 1; } } -> { c = { b = 0; a = 1; } }
  default = defaults: mapVals (v: defaults // v);

  # "b" -> { a = 1; } -> { b_a = 1; }
  inNamespace = prefix: mapKeys (k: "${prefix}_${k}");

  # { a = 1; } -> { name = "a"; a = 1; }
  setNames = lib.mapAttrs (k: v: { name = k; } // v);

  # "foo" -> "\${data.sops_file.secrets.data[\"foo\"]}"
  secret = str: lib.tfRef "data.sops_file.secrets.data[\"${str}\"]";

  hetzner = let

    # https://docs.hetzner.com/cloud/api/getting-started/generating-api-token
    token = secret "hcloud_api_token";

  in { inherit token; };

in rec {

  terraform.required_providers = {

    sops.source = "carlpett/sops";

  };

  provider = {

    sops = {};

    # Configure the Hetzner Cloud Provider
    hcloud.token = lib.mkForce hetzner.token;

  };

  resource = (inNamespace "hcloud" {


    ssh_key = setNames (lib.mapAttrs (_: v: { public_key = v; }) my-lib.ssh-keys);

  });

  # Set the variable value in *.tfvars file
  # or using -var="hcloud_api_token=..." CLI option
  variable = {

  };

  # https://github.com/terranix/terranix-hcloud/blob/main/options.md
  hcloud = {
    enable = true;
    # can also be specified with the TF_VAR_hcloud_api_token environment variable
    provider = { inherit (hetzner) token; };
    export.nix = "hetzner.nix";

  };

  data = {

    sops_file.secrets = {
      source_file = "secrets.enc.yaml";
    };

    hcloud_ssh_keys."all_keys" = {};

  };

  output = {

    "keys_output" = {
      value = lib.tfRef "data.hcloud_ssh_keys.all_keys";
    };

  };

}
