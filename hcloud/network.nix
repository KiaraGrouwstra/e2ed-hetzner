{
  lib,
  resources,
  name,
  ...
}:
let
  server = resources.hcloud_server."${name}";
  network = lib.head server.network;
in
# https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Cloud#Network_configuration
# The public IPv4 address of the server can automatically obtained be via DHCP.
# For IPv6 you have to statically configure both address and gateway.
{
  networking = {
    hostName = name;
    defaultGateway = {
      address = "172.31.1.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address=server.ipv4_address; prefixLength=32; }
        ];
        ipv6.addresses = [
          { address=server.ipv6_address; prefixLength=64; }
        ];
        ipv4.routes = [
          { address = "172.31.1.1"; prefixLength = 32; }
        ];
        ipv6.routes = [
          { address = "fe80::1"; prefixLength = 128; }
        ];
      };
      # either ens3 (amd64) or enp7s0 (arm64)
      enp7s0 = {
        ipv4.addresses = [
          { address=network.ip; prefixLength=32; }
        ];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="${network.mac_address}", NAME="enp7s0"
  '';
}
