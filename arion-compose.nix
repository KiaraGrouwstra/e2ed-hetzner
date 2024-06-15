{
  # smuggling in `inputs` thru `pkgs`: https://github.com/hercules-ci/arion/issues/247
  pkgs,
  ...
}: let
  inherit (pkgs) lib inputs;
  # fixes: Using host resolv.conf is not supported with systemd-resolved
  common = {
    systemd.network.enable = lib.mkForce false;
  };
in {
  project.name = "nixos container";
  services.webserver = {
    nixos = {
      useSystemd = true;
      configuration = import ./servers/manual/configuration.nix {inherit lib pkgs inputs;} // common;
    };
    service = {
      useHostStore = true;
      ports = [
        "8000:80" # host:container
      ];
    };
  };
}
