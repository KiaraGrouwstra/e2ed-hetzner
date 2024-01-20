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
        tfConfig = inputs.terranix.lib.terranixConfiguration {
          inherit system;
          modules = [
            inputs.terranix-hcloud.terranixModules.hcloud
            ./config.nix
          ];
        };
        tf = "${pkgs.opentofu}/bin/tofu";
        sops = "${pkgs.sops}/bin/sops";
      in
      {
        defaultPackage = tfConfig;

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
            inputs.terranix.defaultPackage.${system}
            (opentofu.withPlugins (p: with p; [
              hcloud  # https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs
            ]))
          ];
        };

        apps = let
          tfCommand = cmd: ''
            if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi;
            export TF_CLI_CONFIG_FILE="ci.tfrc"
            cat << EOF > "$TF_CLI_CONFIG_FILE"
            credentials "app.terraform.io" {
                token = "$(${sops} -d --extract '["tf_cloud_token"]' .auto.tfvars.enc.yaml)"
            }
            EOF
            cp ${tfConfig} config.tf.json \
              && ${tf} init \
              && ${tf} ${cmd}
          '';
        in builtins.mapAttrs (name: script: {
            type = "app";
            program = toString (pkgs.writers.writeBash name script);
        }) {
          # nix run .#encode
          encode = "${sops} --output-type yaml -e .auto.tfvars.json > .auto.tfvars.enc.yaml";
          # nix run .#decode
          decode = "${sops} --output-type json -d .auto.tfvars.enc.yaml > .auto.tfvars.json";
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
            rm ${toString ./.}/*.tfstate*
            rm ${toString ./.}/.auto.tfvars.json
            rm ${toString ./.}/ci.tfrc
          '';
        };

        # nix run
        defaultApp = self.apps.${system}.apply;

        formatter = pkgs.treefmt;
      });
}
