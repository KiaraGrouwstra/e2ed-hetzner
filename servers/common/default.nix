{
  lib,
  pkgs,
  inputs,
  util,
  ...
}:
{
  imports =
    [
      ./fresh.nix
      ./net.nix
      # ./paranoid.nix
      # inputs.disko.nixosModules.disko  # infinite recursion encountered
      # ../../hcloud/disk-config.nix  # arion: cannot have this without disko
      # ../../hcloud/network.nix  # arion: cannot have this without disko
    ]
    # ++ lib.attrValues {
    #   inherit
    #     (inputs.srvos.nixosModules)
    #     # server  # TODO reenable once versions aligned, see https://github.com/hercules-ci/arion/issues/249
    #     hardware-hetzner-cloud-arm
    #     ;
    # }
    ;
  users = {
    mutableUsers = false;
    users.root.openssh.authorizedKeys.keys = lib.attrValues (util.dirContents ".pub" ../../ssh-keys);
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
