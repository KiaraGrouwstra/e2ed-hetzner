{
  inputs = {
    # arion's nixpkgs input must be named nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-guest.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    unfree = {
      url = "github:numtide/nixpkgs-unfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-guest";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs-guest";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs-guest";
      inputs.disko.follows = "disko";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
    arion = {
      url = "github:KiaraGrouwstra/arion/kiara";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    impermanence.url = "github:nix-community/impermanence"; 
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    inherit (nixpkgs) lib;

    # nixos configs to deploy by nixos-anywhere
    nixosConfigurations = system: let
      inherit (inputs.nixpkgs-guest) lib legacyPackages;
      inherit (legacyPackages."${system}") pkgs;
      util = import ./lib {inherit pkgs lib;};
    in
      # assumption: server name = config name
      lib.mapAttrs (name: fn:
        fn {
          inherit name system;
          specialArgs = {
            inherit
              inputs
              util
              ;
          };
        })
      {
        combined = {
          name,
          specialArgs,
          system,
        }:
          lib.nixosSystem {
            inherit specialArgs;
            inherit system;
            modules = [
              ./servers/common/vm.nix
              ./servers/common
              ./hcloud
              ./hcloud/disk-config.nix
              {
                nixpkgs.hostPlatform = system;
                networking.hostName = name;
              }
            ];
          };
      };
  in
    lib.attrsets.recursiveUpdate {
      nixosConfigurations = nixosConfigurations system;
    } (inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages."${system}";
      inherit (pkgs) lib;
    in {
      inherit pkgs lib;

      # for `nix fmt`
      formatter = (inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix).config.build.wrapper;

      devShells.default = let
        # https://github.com/NixOS/nixpkgs/issues/283015
        tofuProvider = provider:
          provider.override (oldArgs: {
            provider-source-address =
              lib.replaceStrings
              ["https://registry.terraform.io/providers"]
              ["registry.opentofu.org"]
              oldArgs.homepage;
          });
      in
        pkgs.mkShell {
          pname = "nixos-hcloud";
          packages = let
            tfPlugins = p: [
              p.hcloud
              p.ssh
              p.tls
              p.null
              p.external
              p.cloudflare
            ];
          in [
            inputs.arion.packages.${system}.default
            pkgs.direnv
            pkgs.rage
            pkgs.colmena
            (pkgs.opentofu.withPlugins (p: pkgs.lib.lists.map tofuProvider (tfPlugins p)))
            inputs.nixos-anywhere.packages.${system}.default
            pkgs.jq
          ];
        };

      terraform = let
        pkgs = nixpkgs.legacyPackages."${system}";
        # possible TF blocks: https://opentofu.org/docs/language/syntax/json/#block-type-specific-exceptions
        options = lib.genAttrs ["data" "locals" "module" "output" "provider" "resource" "terraform" "variable"] (_k: lib.mkOption {default = {};});
        # modules to load
        evaluated = lib.evalModules {
          modules = [
            {inherit options;}
            (import ./terraform.nix { inherit lib pkgs inputs; })
          ];
        };
        # TF dislikes empty stuff
        sanitized = lib.mapAttrs (_k: lib.filterAttrs (_k: v: v != {})) (lib.filterAttrs (_k: v: v != {}) evaluated.config);
      in
        sanitized;

      nixosConfigurations = nixosConfigurations system;

      apps = lib.mapAttrs (name: script: {
          type = "app";
          program = toString (pkgs.writers.writeBash name script);
        }) {
          vm = ''
            nixos-rebuild build-vm --flake .#combined && ./result/bin/run-combined-vm
          '';
          convert = "nix eval --json .#terraform.${system} | jq > main.tf.json";
          clean = "rm -rf .terraform/ && rm -f terraform.tfstate* && rm -rf terraform.tfstate.d/";
          destroy = ''
            tofu destroy
            for f in "config.tf.json *.tfstate* *.tfvars.json ci.tfrc .terraform terraform.tfstate.d"; do
                echo $f
                if [[ -e "${toString ./.}/$f" ]]; then
                   rm -rf "${toString ./.}/$f";
                fi;
            done
          '';
          import = ''eval $(tofu show -json | jq -r '.values.root_module.resources | map(select(.mode == "data") | .type as $type | .values[.type[7:]] | map("tofu import " + $type[0:-1] + "." + .name + " " + (.id | tostring) + ";"))[][]')'';
        };

      # nix run
      defaultApp = self.apps.${system}.convert;
    }));
}
