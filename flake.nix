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
            woodpecker-cli
            jq
            inputs.terranix.defaultPackage.${system}
            (opentofu.withPlugins (p: with p; [
              sops    # https://registry.terraform.io/providers/carlpett/sops/latest/docs
              hcloud  # https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs
            ]))
          ];
        };

        apps = let
          tfCommand = cmd: ''
            if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi;
            export TERRAFORM_CLOUD_TOKEN=$(${pkgs.sops}/bin/sops -d --extract '["tf_cloud_token"]' secrets.enc.yaml)
            export TF_CLI_CONFIG_FILE="ci.tfrc"
            cat << EOF > "$TF_CLI_CONFIG_FILE"
            credentials "app.terraform.io" {
                token = "$TERRAFORM_CLOUD_TOKEN"
            }
            EOF
            cp ${terraformConfiguration} config.tf.json \
              && ${tf} init \
              && ${tf} ${cmd}
          '';
        in builtins.mapAttrs (name: script: {
            type = "app";
            program = toString (pkgs.writers.writeBash name script);
        }) {
          # nix run .#check
          check = tfCommand "validate";
          # nix run .#apply
          apply = tfCommand "apply";
          # nix run .#plan
          plan = tfCommand "plan";
          # nix run .#cd
          cd = tfCommand "apply -auto-approve";
          # nix run .#destroy
          destroy = ''
            ${tfCommand "destroy"}
            rm ${toString ./.}/config.tf.json
            rm ${toString ./.}/terraform.tfstate*
            rm ${toString ./.}/secrets.yaml
            rm ${toString ./.}/ci.tfrc
          '';
        };

        # nix run
        defaultApp = self.apps.${system}.apply;

        formatter = pkgs.treefmt;
      });
}
