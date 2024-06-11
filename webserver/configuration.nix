{ pkgs
, lib
, # inputs,
  ...
}: {
  # imports = lib.attrValues (inputs.srvos.nixosModules) {
  #   inherit
  #     server
  #     hardware-hetzner-amd
  #     hardware-hetzner-arm
  #     ;
  # };
  system.stateVersion = "23.11";
  boot.tmp.useTmpfs = true;
  networking.useDHCP = false;
  services = {
    nginx = {
      enable = true;
      virtualHosts.localhost.root = "${pkgs.nix.doc}/share/doc/nix/manual";
    };
    nscd.enable = false;
  };
  system.nssModules = lib.mkForce [ ];
  systemd.services.nginx.serviceConfig.AmbientCapabilities = lib.mkForce [ "CAP_NET_BIND_SERVICE" ];
}
