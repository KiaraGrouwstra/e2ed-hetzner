{ lib
, pkgs
, ...
}: {
  project.name = "nixos container";
  services.webserver = {
    nixos = {
      useSystemd = true;
      configuration = import ./webserver/configuration.nix { inherit lib pkgs; };
    };
    service = {
      useHostStore = true;
      ports = [
        "8000:80" # host:container
      ];
    };
  };
}
