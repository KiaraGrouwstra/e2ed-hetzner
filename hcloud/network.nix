# https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Cloud#Network_configuration
# The public IPv4 address of the server can automatically obtained be via DHCP.
# For IPv6 you have to statically configure both address and gateway.
{
  systemd.network.enable = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "ens3"; # either ens3 (amd64) or enp1s0 (arm64)
    networkConfig.DHCP = "ipv4";
    # address = [
    #   # replace this address with the one assigned to your instance
    #   "2a01:4f8:aaaa:bbbb::1/64"
    # ];
    routes = [
      {routeConfig.Gateway = "fe80::1";}
    ];
  };
}
