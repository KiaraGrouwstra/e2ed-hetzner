{
  lib,
  inputs,
  ...
}:
{
  # nixos-rebuild build-vm: infinite recursion encountered
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud-arm
    # inputs.srvos.nixosModules.server  # error: failed to start SSH
  ];
  # bits to override from srvos.nixosModules.hardware-hetzner-cloud-arm:
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
}
