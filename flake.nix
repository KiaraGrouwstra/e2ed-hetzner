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
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs = {self, ...} @ inputs: inputs.flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = inputs.nixpkgs.legacyPackages."${system}";
      inherit (pkgs) lib;
    in
    {
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
      in pkgs.mkShell {
        pname = "nixos-hcloud";
        packages = [
          inputs.arion.packages.${system}.default
          pkgs.direnv
          pkgs.rage
          pkgs.colmena
          (pkgs.opentofu.withPlugins (p:
            pkgs.lib.lists.map tofuProvider [
              p.hcloud
              p.ssh
              p.tls
              p.null
              p.external
            ]
          ))
          inputs.nixos-anywhere.packages.${system}.default
          pkgs.jq
        ];
      };

      terraform = let
        # possible TF blocks: https://opentofu.org/docs/language/syntax/json/#block-type-specific-exceptions
        options = lib.genAttrs ["data" "locals" "module" "output" "provider" "resource" "terraform" "variable"] (_k: lib.mkOption { default = {}; });
        # modules to load
        evaluated = lib.evalModules {
          modules = [
            { inherit options; }
            ./terraform.nix
          ];
        };
        # TF dislikes empty stuff
        sanitized = lib.filterAttrs (_k: v: v != {}) evaluated.config;
      in sanitized;

      # nixos configs to deploy by nixos-anywhere
      nixosConfigurations = let
        inherit (inputs.nixpkgs-guest) lib legacyPackages;
        inherit (legacyPackages."${system}") pkgs;
        util = (import ./lib {inherit pkgs lib;});
        hardware_path = ./hardware/hcloud-aarch64.nix;
     in
      # assumption: server name = config name
      lib.mapAttrs (name: fn: fn {
        inherit name system;
        specialArgs = {
          inherit
            inputs
            util
          ;
        };
      })
      {
        combined = { name, specialArgs, system }: lib.nixosSystem {
          inherit specialArgs;
          inherit system;
          modules = [
            ./servers/common
            ./hcloud/disk-config.nix
            inputs.disko.nixosModules.disko
            (lib.optionalAttrs (lib.pathExists hardware_path) hardware_path)
            {
              nixpkgs.hostPlatform = system;
              networking.hostName = name;
            }
          ];
        };
      };

      apps = let
        tfCommand = cmd:
          ''
            export WORKSPACE="tf-api"

            # # need cloud token as env var for CLI commands like `workspace`
            # if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi;
            # export TF_TOKEN_app_terraform_io="$(cat ~/.config/opentofu/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')";
            # # using local state, stash cloud state to prevent error `workspaces not supported`
            # if [[ -e .terraform/terraform.tfstate ]]; then mv .terraform/terraform.tfstate terraform.tfstate.d/$(tofu workspace show)/terraform.tfstate; fi;
            # # load cloud state to prevent error `Cloud backend initialization required: please run "tofu init"`
            # if [[ -e terraform.tfstate.d/$WORKSPACE/terraform.tfstate ]]; then mv terraform.tfstate.d/$WORKSPACE/terraform.tfstate .terraform/terraform.tfstate; fi;

            # creates ./.terraform/environment, ./terraform.tfstate.d/$WORKSPACE
            tofu workspace select -or-create $WORKSPACE;

            # updates ./.terraform.lock.hcl
            tofu providers lock && \
            # execute command
            tofu ${cmd} $@;
          '';
      in
        lib.mapAttrs (name: script: {
          type = "app";
          program = toString (pkgs.writers.writeBash name script);
        }) {
          vm = ''
            nixos-rebuild build-vm --flake .#manual && ./result/bin/run-nixos-vm
          '';
          convert = "nix eval --json .#terraform.${system} | jq > main.tf.json";
          clean = "rm -rf .terraform/ && rm -f terraform.tfstate* && rm -rf terraform.tfstate.d/";
          destroy = ''
            ${tfCommand "destroy"}
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
    });
}
