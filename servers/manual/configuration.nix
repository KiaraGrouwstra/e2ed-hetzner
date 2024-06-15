{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports =
    [
      inputs.disko.nixosModules.disko
      ../../hcloud/disk-config.nix
      ../../hcloud/network.nix
    ]
    ++ lib.attrValues {
      inherit
        (inputs.srvos.nixosModules)
        server
        hardware-hetzner-cloud-arm
        mixins-terminfo
        ;
    };
  # TODO: fill
  users.users.root.openssh.authorizedKeys.keys = ["ssh-dss AAAAB3Nza... alice@foobar"];
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
  system.nssModules = lib.mkForce [];
  systemd.services.nginx.serviceConfig.AmbientCapabilities = lib.mkForce ["CAP_NET_BIND_SERVICE"];
}
