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
  server-common = import ./servers/common.nix {inherit lib inputs;};
  arion-common = {
    nixos.useSystemd = true;
    service.useHostStore = true;
  };
  container-common = {
    systemd.network.enable = lib.mkForce false;
  };
in {
  project.name = "nixos container";
  # ports: host:container
  services = mapVals (default arion-common) {

    manual = {
      nixos = {
        configuration = defaults [
          server-common
          (import ./servers/manual/configuration.nix {inherit lib pkgs;})
          container-common
        ];
      };
      service = {
        ports = [
          "8888:80"
        ];
      };
    };
    # tryton = {
    #   nixos = {
    #     configuration = common // import ./servers/tryton/configuration.nix {inherit lib pkgs;} // container-common;
    #   };
    #   service = {
    #     ports = [
    #       "8000:8000"
    #     ];
    #   };
    # };

  };
}
