{
  lib,
  pkgs,
  ...
}: {
  services = {
    nginx = {
      enable = true;
      virtualHosts.localhost.root = "${pkgs.nix.doc}/share/doc/nix/manual";
    };
    nscd.enable = false;
  };
  system.nssModules = lib.mkForce [];
  systemd.services.nginx.serviceConfig.AmbientCapabilities = lib.mkForce ["CAP_NET_BIND_SERVICE"];
}
