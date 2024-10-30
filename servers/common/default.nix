{
  lib,
  modulesPath,
  inputs,
  util,
  ...
}: {
  imports = [
    # ./headless
    "${modulesPath}/installer/scan/not-detected.nix"
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ./fresh.nix
    ./net.nix
    ./ephemeral.nix
    ./persistence.nix
    ./paranoid.nix
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
