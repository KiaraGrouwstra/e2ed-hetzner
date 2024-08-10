{
  # smuggling in `inputs` thru `pkgs`: https://github.com/hercules-ci/arion/issues/247
  pkgs,
  ...
}: let
  inherit (pkgs) lib inputs;
  inherit
    (import ./lib/default.nix {inherit lib pkgs;})
      mapVals
      default
      defaults
      moveSecrets
    ;
  # fixes: Using host resolv.conf is not supported with systemd-resolved
  arion-common =
  # (defaults (import ./servers/common/imports.nix {inherit inputs;}))
  # //
  {
    nixos.useSystemd = true;
    service = {
      useHostStore = true;
      secrets = moveSecrets "/run/container-secrets" {
        sops_key = {};
      };
    };
  };
  container-common = {
    networking.useDHCP = false;
    networking.firewall.enable = false;
    systemd.network.enable = lib.mkForce false;
  };
in {
  project.name = "nixos-container";
  secrets = {
    "sops_key".file = ../tf-config/keys.txt;
  };
  # ports: host:container, host must be >=1024, same for container to test by vm
  # arion exec NAME bash
  services = mapVals (default arion-common) {

    combined = {
      nixos = {
        configuration = {
          imports = [
            # inputs.disko.nixosModules.disko
            inputs.sops-nix.nixosModules.default
            ./servers/common
            # ./servers/manual
            ./servers/nextcloud
          ];
        }
        // container-common
        ;
      };
      service = {
        # solves fuse error when running containers,
        # but also enables firewall and causes some warnings/errors
        privileged = true;
        # needed by (unless privileged=true): sops-nix (unless sops.useTmpfs), lldap opensearch woodpecker-server
        # capabilities.CAP_SYS_ADMIN = true;
        ports = lib.lists.map (ports: "127.0.0.1:${ports}") [
          "8888:8888" # manual
          "9980:9980" # nextcloud collabora
          "1465:465" # nextcloud smtp
        ];
      };
    };

  };
}
