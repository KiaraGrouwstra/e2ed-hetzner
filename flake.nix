{
  inputs = {
    # arion's nixpkgs input must be named nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-guest.url = "github:NixOS/nixpkgs/nixos-23.11";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-guest";
    };
    teraflops = {
      url = "github:aanderse/teraflops/opentofu";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs-guest";
    };
    unfree = {
      url = "github:numtide/nixpkgs-unfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {self, teraflops, ...} @ inputs: let
    guest = rec {
      system = "aarch64-linux";
      pkgs = inputs.nixpkgs-guest.legacyPackages."${system}";
    };
    host = rec {
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages."${system}";
    };
    # https://github.com/NixOS/nixpkgs/issues/283015
    tofuProvider = provider:
      provider.override (oldArgs: {
        provider-source-address =
          host.pkgs.lib.replaceStrings
          ["https://registry.terraform.io/providers"]
          ["registry.opentofu.org"]
          oldArgs.homepage;
      });
  in {
    inherit inputs;
    # arion containers use the package set for the guest on the host system
    pkgs = inputs.nixpkgs-guest.legacyPackages."${host.system}";

    # for `nix fmt`
    formatter = {"${host.system}" = (inputs.treefmt-nix.lib.evalModule host.pkgs ./treefmt.nix).config.build.wrapper;};

    devShells = let
      inherit (host) system pkgs;
    in {
      "${system}".default = pkgs.mkShell {
        pname = "teraflops-hcloud";
        packages = [
          pkgs.rage
          pkgs.colmena
          (pkgs.opentofu.withPlugins (p:
            pkgs.lib.lists.map tofuProvider [
              p.hcloud
              p.ssh
              p.tls
            ]))
          teraflops.packages.${system}.default
        ];
      };
    };

    teraflops = let
      inherit (guest) pkgs;
      inherit (pkgs) lib;
    in { tf, outputs, resources, ... }: {
      imports = [
        teraflops.modules.hcloud
        (import ./teraflops.nix { inherit lib pkgs inputs tf outputs resources; })
      ];
    };
  }
  // inputs.flake-utils.lib.eachDefaultSystem (system:
    let
      inherit (host) pkgs;
    in
    {
      apps = let
        sops = "${pkgs.sops}/bin/sops";
        tfCommand = cmd:
          ''
            # # need cloud token as env var for CLI commands like `workspace`
            # if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi;
            export TF_TOKEN_app_terraform_io="$(${sops} -d --extract '["tf_cloud_token"]' .auto.tfvars.enc.yaml)";
            # # using local state, stash cloud state to prevent error `workspaces not supported`
            # if [[ -e .terraform/terraform.tfstate ]]; then mv .terraform/terraform.tfstate terraform.tfstate.d/$(tofu workspace show)/terraform.tfstate; fi;
            # load cloud state to prevent error `Cloud backend initialization required: please run "tofu init"`
            mv terraform.tfstate.d/hcloud/terraform.tfstate .terraform/terraform.tfstate;
            # tofu workspace select -or-create hcloud;
            teraflops init && tofu providers lock -platform=linux_aarch64 && teraflops -f $PWD ${cmd};
          '';
      in
        builtins.mapAttrs (name: script: {
          type = "app";
          program = toString (pkgs.writers.writeBash name script);
        }) {
          # https://github.com/hercules-ci/arion/issues/230
          local = ''
            nix run nixpkgs/23.11#arion -- up
          '';
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
