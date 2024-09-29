{ ... }: {
  networking = {
    networking.hostName = "my-host";
    # FIXME: Hetzner Cloud doesn't provide us with that configuration
    # systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f9:c010:52fd::1/128";

    # hostName = "vps";  # contradicted by arion
    # useDHCP = true;  # contradicted by one of my settings
    nameservers = [
      "2a01:4ff:ff00::add:2"
      "2a01:4ff:ff00::add:1"
    ];
    # interfaces.enp7s0.ipv6.addresses = [
    #   {
    #     # address = pconf.vps.ip6;
    #     prefixLength = 64;
    #   }
    # ];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp7s0";
    };
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 80 443 ];
    # firewall.allowedUDPPorts = [ ... ];
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "enp7s0";
      # Lazy IPv6 connectivity for the container
      enableIPv6 = true;
    };
  };
}
