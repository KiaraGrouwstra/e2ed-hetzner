{
  lib,
  inputs,
  ...
}:
{
  imports = [
    # inputs.srvos.nixosModules.hardware-hetzner-cloud-arm
  ];
  # bits to override from srvos.nixosModules.hardware-hetzner-cloud-arm:
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
}
