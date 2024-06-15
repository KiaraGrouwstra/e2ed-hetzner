let
  flake = builtins.getFlake (toString ./.);
  inherit (flake) inputs pkgs;
in
  pkgs // {inherit inputs;}
