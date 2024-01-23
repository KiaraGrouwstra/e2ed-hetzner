{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    nixpkgs-unfree = {
      url = "github:numtide/nixpkgs-unfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
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
    nix-nomad = {
      url = "github:tristanpemble/nix-nomad";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
      inputs.gomod2nix.follows = "gomod2nix";
    };
    gomod2nix = {
      url = "github:tweag/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, nix-nomad, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        unfree = inputs.nixpkgs-unfree.legacyPackages.${system}.pkgs;
        modules = {
          hcloud = [
            inputs.terranix-hcloud.terranixModules.hcloud
            ./config.nix
          ];
          nomad = [
            "${nix-nomad}/modules"
            ./nomad.nix
          ];
        };
        tfConfig = modules: inputs.terranix.lib.terranixConfiguration { inherit system modules; };
        tfCfg = builtins.mapAttrs (_: tfConfig) {
          hcloud = modules.hcloud ++ modules.nomad;
          nomad = modules.nomad;
        };
        tf = "${pkgs.opentofu}/bin/tofu";
        sops = "${pkgs.sops}/bin/sops";
      in
      {
        defaultPackage = tfCfg.hcloud;

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
            just
            pkgs.sops
            rage
            woodpecker-cli
            inputs.terranix.defaultPackage.${system}
            (opentofu.withPlugins (p: with p; [
              hcloud  # https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs
              nomad  # https://registry.terraform.io/providers/hashicorp/nomad/latest/docs
            ]))
            unfree.nomad
            damon
            levant
          ];
        };

        apps = let
          locally = ''
            # using local state, stash cloud state to prevent error `workspaces not supported`
            if [[ -e .terraform/terraform.tfstate ]]; then mv .terraform/terraform.tfstate terraform.tfstate.d/$(tofu workspace show)/terraform.tfstate; fi;
          '';
          compile = tfModule: ''
            echo ${tfModule};
            cp ${tfModule} config.tf.json \
              && chmod 0600 config.tf.json;
          '';
          tfCommand = cmd: ''
            # need cloud token as env var for CLI commands like `workspace`
            export TF_TOKEN_app_terraform_io="$(${sops} -d --extract '["tf_cloud_token"]' .auto.tfvars.enc.yaml)";
          '' + compile tfCfg.hcloud + locally + ''
            # load cloud state to prevent error `Cloud backend initialization required: please run "tofu init"`
            mv terraform.tfstate.d/hcloud/terraform.tfstate .terraform/terraform.tfstate;
            ${tf} workspace select -or-create hcloud;
            ${tf} init && ${tf} ${cmd};
          '';
        in builtins.mapAttrs (name: script: {
            type = "app";
            program = toString (pkgs.writers.writeBash name script);
        }) {
          validate = tfCommand "validate";
          apply = tfCommand "apply";
          plan = tfCommand "plan";
          cd = tfCommand "apply -auto-approve";
          local = locally + compile tfCfg.nomad + ''
            ${tf} workspace select -or-create nomad;
            ${tf} init && ${tf} apply -auto-approve;
          '';
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

        formatter = pkgs.treefmt;
      });
}
