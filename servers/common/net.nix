{
  lib,
  ...
}:
{
  networking = {
    nameservers = [
      "8.8.8.8"
      "2a01:4ff:ff00::add:2"
      "2a01:4ff:ff00::add:1"
    ];
    usePredictableInterfaceNames = lib.mkForce false;
  };
}
