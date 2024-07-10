{
  lib,
  pkgs,
  ...
}: {
  services = {
    nginx = {
      enable = true;
      virtualHosts.localhost = {
        root = "${pkgs.nix.doc}/share/doc/nix/manual";
        listen = [
          {
            addr = "127.0.0.1";
            port = 8888;
            ssl = false;
          }
        ];
      };
    };
    nscd.enable = false;
  };
  system.nssModules = lib.mkForce [];
  systemd.services.nginx.serviceConfig.AmbientCapabilities = lib.mkForce ["CAP_NET_BIND_SERVICE"];
}
