{
  inputs = {
    # arion's nixpkgs input must be named nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-guest.url = "github:NixOS/nixpkgs/nixos-24.05";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-guest";
    };
    teraflops = {
      url = "github:aanderse/teraflops";
      inputs.nixpkgs.follows = "nixpkgs";
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
    flake-utils.url = "github:numtide/flake-utils";
    arion = {
      url = "github:KiaraGrouwstra/arion/kiara";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {self, teraflops, nixpkgs, nixpkgs-guest, arion, ...} @ inputs: let
    guest = rec {
      system = "aarch64-linux";
      pkgs = nixpkgs-guest.legacyPackages."${system}";
      # inherit (nixpkgs-guest) lib;
    };
    host = rec {
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages."${system}";
      # inherit (nixpkgs) lib;
    };
    inherit (host.pkgs) lib;
    # https://github.com/NixOS/nixpkgs/issues/283015
    tofuProvider = provider:
      provider.override (oldArgs: {
        provider-source-address =
          lib.replaceStrings
          ["https://registry.terraform.io/providers"]
          ["registry.opentofu.org"]
          oldArgs.homepage;
      });
    # arion containers use the package set for the guest on the host system
    pkgs = nixpkgs-guest.legacyPackages."${host.system}";
  in {
    inherit inputs pkgs;

    # for `nix fmt`
    formatter = {"${host.system}" = (inputs.treefmt-nix.lib.evalModule host.pkgs ./treefmt.nix).config.build.wrapper;};

    devShells = let
      inherit (host) system pkgs;
    in {
      "${system}".default = pkgs.mkShell {
        pname = "teraflops-hcloud";
        packages = [
          arion.packages.${system}.default
          pkgs.rage
          pkgs.colmena
          (pkgs.opentofu.withPlugins (p:
            pkgs.lib.lists.map tofuProvider [
              p.hcloud
              p.ssh
              p.tls
            ]))
          teraflops.packages.${system}.default
          pkgs.jaq
        ];
      };
    };

    teraflops = let
      inherit (guest) pkgs;
    in { tf, outputs, resources, ... }: {
      imports = [
        teraflops.modules.hcloud
        (import ./teraflops.nix { inherit lib pkgs inputs tf outputs resources; })
      ];
    };

    # local VMs
    nixosConfigurations = let
      inherit (host) system;
      # specialArgs = {inherit inputs;};
    in {
      manual = nixpkgs-guest.lib.nixosSystem {
        inherit system pkgs lib;
        modules = [
          inputs.disko.nixosModules.disko
          ./servers/common/vm.nix
          ./servers/common
          ./servers/manual
          (let ips = [
            8888
          ]; in {
            virtualisation.vmVariant = {
              virtualisation.diskSize = 2048;
              virtualisation.forwardPorts = lib.lists.map (ip: {
                from = "host";
                host.port = ip;
                guest.port = ip;
              }) ips;
            };
            networking.firewall = {
              # enable = false;
              allowedTCPPorts = ips;
            };
          })
        ];
      };
    };
    
  }
  // inputs.flake-utils.lib.eachDefaultSystem (system:
    let
      inherit (host) pkgs;
    in
    {
      apps = let
        tfCommand = cmd:
          ''
            export WORKSPACE="hcloud"

            # # need cloud token as env var for CLI commands like `workspace`
            # if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi;
            export TF_TOKEN_app_terraform_io="$(cat ~/.config/opentofu/credentials.tfrc.json | jaq -r '.credentials."app.terraform.io".token')";
            # # using local state, stash cloud state to prevent error `workspaces not supported`
            # if [[ -e .terraform/terraform.tfstate ]]; then mv .terraform/terraform.tfstate terraform.tfstate.d/$(teraflops tf workspace show)/terraform.tfstate; fi;
            # load cloud state to prevent error `Cloud backend initialization required: please run "tofu init"`
            if [[ -e terraform.tfstate.d/$WORKSPACE/terraform.tfstate ]]; then mv terraform.tfstate.d/$WORKSPACE/terraform.tfstate .terraform/terraform.tfstate; fi;

            # creates ./.terraform/environment, ./terraform.tfstate.d/$WORKSPACE
            teraflops tf workspace select -or-create $WORKSPACE;

            # updates ./.terraform/plugin_path, ./.direnv/
            teraflops init --upgrade && \
            # updates ./.terraform.lock.hcl
            tofu providers lock -platform=linux_amd64 && \
            # execute command
            teraflops -f $PWD ${cmd};
          '';
      in
        builtins.mapAttrs (name: script: {
          type = "app";
          program = toString (pkgs.writers.writeBash name script);
        }) {
          local = "${lib.getExe arion.packages.${system}.default} up";
          vm = ''
            nixos-rebuild build-vm --flake .#manual && ./result/bin/run-nixos-vm
          '';
          clean = "rm -rf .terraform/ && rm -rf terraform.tfstate.d/";
          validate = tfCommand "validate";
          apply = tfCommand "apply";
          plan = tfCommand "plan";
          cd = tfCommand "apply -auto-approve";
          destroy = ''
            ${tfCommand "destroy"}
            for f in "config.tf.json *.tfstate* *.tfvars.json ci.tfrc .terraform terraform.tfstate.d"; do
                echo $f
                if [[ -e "${toString ./.}/$f" ]]; then
                   rm -rf "${toString ./.}/$f";
                fi;
            done
          '';
        };

      # nix run
      defaultApp = self.apps.${system}.apply;
    });
}
