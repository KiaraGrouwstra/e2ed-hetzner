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
  server-common = import ./servers/common {inherit lib inputs;};
  arion-common = {
    nixos.useSystemd = true;
    service.useHostStore = true;
  };
  container-common = {
    systemd.network.enable = lib.mkForce false;
  };
in {
  project.name = "nixos-container";
  # ports: host:container, host must be >=1024
  # arion exec NAME bash
  services = mapVals (default arion-common) {

    combined = {
      nixos = {
        configuration = defaults [
          server-common
          (import ./servers/tryton {inherit lib pkgs inputs;})
          container-common
        ];
      };
      service = {
        ports = lib.lists.map (ports: "127.0.0.1:${ports}") [
          "8000:8000" # tryton
        ];
      };
    };

  };
}
