{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    terranix-hcloud = {
      url = "github:terranix/terranix-hcloud";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.terranix.follows = "terranix";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        terraformConfiguration = inputs.terranix.lib.terranixConfiguration {
          inherit system;
          modules = [
            inputs.terranix-hcloud.terranixModules.hcloud
            ./config.nix
          ];
        };
        tf = "${pkgs.opentofu}/bin/tofu";
      in
      {
        defaultPackage = terraformConfiguration;

        # Auto formatters. This also adds a flake check to ensure that the
        # source tree was auto formatted.
        treefmt.config = {
          projectRootFile = "flake.nix";
          programs = {
            nixpkgs-fmt.enable = true;
          };
        };

        # nix develop
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            treefmt
            sops
            rage
            inputs.terranix.defaultPackage.${system}
            (opentofu.withPlugins (p: with p; [
              sops    # https://registry.terraform.io/providers/carlpett/sops/latest/docs
              hcloud  # https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs
            ]))
          ];
        };

        # nix run ".#compile"
        apps.compile = {
          type = "app";
          program = toString (pkgs.writers.writeBash "compile" ''
            cp ${terraformConfiguration} config.tf.json
          '');
        };

        # nix run ".#check"
        apps.check = {
          type = "app";
          program = toString (pkgs.writers.writeBash "check" ''
            if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
            cp ${terraformConfiguration} config.tf.json \
              && ${tf} init \
              && ${tf} validate
          '');
        };

        # nix run ".#apply"
        apps.apply = {
          type = "app";
          program = toString (pkgs.writers.writeBash "apply" ''
            if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
            cp ${terraformConfiguration} config.tf.json \
              && ${tf} init \
              && ${tf} apply
          '');
        };

        # nix run ".#destroy"
        apps.destroy = {
          type = "app";
          program = toString (pkgs.writers.writeBash "destroy" ''
            if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
            cp ${terraformConfiguration} config.tf.json \
              && ${tf} init \
              && ${tf} destroy
            rm ${toString ./.}/config.tf.json
            rm ${toString ./.}/terraform.tfstate*
          '');
        };

        # nix run
        defaultApp = self.apps.${system}.apply;

        formatter = pkgs.treefmt;
      });
}
