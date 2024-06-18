{
  lib,
  inputs,
  ...
}: {
  imports =
    [
      inputs.disko.nixosModules.disko
      ../hcloud/disk-config.nix
      ../hcloud/network.nix
    ]
    ++ lib.attrValues {
      inherit
        (inputs.srvos.nixosModules)
        # server  # arion: https://github.com/hercules-ci/arion/issues/249
        hardware-hetzner-cloud-arm
        ;
    };
  # TODO: fill
  users.users.root.openssh.authorizedKeys.keys = ["ssh-dss AAAAB3Nza... alice@foobar"];
  system.stateVersion = "23.11";
  boot.tmp.useTmpfs = true;
  networking.useDHCP = false;
}
