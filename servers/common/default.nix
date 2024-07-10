{
  lib,
  inputs,
  ...
}: {
  imports =
    [
      # ./fresh.nix
      # ./net.nix
      # ./paranoid.nix
      # inputs.disko.nixosModules.disko  # nixosConfigurations: infinite recursion encountered
      ../../hcloud/disk-config.nix
      ../../hcloud/network.nix
    ]
    # ++ lib.attrValues {
    #   inherit
    #     (inputs.srvos.nixosModules)
    #     # server  # TODO reenable once versions aligned, see https://github.com/hercules-ci/arion/issues/249
    #     hardware-hetzner-cloud-arm
    #     ;
    # }
    ;
  # TODO: fill
  users.users.root.openssh.authorizedKeys.keys = ["ssh-dss AAAAB3Nza... alice@foobar"];
  system.stateVersion = "23.11";
  boot.tmp.useTmpfs = true;
  networking.useDHCP = false;

  # lacking srvos server:
  services.openssh.enable = true;

  # # Let's Encrypt ACME
  # security.acme = {
  #   acceptTerms = true;
  #   # defaults.email = pconf.mail.info;
  # };
}