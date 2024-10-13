{
  lib,
  ...
}:
# https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Cloud#Network_configuration
# The public IPv4 address of the server can automatically obtained be via DHCP.
# For IPv6 you have to statically configure both address and gateway.
{
  networking = {
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
        ipv4.routes = [
          { address = "172.31.1.1"; prefixLength = 32; }
        ];
        ipv6.routes = [
          { address = "fe80::1"; prefixLength = 128; }
        ];
      };
    };
  };
}
