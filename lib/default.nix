{ lib, ... }:

{
  ssh-keys = import ./ssh-keys.nix { inherit lib; };
}
