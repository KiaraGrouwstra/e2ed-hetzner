{
  lib,
  modulesPath,
  inputs,
  util,
  ...
}:
{
  imports =
    [
      ./headless
      (modulesPath + "/installer/scan/not-detected.nix")
      (modulesPath + "/profiles/qemu-guest.nix")
      ./fresh.nix
      ./net.nix
      # ./paranoid.nix
      # inputs.srvos.nixosModules.server  # nixos-rebuild build-vm: infinite recursion encountered
      # inputs.srvos.nixosModules.hardware-hetzner-cloud-arm  # nixos-rebuild build-vm: infinite recursion encountered
      # inputs.disko.nixosModules.disko
    ];
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  users = {
    mutableUsers = false;
    users.root.openssh.authorizedKeys.keys = lib.attrValues (util.dirContents ".pub" ../../ssh-keys);
    users.root.password = "password";
  };
  # boot.tmp.useTmpfs = true;
  # networking.useDHCP = false;  # breaks port forwarding on VM
  system.stateVersion = "24.11";

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
