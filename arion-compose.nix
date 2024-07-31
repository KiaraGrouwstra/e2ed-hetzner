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
    ;
  # fixes: Using host resolv.conf is not supported with systemd-resolved
  arion-common =
  # (defaults (import ./servers/common/imports.nix {inherit inputs;}))
  # //
  {
    nixos.useSystemd = true;
    service.useHostStore = true;
  };
  container-common = {
    networking.useDHCP = false;
    networking.firewall.enable = false;
    systemd.network.enable = lib.mkForce false;
  };
in {
  project.name = "nixos-container";
  # ports: host:container, host must be >=1024, same for container to test by vm
  # arion exec NAME bash
  services = mapVals (default arion-common) {

    combined = {
      nixos = {
        configuration = {
          imports = [
            # inputs.disko.nixosModules.disko
            ./servers/common
            ./servers/manual
          ];
        }
        // container-common
        ;
      };
      service = {
        # solves fuse error when running containers,
        # but also enables firewall and causes some warnings/errors
        privileged = true;
        # needed by: lldap opensearch woodpecker-server (unless privileged=true)
        # capabilities.CAP_SYS_ADMIN = true;
        ports = lib.lists.map (ports: "127.0.0.1:${ports}") [
          "8888:8888" # manual
        ];
      };
    };

  };
}
