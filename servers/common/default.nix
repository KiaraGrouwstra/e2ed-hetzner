{
  lib,
  inputs,
  util,
  ...
}:
{
  imports =
    [
      ./headless
      ./fresh.nix
      ./net.nix
      # ./paranoid.nix
      inputs.srvos.nixosModules.server
      inputs.srvos.nixosModules.hardware-hetzner-cloud-arm
      # inputs.disko.nixosModules.disko
    ];
  users = {
    mutableUsers = false;
    users.root.openssh.authorizedKeys.keys = lib.attrValues (util.dirContents ".pub" ../../ssh-keys);
    users.root.password = "password";
  };
  system.stateVersion = "24.05";
  boot.tmp.useTmpfs = true;
  # networking.useDHCP = false;  # breaks port forwarding on VM

  # lacking srvos server:
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
  };

  # # Let's Encrypt ACME
  # security.acme = {
  #   acceptTerms = true;
  #   # defaults.email = pconf.mail.info;
  # };
}
